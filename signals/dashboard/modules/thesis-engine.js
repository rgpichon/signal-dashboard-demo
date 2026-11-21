/**
 * SIGNAL Thesis Engine — Phase T4 (Explore mode)
 */
(function () {
  'use strict';

  var API_BASE =
    typeof window.SIGNAL_API_BASE !== 'undefined'
      ? window.SIGNAL_API_BASE
      : 'http://localhost:8000';

  window.ThesisEngine = {
    activeThesisId: null,
    thesisNode: {
      focal_series_id: '',
      shock_pct: 20,
      direction: 'long',
      asset_class: 'commodity',
      geography: 'global',
      time_horizon: 'medium',
      confidence: 'moderate',
      claim: '',
      trigger: '',
      asset_expression: '',
      generated_statement: '',
      addressed: [],
      flagged: [],
      tensions: [],
      completeness_pct: 0,
      consistency: 'clean',
    },
    dismissedIds: [],
    mode: 'explore',
    expanding: false,
    flaggedQueue: [],
    explainInFlight: false,
    regimeSnapshot: null,
    stanceColors: {},
    chartVisibility: {},
    chartModel: null,
    _chartResizeObserver: null,
    variableHistory: {},
    _historyLoaded: false,
    monitorData: null,
    _monitorInterval: null,
  };

  var HIST_DAYS = 60;
  var PREFIX_COLORS = {
    CM: '#f0a94a',
    RATES: '#5b9ef4',
    EQ: '#2dd4a0',
    FX: '#94a3b8',
    CREDIT: '#f4735a',
    MACRO: '#a78bfa',
  };
  var STANCE_COLORS = {
    supports: '#2dd4a0',
    challenges: '#f4735a',
    neutral: '#555d6e',
  };

  var REGIME_KEYS = [
    { key: 'growth_pulse', label: 'GRW' },
    { key: 'credit_stress', label: 'CRD' },
    { key: 'real_yield', label: 'RY' },
    { key: 'dollar_strength', label: 'USD' },
    { key: 'rates_vol', label: 'RV' },
    { key: 'equity_vol', label: 'EV' },
    { key: 'curve_shape', label: 'CRV' },
  ];

  var MONITOR_INDICATOR_ORDER = [
    'growth_pulse',
    'credit_stress',
    'real_yield',
    'dollar_strength',
    'rates_vol',
    'equity_vol',
    'curve_shape',
  ];

  function esc(s) {
    if (s == null) return '';
    return String(s)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;');
  }

  function escAttr(s) {
    return esc(s).replace(/"/g, '&quot;');
  }

  function teardownChartObserver() {
    var ro = window.ThesisEngine._chartResizeObserver;
    if (ro) {
      try {
        ro.disconnect();
      } catch (e) {}
      window.ThesisEngine._chartResizeObserver = null;
    }
  }

  function horizonDaysFromThesis() {
    var h = window.ThesisEngine.thesisNode.time_horizon || 'medium';
    if (h === 'short') return 60;
    if (h === 'long') return 300;
    return 150;
  }

  function prefixColorForSeriesId(sid) {
    if (!sid) return '#888888';
    var i = String(sid).indexOf('.');
    var pre = i >= 0 ? String(sid).slice(0, i).toUpperCase() : String(sid).toUpperCase();
    return PREFIX_COLORS[pre] || '#888888';
  }

  function lineColorForSeries(seriesId, isFocal) {
    var st = window.ThesisEngine.stanceColors[seriesId];
    if (st) return st;
    return prefixColorForSeriesId(seriesId);
  }

  function parseISODate(d) {
    if (!d) return new Date(NaN);
    var s = String(d);
    var m = s.match(/^(\d{4})-(\d{2})-(\d{2})/);
    if (m) {
      return new Date(Date.UTC(+m[1], +m[2] - 1, +m[3], 12, 0, 0));
    }
    var x = new Date(s);
    return isNaN(x.getTime()) ? new Date(NaN) : x;
  }

  function dayDiffDaysolder(dNewer, dOlder) {
    var a = parseISODate(dNewer).getTime();
    var b = parseISODate(dOlder).getTime();
    if (isNaN(a) || isNaN(b)) return NaN;
    return Math.round((a - b) / 86400000);
  }

  var CHART_MAX_SERIES = 6;
  var CHART_MIN_IMPORTANCE = 0.1;

  /** Focal always; plus up to 5 other layer-1 OLS by importance (excl. focal). Layer 2 / static excluded. */
  function selectChartSeriesIds(flagged, focal) {
    var pool = [];
    (flagged || []).forEach(function (f) {
      if (!f || !f.series_id) return;
      if (f.layer !== 1) return;
      if ((f.source || '').toLowerCase() !== 'ols') return;
      var imp = f.importance_score;
      if (imp == null || isNaN(imp) || imp < CHART_MIN_IMPORTANCE) return;
      if (f.predicted_move_pct == null || isNaN(f.predicted_move_pct)) return;
      pool.push(f);
    });
    pool.sort(function (a, b) {
      return (b.importance_score || 0) - (a.importance_score || 0);
    });
    var ids = [];
    var seen = {};
    if (focal) {
      ids.push(focal);
      seen[focal] = true;
    }
    for (var i = 0; i < pool.length && ids.length < CHART_MAX_SERIES; i++) {
      var sid = pool[i].series_id;
      if (seen[sid]) continue;
      seen[sid] = true;
      ids.push(sid);
    }
    return ids;
  }

  function buildProjectionMeta(flagged, focal, chartIds) {
    var rowById = {};
    (flagged || []).forEach(function (f) {
      if (f && f.series_id) rowById[f.series_id] = f;
    });
    var out = [];
    (chartIds || []).forEach(function (sid) {
      var f = rowById[sid];
      if (
        f &&
        f.predicted_move_pct != null &&
        !isNaN(f.predicted_move_pct)
      ) {
        out.push({
          series_id: f.series_id,
          name: f.name || '',
          source: 'ols',
          r_squared: f.r_squared,
          predicted_move_pct: f.predicted_move_pct,
          predicted_move_ewls: f.predicted_move_ewls,
          ci_95_low: f.ci_95_low,
          ci_95_high: f.ci_95_high,
          isFocal: !!(focal && sid === focal),
        });
      } else if (focal && sid === focal) {
        var shock = parseFloat(window.ThesisEngine.thesisNode.shock_pct);
        if (isNaN(shock)) shock = 0;
        out.push({
          series_id: focal,
          name: '',
          source: 'ols',
          r_squared: 1,
          predicted_move_pct: shock,
          ci_95_low: null,
          ci_95_high: null,
          isFocal: true,
        });
      }
    });
    return out;
  }

  function mountScenarioChartIfNeeded() {
    var slot = document.getElementById('te-chart-slot');
    if (!slot || slot.querySelector('#te-chart-block')) return;
    slot.innerHTML =
      '<div class="te-chart-block" id="te-chart-block">' +
      '<div class="te-chart-header">' +
      '<span class="te-chart-title">Scenario — price paths &amp; projections</span>' +
      '<span class="te-chart-subtitle">normalised to 0% at today</span>' +
      '<button type="button" class="te-chart-toggle" id="te-chart-toggle">hide ↑</button>' +
      '</div>' +
      '<div class="te-chart-body" id="te-chart-body">' +
      '<div class="te-chart-tooltip" id="te-chart-tooltip"></div>' +
      '<svg id="te-scenario-svg" xmlns="http://www.w3.org/2000/svg"></svg>' +
      '</div>' +
      '<div class="te-chart-legend" id="te-chart-legend"></div>' +
      '</div>';
    var toggle = document.getElementById('te-chart-toggle');
    var body = document.getElementById('te-chart-body');
    if (toggle && body) {
      toggle.addEventListener('click', function () {
        body.classList.toggle('hidden');
        toggle.textContent = body.classList.contains('hidden') ? 'show ↓' : 'hide ↑';
        if (!body.classList.contains('hidden')) rerenderScenarioChart();
      });
    }
    var block = document.getElementById('te-chart-block');
    teardownChartObserver();
    if (block && typeof ResizeObserver !== 'undefined') {
      window.ThesisEngine._chartResizeObserver = new ResizeObserver(function () {
        if (window.ThesisEngine.mode === 'explore') rerenderScenarioChart();
      });
      window.ThesisEngine._chartResizeObserver.observe(block);
    }
  }

  function loadScenarioChartAfterExpand(flagged) {
    mountScenarioChartIfNeeded();
    var focal = (window.ThesisEngine.thesisNode.focal_series_id || '').trim();
    var chartIds = selectChartSeriesIds(flagged, focal);
    var fetchIds = chartIds.slice();
    var horizon = horizonDaysFromThesis();
    var totalDays = HIST_DAYS + horizon;
    window.ThesisEngine.chartVisibility = {};
    window.ThesisEngine.stanceColors = {};
    var projMeta = buildProjectionMeta(flagged, focal, chartIds);
    projMeta.forEach(function (m) {
      window.ThesisEngine.chartVisibility[m.series_id] = true;
    });
    fetchIds.forEach(function (id) {
      window.ThesisEngine.chartVisibility[id] = true;
    });
    window.ThesisEngine.chartModel = {
      focalId: focal || null,
      horizonDays: horizon,
      totalDays: totalDays,
      historicalById: {},
      projectionMeta: projMeta,
    };
    if (!fetchIds.length) {
      rerenderScenarioChart();
      return;
    }
    var url =
      API_BASE +
      '/api/research/series?series_ids=' +
      encodeURIComponent(fetchIds.join(',')) +
      '&days=' +
      HIST_DAYS;
    fetch(url)
      .then(function (r) {
        return r.json();
      })
      .then(function (data) {
        var hist = {};
        if (!data || data.error || !data.series) {
          window.ThesisEngine.chartModel.historicalById = hist;
          rerenderScenarioChart();
          return;
        }
        var seriesObj = data.series;
        fetchIds.forEach(function (sid) {
          var rows = seriesObj[sid];
          if (!rows || !rows.length) return;
          var sorted = rows.slice().sort(function (a, b) {
            return String(a.date).localeCompare(String(b.date));
          });
          var last = sorted[sorted.length - 1];
          var vToday = parseFloat(last.value);
          if (!isFinite(vToday) || vToday === 0) return;
          var lastDate = last.date;
          var pts = [];
          for (var i = 0; i < sorted.length; i++) {
            var vr = parseFloat(sorted[i].value);
            if (!isFinite(vr)) continue;
            var dd = dayDiffDaysolder(lastDate, sorted[i].date);
            if (isNaN(dd) || dd < 0 || dd > HIST_DAYS) continue;
            var dayX = HIST_DAYS - dd;
            var pct = (vr / vToday - 1) * 100;
            pts.push({
              dayX: dayX,
              pct: pct,
              dateStr: String(sorted[i].date),
            });
          }
          if (pts.length) {
            pts.sort(function (a, b) {
              return a.dayX - b.dayX;
            });
            hist[sid] = pts;
          }
        });
        window.ThesisEngine.chartModel.historicalById = hist;
        rerenderScenarioChart();
      })
      .catch(function () {
        if (window.ThesisEngine.chartModel) {
          window.ThesisEngine.chartModel.historicalById = {};
        }
        rerenderScenarioChart();
      });
  }

  function rerenderScenarioChart() {
    var model = window.ThesisEngine.chartModel;
    var svg = document.getElementById('te-scenario-svg');
    var leg = document.getElementById('te-chart-legend');
    var tip = document.getElementById('te-chart-tooltip');
    var bodyEl = document.getElementById('te-chart-body');
    if (!model || !svg || !leg) return;

    var margin = { top: 18, right: 24, bottom: 28, left: 44 };
    var height = 240;
    var containerW =
      bodyEl && bodyEl.clientWidth > 0 ? bodyEl.clientWidth : svg.clientWidth || 400;
    if (containerW < 120) containerW = 400;
    var width = containerW;
    var innerW = width - margin.left - margin.right;
    var innerH = height - margin.top - margin.bottom;
    var totalDays = model.totalDays;
    var focalId = model.focalId;

    function xScale(d) {
      return margin.left + (d / totalDays) * innerW;
    }
    function yScale(v, yMin, yMax) {
      var span = yMax - yMin || 1e-6;
      return margin.top + innerH - ((v - yMin) / span) * innerH;
    }

    var values = [];
    var hist = model.historicalById || {};
    Object.keys(hist).forEach(function (sid) {
      (hist[sid] || []).forEach(function (p) {
        values.push(p.pct);
      });
    });
    (model.projectionMeta || []).forEach(function (m) {
      var olsP = m.predicted_move_pct;
      var ewlsP = m.predicted_move_ewls;
      var dualProj =
        ewlsP != null &&
        !isNaN(+ewlsP) &&
        olsP != null &&
        !isNaN(+olsP) &&
        Math.abs(+ewlsP - +olsP) > 1.0;
      var primaryY = dualProj ? +ewlsP : +olsP;
      values.push(primaryY);
      if (dualProj) values.push(+olsP);
      if (m.ci_95_low != null) values.push(m.ci_95_low);
      if (m.ci_95_high != null) values.push(m.ci_95_high);
    });
    values.push(0);
    var yMinRaw = values.length ? Math.min.apply(null, values) : -5;
    var yMaxRaw = values.length ? Math.max.apply(null, values) : 5;
    var yMin = yMinRaw * 1.15;
    var yMax = yMaxRaw * 1.15;
    if (yMin === yMax) {
      yMin -= 1;
      yMax += 1;
    }

    var todayX = xScale(HIST_DAYS);
    var projEndX = xScale(totalDays);

    var parts = [];
    parts.push(
      '<defs><clipPath id="te-chart-clip"><rect x="' +
        margin.left +
        '" y="' +
        margin.top +
        '" width="' +
        innerW +
        '" height="' +
        innerH +
        '"/></clipPath></defs>'
    );

    var gridLevels = [-15, -10, -5, 0, 5, 10, 15, 20, 25];
    gridLevels.forEach(function (gv) {
      if (gv < yMin || gv > yMax) return;
      var gy = yScale(gv, yMin, yMax);
      var stroke =
        gv === 0 ? 'rgba(255,255,255,0.12)' : 'rgba(255,255,255,0.04)';
      var sw = gv === 0 ? 1 : 0.5;
      parts.push(
        '<line x1="' +
          margin.left +
          '" y1="' +
          gy +
          '" x2="' +
          (margin.left + innerW) +
          '" y2="' +
          gy +
          '" stroke="' +
          stroke +
          '" stroke-width="' +
          sw +
          '"/>'
      );
    });
    var gLo = Math.floor(yMin / 5) * 5;
    var gHi = Math.ceil(yMax / 5) * 5;
    for (var g = gLo; g <= gHi; g += 5) {
      if (g < yMin || g > yMax) continue;
      var gyTxt = yScale(g, yMin, yMax);
      parts.push(
        '<text x="' +
          (margin.left - 8) +
          '" y="' +
          (gyTxt + 3) +
          '" text-anchor="end" font-size="9" font-family="ui-monospace,Menlo,monospace" fill="rgba(255,255,255,0.35)">' +
          g +
          '%</text>'
      );
    }

    parts.push(
      '<rect x="' +
        todayX +
        '" y="' +
        margin.top +
        '" width="' +
        (margin.left + innerW - todayX) +
        '" height="' +
        innerH +
        '" fill="rgba(255,255,255,0.015)" clip-path="url(#te-chart-clip)"/>'
    );

    var vis = window.ThesisEngine.chartVisibility;

    (model.projectionMeta || []).forEach(function (m) {
      var sid = m.series_id;
      var isFoc = !!(focalId && sid === focalId);
      if (!isFoc && vis[sid] === false) return;
      var col = lineColorForSeries(sid, isFoc);
      if (
        m.ci_95_low != null &&
        m.ci_95_high != null &&
        !isNaN(m.ci_95_low) &&
        !isNaN(m.ci_95_high)
      ) {
        var y0 = yScale(0, yMin, yMax);
        var yL = yScale(m.ci_95_low, yMin, yMax);
        var yH = yScale(m.ci_95_high, yMin, yMax);
        var op = 0.08;
        parts.push(
          '<polygon points="' +
            todayX +
            ',' +
            y0 +
            ' ' +
            projEndX +
            ',' +
            yL +
            ' ' +
            projEndX +
            ',' +
            yH +
            '" fill="' +
            col +
            '" fill-opacity="' +
            op +
            '" clip-path="url(#te-chart-clip)"/>'
        );
      }
    });

    (model.projectionMeta || []).forEach(function (m) {
      var sid = m.series_id;
      var isFoc = !!(focalId && sid === focalId);
      if (!isFoc && vis[sid] === false) return;
      var col = lineColorForSeries(sid, isFoc);
      var olsPred = m.predicted_move_pct;
      var ewlsPred = m.predicted_move_ewls;
      var useDual =
        ewlsPred != null &&
        !isNaN(+ewlsPred) &&
        olsPred != null &&
        !isNaN(+olsPred) &&
        Math.abs(+ewlsPred - +olsPred) > 1.0;
      var y0 = yScale(0, yMin, yMax);
      var swP = isFoc ? 2 : Math.min(2, Math.max(0.8, 0.8 + (m.r_squared || 0) * 1.2));
      var opP = isFoc ? 1 : 0.75;
      var dash = m.source === 'static_graph' ? ' stroke-dasharray="4 3"' : '';

      if (useDual) {
        var yOls = yScale(+olsPred, yMin, yMax);
        var swSec = swP * 0.7;
        var opSec = opP * 0.3;
        parts.push(
          '<line x1="' +
            todayX +
            '" y1="' +
            y0 +
            '" x2="' +
            projEndX +
            '" y2="' +
            yOls +
            '" stroke="' +
            col +
            '" stroke-width="' +
            swSec +
            '" stroke-opacity="' +
            opSec +
            '" stroke-dasharray="4 3" clip-path="url(#te-chart-clip)"/>'
        );
        var olsLbl =
          '(OLS: ' +
          (+olsPred >= 0 ? '+' : '') +
          Number(olsPred).toFixed(1) +
          '%)';
        parts.push(
          '<text x="' +
            (projEndX + 4) +
            '" y="' +
            (yOls + 3) +
            '" font-size="8" font-family="ui-monospace,Menlo,monospace" fill="' +
            col +
            '" fill-opacity="0.7">' +
            esc(olsLbl) +
            '</text>'
        );
      }

      var primaryPred = useDual ? +ewlsPred : +olsPred;
      var y1 = yScale(primaryPred, yMin, yMax);
      parts.push(
        '<line x1="' +
          todayX +
          '" y1="' +
          y0 +
          '" x2="' +
          projEndX +
          '" y2="' +
          y1 +
          '" stroke="' +
          col +
          '" stroke-width="' +
          swP +
          '" stroke-opacity="' +
          opP +
          '"' +
          dash +
          ' clip-path="url(#te-chart-clip)"/>'
      );
      var lbl =
        (primaryPred >= 0 ? '+' : '') +
        Number(primaryPred).toFixed(1) +
        '%';
      parts.push(
        '<text x="' +
          (projEndX + 4) +
          '" y="' +
          (y1 + 3) +
          '" font-size="9" font-family="ui-monospace,Menlo,monospace" fill="' +
          col +
          '">' +
          esc(lbl) +
          '</text>'
      );
    });

    Object.keys(hist).forEach(function (sid) {
      var isFoc = !!(focalId && sid === focalId);
      if (!isFoc && vis[sid] === false) return;
      var pts = hist[sid];
      if (!pts || !pts.length) return;
      var col = lineColorForSeries(sid, isFoc);
      var swH = isFoc ? 2 : 1;
      var opH = isFoc ? 1 : 0.65;
      var d = pts
        .map(function (p) {
          return xScale(p.dayX) + ',' + yScale(p.pct, yMin, yMax);
        })
        .join(' ');
      parts.push(
        '<polyline points="' +
          d +
          '" fill="none" stroke="' +
          col +
          '" stroke-width="' +
          swH +
          '" stroke-opacity="' +
          opH +
          '" clip-path="url(#te-chart-clip)"/>'
      );
    });

    Object.keys(hist).forEach(function (sid) {
      var isFoc = !!(focalId && sid === focalId);
      if (!isFoc && vis[sid] === false) return;
      var pts = hist[sid];
      if (!pts || !pts.length) return;
      var col = lineColorForSeries(sid, isFoc);
      var d = pts
        .map(function (p) {
          return xScale(p.dayX) + ',' + yScale(p.pct, yMin, yMax);
        })
        .join(' ');
      parts.push(
        '<polyline data-series-id="' +
          esc(sid) +
          '" class="te-scenario-hit" points="' +
          d +
          '" fill="none" stroke="transparent" stroke-width="14" clip-path="url(#te-chart-clip)"/>'
      );
    });

    parts.push(
      '<line x1="' +
        todayX +
        '" y1="' +
        margin.top +
        '" x2="' +
        todayX +
        '" y2="' +
        (margin.top + innerH) +
        '" stroke="rgba(255,255,255,0.2)" stroke-width="1" stroke-dasharray="3 3"/>'
    );
    parts.push(
      '<text x="' +
        todayX +
        '" y="' +
        (margin.top - 4) +
        '" text-anchor="middle" font-size="9" font-family="ui-monospace,Menlo,monospace" fill="rgba(255,255,255,0.2)">today / trigger</text>'
    );

    var half = model.horizonDays / 2;
    var xLabs = [
      { d: 0, t: '−' + HIST_DAYS + 'd' },
      { d: HIST_DAYS / 2, t: '−' + HIST_DAYS / 2 + 'd' },
      { d: HIST_DAYS, t: 'now' },
      { d: HIST_DAYS + half, t: '+' + half + 'd' },
      { d: totalDays, t: '+' + model.horizonDays + 'd' },
    ];
    xLabs.forEach(function (L) {
      var xx = xScale(L.d);
      parts.push(
        '<text x="' +
          xx +
          '" y="' +
          (height - 8) +
          '" text-anchor="middle" font-size="9" font-family="ui-monospace,Menlo,monospace" fill="rgba(255,255,255,0.2)">' +
          esc(L.t) +
          '</text>'
      );
    });

    svg.setAttribute('width', String(width));
    svg.setAttribute('height', String(height));
    svg.setAttribute('viewBox', '0 0 ' + width + ' ' + height);
    svg.innerHTML = parts.join('');

    var legendIds = {};
    (model.projectionMeta || []).forEach(function (m) {
      legendIds[m.series_id] = m;
    });
    Object.keys(hist).forEach(function (sid) {
      if (!legendIds[sid]) {
        legendIds[sid] = {
          series_id: sid,
          name: '',
          source: 'ols',
          isFocal: !!(focalId && sid === focalId),
        };
      }
    });
    var order = Object.keys(legendIds);
    order.sort(function (a, b) {
      var af = focalId && a === focalId ? 0 : 1;
      var bf = focalId && b === focalId ? 0 : 1;
      if (af !== bf) return af - bf;
      return a.localeCompare(b);
    });

    leg.innerHTML = order
      .map(function (sid) {
        var meta = legendIds[sid];
        var isFoc = !!(focalId && sid === focalId);
        var col = lineColorForSeries(sid, isFoc);
        var lineStyle =
          meta.source === 'static_graph'
            ? 'border-top: 2px dashed ' + col
            : 'border-top: 2px solid ' + col;
        var muted =
          !isFoc && vis[sid] === false ? ' muted' : '';
        return (
          '<div class="te-legend-item' +
          muted +
          '" data-series-id="' +
          esc(sid) +
          '" data-focal="' +
          (isFoc ? '1' : '0') +
          '">' +
          '<span class="te-legend-line" style="' +
          lineStyle +
          '"></span>' +
          '<span class="te-legend-label">' +
          esc(sid) +
          '</span></div>'
        );
      })
      .join('');
    leg.querySelectorAll('.te-legend-item').forEach(function (item) {
      item.addEventListener('click', function () {
        var sid = item.getAttribute('data-series-id');
        var isFoc = item.getAttribute('data-focal') === '1';
        if (isFoc) return;
        var cur = window.ThesisEngine.chartVisibility[sid] !== false;
        window.ThesisEngine.chartVisibility[sid] = !cur;
        rerenderScenarioChart();
      });
    });

    function hideTip() {
      if (tip) {
        tip.classList.remove('visible');
        tip.innerHTML = '';
      }
    }
    svg.querySelectorAll('.te-scenario-hit').forEach(function (poly) {
      poly.addEventListener('mouseleave', hideTip);
      poly.addEventListener('mousemove', function (ev) {
        var sid = poly.getAttribute('data-series-id');
        var pts2 = hist[sid];
        if (!pts2 || !pts2.length || !tip || !bodyEl) return;
        var rect = svg.getBoundingClientRect();
        var scaleX = width / (rect.width || width);
        var mx = (ev.clientX - rect.left) * scaleX;
        var day = ((mx - margin.left) / innerW) * totalDays;
        if (day < 0 || day > HIST_DAYS) {
          hideTip();
          return;
        }
        var closest = pts2[0];
        var best = Math.abs(pts2[0].dayX - day);
        for (var j = 1; j < pts2.length; j++) {
          var dd = Math.abs(pts2[j].dayX - day);
          if (dd < best) {
            best = dd;
            closest = pts2[j];
          }
        }
        var metaP = legendIds[sid] || { name: '' };
        var nm = metaP.name || '';
        var ago = Math.round(HIST_DAYS - closest.dayX);
        var agoTxt = ago <= 0 ? 'today' : ago + ' days ago';
        var cls = closest.pct >= 0 ? 'pos' : 'neg';
        var pctStr = (closest.pct >= 0 ? '+' : '') + closest.pct.toFixed(1) + '%';
        tip.innerHTML =
          '<div class="te-tip-mono">' +
          esc(sid) +
          (nm ? ' · ' + esc(nm) : '') +
          '</div>' +
          '<div class="te-tip-val ' +
          cls +
          '">' +
          esc(pctStr) +
          ' from today</div>' +
          '<div class="te-tip-mono">' +
          esc(agoTxt) +
          '</div>';
        tip.classList.add('visible');
        var br = bodyEl.getBoundingClientRect();
        var tr = tip.getBoundingClientRect();
        var px = ev.clientX - br.left + 12;
        var py = ev.clientY - br.top + 12;
        if (px + tr.width > bodyEl.clientWidth - 4) {
          px = bodyEl.clientWidth - tr.width - 4;
        }
        if (py + tr.height > bodyEl.clientHeight - 4) {
          py = ev.clientY - br.top - tr.height - 8;
        }
        tip.style.left = Math.max(4, px) + 'px';
        tip.style.top = Math.max(4, py) + 'px';
      });
    });
  }

  function transmissionElForSeries(seriesId) {
    var cards = document.querySelectorAll('.te-var-card');
    for (var i = 0; i < cards.length; i++) {
      if (cards[i].getAttribute('data-series-id') === seriesId) {
        return cards[i].querySelector('.te-transmission');
      }
    }
    return null;
  }

  function pillClass(state) {
    var u = (state || '').toUpperCase();
    if (u === 'ELEVATED') return 'elevated';
    if (u === 'SUPPRESSED') return 'suppressed';
    if (u === 'NORMAL') return 'normal';
    return 'insufficient';
  }

  function regimeIndicatorLabel(key) {
    var t = String(key || '').replace(/_/g, ' ');
    if (!t) return '';
    return t.charAt(0).toUpperCase() + t.slice(1).toLowerCase();
  }

  function importanceFillClass(f) {
    var imp = f.importance_score != null ? Number(f.importance_score) : 0;
    var src = (f.source || '').toLowerCase();
    if (
      src === 'static_graph' ||
      f.regime_pct_756d == null ||
      f.regime_pct_756d === ''
    ) {
      return 'te-imp-fill standard';
    }
    var p756 = parseInt(f.regime_pct_756d, 10);
    var p90 =
      f.regime_pct_90d != null && f.regime_pct_90d !== ''
        ? parseInt(f.regime_pct_90d, 10)
        : NaN;
    if (!isNaN(p756) && p756 >= 70 && imp >= 0.15) {
      return 'te-imp-fill structural';
    }
    if (!isNaN(p90) && p90 >= 70 && p756 < 50 && imp >= 0.15) {
      return 'te-imp-fill tactical';
    }
    return 'te-imp-fill standard';
  }

  function buildRegimeTooltipHtml(indKey, p90n, p756n, dataTransition) {
    var label = regimeIndicatorLabel(indKey);
    var line90 =
      p90n != null && !isNaN(p90n) ? p90n + 'th percentile' : '—';
    var line756 =
      p756n != null && !isNaN(p756n) ? p756n + 'th percentile' : '—';
    var html =
      '<div class="te-tooltip-indicator">' +
      esc(label) +
      '</div>' +
      '<div class="te-tooltip-row"><span>Tactical (90d):</span><span class="val">' +
      esc(line90) +
      '</span></div>' +
      '<div class="te-tooltip-row"><span>Structural (3yr):</span><span class="val">' +
      esc(line756) +
      '</span></div>';
    if (
      dataTransition &&
      p90n != null &&
      !isNaN(p90n) &&
      p756n != null &&
      !isNaN(p756n)
    ) {
      var tw =
        p90n > p756n
          ? '⚠ Possible regime transition — tactically elevated, structurally normal'
          : '⚠ Possible regime transition — tactically suppressed, structurally elevated';
      html +=
        '<div class="te-tooltip-transition">' + esc(tw) + '</div>';
    }
    return html;
  }

  function positionRegimeTooltip(wrap, tip, pill) {
    var wr = wrap.getBoundingClientRect();
    var pr = pill.getBoundingClientRect();
    var left = pr.left - wr.left + wrap.scrollLeft;
    var top = pr.bottom - wr.top + wrap.scrollTop + 6;
    tip.style.left = left + 'px';
    tip.style.top = top + 'px';
    var tw = tip.offsetWidth;
    var maxL = Math.max(0, wrap.clientWidth - tw - 6);
    if (left > maxL) {
      tip.style.left = maxL + 'px';
    }
  }

  function wireRegimeBarTooltips(wrap) {
    var tip = wrap.querySelector('#te-regime-tooltip');
    if (!tip) return;
    var pills = wrap.querySelectorAll('.te-regime-pill[data-indicator]');
    function hideTip() {
      tip.classList.remove('visible');
    }
    pills.forEach(function (pill) {
      pill.addEventListener('mouseenter', function () {
        var ind = pill.getAttribute('data-indicator');
        var p90s = pill.getAttribute('data-pct90');
        var p756s = pill.getAttribute('data-pct756');
        var p90n =
          p90s != null && p90s !== '' ? parseInt(p90s, 10) : null;
        var p756n =
          p756s != null && p756s !== '' ? parseInt(p756s, 10) : null;
        if (p90n != null && isNaN(p90n)) p90n = null;
        if (p756n != null && isNaN(p756n)) p756n = null;
        var dt = pill.getAttribute('data-transition') === 'true';
        tip.innerHTML = buildRegimeTooltipHtml(ind, p90n, p756n, dt);
        tip.classList.add('visible');
        requestAnimationFrame(function () {
          positionRegimeTooltip(wrap, tip, pill);
        });
      });
      pill.addEventListener('mouseleave', hideTip);
    });
  }

  function readFormIntoNode() {
    var n = window.ThesisEngine.thesisNode;
    n.claim = (document.getElementById('te-claim') || {}).value || '';
    n.trigger = (document.getElementById('te-trigger') || {}).value || '';
    n.focal_series_id =
      (document.getElementById('te-focal') || {}).value || '';
    n.shock_pct = parseFloat(
      (document.getElementById('te-shock-slider') || {}).value || '0'
    );
    n.direction = (document.getElementById('te-direction') || {}).value || 'long';
    n.asset_class =
      (document.getElementById('te-asset-class') || {}).value || 'commodity';
    n.geography =
      (document.getElementById('te-geography') || {}).value || 'global';
    n.time_horizon =
      (document.getElementById('te-horizon') || {}).value || 'medium';
    n.confidence =
      (document.getElementById('te-confidence') || {}).value || 'moderate';
    n.asset_expression =
      (document.getElementById('te-asset-expr') || {}).value || '';
  }

  function writeNodeIntoForm() {
    var n = window.ThesisEngine.thesisNode;
    var set = function (id, v) {
      var el = document.getElementById(id);
      if (el) el.value = v != null ? v : '';
    };
    set('te-claim', n.claim);
    set('te-trigger', n.trigger);
    set('te-focal', n.focal_series_id);
    var sl = document.getElementById('te-shock-slider');
    var sv = document.getElementById('te-shock-val');
    if (sl) {
      sl.value = String(n.shock_pct != null ? n.shock_pct : 0);
    }
    if (sv) sv.textContent = (n.shock_pct != null ? n.shock_pct : 0) + '%';
    set('te-direction', n.direction);
    set('te-asset-class', n.asset_class);
    set('te-geography', n.geography);
    set('te-horizon', n.time_horizon);
    set('te-confidence', n.confidence);
    set('te-asset-expr', n.asset_expression);
  }

  function updateClaimPreview() {
    var el = document.getElementById('te-claim-preview');
    var c = window.ThesisEngine.thesisNode.claim || '';
    if (el) el.textContent = c.length > 90 ? c.slice(0, 90) + '…' : c || '—';
  }

  function updateCompletenessBar() {
    var addressed = window.ThesisEngine.thesisNode.addressed.length;
    var cards = document.querySelectorAll('.te-var-card:not(.addressed)');
    var remaining = 0;
    cards.forEach(function (c) {
      if (c.style.display !== 'none' && !c.hasAttribute('data-dismissed')) {
        remaining++;
      }
    });
    var pct = 0;
    if (addressed) {
      pct = Math.round(
        (100 * addressed) / Math.max(remaining + addressed, 1)
      );
    }
    var fill = document.getElementById('te-completeness-fill');
    if (fill) fill.style.width = pct + '%';
    var lbl = document.getElementById('te-completeness-pct');
    if (lbl) lbl.textContent = pct + '%';
  }

  function setConsistencyUi(consistency) {
    var el = document.getElementById('te-consistency');
    if (!el) return;
    el.textContent =
      consistency === 'conflict_detected'
        ? 'Conflict'
        : consistency === 'tensions_present'
          ? 'Tensions'
          : 'Clean';
    el.className =
      'te-consistency' +
      (consistency === 'conflict_detected'
        ? ' conflict_detected'
        : consistency === 'tensions_present'
          ? ' tensions_present'
          : '');
  }

  function renderRegimeBar(snapshot) {
    var wrap = document.getElementById('te-regime-bar');
    if (!wrap) return;
    if (
      !snapshot ||
      Object.keys(snapshot).length === 0 ||
      !REGIME_KEYS.some(function (r) {
        return snapshot[r.key] != null && snapshot[r.key] !== '';
      })
    ) {
      wrap.innerHTML =
        '<span class="te-regime-bar-label">Regime</span><span class="te-regime-pill insufficient">No snapshot — expand first</span>';
      return;
    }
    var html = '<span class="te-regime-bar-label">Regime</span>';
    REGIME_KEYS.forEach(function (r) {
      var raw = snapshot[r.key];
      var st = raw != null && raw !== '' ? raw : '—';
      var cls = st === '—' ? 'insufficient' : pillClass(st);
      var k90 = r.key + '_pct_90d';
      var k756 = r.key + '_pct_756d';
      var raw90 = snapshot[k90];
      var raw756 = snapshot[k756];
      var p90 =
        raw90 != null && raw90 !== '' ? parseInt(raw90, 10) : null;
      var p756 =
        raw756 != null && raw756 !== '' ? parseInt(raw756, 10) : null;
      if (p90 != null && isNaN(p90)) p90 = null;
      if (p756 != null && isNaN(p756)) p756 = null;
      var both =
        p90 != null &&
        p756 != null &&
        !isNaN(p90) &&
        !isNaN(p756);
      var dataTransition = both && Math.abs(p90 - p756) > 30;
      var attrs =
        ' data-indicator="' +
        escAttr(r.key) +
        '" data-transition="' +
        (dataTransition ? 'true' : 'false') +
        '"';
      if (p90 != null) attrs += ' data-pct90="' + p90 + '"';
      if (p756 != null) attrs += ' data-pct756="' + p756 + '"';
      var pctPart =
        p90 != null
          ? '<span class="te-pct-num"> · ' + esc(String(p90)) + '</span>'
          : '';
      html +=
        '<span class="te-regime-pill ' +
        cls +
        '"' +
        attrs +
        '>' +
        esc(r.label) +
        ': ' +
        esc(st) +
        pctPart +
        '</span>';
    });
    html += '<div id="te-regime-tooltip"></div>';
    wrap.innerHTML = html;
    wireRegimeBarTooltips(wrap);
  }

  function renderVariableSections(flagged) {
    var host = document.getElementById('te-var-rings');
    if (!host) return;
    var l1ols = [];
    var l2ols = [];
    var statics = [];
    (flagged || []).forEach(function (f) {
      if (!f || !f.series_id) return;
      if (f.source === 'static_graph') statics.push(f);
      else if (f.layer === 2) l2ols.push(f);
      else l1ols.push(f);
    });

    function section(title, items) {
      if (!items.length) return '';
      var h = '<div class="te-ring-section"><div class="te-ring-title">' + esc(title) + '</div>';
      items.forEach(function (f) {
        h += renderOneCard(f);
      });
      h += '</div>';
      return h;
    }

    host.innerHTML =
      section('Layer 1 — direct impacts', l1ols) +
      section('Layer 2 — second-order effects', l2ols) +
      section('Static graph — inferred', statics);

    host.querySelectorAll('.te-var-card .te-stance-row button').forEach(function (btn) {
      btn.addEventListener('click', onStanceClick);
    });
    host.querySelectorAll('.te-dismiss').forEach(function (btn) {
      btn.addEventListener('click', onDismissClick);
    });
  }

  function isValidBetaNum(x) {
    return x != null && x !== '' && !isNaN(Number(x));
  }

  function renderRollingBetaRowHtml(f) {
    if (f.layer !== 1 || String(f.source || '').toLowerCase() !== 'ols') {
      return '';
    }
    var b60 = isValidBetaNum(f.beta_60d) ? Number(f.beta_60d) : null;
    var b120 = isValidBetaNum(f.beta_120d) ? Number(f.beta_120d) : null;
    var b252 = isValidBetaNum(f.beta_252d) ? Number(f.beta_252d) : null;
    if (b60 == null && b120 == null && b252 == null) {
      return '';
    }
    var ci = f.beta_60d_ci;
    var ciL =
      ci && ci[0] != null && !isNaN(Number(ci[0]))
        ? Number(ci[0])
        : null;
    var ciH =
      ci && ci[1] != null && !isNaN(Number(ci[1]))
        ? Number(ci[1])
        : null;

    function winHtml(period, val, showCi) {
      var h =
        '<span class="te-beta-window"><span class="te-beta-period">' +
        period +
        'd</span><span class="te-beta-val">' +
        val.toFixed(3) +
        '</span>';
      if (showCi && ciL != null && ciH != null) {
        h +=
          '<span class="te-beta-ci">[' +
          ciL.toFixed(2) +
          ', ' +
          ciH.toFixed(2) +
          ']</span>';
      }
      h += '</span>';
      return h;
    }

    var parts = ['<div class="te-beta-row"><span class="te-beta-label">β</span>'];
    if (b60 != null) parts.push(winHtml(60, b60, true));
    if (b120 != null) parts.push(winHtml(120, b120, false));
    if (b252 != null) parts.push(winHtml(252, b252, false));

    var bt = f.beta_trend;
    if (bt != null && bt !== 'insufficient_data') {
      var btNorm = String(bt);
      var trendTxt =
        bt === 'strengthening'
          ? '↑ strengthening'
          : bt === 'weakening'
            ? '↓ weakening'
            : bt === 'stable'
              ? '→ stable'
              : btNorm;
      var trendCls =
        btNorm === 'strengthening' ||
        btNorm === 'weakening' ||
        btNorm === 'stable'
          ? btNorm
          : '';
      parts.push(
        '<span class="te-beta-trend' +
        (trendCls ? ' ' + trendCls : '') +
        '">' +
        esc(trendTxt) +
        '</span>'
      );
    }
    if (
      f.beta_trend_significant === false &&
      bt != null &&
      bt !== 'stable' &&
      bt !== 'insufficient_data'
    ) {
      parts.push(
        '<span class="te-beta-insignificant" title="Trend not statistically significant">*</span>'
      );
    }
    parts.push('</div>');
    return parts.join('');
  }

  function renderBreakWarningHtml(f) {
    if (f.layer !== 1 || String(f.source || '').toLowerCase() !== 'ols') {
      return '';
    }
    if (!f.break_detected || !f.beta_note) return '';
    var note = String(f.beta_note).trim();
    if (!note) return '';
    return '<div class="te-break-warning">⚠ ' + esc(note) + '</div>';
  }

  function renderOneCard(f) {
    var rawSid = f.series_id != null ? String(f.series_id) : '';
    var sid = esc(rawSid);
    var name = esc(f.name || '');
    var src =
      (f.source || '').toLowerCase() === 'static_graph' ? 'static' : 'OLS';
    var move = f.predicted_move_pct;
    var moveCls = '';
    var moveHtml = '—';
    if (move != null && !isNaN(move)) {
      moveCls = move >= 0 ? 'pos' : 'neg';
      moveHtml = (move >= 0 ? '+' : '') + Number(move).toFixed(2) + '%';
    }
    var r2 =
      f.r_squared != null
        ? 'R² ' + Number(f.r_squared).toFixed(2)
        : '';
    var imp = Math.min(100, (f.importance_score || 0) * 100);
    var impFillCls = importanceFillClass(f);
    var regimeNote = f.regime_note
      ? '<div class="te-regime-note">' + esc(f.regime_note) + '</div>'
      : '';
    var betaRowHtml = renderRollingBetaRowHtml(f);
    var breakWarnHtml = renderBreakWarningHtml(f);
    return (
      '<div class="te-var-card" data-series-id="' +
      escAttr(rawSid) +
      '">' +
      '<div class="te-var-card-top">' +
      '<div class="te-var-meta">' +
      '<span class="te-var-id">' +
      sid +
      '</span>' +
      '<span class="te-badge">' +
      src +
      '</span>' +
      '<div class="te-var-name">' +
      name +
      '</div></div>' +
      '<div class="te-var-move ' +
      moveCls +
      '">' +
      moveHtml +
      (r2 ? '<div style="font-size:10px;color:var(--text-muted)">' + r2 + '</div>' : '') +
      '</div></div>' +
      '<div class="te-importance-bar"><div class="te-importance-bar-fill ' +
      esc(impFillCls) +
      '" style="width:' +
      imp +
      '%"></div></div>' +
      betaRowHtml +
      breakWarnHtml +
      '<div class="te-transmission loading" data-series-id="' +
      escAttr(rawSid) +
      '">Generating…</div>' +
      regimeNote +
      '<div class="te-stance-row">' +
      '<button type="button" data-stance="supports">Supports</button>' +
      '<button type="button" data-stance="challenges">Challenges</button>' +
      '<button type="button" data-stance="neutral">Neutral</button>' +
      '<button type="button" class="te-dismiss" data-series-id="' +
      escAttr(rawSid) +
      '">Dismiss ×</button>' +
      '</div></div>'
    );
  }

  function onDismissClick(e) {
    var card = e.target.closest('.te-var-card');
    if (!card) return;
    var sid = card.getAttribute('data-series-id');
    if (sid && window.ThesisEngine.dismissedIds.indexOf(sid) < 0) {
      window.ThesisEngine.dismissedIds.push(sid);
    }
    card.style.display = 'none';
    card.setAttribute('data-dismissed', '1');
    updateCompletenessBar();
  }

  function onStanceClick(e) {
    var btn = e.target.closest('[data-stance]');
    if (!btn) return;
    var stance = btn.getAttribute('data-stance');
    var card = btn.closest('.te-var-card');
    if (!card) return;
    var seriesId = card.getAttribute('data-series-id');
    var flagged = window.ThesisEngine.thesisNode.flagged || [];
    var f = null;
    for (var fi = 0; fi < flagged.length; fi++) {
      if ((flagged[fi] || {}).series_id === seriesId) {
        f = flagged[fi];
        break;
      }
    }
    window.ThesisEngine.thesisNode.addressed.push({
      series_id: seriesId,
      stance: stance,
      name: f ? f.name : null,
      beta: f ? f.beta : null,
      predicted_move_pct: f ? f.predicted_move_pct : null,
      r_squared: f ? f.r_squared : null,
      source: f ? f.source : null,
      user_note: '',
      transmission: f && f.transmission != null ? f.transmission : '',
    });
    card.classList.add('addressed');
    var row = card.querySelector('.te-stance-row');
    if (row) {
      row.innerHTML =
        '<span class="te-stance-badge">Stance: ' + esc(stance) + '</span>';
    }
    fetch(API_BASE + '/api/thesis-engine/check', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ addressed: window.ThesisEngine.thesisNode.addressed }),
    })
      .then(function (r) {
        return r.json();
      })
      .then(function (data) {
        var tens = data.tensions || [];
        tens.forEach(function (t) {
          if (t && typeof t.resolved !== 'boolean') t.resolved = false;
        });
        window.ThesisEngine.thesisNode.tensions = tens;
        window.ThesisEngine.thesisNode.consistency = data.consistency || 'clean';
        setConsistencyUi(window.ThesisEngine.thesisNode.consistency);
      })
      .catch(function () {});
    window.ThesisEngine.stanceColors[seriesId] =
      STANCE_COLORS[stance] || STANCE_COLORS.neutral;
    rerenderScenarioChart();
    updateCompletenessBar();

    var rsRec = window.ThesisEngine.regimeSnapshot;
    var fingerprint =
      rsRec && rsRec.fingerprint != null && rsRec.fingerprint !== ''
        ? String(rsRec.fingerprint)
        : null;
    fetch(API_BASE + '/api/thesis-engine/record-stance', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        thesis_id: window.ThesisEngine.activeThesisId || null,
        focal_series_id:
          window.ThesisEngine.thesisNode.focal_series_id || '',
        target_series_id: seriesId,
        stance: stance,
        regime_fingerprint: fingerprint,
      }),
    }).catch(function () {});

    loadVariableHistory();
  }

  function loadVariableHistory() {
    var focal = (window.ThesisEngine.thesisNode.focal_series_id || '').trim();
    if (!focal) return;

    var rs = window.ThesisEngine.regimeSnapshot;
    var fingerprint =
      rs && rs.fingerprint != null && rs.fingerprint !== ''
        ? String(rs.fingerprint)
        : '';

    var url =
      API_BASE +
      '/api/thesis-engine/history/' +
      encodeURIComponent(focal) +
      (fingerprint
        ? '?regime_fingerprint=' + encodeURIComponent(fingerprint)
        : '');

    fetch(url)
      .then(function (r) {
        if (!r.ok) return null;
        return r.json();
      })
      .then(function (data) {
        if (!data || data.error) return;
        window.ThesisEngine.variableHistory = data.variables || {};
        window.ThesisEngine._historyLoaded = true;
        applyHistoryBadges();
        renderPatternsSidebarContent();
      })
      .catch(function () {});
  }

  function historyCardSelector(seriesId) {
    return (
      '[data-series-id="' +
      String(seriesId).replace(/\\/g, '\\\\').replace(/"/g, '\\"') +
      '"]'
    );
  }

  function applyHistoryBadges() {
    if (!window.ThesisEngine._historyLoaded) return;

    var history = window.ThesisEngine.variableHistory;
    if (!history || !Object.keys(history).length) return;

    Object.keys(history).forEach(function (seriesId) {
      var entry = history[seriesId];
      if (!entry) return;

      var card = document.querySelector(
        '.te-var-card' + historyCardSelector(seriesId)
      );
      if (!card) return;

      var cond = entry.conditional;
      var uncond = entry.unconditional;

      var badge = null;
      var context = '';

      if (cond && cond.total >= 3) {
        badge = cond;
        context = 'similar';
      } else if (uncond && uncond.total >= 3) {
        badge = uncond;
        context = 'mixed regimes';
      }

      if (!badge) return;

      var existing = card.querySelector('.te-history-badge');
      if (existing) existing.remove();

      var dom = badge.dominant_stance;
      var cls =
        dom === 'supports'
          ? 'supports'
          : dom === 'challenges'
            ? 'challenges'
            : 'low';

      var countPart = badge[dom] != null ? badge[dom] : 0;
      var countText =
        countPart +
        '/' +
        badge.total +
        ' ' +
        context +
        ': ' +
        dom;

      var badgeEl = document.createElement('div');
      badgeEl.className = 'te-history-badge ' + cls;
      badgeEl.textContent = countText;
      badgeEl.title =
        context === 'similar'
          ? 'Based on theses with similar regime context'
          : 'Based on all past theses (mixed regimes)';

      var varName = card.querySelector('.te-var-name, .te-series-name');
      if (varName && varName.parentNode) {
        varName.parentNode.insertBefore(badgeEl, varName.nextSibling);
      } else {
        card.insertBefore(badgeEl, card.firstChild);
      }
    });
  }

  function renderPatternsSidebarContent() {
    var history = window.ThesisEngine.variableHistory;
    var focal =
      (window.ThesisEngine.thesisNode.focal_series_id || '').trim();

    var sidebar = document.getElementById('te-patterns-sidebar');
    if (!sidebar) return;

    var entries = Object.keys(history || {})
      .map(function (sid) {
        return [sid, history[sid]];
      })
      .filter(function (pair) {
        var e = pair[1];
        var t = e && e.unconditional;
        return t && t.total >= 3;
      })
      .sort(function (a, b) {
        var ta = (a[1].unconditional && a[1].unconditional.total) || 0;
        var tb = (b[1].unconditional && b[1].unconditional.total) || 0;
        return tb - ta;
      });

    if (!entries.length) {
      sidebar.innerHTML =
        '<div class="te-patterns-header">Past patterns</div>' +
        '<div class="te-patterns-empty">' +
        'No history yet — address variables to build patterns.</div>';
      return;
    }

    var html =
      '<div class="te-patterns-header">Past patterns</div>' +
      '<div class="te-patterns-focal">focal: ' +
      esc(focal) +
      '</div>' +
      '<div class="te-patterns-list">';

    for (var i = 0; i < entries.length; i++) {
      var sid = entries[i][0];
      var entry = entries[i][1];
      var u = entry.unconditional;
      var c = entry.conditional;
      var use = c && c.total >= 3 ? c : u;
      var ctx = c && c.total >= 3 ? 'similar' : 'all';
      var dom = use.dominant_stance;
      var pcls =
        dom === 'supports'
          ? 'supports'
          : dom === 'challenges'
            ? 'challenges'
            : 'neutral';
      var domPart = use[dom] != null ? use[dom] : 0;
      html +=
        '<div class="te-patterns-row">' +
        '<span class="te-patterns-series">' +
        esc(sid) +
        '</span>' +
        '<span class="te-patterns-stance ' +
        esc(pcls) +
        '">' +
        esc(dom) +
        '</span>' +
        '<span class="te-patterns-count">' +
        domPart +
        '/' +
        use.total +
        ' ' +
        esc(ctx) +
        '</span>' +
        '</div>';
    }

    html += '</div>';
    sidebar.innerHTML = html;
  }

  function togglePatternsSidebar() {
    var sidebar = document.getElementById('te-patterns-sidebar');
    var btn = document.getElementById('te-patterns-toggle');
    if (!sidebar || !btn) return;
    var isOpen = sidebar.classList.contains('open');
    sidebar.classList.toggle('open', !isOpen);
    btn.textContent = isOpen ? 'Patterns ▸' : 'Patterns ◂';
  }

  function buildExplainQueue(flagged) {
    window.ThesisEngine.flaggedQueue = [];
    var n = window.ThesisEngine.thesisNode;
    (flagged || []).forEach(function (f) {
      if (!f || f.transmission != null) return;
      window.ThesisEngine.flaggedQueue.push({
        series_id: f.series_id,
        beta: f.beta != null ? f.beta : 0,
        predicted_move_pct: f.predicted_move_pct,
      });
    });
  }

  function processExplainQueue() {
    if (window.ThesisEngine.explainInFlight) return;
    var item = window.ThesisEngine.flaggedQueue.shift();
    if (!item) return;
    window.ThesisEngine.explainInFlight = true;
    var n = window.ThesisEngine.thesisNode;
    fetch(API_BASE + '/api/thesis-engine/explain', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        focal_series_id: n.focal_series_id,
        target_series_id: item.series_id,
        beta: item.beta,
        shock_pct: n.shock_pct,
        claim: n.claim || '',
      }),
    })
      .then(function (r) {
        return r.json();
      })
      .then(function (data) {
        var el = transmissionElForSeries(item.series_id);
        var tx = (data && data.transmission) || '—';
        if (el) {
          el.classList.remove('loading');
          el.textContent = tx;
        }
        var addr = window.ThesisEngine.thesisNode.addressed || [];
        for (var ai = 0; ai < addr.length; ai++) {
          if (addr[ai] && addr[ai].series_id === item.series_id) {
            addr[ai].transmission = tx;
            break;
          }
        }
      })
      .catch(function () {
        var el = transmissionElForSeries(item.series_id);
        if (el) {
          el.classList.remove('loading');
          el.textContent = '—';
        }
      })
      .finally(function () {
        window.ThesisEngine.explainInFlight = false;
        setTimeout(processExplainQueue, 500);
      });
  }

  function runExpansion() {
    readFormIntoNode();
    var n = window.ThesisEngine.thesisNode;
    window.ThesisEngine.expanding = true;
    var btn = document.getElementById('te-btn-expand');
    if (btn) btn.disabled = true;
    fetch(API_BASE + '/api/thesis-engine/expand', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        focal_series_id: n.focal_series_id,
        shock_pct: n.shock_pct,
        asset_class: n.asset_class,
        geography: n.geography,
        addressed: n.addressed,
      }),
    })
      .then(function (r) {
        return r.json();
      })
      .then(function (data) {
        window.ThesisEngine.expanding = false;
        if (btn) btn.disabled = false;
        if (data.error) {
          var host = document.getElementById('te-var-rings');
          if (host) {
            host.innerHTML =
              '<p class="te-parse-note">' + esc(data.error) + '</p>';
          }
          teardownChartObserver();
          var slotErr = document.getElementById('te-chart-slot');
          if (slotErr) slotErr.innerHTML = '';
          window.ThesisEngine.chartModel = null;
          window.ThesisEngine.chartVisibility = {};
          window.ThesisEngine.stanceColors = {};
          window.ThesisEngine.variableHistory = {};
          window.ThesisEngine._historyLoaded = false;
          return;
        }
        n.flagged = data.flagged || [];
        window.ThesisEngine.regimeSnapshot = data.regime_snapshot || null;
        window.ThesisEngine.variableHistory = {};
        window.ThesisEngine._historyLoaded = false;
        renderRegimeBar(window.ThesisEngine.regimeSnapshot);
        loadScenarioChartAfterExpand(n.flagged);
        renderVariableSections(n.flagged);
        loadVariableHistory();
        n.completeness_pct = data.completeness_pct != null ? data.completeness_pct : 0;
        var fill = document.getElementById('te-completeness-fill');
        if (fill) fill.style.width = n.completeness_pct + '%';
        var lbl = document.getElementById('te-completeness-pct');
        if (lbl) lbl.textContent = n.completeness_pct + '%';
        buildExplainQueue(n.flagged);
        processExplainQueue();
        updateCompletenessBar();
      })
      .catch(function () {
        window.ThesisEngine.expanding = false;
        if (btn) btn.disabled = false;
      });
  }

  function openParsePopover() {
    var pop = document.getElementById('te-parse-popover');
    if (pop) pop.classList.add('open');
  }

  function closeParsePopover() {
    var pop = document.getElementById('te-parse-popover');
    if (pop) pop.classList.remove('open');
  }

  function runParse() {
    var ta = document.getElementById('te-parse-text');
    var raw = (ta && ta.value) || '';
    var note = document.getElementById('te-parse-note');
    if (note) note.textContent = '';
    fetch(API_BASE + '/api/thesis-engine/parse', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ raw_text: raw }),
    })
      .then(function (r) {
        return r.json();
      })
      .then(function (data) {
        var p = data.parsed || {};
        if (!data.llama_available) {
          if (note) {
            note.textContent =
              'Llama unavailable — fill fields manually';
          }
        } else {
          var n = window.ThesisEngine.thesisNode;
          if (p.focal_series_id != null) n.focal_series_id = p.focal_series_id;
          if (p.shock_pct != null) n.shock_pct = p.shock_pct;
          if (p.direction != null) n.direction = p.direction;
          if (p.asset_class != null) n.asset_class = p.asset_class;
          if (p.geography != null) n.geography = p.geography;
          if (p.time_horizon != null) n.time_horizon = p.time_horizon;
          if (p.trigger != null) n.trigger = p.trigger;
          if (p.claim != null) n.claim = p.claim;
          writeNodeIntoForm();
          updateClaimPreview();
          closeParsePopover();
        }
      })
      .catch(function () {
        if (note) note.textContent = 'Parse failed — fill manually';
      });
  }

  function setLeftPanelStructureActive(on) {
    var lp = document.getElementById('te-left-panel');
    if (!lp) return;
    if (on) lp.classList.add('te-structure-active');
    else lp.classList.remove('te-structure-active');
  }

  function checkExpression(expression, direction) {
    var expr = (expression || '').toLowerCase();
    var dir = (direction || '').toLowerCase();
    if (!expression || String(expression).trim() === '') {
      return { ok: false, message: 'No expression stated.' };
    }
    var hasLong = /\blong\b/.test(expr);
    var hasShort = /\bshort\b/.test(expr);
    if (dir === 'short' && hasLong && !hasShort) {
      return {
        ok: false,
        message:
          'Expression mentions long positions — confirm this is intentional for a short thesis.',
      };
    }
    if (dir === 'long' && hasShort && !hasLong) {
      return {
        ok: false,
        message:
          'Expression mentions short positions — confirm this is intentional for a long thesis.',
      };
    }
    return {
      ok: true,
      message: 'Expression is consistent with stated direction.',
    };
  }

  function getTransmissionForAddressedSeries(seriesId) {
    var v = null;
    var addr = window.ThesisEngine.thesisNode.addressed || [];
    for (var i = 0; i < addr.length; i++) {
      if (addr[i] && addr[i].series_id === seriesId) {
        v = addr[i];
        break;
      }
    }
    if (v && v.transmission) return String(v.transmission);
    var el = transmissionElForSeries(seriesId);
    if (!el) return '';
    var t = el.textContent || '';
    if (t === 'Generating…') return '';
    return t;
  }

  function generateThesisStatement() {
    var ta = document.getElementById('te-statement-textarea');
    var n = window.ThesisEngine.thesisNode;
    if (ta) {
      ta.placeholder = 'Generating thesis statement…';
      ta.disabled = true;
    }
    var supporting = (n.addressed || [])
      .filter(function (v) {
        return v && v.stance === 'supports';
      })
      .map(function (v) {
        return {
          series_id: v.series_id,
          name: v.name,
          predicted_move_pct: v.predicted_move_pct,
          transmission: v.transmission || getTransmissionForAddressedSeries(v.series_id),
        };
      });
    var risks = (n.addressed || [])
      .filter(function (v) {
        return v && v.stance === 'challenges';
      })
      .map(function (v) {
        return {
          series_id: v.series_id,
          name: v.name,
          predicted_move_pct: v.predicted_move_pct,
          transmission: v.transmission || getTransmissionForAddressedSeries(v.series_id),
        };
      });
    var body = {
      claim: n.claim,
      trigger: n.trigger,
      focal_series_id: n.focal_series_id,
      shock_pct: n.shock_pct,
      time_horizon: n.time_horizon,
      asset_expression: n.asset_expression,
      supporting: supporting,
      risks: risks,
    };
    return fetch(API_BASE + '/api/thesis-engine/generate-statement', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    })
      .then(function (r) {
        return r.text().then(function (text) {
          var data = {};
          try {
            data = text ? JSON.parse(text) : {};
          } catch (e) {
            data = {};
          }
          return { ok: r.ok, data: data };
        });
      })
      .then(function (out) {
        if (ta) {
          ta.disabled = false;
          if (out.ok && out.data && out.data.statement) {
            ta.value = out.data.statement;
            ta.placeholder = '';
            n.generated_statement = out.data.statement;
          } else {
            ta.placeholder =
              'Generation failed — type your statement';
          }
        }
      })
      .catch(function () {
        if (ta) {
          ta.disabled = false;
          ta.placeholder = 'Generation failed — type your statement';
        }
      });
  }

  function saveThesis() {
    var node = window.ThesisEngine.thesisNode;
    var title = (node.claim || '').slice(0, 60) || 'New thesis';
    var contentHtml =
      '<div class="te-thesis-document">' +
      '<p>' +
      esc(node.generated_statement || '') +
      '</p>' +
      '</div>';
    var metaCopy;
    try {
      window.ThesisEngine.thesisNode.engine_version = 1;
      metaCopy = JSON.parse(JSON.stringify(node));
    } catch (e) {
      metaCopy = {};
    }
    var payload = {
      title: title,
      content_html: contentHtml,
      metadata: metaCopy,
      tags: [node.asset_class, node.geography].filter(Boolean),
      status: 'active',
    };
    var btn = document.getElementById('te-save-btn');
    if (btn) {
      btn.textContent = 'Saving…';
      btn.disabled = true;
    }
    var base = API_BASE + '/api/research-theses';
    var finishOk = function () {
      if (btn) {
        btn.textContent = 'Saved ✓';
        setTimeout(function () {
          btn.textContent = 'Save thesis →';
          btn.disabled = false;
        }, 3000);
      }
    };
    var finishErr = function () {
      if (btn) {
        btn.textContent = 'Save failed — try again';
        btn.style.color = 'var(--red, #f4735a)';
        setTimeout(function () {
          btn.textContent = 'Save thesis →';
          btn.style.color = '';
          btn.disabled = false;
        }, 3000);
      }
    };
    if (window.ThesisEngine.activeThesisId) {
      fetch(base + '/' + encodeURIComponent(window.ThesisEngine.activeThesisId), {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      })
        .then(function (r) {
          if (!r.ok) throw new Error('HTTP ' + r.status);
          return r.json();
        })
        .then(function () {
          finishOk();
        })
        .catch(function () {
          finishErr();
        });
      return;
    }
    fetch(base, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ title: title }),
    })
      .then(function (r) {
        if (!r.ok) throw new Error('HTTP ' + r.status);
        return r.json();
      })
      .then(function (data) {
        if (!data || !data.id) throw new Error('no id');
        window.ThesisEngine.activeThesisId = data.id;
        return fetch(
          base + '/' + encodeURIComponent(window.ThesisEngine.activeThesisId),
          {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload),
          }
        );
      })
      .then(function (r) {
        if (!r.ok) throw new Error('HTTP ' + r.status);
        finishOk();
      })
      .catch(function () {
        finishErr();
      });
  }

  function formatMoveCell(pct) {
    if (pct == null || isNaN(pct)) {
      return '<span class="te-move-cell">—</span>';
    }
    var cls = pct >= 0 ? 'pos' : 'neg';
    var s =
      pct >= 0
        ? '+' + Number(pct).toFixed(1) + '%'
        : '−' + Math.abs(Number(pct)).toFixed(1) + '%';
    return '<span class="te-move-cell ' + cls + '">' + esc(s) + '</span>';
  }

  function formatR2Cell(r2) {
    if (r2 == null || isNaN(r2)) return '—';
    return Number(r2).toFixed(2);
  }

  function updateStructureCompleteness() {
    var n = window.ThesisEngine.thesisNode;
    var a = (n.addressed || []).length;
    var f = (n.flagged || []).length;
    var pct =
      a === 0
        ? 0
        : Math.min(
            100,
            Math.round((100 * a) / Math.max(f + a, 1))
          );
    var fill = document.getElementById('te-struct-completeness-fill');
    var lbl = document.getElementById('te-struct-completeness-pct');
    if (fill) fill.style.width = pct + '%';
    if (lbl) lbl.textContent = pct + '%';
  }

  function renderExpressionCheckBlock() {
    var host = document.getElementById('te-expression-check');
    if (!host) return;
    var n = window.ThesisEngine.thesisNode;
    var r = checkExpression(n.asset_expression, n.direction);
    host.className = 'te-expression-check ' + (r.ok ? 'ok' : 'warn');
    host.textContent = r.message;
  }

  function buildVarTableRows(vars) {
    if (!vars.length) return '';
    var rows = '';
    for (var i = 0; i < vars.length; i++) {
      var v = vars[i];
      var sid = esc(v.series_id || '');
      var nm = v.name != null && String(v.name) !== '' ? esc(v.name) : sid;
      var noteAttr = escAttr(v.user_note != null ? v.user_note : '');
      rows +=
        '<tr data-series-id="' +
        sid +
        '">' +
        '<td class="te-td-mono">' +
        sid +
        '</td>' +
        '<td>' +
        nm +
        '</td>' +
        '<td>' +
        formatMoveCell(v.predicted_move_pct) +
        '</td>' +
        '<td>' +
        esc(formatR2Cell(v.r_squared)) +
        '</td>' +
        '<td><input type="text" class="te-note-input" data-series-id="' +
        sid +
        '" placeholder="Add note…" value="' +
        noteAttr +
        '" /></td>' +
        '</tr>';
    }
    return rows;
  }

  function wireStructureNoteInputs() {
    document.querySelectorAll('#te-structure-view .te-note-input').forEach(function (inp) {
      inp.addEventListener('change', function () {
        var sid = inp.getAttribute('data-series-id');
        var addr = window.ThesisEngine.thesisNode.addressed || [];
        for (var j = 0; j < addr.length; j++) {
          if (addr[j] && addr[j].series_id === sid) {
            addr[j].user_note = inp.value;
            break;
          }
        }
      });
    });
  }

  function renderTensionsBodyHTML() {
    var tens = window.ThesisEngine.thesisNode.tensions || [];
    var unresolved = 0;
    tens.forEach(function (t) {
      if (t && !t.resolved) unresolved++;
    });
    var badge = document.getElementById('te-tensions-badge');
    if (badge) {
      badge.textContent = String(tens.length);
      badge.classList.toggle('te-badge-amber', unresolved > 0);
    }
    if (
      !tens.length ||
      tens.every(function (t) {
        return t && t.resolved;
      })
    ) {
      return '<p class="te-struct-muted">No tensions detected</p>';
    }
    var html = '';
    for (var i = 0; i < tens.length; i++) {
      var t = tens[i];
      if (!t) continue;
      var va = esc(t.variable_a || '');
      var vb = esc(t.variable_b || '');
      var desc = esc(t.description || '');
      var res = !!t.resolved;
      var tid = 'te-tension-' + i;
      html +=
        '<div class="te-tension-card' +
        (res ? ' resolved' : '') +
        '" data-tension-index="' +
        i +
        '">' +
        '<div class="te-tension-vars">' +
        va +
        ' ↔ ' +
        vb +
        '</div>' +
        '<div class="te-tension-desc">' +
        desc +
        '</div>';
      if (!res) {
        html +=
          '<button type="button" class="te-resolve-btn" data-tension-index="' +
          i +
          '">Resolve →</button>' +
          '<div class="te-resolution-area" id="' +
          tid +
          '-area" style="display:none">' +
          '<textarea class="te-resolution-textarea" id="' +
          tid +
          '-ta" placeholder="Enter resolution note…"></textarea>' +
          '<button type="button" class="te-resolve-confirm" data-tension-index="' +
          i +
          '">Confirm resolution</button>' +
          '</div>';
      } else {
        html +=
          '<div class="te-tension-resolved-msg">Resolved ✓ <span class="te-struct-muted">' +
          esc(t.resolution_note || '') +
          '</span></div>';
      }
      html += '</div>';
    }
    return html;
  }

  function bindTensionEvents() {
    var body = document.getElementById('te-struct-tensions-body');
    if (!body) return;
    body.querySelectorAll('.te-resolve-btn').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var idx = parseInt(btn.getAttribute('data-tension-index'), 10);
        var area = document.getElementById('te-tension-' + idx + '-area');
        if (area) area.style.display = 'flex';
      });
    });
    body.querySelectorAll('.te-resolve-confirm').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var idx = parseInt(btn.getAttribute('data-tension-index'), 10);
        var tens = window.ThesisEngine.thesisNode.tensions || [];
        var t = tens[idx];
        if (!t) return;
        var ta = document.getElementById('te-tension-' + idx + '-ta');
        t.resolved = true;
        t.resolution_note = ta ? ta.value : '';
        document.getElementById('te-struct-tensions-body').innerHTML =
          renderTensionsBodyHTML();
        bindTensionEvents();
      });
    });
  }

  function openUnknownsCount() {
    var n = window.ThesisEngine.thesisNode;
    var addrIds = {};
    (n.addressed || []).forEach(function (v) {
      if (v && v.series_id) addrIds[v.series_id] = true;
    });
    var dismissed = window.ThesisEngine.dismissedIds || [];
    var c = 0;
    (n.flagged || []).forEach(function (f) {
      if (!f || !f.series_id) return;
      if (addrIds[f.series_id]) return;
      if (dismissed.indexOf(f.series_id) >= 0) return;
      c++;
    });
    return c;
  }

  function renderStructureView() {
    var host = document.getElementById('te-mode-structure');
    if (!host) return;
    readFormIntoNode();
    var n = window.ThesisEngine.thesisNode;
    var sup = (n.addressed || []).filter(function (v) {
      return v && v.stance === 'supports';
    });
    var risk = (n.addressed || []).filter(function (v) {
      return v && v.stance === 'challenges';
    });
    var unk = openUnknownsCount();
    host.innerHTML =
      '<div class="te-structure-with-sidebar">' +
      '<div class="te-structure-main">' +
      '<div class="te-structure-view" id="te-structure-view">' +
      '<div class="te-struct-section">' +
      '<div class="te-struct-section-header">' +
      '<span class="te-struct-section-title">Thesis statement</span>' +
      '<div class="te-struct-header-actions">' +
      '<button type="button" class="te-regenerate-btn" id="te-regenerate-statement">Regenerate</button>' +
      '<button type="button" class="te-patterns-toggle" id="te-patterns-toggle">Patterns ▸</button>' +
      '</div></div>' +
      '<div class="te-struct-section-body">' +
      '<textarea class="te-statement-textarea" id="te-statement-textarea" placeholder=""></textarea>' +
      '</div></div>' +
      '<div class="te-struct-section">' +
      '<div class="te-struct-section-header">' +
      '<span class="te-struct-section-title">Supporting variables</span>' +
      '<span class="te-struct-count-badge" id="te-supporting-badge">' +
      sup.length +
      '</span></div>' +
      '<div class="te-struct-section-body" id="te-supporting-body"></div></div>' +
      '<div class="te-struct-section">' +
      '<div class="te-struct-section-header">' +
      '<span class="te-struct-section-title">Risk variables</span>' +
      '<span class="te-struct-count-badge" id="te-risk-badge">' +
      risk.length +
      '</span></div>' +
      '<div class="te-struct-section-body" id="te-risk-body"></div></div>' +
      '<div class="te-struct-section">' +
      '<div class="te-struct-section-header">' +
      '<span class="te-struct-section-title">Tensions</span>' +
      '<span class="te-struct-count-badge" id="te-tensions-badge">0</span></div>' +
      '<div class="te-struct-section-body" id="te-struct-tensions-body"></div></div>' +
      '<div class="te-struct-section">' +
      '<div class="te-struct-section-header">' +
      '<span class="te-struct-section-title">Open unknowns</span></div>' +
      '<div class="te-struct-section-body" id="te-open-unknowns-body"></div></div>' +
      '<div class="te-struct-section">' +
      '<div class="te-struct-section-header">' +
      '<span class="te-struct-section-title">Thesis expression</span></div>' +
      '<div class="te-struct-section-body">' +
      '<div class="te-expression-display">' +
      esc(n.asset_expression || '—') +
      '</div>' +
      '<div id="te-expression-check" class="te-expression-check"></div>' +
      '</div></div>' +
      '<div class="te-struct-section">' +
      '<div class="te-struct-section-header">' +
      '<span class="te-struct-section-title">Completeness</span></div>' +
      '<div class="te-struct-section-body te-struct-save-row">' +
      '<div class="te-completeness-row te-completeness-row--struct">' +
      '<div class="te-completeness-label">Completeness <span id="te-struct-completeness-pct">0%</span></div>' +
      '<div class="te-completeness-bar"><div class="te-completeness-fill" id="te-struct-completeness-fill" style="width:0%"></div></div></div>' +
      '<button type="button" class="te-save-btn" id="te-save-btn">Save thesis →</button>' +
      '</div></div></div></div>' +
      '<div class="te-patterns-sidebar" id="te-patterns-sidebar"></div>' +
      '</div>';

    var sb = document.getElementById('te-supporting-body');
    if (sb) {
      if (!sup.length) {
        sb.innerHTML =
          '<p class="te-struct-muted">No variables marked as supporting yet.</p>';
      } else {
        sb.innerHTML =
          '<table class="te-var-table"><thead><tr>' +
          '<th>Series</th><th>Name</th><th>Predicted move</th><th>R²</th><th>Note</th>' +
          '</tr></thead><tbody>' +
          buildVarTableRows(sup) +
          '</tbody></table>';
      }
    }
    var rb = document.getElementById('te-risk-body');
    if (rb) {
      if (!risk.length) {
        rb.innerHTML =
          '<p class="te-struct-muted">No variables marked as risks yet.</p>';
      } else {
        rb.innerHTML =
          '<table class="te-var-table"><thead><tr>' +
          '<th>Series</th><th>Name</th><th>Predicted move</th><th>R²</th><th>Note</th>' +
          '</tr></thead><tbody>' +
          buildVarTableRows(risk) +
          '</tbody></table>';
      }
    }
    document.getElementById('te-struct-tensions-body').innerHTML =
      renderTensionsBodyHTML();
    bindTensionEvents();

    var ou = document.getElementById('te-open-unknowns-body');
    if (ou) {
      if (unk === 0) {
        ou.innerHTML =
          '<p class="te-open-unknowns-all">All surfaced variables addressed.</p>';
      } else {
        ou.innerHTML =
          '<p class="te-struct-muted">' +
          unk +
          ' variables in the outer ring not yet addressed.</p>' +
          '<button type="button" class="te-address-explore-btn" id="te-address-explore-btn">Address in Explore →</button>';
      }
    }

    updateStructureCompleteness();
    renderExpressionCheckBlock();
    wireStructureNoteInputs();

    var ta = document.getElementById('te-statement-textarea');
    if (ta) {
      ta.addEventListener('input', function () {
        window.ThesisEngine.thesisNode.generated_statement = ta.value;
      });
      if (n.generated_statement) {
        ta.value = n.generated_statement;
        ta.placeholder = '';
        ta.disabled = false;
      } else {
        ta.value = '';
        generateThesisStatement();
      }
    }

    var reg = document.getElementById('te-regenerate-statement');
    if (reg) {
      reg.addEventListener('click', function () {
        if (
          !window.confirm(
            'Regenerate will overwrite your edits. Continue?'
          )
        ) {
          return;
        }
        generateThesisStatement();
      });
    }
    var pat = document.getElementById('te-patterns-toggle');
    if (pat) {
      pat.addEventListener('click', togglePatternsSidebar);
    }
    var saveBtn = document.getElementById('te-save-btn');
    if (saveBtn) {
      saveBtn.addEventListener('click', function () {
        saveThesis();
      });
    }
    var exBtn = document.getElementById('te-address-explore-btn');
    if (exBtn) {
      exBtn.addEventListener('click', function () {
        setMode('explore');
      });
    }

    renderPatternsSidebarContent();
  }

  function clearMonitorInterval() {
    var iv = window.ThesisEngine._monitorInterval;
    if (iv != null) {
      clearInterval(iv);
      window.ThesisEngine._monitorInterval = null;
    }
  }

  async function loadMonitorData() {
    var id = window.ThesisEngine.activeThesisId;
    var url =
      API_BASE +
      '/api/thesis-engine/monitor/' +
      encodeURIComponent(String(id));
    var resp = await fetch(url);
    if (!resp.ok) throw new Error('HTTP ' + resp.status);
    var data = await resp.json();
    if (data.error) throw new Error(data.error);
    window.ThesisEngine.monitorData = data;
    return data;
  }

  function monitorDateOnly(iso) {
    if (iso == null) return '—';
    var s = String(iso);
    var m = s.match(/^(\d{4}-\d{2}-\d{2})/);
    if (m) return m[1];
    var d = new Date(s);
    if (isNaN(d.getTime())) return '—';
    return d.toISOString().slice(0, 10);
  }

  function monitorIndicatorLabel(key) {
    var t = String(key || '').replace(/_/g, ' ');
    if (!t) return '';
    return t.charAt(0).toUpperCase() + t.slice(1).toLowerCase();
  }

  function monitorHorizonFillColor(pct) {
    var p = Number(pct) || 0;
    if (p < 60) return 'var(--green, #2dd4a0)';
    if (p < 90) return 'var(--amber, #f0a94a)';
    return 'var(--red, #f4735a)';
  }

  function monitorLoadingHtml() {
    return (
      '<div class="te-monitor-loading">' +
      '<span class="te-monitor-spinner" aria-hidden="true"></span>' +
      '<span>Loading…</span></div>'
    );
  }

  function monitorErrorHtml(msg) {
    return (
      '<div class="te-monitor-error">' +
      esc(msg || 'Failed to load monitor data') +
      '</div>'
    );
  }

  function monitorVelocityClass(v) {
    var x = v == null ? NaN : Number(v);
    if (x > 1.5) return 'te-signal-stat-val hot';
    if (x >= 0.8) return 'te-signal-stat-val warm';
    return 'te-signal-stat-val';
  }

  function monitorSentimentClass(s) {
    var x = s == null ? NaN : Number(s);
    if (x > 0.1) return 'te-signal-stat-val pos';
    if (x < -0.1) return 'te-signal-stat-val neg';
    return 'te-signal-stat-val';
  }

  function monitorFormatVelocity(v) {
    if (v == null || v === '') return '—';
    var n = Number(v);
    if (isNaN(n)) return esc(String(v));
    return n.toFixed(1) + '×';
  }

  function monitorFormatSentiment(s) {
    if (s == null || s === '') return '—';
    var n = Number(s);
    if (isNaN(n)) return esc(String(s));
    var sign = n > 0 ? '+' : '';
    return sign + n.toFixed(2);
  }

  function monitorSeverityClass(sev) {
    var s = String(sev || '').toLowerCase();
    if (s === 'high' || s === 'critical' || s === 'severe') return 'high';
    if (s === 'medium' || s === 'med') return 'medium';
    return 'low';
  }

  function monitorTimeAgo(iso) {
    if (!iso) return '—';
    var t = new Date(iso).getTime();
    if (isNaN(t)) return '—';
    var ms = Date.now() - t;
    if (ms < 0) return 'Less than 1 hour ago';
    var h = Math.floor(ms / 3600000);
    if (h < 1) return 'Less than 1 hour ago';
    if (h < 24) return h + ' hours ago';
    var d = Math.floor(h / 24);
    return d + ' days ago';
  }

  function renderMonitorSummaryInner(data) {
    var claimRaw = (data.claim && String(data.claim).trim()) || '';
    var claimShow =
      claimRaw.length > 60 ? claimRaw.slice(0, 60) + '…' : claimRaw;
    if (!claimShow) claimShow = 'No claim stated';
    var pct = Number(data.horizon_pct) || 0;
    var fillW = Math.min(100, Math.max(0, pct));
    var fillColor = monitorHorizonFillColor(pct);
    return (
      '<div class="te-monitor-summary">' +
      '<div class="te-monitor-summary-left">' +
      '<div class="te-monitor-claim">' +
      esc(claimShow) +
      '</div>' +
      '<div class="te-monitor-meta">' +
      esc(data.time_horizon || 'medium') +
      ' · ' +
      esc(data.confidence || 'moderate') +
      '</div>' +
      '<div class="te-monitor-meta">' +
      'Created: ' +
      esc(monitorDateOnly(data.created_at)) +
      ' · Active for: ' +
      esc(String(data.days_active != null ? data.days_active : '—')) +
      ' days</div></div>' +
      '<div class="te-monitor-summary-right">' +
      '<div class="te-horizon-wrap">' +
      '<div class="te-horizon-label">' +
      esc(String(pct)) +
      '% of stated horizon elapsed</div>' +
      '<div class="te-horizon-track">' +
      '<div class="te-horizon-fill" style="width:' +
      fillW +
      '%;background:' +
      fillColor +
      '"></div></div></div>' +
      '<button type="button" class="te-refresh-btn" id="te-monitor-refresh-btn">Refresh ↻</button>' +
      '</div></div>'
    );
  }

  function computeRegimeTransitionsFromMonitor(data) {
    var snap = data.regime_current;
    if (!snap) return [];
    var out = [];
    for (var i = 0; i < MONITOR_INDICATOR_ORDER.length; i++) {
      var ind = MONITOR_INDICATOR_ORDER[i];
      var p90 = snap[ind + '_pct_90d'];
      var p756 = snap[ind + '_pct_756d'];
      if (p90 == null || p756 == null) continue;
      var n90 = parseInt(p90, 10);
      var n756 = parseInt(p756, 10);
      if (isNaN(n90) || isNaN(n756)) continue;
      if (Math.abs(n90 - n756) <= 30) continue;
      out.push({
        indicator: ind,
        tactical_pct: n90,
        structural_pct: n756,
        note:
          n90 > n756
            ? 'Tactically elevated (' +
              n90 +
              'th pct) but structurally normal (' +
              n756 +
              'th pct) — possible regime transition in progress'
            : 'Tactically suppressed (' +
              n90 +
              'th pct) but structurally elevated (' +
              n756 +
              'th pct) — possible mean reversion signal',
      });
    }
    return out;
  }

  function renderMonitorRegimeSection(data) {
    var fpCurrent =
      (data.regime_current && data.regime_current.fingerprint) || '';
    var rac = data.regime_at_creation;
    var html =
      '<div class="te-drift-section">' +
      '<div class="te-drift-section-head">' +
      '<div class="te-drift-title">Regime drift since thesis creation</div>' +
      '<div class="te-drift-fp">' +
      esc(fpCurrent) +
      '</div></div>';

    if (!rac || !rac.indicators) {
      html +=
        '<div class="te-drift-empty">' +
        'Regime snapshot not recorded at creation. ' +
        'Re-save this thesis to capture the current regime.' +
        '</div></div>';
      return html;
    }

    html += '<div class="te-drift-grid">';
    var curInd = (data.regime_current && data.regime_current.indicators) || {};
    var creInd = rac.indicators || {};
    MONITOR_INDICATOR_ORDER.forEach(function (ind) {
      var was = creInd[ind];
      var now = curInd[ind];
      var changed = was !== now;
      var rowCls = 'te-drift-row' + (changed ? ' changed' : '');
      var nowCls = 'now' + (changed ? ' changed' : '');
      var badge = changed
        ? '<span class="te-drift-changed-badge">changed</span>'
        : '';
      html +=
        '<div class="' +
        rowCls +
        '">' +
        '<span class="te-drift-indicator">' +
        esc(monitorIndicatorLabel(ind)) +
        '</span>' +
        '<div class="te-drift-states">' +
        '<span class="was">' +
        esc(was != null ? String(was) : '—') +
        '</span>' +
        '<span>→</span>' +
        '<span class="' +
        nowCls +
        '">' +
        esc(now != null ? String(now) : '—') +
        '</span>' +
        badge +
        '</div></div>';
    });
    html += '</div>';

    var transitions = computeRegimeTransitionsFromMonitor(data);
    if (transitions.length > 0) {
      html += '<div class="te-transition-section">';
      html +=
        '<div class="te-transition-header">Regime transitions detected</div>';
      transitions.forEach(function (t) {
        html += '<div class="te-transition-card">';
        html +=
          '<div class="te-transition-indicator">' +
          esc(monitorIndicatorLabel(t.indicator)) +
          '</div>';
        html +=
          '<div class="te-transition-pcts">Tactical: ' +
          esc(String(t.tactical_pct)) +
          'th pct &nbsp;·&nbsp; Structural: ' +
          esc(String(t.structural_pct)) +
          'th pct</div>';
        html +=
          '<div class="te-transition-note">' + esc(t.note) + '</div>';
        html += '</div>';
      });
      html += '</div>';
    }

    var ch = data.regime_changes;
    if (!ch || ch.length === 0) {
      html +=
        '<div class="te-drift-foot">' +
        'No regime changes detected since thesis creation.' +
        '</div>';
    }
    html += '</div>';
    return html;
  }

  function renderMonitorSignalsSection(data) {
    var sigs = data.relevant_signals || [];
    var n = sigs.length;
    var html =
      '<div class="te-feed-section">' +
      '<div class="te-feed-head">' +
      '<div class="te-feed-title">Signal feed — thesis relevant</div>' +
      '<div class="te-feed-sub">' +
      n +
      ' active signals</div></div>';

    if (n === 0) {
      html +=
        '<div class="te-feed-empty">' +
        'No signals matching this thesis variable set in the last 30 days.' +
        '</div></div>';
      return html;
    }

    sigs.forEach(function (sig) {
      var imp = String(sig.thesis_impact || 'neutral').toLowerCase();
      html +=
        '<div class="te-signal-card">' +
        '<div class="te-signal-top">' +
        '<div class="te-signal-topic">' +
        esc(sig.topic || '') +
        '</div>' +
        '<div class="te-signal-stats">' +
        '<div class="te-signal-stat"><div class="' +
        monitorVelocityClass(sig.velocity_7d) +
        '">' +
        monitorFormatVelocity(sig.velocity_7d) +
        '</div>' +
        '<div class="te-signal-stat-lbl">vel 7d</div></div>' +
        '<div class="te-signal-stat"><div class="' +
        monitorSentimentClass(sig.sentiment_avg) +
        '">' +
        monitorFormatSentiment(sig.sentiment_avg) +
        '</div>' +
        '<div class="te-signal-stat-lbl">sent</div></div>' +
        '</div></div>' +
        '<div class="te-signal-relevance">→ ' +
        esc(sig.relevance_note || '') +
        '</div>' +
        '<span class="te-impact-badge ' +
        esc(imp) +
        '">' +
        (imp === 'amplifies'
          ? 'Amplifies'
          : imp === 'challenges'
            ? 'Challenges'
            : 'Neutral') +
        '</span>' +
        '<div class="te-signal-actions">' +
        '<button type="button" class="te-signal-action-btn confirm">Confirms thesis</button>' +
        '<button type="button" class="te-signal-action-btn flag">Flag for review</button>' +
        '</div></div>';
    });
    html += '</div>';
    return html;
  }

  function renderMonitorAnomaliesSection(data) {
    var rows = data.relevant_anomalies || [];
    var n = rows.length;
    var html =
      '<div class="te-feed-section">' +
      '<div class="te-feed-head">' +
      '<div class="te-feed-title">Anomaly feed — thesis relevant</div>' +
      '<div class="te-feed-sub">' +
      n +
      ' anomal' +
      (n === 1 ? 'y' : 'ies') +
      '</div></div>';

    if (n === 0) {
      html +=
        '<div class="te-feed-empty">' +
        'No anomalies detected for this thesis variable set recently.' +
        '</div></div>';
      return html;
    }

    rows.forEach(function (a) {
      var imp = String(a.thesis_impact || 'neutral').toLowerCase();
      var sev = monitorSeverityClass(a.severity);
      html +=
        '<div class="te-anomaly-card">' +
        '<div class="te-severity-dot ' +
        esc(sev) +
        '"></div>' +
        '<div class="te-anomaly-left">' +
        '<div class="te-anomaly-series">' +
        esc(a.series_id || '') +
        '</div>' +
        '<div class="te-anomaly-desc">' +
        esc(a.description || '') +
        '</div>' +
        '<div class="te-anomaly-time">' +
        esc(monitorTimeAgo(a.detected_at)) +
        '</div></div>' +
        '<span class="te-impact-badge ' +
        esc(imp) +
        '">' +
        (imp === 'amplifies'
          ? 'Amplifies'
          : imp === 'challenges'
            ? 'Challenges'
            : 'Neutral') +
        '</span></div>';
    });
    html += '</div>';
    return html;
  }

  function renderMonitorHealthRow(data) {
    var n = window.ThesisEngine.thesisNode;
    var comp = n.completeness_pct;
    var compNum = comp == null ? 0 : Number(comp);
    if (isNaN(compNum)) compNum = 0;
    var compDot =
      compNum >= 50 ? 'te-health-dot green' : 'te-health-dot amber';
    var cons = String(n.consistency || 'clean').toLowerCase();
    var consDot = 'te-health-dot green';
    var consVal = 'Clean';
    var consCls = 'te-health-val clean';
    if (cons === 'tensions_present') {
      consDot = 'te-health-dot amber';
      consVal = 'Tensions present';
      consCls = 'te-health-val tensions';
    } else if (cons === 'conflict_detected') {
      consDot = 'te-health-dot red';
      consVal = 'Conflict detected';
      consCls = 'te-health-val conflict';
    }
    var lastUp = n.last_expanded || data.created_at;
    var fp =
      data.regime_at_creation && data.regime_at_creation.fingerprint
        ? String(data.regime_at_creation.fingerprint)
        : '—';
    return (
      '<div class="te-health-row">' +
      '<div class="te-health-item">' +
      '<span class="' +
      compDot +
      '"></span>' +
      '<span class="te-health-label">Completeness</span>' +
      '<span class="te-health-val">' +
      esc(String(compNum)) +
      '%</span></div>' +
      '<div class="te-health-item">' +
      '<span class="' +
      consDot +
      '"></span>' +
      '<span class="te-health-label">Consistency</span>' +
      '<span class="' +
      consCls +
      '">' +
      esc(consVal) +
      '</span></div>' +
      '<div class="te-health-item">' +
      '<span class="te-health-label">Last updated</span>' +
      '<span class="te-health-val">' +
      esc(monitorDateOnly(lastUp)) +
      '</span></div>' +
      '<div class="te-health-item te-health-regime">' +
      '<span class="te-health-label">Regime at creation</span>' +
      '<span class="te-health-fp">' +
      esc(fp) +
      '</span></div></div>'
    );
  }

  function renderMonitorSectionsOnly(data) {
    return (
      renderMonitorRegimeSection(data) +
      renderMonitorSignalsSection(data) +
      renderMonitorAnomaliesSection(data) +
      renderMonitorHealthRow(data)
    );
  }

  function onMonitorRefreshClick() {
    if (window.ThesisEngine.mode !== 'monitor') return;
    if (!window.ThesisEngine.activeThesisId) return;
    var bodyEl = document.getElementById('te-monitor-body');
    if (!bodyEl) return;
    bodyEl.innerHTML = monitorLoadingHtml();
    loadMonitorData()
      .then(function (d) {
        if (window.ThesisEngine.mode !== 'monitor') return;
        var be = document.getElementById('te-monitor-body');
        if (be) be.innerHTML = renderMonitorSectionsOnly(d);
      })
      .catch(function (e) {
        if (window.ThesisEngine.mode !== 'monitor') return;
        var be = document.getElementById('te-monitor-body');
        if (be) be.innerHTML = monitorErrorHtml(e.message || String(e));
      });
  }

  function renderMonitorView() {
    var host = document.getElementById('te-mode-monitor');
    if (!host) return;

    clearMonitorInterval();

    if (!window.ThesisEngine.activeThesisId) {
      host.innerHTML =
        '<div class="te-monitor-unsaved">' +
        '<p class="te-monitor-unsaved-line">No saved thesis to monitor.</p>' +
        '<p class="te-monitor-unsaved-line te-monitor-unsaved-sub">Save your thesis from Structure mode first.</p>' +
        '<button type="button" class="te-btn-primary" id="te-monitor-goto-structure">Go to Structure →</button>' +
        '</div>';
      var gb = document.getElementById('te-monitor-goto-structure');
      if (gb) {
        gb.addEventListener('click', function () {
          setMode('structure');
        });
      }
      return;
    }

    host.innerHTML =
      '<div class="te-monitor-view" id="te-monitor-view-root">' +
      '<div id="te-monitor-summary" style="display:none"></div>' +
      '<div id="te-monitor-body">' +
      monitorLoadingHtml() +
      '</div></div>';

    loadMonitorData()
      .then(function (data) {
        if (window.ThesisEngine.mode !== 'monitor') return;
        var summaryEl = document.getElementById('te-monitor-summary');
        var bodyEl = document.getElementById('te-monitor-body');
        if (!summaryEl || !bodyEl) return;
        summaryEl.style.display = '';
        summaryEl.innerHTML = renderMonitorSummaryInner(data);
        bodyEl.innerHTML = renderMonitorSectionsOnly(data);

        window.ThesisEngine._monitorInterval = setInterval(function () {
          if (window.ThesisEngine.mode !== 'monitor') return;
          loadMonitorData()
            .then(function (d) {
              if (window.ThesisEngine.mode !== 'monitor') return;
              var s = document.getElementById('te-monitor-summary');
              var b = document.getElementById('te-monitor-body');
              if (s && b) {
                s.innerHTML = renderMonitorSummaryInner(d);
                b.innerHTML = renderMonitorSectionsOnly(d);
              }
            })
            .catch(function () {});
        }, 300000);
      })
      .catch(function (e) {
        if (window.ThesisEngine.mode !== 'monitor') return;
        var bodyEl = document.getElementById('te-monitor-body');
        if (bodyEl) bodyEl.innerHTML = monitorErrorHtml(e.message || String(e));
      });
  }

  function bindMonitorHostClicksOnce() {
    var host = document.getElementById('te-mode-monitor');
    if (!host || host._teMonitorClicksBound) return;
    host._teMonitorClicksBound = true;
    host.addEventListener('click', function (e) {
      if (window.ThesisEngine.mode !== 'monitor') return;
      var t = e.target;
      var refBtn =
        t && t.closest ? t.closest('#te-monitor-refresh-btn') : null;
      if (refBtn && host.contains(refBtn)) {
        e.preventDefault();
        onMonitorRefreshClick();
        return;
      }
      var btn = t && t.closest ? t.closest('.te-signal-action-btn') : null;
      if (
        btn &&
        host.contains(btn) &&
        !btn.classList.contains('noted') &&
        !btn.disabled
      ) {
        e.preventDefault();
        btn.classList.add('noted');
        btn.textContent = 'Noted ✓';
        btn.disabled = true;
      }
    });
  }

  function setMode(mode) {
    if (mode !== 'monitor') {
      clearMonitorInterval();
    }
    window.ThesisEngine.mode = mode;
    document.querySelectorAll('.te-mode-switcher button').forEach(function (b) {
      b.classList.toggle('active', b.getAttribute('data-mode') === mode);
    });
    var ex = document.getElementById('te-mode-explore');
    var st = document.getElementById('te-mode-structure');
    var mo = document.getElementById('te-mode-monitor');
    if (ex) ex.style.display = mode === 'explore' ? '' : 'none';
    if (st) st.style.display = mode === 'structure' ? '' : 'none';
    if (mo) mo.style.display = mode === 'monitor' ? '' : 'none';
    if (mode === 'structure') {
      setLeftPanelStructureActive(true);
      renderStructureView();
    } else {
      setLeftPanelStructureActive(false);
    }
    if (mode === 'explore') {
      setTimeout(function () {
        rerenderScenarioChart();
      }, 0);
    }
    if (mode === 'monitor') {
      bindMonitorHostClicksOnce();
      renderMonitorView();
    }
  }

  function newThesis() {
    window.ThesisEngine.thesisNode = {
      focal_series_id: '',
      shock_pct: 20,
      direction: 'long',
      asset_class: 'commodity',
      geography: 'global',
      time_horizon: 'medium',
      confidence: 'moderate',
      claim: '',
      trigger: '',
      asset_expression: '',
      generated_statement: '',
      addressed: [],
      flagged: [],
      tensions: [],
      completeness_pct: 0,
      consistency: 'clean',
    };
    window.ThesisEngine.dismissedIds = [];
    window.ThesisEngine.activeThesisId = null;
    var t = document.getElementById('te-thesis-title');
    if (t) t.value = 'New thesis';
    writeNodeIntoForm();
    updateClaimPreview();
    var host = document.getElementById('te-var-rings');
    if (host) host.innerHTML = '';
    renderRegimeBar(null);
    setConsistencyUi('clean');
    updateCompletenessBar();
    teardownChartObserver();
    var slotNt = document.getElementById('te-chart-slot');
    if (slotNt) slotNt.innerHTML = '';
    window.ThesisEngine.chartModel = null;
    window.ThesisEngine.chartVisibility = {};
    window.ThesisEngine.stanceColors = {};
    window.ThesisEngine.variableHistory = {};
    window.ThesisEngine._historyLoaded = false;
    setMode('explore');
  }

  function buildShellHtml() {
    return (
      '<div class="te-tab-body">' +
      '<div class="te-topbar">' +
      '<div class="te-topbar-left">' +
      '<input type="text" class="te-title-input" id="te-thesis-title" value="New thesis" />' +
      '<div class="te-claim-preview" id="te-claim-preview">—</div></div>' +
      '<div class="te-topbar-right">' +
      '<span class="te-consistency" id="te-consistency">Clean</span>' +
      '<button type="button" class="te-btn-new" id="te-btn-new">+ New</button>' +
      '<div class="te-mode-switcher">' +
      '<button type="button" data-mode="explore" class="active">Explore</button>' +
      '<button type="button" data-mode="structure">Structure</button>' +
      '<button type="button" data-mode="monitor">Monitor</button>' +
      '</div></div></div>' +
      '<div id="te-mode-structure" class="te-mode-structure-root" style="display:none"></div>' +
      '<div id="te-mode-monitor" class="te-mode-structure-root te-mode-monitor-root" style="display:none"></div>' +
      '<div id="te-mode-explore" class="te-body-cols">' +
      '<div class="te-left-wrap">' +
      '<div class="te-left-panel" id="te-left-panel">' +
      '<div class="te-field"><label>Claim</label><textarea id="te-claim"></textarea></div>' +
      '<div class="te-field"><label>Trigger</label><input type="text" id="te-trigger" /></div>' +
      '<div class="te-field"><label>Focal series ID</label><input type="text" id="te-focal" placeholder="CM.BRENT" /></div>' +
      '<div class="te-field"><label>Shock %</label><div class="te-shock-row">' +
      '<input type="range" id="te-shock-slider" min="-50" max="50" step="1" value="20" />' +
      '<span class="te-shock-val" id="te-shock-val">20%</span></div></div>' +
      '<div class="te-field"><label>Direction</label><select id="te-direction">' +
      '<option value="long">long</option><option value="short">short</option>' +
      '<option value="relative_value">relative_value</option><option value="macro_hedge">macro_hedge</option></select></div>' +
      '<div class="te-field"><label>Asset class</label><select id="te-asset-class">' +
      '<option value="commodity">commodity</option><option value="rates">rates</option>' +
      '<option value="fx">fx</option><option value="equity">equity</option>' +
      '<option value="credit">credit</option><option value="multi">multi</option></select></div>' +
      '<div class="te-field"><label>Geography</label><select id="te-geography">' +
      '<option value="global">global</option><option value="us">us</option>' +
      '<option value="eu">eu</option><option value="em">em</option></select></div>' +
      '<div class="te-field"><label>Time horizon</label><select id="te-horizon">' +
      '<option value="short">short</option><option value="medium">medium</option>' +
      '<option value="long">long</option></select></div>' +
      '<div class="te-field"><label>Confidence</label><select id="te-confidence">' +
      '<option value="speculative">speculative</option><option value="moderate">moderate</option>' +
      '<option value="high">high</option></select></div>' +
      '<div class="te-field"><label>Asset expression</label><input type="text" id="te-asset-expr" /></div>' +
      '<div class="te-divider"></div>' +
      '<div class="te-parse-wrap">' +
      '<button type="button" class="te-btn-primary" id="te-btn-parse">Parse from text</button>' +
      '<div class="te-parse-popover" id="te-parse-popover">' +
      '<textarea id="te-parse-text" rows="4" style="width:100%;box-sizing:border-box" placeholder="Describe your thesis…"></textarea>' +
      '<button type="button" class="te-btn-primary" id="te-parse-confirm" style="margin-top:8px">Confirm</button>' +
      '<div class="te-parse-note" id="te-parse-note"></div></div></div>' +
      '<button type="button" class="te-btn-primary" id="te-btn-expand">Run expansion →</button>' +
      '</div>' +
      '<button type="button" class="te-collapse-toggle" id="te-collapse-btn" title="Toggle panel">‹</button>' +
      '</div>' +
      '<div class="te-right-panel">' +
      '<div class="te-regime-bar" id="te-regime-bar"></div>' +
      '<div id="te-chart-slot"></div>' +
      '<div id="te-var-rings"></div>' +
      '<div class="te-completeness-row">' +
      '<div class="te-completeness-label">Completeness <span id="te-completeness-pct">0%</span></div>' +
      '<div class="te-completeness-bar"><div class="te-completeness-fill" id="te-completeness-fill" style="width:0%"></div></div>' +
      '</div></div></div></div>'
    );
  }

  function wireEvents(root) {
    document.getElementById('te-collapse-btn').addEventListener('click', function () {
      document.getElementById('te-left-panel').classList.toggle('collapsed');
      var b = document.getElementById('te-collapse-btn');
      if (b) {
        b.textContent = document
          .getElementById('te-left-panel')
          .classList.contains('collapsed')
          ? '›'
          : '‹';
      }
    });
    document.getElementById('te-shock-slider').addEventListener('input', function () {
      document.getElementById('te-shock-val').textContent = this.value + '%';
      window.ThesisEngine.thesisNode.shock_pct = parseFloat(this.value);
    });
    document.getElementById('te-claim').addEventListener('input', function () {
      window.ThesisEngine.thesisNode.claim = this.value;
      updateClaimPreview();
    });
    document.getElementById('te-btn-expand').addEventListener('click', runExpansion);
    document.getElementById('te-btn-parse').addEventListener('click', function (e) {
      e.stopPropagation();
      openParsePopover();
    });
    document.getElementById('te-parse-confirm').addEventListener('click', runParse);
    document.getElementById('te-btn-new').addEventListener('click', newThesis);
    document.querySelectorAll('.te-mode-switcher button').forEach(function (b) {
      b.addEventListener('click', function () {
        setMode(b.getAttribute('data-mode'));
      });
    });
    document.addEventListener('click', function (e) {
      var pop = document.getElementById('te-parse-popover');
      var parseBtn = document.getElementById('te-btn-parse');
      if (
        pop &&
        pop.classList.contains('open') &&
        !pop.contains(e.target) &&
        e.target !== parseBtn
      ) {
        closeParsePopover();
      }
    });
  }

  var _mounted = false;

  window.ThesisEngineApp = {
    activate: function () {
      var cont = document.getElementById('thesis-engine-root');
      if (!cont) return;
      if (!_mounted) {
        cont.innerHTML = buildShellHtml();
        writeNodeIntoForm();
        wireEvents(cont);
        updateClaimPreview();
        renderRegimeBar(null);
        updateCompletenessBar();
        _mounted = true;
      } else {
        writeNodeIntoForm();
        updateClaimPreview();
      }
    },
  };
})();
