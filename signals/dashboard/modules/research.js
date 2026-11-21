/**
 * signals/dashboard/modules/research.js
 * SIGNAL Research Market Overview — Phase 2, Spec 11
 *
 * Renders the Market overview into #canvas-overview.
 * Called by ResearchV2.navigate('overview').
 *
 * Reads from window.STATE only (populated by app.js on init).
 * No API calls — instant render from already-fetched data.
 *
 * Public API (exposed as window.ResearchOverview):
 *   ResearchOverview.render(containerEl)
 */

(function () {
  'use strict';

  function esc(str) {
    if (str == null) return '';
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;');
  }

  function fmtVal(val, decimals) {
    if (val == null || isNaN(val)) return '—';
    return Number(val).toFixed(decimals != null ? decimals : 2);
  }

  function fmtPct(val) {
    if (val == null || isNaN(val)) return '—';
    var n = Number(val);
    return (n >= 0 ? '+' : '') + n.toFixed(2) + '%';
  }

  function pctClass(val) {
    if (val == null || isNaN(val)) return '';
    return Number(val) >= 0 ? 'ro-pos' : 'ro-neg';
  }

  // ─── Section: Market snapshot ─────────────────────────────────────────────
  // Uses briefing.market_snapshot (8 key instruments with names)
  // Falls back to latestPrices for known series if briefing not available

  function renderMarketSnapshot(briefing, latestPrices) {
    var snapshot = (briefing && briefing.market_snapshot) || [];

    // If no briefing snapshot, build from latestPrices using known key series
    if (!snapshot.length && latestPrices) {
      var keySeries = [
        { series_id: 'EQ.SPX',    name: 'S&P 500'  },
        { series_id: 'EQ.SX7E',   name: 'Euro Stoxx 50' },
        { series_id: 'FX.EURUSD', name: 'EUR/USD'  },
        { series_id: 'CM.GOLD',   name: 'Gold'     },
        { series_id: 'CM.BRENT',  name: 'Brent'    },
        { series_id: 'EQ.VIX',    name: 'VIX'      },
        { series_id: 'RATES.US10Y', name: 'US 10Y' },
        { series_id: 'FX.DXY',    name: 'DXY'      },
      ];
      keySeries.forEach(function (k) {
        var p = latestPrices[k.series_id];
        if (p) {
          snapshot.push({
            series_id: k.series_id,
            name: k.name,
            value: p.value,
            pct_chg_1d: p.pct_chg,
          });
        }
      });
    }

    if (!snapshot.length) {
      return '<div class="ro-empty">No market data available</div>';
    }

    var html = '<div class="ro-snapshot-grid">';
    snapshot.forEach(function (item) {
      var chgClass = pctClass(item.pct_chg_1d);
      var decimals = item.series_id && item.series_id.startsWith('RATES.') ? 3
                   : item.series_id && item.series_id.startsWith('FX.')    ? 4
                   : 2;
      html += '<div class="ro-snapshot-tile" data-instrument-id="' + esc(item.series_id) + '" style="cursor:pointer">' +
        '<div class="ro-tile-name">' + esc(item.name || item.series_id) + '</div>' +
        '<div class="ro-tile-value">' + fmtVal(item.value, decimals) + '</div>' +
        '<div class="ro-tile-chg ' + chgClass + '">' + fmtPct(item.pct_chg_1d) + '</div>' +
        '</div>';
    });
    html += '</div>';
    return html;
  }

  // ─── Section: Factor heatmap ──────────────────────────────────────────────
  // Shows which macro factors are stressed today based on latestPrices
  // for the factor proxy instruments

  function renderFactorHeatmap(latestPrices) {
    if (!latestPrices) return '';

    var factors = [
      { id: 'f_rates',     label: 'Rates',     proxy: 'RATES.US10Y',   invert: false },
      { id: 'f_dollar',    label: 'Dollar',    proxy: 'FX.DXY',        invert: false },
      { id: 'f_risk',      label: 'Risk (VIX)',proxy: 'EQ.VIX',        invert: true  },
      { id: 'f_growth',    label: 'Growth',    proxy: 'CM.COPPER',     invert: false },
      { id: 'f_credit',    label: 'Credit',    proxy: 'CREDIT.HY_OAS', invert: true  },
      { id: 'f_inflation', label: 'Inflation', proxy: 'RATES.BREAKEVEN',invert: false },
    ];

    var hasAny = factors.some(function (f) {
      return latestPrices[f.proxy] != null;
    });
    if (!hasAny) return '';

    var html = '<div class="ro-factor-row">';
    factors.forEach(function (f) {
      var p = latestPrices[f.proxy];
      var chg = p ? Number(p.pct_chg) : null;
      if (chg == null && p) chg = Number(p.daily_chg);

      var intensity = 'ro-factor-neutral';
      var arrow = '→';
      if (chg != null && !isNaN(chg)) {
        var effective = f.invert ? -chg : chg;
        if (effective > 1)       { intensity = 'ro-factor-high';   arrow = '↑'; }
        else if (effective > 0.3){ intensity = 'ro-factor-mid';    arrow = '↗'; }
        else if (effective < -1) { intensity = 'ro-factor-low';    arrow = '↓'; }
        else if (effective < -0.3){ intensity = 'ro-factor-mild';  arrow = '↘'; }
      }

      var valStr = p ? fmtVal(p.value, 2) : '—';
      var chgStr = chg != null ? fmtPct(chg) : '—';

      html += '<div class="ro-factor-tile ' + intensity + '">' +
        '<div class="ro-factor-label">' + esc(f.label) + '</div>' +
        '<div class="ro-factor-arrow">' + arrow + '</div>' +
        '<div class="ro-factor-val">' + esc(valStr) + '</div>' +
        '<div class="ro-factor-chg">' + esc(chgStr) + '</div>' +
        '</div>';
    });
    html += '</div>';
    return html;
  }

  // ─── Section: Signal watch ────────────────────────────────────────────────

  function renderSignalWatch(signals) {
    if (!signals || !signals.length) {
      return '<div class="ro-empty">No signal data</div>';
    }
    var top = signals.slice(0, 8);
    var html = '<div class="ro-signal-list">';
    top.forEach(function (s) {
      var sent = s.sentiment_avg;
      var sentClass = sent == null ? 'ro-sent-neu'
                    : sent > 0.1  ? 'ro-sent-pos'
                    : sent < -0.1 ? 'ro-sent-neg'
                    : 'ro-sent-neu';
      var sentLabel = sent == null ? '' : Number(sent).toFixed(2);
      var anomaly = s.anomaly_flag
        ? '<span class="ro-signal-flag ro-signal-flag--alert">!</span>' : '';
      html += '<div class="ro-signal-row">' +
        '<span class="ro-signal-topic">' + esc(s.topic) + '</span>' +
        '<span class="ro-signal-count">' + (s.article_count || 0) + ' art.</span>' +
        (sentLabel ? '<span class="ro-signal-sent ' + sentClass + '">' + sentLabel + '</span>' : '') +
        anomaly +
        '</div>';
    });
    html += '</div>';
    return html;
  }

  // ─── Section: Universe movers ─────────────────────────────────────────────
  // Top 5 movers from latestPrices within the universe

  function renderTopMovers(universe, latestPrices) {
    if (!universe || !universe.length || !latestPrices) return '';

    var movers = universe
      .filter(function (inst) {
        var p = latestPrices[inst.id];
        return p && p.pct_chg != null && !isNaN(p.pct_chg);
      })
      .map(function (inst) {
        var p = latestPrices[inst.id];
        return { id: inst.id, name: inst.name, pct_chg: Number(p.pct_chg), value: p.value };
      })
      .sort(function (a, b) { return Math.abs(b.pct_chg) - Math.abs(a.pct_chg); })
      .slice(0, 8);

    if (!movers.length) return '';

    var html = '<div class="ro-movers-list">';
    movers.forEach(function (m) {
      var cls = m.pct_chg >= 0 ? 'ro-pos' : 'ro-neg';
      html += '<div class="ro-mover-row" data-instrument-id="' + esc(m.id) + '" style="cursor:pointer">' +
        '<span class="ro-mover-name">' + esc(m.name || m.id) + '</span>' +
        '<span class="ro-mover-id">' + esc(m.id) + '</span>' +
        '<span class="ro-mover-chg ' + cls + '">' + fmtPct(m.pct_chg) + '</span>' +
        '</div>';
    });
    html += '</div>';
    return html;
  }

  // ─── Main render ──────────────────────────────────────────────────────────

  function render(containerEl) {
    var STATE = window.STATE || {};
    var briefing = STATE.briefing || null;
    var latestPrices = STATE.latestPrices || {};
    var signals = STATE.signals || [];
    var universe = STATE.universe || [];
    var regime = STATE.regime || null;

    var html = '<div class="ro-root">';

    // Row 1: regime fingerprint bar (if available)
    if (regime) {
      var indicators = [
        { key: 'growth_pulse',    label: 'GRW' },
        { key: 'credit_stress',   label: 'CRD' },
        { key: 'real_yield',      label: 'RY'  },
        { key: 'dollar_strength', label: 'USD' },
        { key: 'rates_vol',       label: 'RV'  },
        { key: 'equity_vol',      label: 'EV'  },
        { key: 'curve_shape',     label: 'CRV' },
      ];
      var REGIME_COLORS = {
        elevated: 'var(--red)', high: 'var(--red)', stress: 'var(--red)',
        suppressed: 'var(--green)', low: 'var(--green)', normal: 'var(--green)',
        rising: 'var(--teal)', moderate: 'var(--teal)',
        flat: 'var(--text-secondary)', inverted: 'var(--red)', steep: 'var(--green)',
        strong: 'var(--red)', weak: 'var(--green)',
        insufficient_data: 'var(--text-muted)',
      };
      html += '<div class="ro-regime-bar">';
      indicators.forEach(function (ind) {
        var state = (regime[ind.key] || '—').toLowerCase().replace(/_/g, ' ');
        var color = REGIME_COLORS[regime[ind.key] ? regime[ind.key].toLowerCase() : ''] || 'var(--text-secondary)';
        html += '<div class="ro-regime-pill" style="border-color:' + color + ';color:' + color + '">' +
          '<span class="ro-regime-pill-key">' + esc(ind.label) + '</span>' +
          '<span class="ro-regime-pill-val">' + esc(state) + '</span>' +
          '</div>';
      });
      if (regime.date) {
        html += '<span class="ro-regime-date">as of ' + esc(regime.date) + '</span>';
      }
      html += '</div>';
    }

    // Row 2: factor heatmap
    var factorHtml = renderFactorHeatmap(latestPrices);
    if (factorHtml) {
      html += '<div class="ro-section">';
      html += '<div class="ro-section-label">Factor moves today</div>';
      html += factorHtml;
      html += '</div>';
    }

    // Row 3: market snapshot tiles
    html += '<div class="ro-section">';
    html += '<div class="ro-section-label">Market snapshot</div>';
    html += renderMarketSnapshot(briefing, latestPrices);
    html += '</div>';

    // Row 4: two columns — top movers + signal watch
    var moversHtml = renderTopMovers(universe, latestPrices);
    html += '<div class="ro-two-col">';

    // Left: top movers
    html += '<div class="ro-col">';
    html += '<div class="ro-section-label">Top movers</div>';
    if (moversHtml) {
      html += moversHtml;
    } else {
      html += '<div class="ro-empty">No price data</div>';
    }
    html += '</div>';

    // Right: signal watch
    html += '<div class="ro-col">';
    html += '<div class="ro-section-label">Signal watch</div>';
    html += renderSignalWatch(signals);
    html += '</div>';

    html += '</div>'; // .ro-two-col
    html += '</div>'; // .ro-root

    containerEl.innerHTML = html;

    // Click delegation for instrument → Analysis prefill
    if (!containerEl._roInstrumentNavBound) {
      containerEl._roInstrumentNavBound = true;
      containerEl.addEventListener('click', function (e) {
        var row = e.target.closest('.ro-mover-row, .ro-snapshot-tile');
        if (!row) return;
        var id = row.dataset.instrumentId;
        if (!id) return;
        if (window.ResearchV2 && typeof ResearchV2._prefillAnalysis === 'function') {
          ResearchV2._prefillAnalysis(id);
        }
      });
    }
  }

  // ─── Public API ───────────────────────────────────────────────────────────

  var ResearchOverview = {
    render: render,
  };

  window.ResearchOverview = ResearchOverview;

})();
