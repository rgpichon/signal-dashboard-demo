/**
 * signals/dashboard/modules/intelligence.js
 * SIGNAL Intelligence Dashboard — Phase 1, Spec 10
 *
 * Extracted and enhanced from the Intelligence object in app.js.
 * Renders the S tab dashboard: Today, Signals, Regime, Market,
 * and computed data cards.
 *
 * Reads from window.STATE (populated by app.js on init).
 * Reads from window.ThesisManager for active thesis status.
 *
 * Public API (exposed as window.Intelligence):
 *   Intelligence.init()
 *   Intelligence.renderAllCards()
 *   Intelligence.openSection(target)
 *   Intelligence.backToHub()
 *   Intelligence.filterCards(query)
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

  function truncate(str, max) {
    if (!str) return '';
    return str.length > max ? str.slice(0, max) + '…' : str;
  }

  function fmtPct(val) {
    if (val == null || isNaN(val)) return '—';
    var n = Number(val);
    return (n >= 0 ? '+' : '') + n.toFixed(2) + '%';
  }

  var REGIME_COLORS = {
    elevated:          'var(--red)',
    high:              'var(--red)',
    stress:            'var(--red)',
    suppressed:        'var(--green)',
    low:               'var(--green)',
    normal:            'var(--green)',
    rising:            'var(--teal)',
    moderate:          'var(--teal)',
    flat:              'var(--text-secondary)',
    inverted:          'var(--red)',
    steep:             'var(--green)',
    strong:            'var(--red)',
    weak:              'var(--green)',
    insufficient_data: 'var(--text-muted)',
  };

  function regimeColor(state) {
    if (!state) return 'var(--text-secondary)';
    return REGIME_COLORS[state.toLowerCase()] || 'var(--text-secondary)';
  }

  /** Delegated clicks: market rows → prefill Analysis X */
  function wireIntelMarketRows(el) {
    if (el._intelMarketNavBound) return;
    el._intelMarketNavBound = true;
    el.addEventListener('click', function (e) {
      var row = e.target.closest('.intel-market-row');
      if (!row) return;
      var id = row.dataset.instrumentId;
      if (!id) return;
      if (typeof Shell !== 'undefined') Shell.navigate('research');
      setTimeout(function () {
        if (window.ResearchV2 && typeof ResearchV2._prefillAnalysis === 'function') {
          ResearchV2._prefillAnalysis(id);
        }
      }, 50);
    });
  }

  /** Delegated clicks: signal rows → Research → Signals view */
  function wireIntelSignalRows(el) {
    if (el._intelSignalsNavBound) return;
    el._intelSignalsNavBound = true;
    el.addEventListener('click', function (e) {
      var row = e.target.closest('.intel-signal-row');
      if (!row) return;
      if (typeof Shell !== 'undefined') Shell.navigate('research');
      setTimeout(function () {
        if (typeof ResearchV2 !== 'undefined' && ResearchV2.navigate) {
          ResearchV2.navigate('signals');
        }
      }, 50);
    });
  }

  // ─── Card renderers ───────────────────────────────────────────────────────

  function renderCardToday(el) {
    var briefing = window.STATE && window.STATE.briefing;
    if (!briefing) {
      el.innerHTML = '<div class="intel-empty">No briefing data</div>';
      return;
    }

    var html = '';

    // Highlights
    var highlights = briefing.highlights || [];
    if (highlights.length > 0) {
      html += '<div class="intel-card-section-label">Highlights</div>';
      highlights.slice(0, 3).forEach(function (h) {
        var dirClass = h.direction === 'up' ? 'intel-pos'
                     : h.direction === 'down' ? 'intel-neg' : '';
        html += '<div class="intel-highlight-row">' +
          '<span class="intel-highlight-label ' + dirClass + '">' +
            esc(truncate(h.label, 40)) + '</span>' +
          '<span class="intel-highlight-desc">' +
            esc(truncate(h.description, 60)) + '</span>' +
          '</div>';
      });
    }

    // Signal watch
    var signals = briefing.signal_watch || [];
    if (signals.length > 0) {
      html += '<div class="intel-card-section-label" style="margin-top:8px;">Signal watch</div>';
      signals.slice(0, 3).forEach(function (s) {
        var sent = s.sentiment_avg;
        var sentClass = sent == null ? '' : (sent > 0.1 ? 'intel-pos' : sent < -0.1 ? 'intel-neg' : '');
        html += '<div class="intel-signal-row">' +
          '<span class="intel-signal-topic">' + esc(s.topic) + '</span>' +
          '<span class="intel-signal-count">' + (s.article_count || 0) + '</span>' +
          (sent != null ? '<span class="intel-signal-sent ' + sentClass + '">' +
            Number(sent).toFixed(2) + '</span>' : '') +
          '</div>';
      });
    }

    if (!html) {
      html = '<div class="intel-empty">No data today</div>';
    }

    el.innerHTML = html;
  }

  function renderCardSignals(el) {
    var signals = (window.STATE && window.STATE.signals) || [];
    if (!signals.length) {
      el.innerHTML = '<div class="intel-empty">No signal data</div>';
      return;
    }
    var top = signals.slice(0, 5);
    var html = '';
    top.forEach(function (s) {
      var anomaly = s.anomaly_flag
        ? '<span class="intel-badge intel-badge-alert">!</span>' : '';
      var diverge = s.divergence_flag
        ? '<span class="intel-badge intel-badge-warn">~</span>' : '';
      var sent = s.sentiment_avg;
      var sentClass = sent == null ? '' : (sent > 0.1 ? 'intel-pos' : sent < -0.1 ? 'intel-neg' : '');
      html += '<div class="intel-signal-row" data-topic="' + esc(s.topic) + '" style="cursor:pointer">' +
        '<span class="intel-signal-topic">' + esc(s.topic) + '</span>' +
        '<span class="intel-signal-count">' + (s.article_count || 0) + '</span>' +
        (sent != null ? '<span class="intel-signal-sent ' + sentClass + '">' +
          Number(sent).toFixed(2) + '</span>' : '') +
        anomaly + diverge +
        '</div>';
    });
    el.innerHTML = html;
    wireIntelSignalRows(el);
  }

  function renderCardRegime(el) {
    var regime = window.STATE && window.STATE.regime;
    if (!regime) {
      el.innerHTML = '<div class="intel-empty">No regime data</div>';
      return;
    }
    var indicators = [
      { key: 'growth_pulse',    label: 'GRW' },
      { key: 'credit_stress',   label: 'CRD' },
      { key: 'real_yield',      label: 'RY'  },
      { key: 'dollar_strength', label: 'USD' },
      { key: 'rates_vol',       label: 'RV'  },
      { key: 'equity_vol',      label: 'EV'  },
      { key: 'curve_shape',     label: 'CRV' },
    ];
    var html = '<div class="intel-regime-badges">';
    indicators.forEach(function (ind) {
      var state = (regime[ind.key] || '—').replace(/_/g, ' ');
      var color = regimeColor(regime[ind.key] || '');
      html += '<div class="intel-regime-badge" style="border-color:' + color + ';color:' + color + '">' +
        '<span class="intel-regime-badge-label">' + esc(ind.label) + '</span>' +
        '<span class="intel-regime-badge-state">' + esc(state) + '</span>' +
        '</div>';
    });
    html += '</div>';
    if (regime.date) {
      html += '<div class="intel-regime-date">As of ' + esc(regime.date) + '</div>';
    }
    if (regime.fingerprint) {
      html += '<div class="intel-regime-fingerprint">' + esc(regime.fingerprint) + '</div>';
    }
    el.innerHTML = html;
  }

  function renderCardMarket(el) {
    var briefing = window.STATE && window.STATE.briefing;
    var snapshot = briefing && briefing.market_snapshot;
    if (!snapshot || !snapshot.length) {
      // Fallback to latestPrices
      var lp = (window.STATE && window.STATE.latestPrices) || {};
      var keys = Object.keys(lp).slice(0, 6);
      if (!keys.length) {
        el.innerHTML = '<div class="intel-empty">No market data</div>';
        return;
      }
      var html = '';
      keys.forEach(function (id) {
        var p = lp[id];
        var chgClass = p.pct_chg >= 0 ? 'intel-pos' : 'intel-neg';
        html += '<div class="intel-market-row" data-instrument-id="' + esc(id) + '" style="cursor:pointer">' +
          '<span class="intel-market-name">' + esc(id) + '</span>' +
          '<span class="intel-market-val">' + (p.value != null ? Number(p.value).toFixed(2) : '—') + '</span>' +
          '<span class="intel-market-chg ' + chgClass + '">' + fmtPct(p.pct_chg) + '</span>' +
          '</div>';
      });
      el.innerHTML = html;
      wireIntelMarketRows(el);
      return;
    }
    var html = '';
    snapshot.slice(0, 6).forEach(function (item) {
      var chgClass = (item.pct_chg_1d || 0) >= 0 ? 'intel-pos' : 'intel-neg';
      html += '<div class="intel-market-row" data-instrument-id="' + esc(item.series_id) + '" style="cursor:pointer">' +
        '<span class="intel-market-name">' + esc(item.name || item.series_id) + '</span>' +
        '<span class="intel-market-val">' + (item.value != null ? Number(item.value).toFixed(2) : '—') + '</span>' +
        '<span class="intel-market-chg ' + chgClass + '">' + fmtPct(item.pct_chg_1d) + '</span>' +
        '</div>';
    });
    el.innerHTML = html;
    wireIntelMarketRows(el);
  }

  function renderCardCorrelations(el) {
    var universe = (window.STATE && window.STATE.universe) || [];
    el.innerHTML = '<div class="intel-placeholder">' +
      '<span class="intel-placeholder-count">' + universe.length + '</span>' +
      '<span class="intel-placeholder-label">instruments tracked</span>' +
      '</div>' +
      '<div class="intel-empty" style="margin-top:6px;">Click Open to explore correlations</div>';
  }

  function renderCardForecasts(el) {
    el.innerHTML = '<div class="intel-placeholder">' +
      '<span class="intel-placeholder-label">ARIMA · STL decomposition</span>' +
      '</div>' +
      '<div class="intel-empty" style="margin-top:6px;">Click Open to run forecasts</div>';
  }

  function renderCardVolatility(el) {
    el.innerHTML = '<div class="intel-placeholder">' +
      '<span class="intel-placeholder-label">Realized · GARCH surface</span>' +
      '</div>' +
      '<div class="intel-empty" style="margin-top:6px;">Click Open to explore volatility</div>';
  }

  function renderCardScenarios(el) {
    el.innerHTML = '<div class="intel-placeholder">' +
      '<span class="intel-placeholder-label">Macro shock scenarios</span>' +
      '</div>' +
      '<div class="intel-empty" style="margin-top:6px;">Click Open to run scenarios</div>';
  }

  // ─── Active thesis status ─────────────────────────────────────────────────
  // Injected into the intelligence screen header area if a thesis is active.

  function renderActiveThesisStatus() {
    var existing = document.getElementById('intel-thesis-status');
    if (existing) existing.remove();

    var tm = window.ThesisManager;
    if (!tm || typeof tm.getActive !== 'function') return;
    var thesis = tm.getActive();
    if (!thesis) return;

    var bar = document.createElement('div');
    bar.id = 'intel-thesis-status';
    bar.className = 'intel-thesis-status';
    bar.innerHTML =
      '<span class="intel-thesis-status-label">Active thesis:</span>' +
      '<span class="intel-thesis-status-title intel-thesis-status-link">' +
        esc(truncate(thesis.title || 'Untitled', 50)) +
      '</span>' +
      '<span class="intel-thesis-status-meta">' +
        (thesis.updated_at ? 'saved ' + new Date(thesis.updated_at).toLocaleTimeString() : '') +
      '</span>';

    var link = bar.querySelector('.intel-thesis-status-link');
    if (link) {
      link.addEventListener('click', function () {
        if (typeof Shell !== 'undefined') Shell.navigate('research');
        setTimeout(function () {
          if (typeof ResearchV2 !== 'undefined') ResearchV2.navigate('thesis');
          setTimeout(function () {
            var layout = window.ThesisManager && ThesisManager.getCanvasLayout();
            if (layout && layout.panels && layout.panels.length > 0) {
              var canvasBtn = document.getElementById('thesis-mode-canvas');
              if (canvasBtn) canvasBtn.click();
            }
          }, 300);
        }, 50);
      });
    }

    var screen = document.getElementById('screen-intelligence');
    var searchBar = screen && screen.querySelector('.intel-search-bar');
    if (searchBar) {
      screen.insertBefore(bar, searchBar.nextSibling);
    }
  }

  // ─── Navigation ───────────────────────────────────────────────────────────

  function openSection(target) {
    var researchViews = ['correlations', 'forecasts', 'volatility', 'scenarios',
                         'factors', 'momentum', 'rates', 'overview'];
    var screenId;
    if (researchViews.indexOf(target) !== -1) {
      if (typeof Shell !== 'undefined') Shell.navigate('research');
      if (typeof ResearchV2 !== 'undefined') {
        setTimeout(function () { ResearchV2.navigate(target); }, 50);
      }
      screenId = 'screen-research';
    } else {
      if (typeof Shell !== 'undefined') Shell.navigate(target);
      screenId = 'screen-' + target;
    }
    injectBackButton(screenId);
    Intelligence.activeSection = target;
  }

  function backToHub() {
    if (typeof Shell !== 'undefined') Shell.navigate('intelligence', { openPanel: false });
    Intelligence.activeSection = null;
  }

  function injectBackButton(screenId) {
    var screen = document.getElementById(screenId);
    if (!screen) return;
    var existing = screen.querySelector('.intel-back-bar');
    if (existing) existing.remove();
    var bar = document.createElement('div');
    bar.className = 'intel-back-bar';
    bar.innerHTML = '<button class="intel-back-btn" type="button">&larr; Intelligence</button>';
    bar.querySelector('.intel-back-btn').addEventListener('click', function () {
      backToHub();
      bar.remove();
    });
    screen.insertBefore(bar, screen.firstChild);
  }

  // ─── Search ───────────────────────────────────────────────────────────────

  function initSearch() {
    var input = document.getElementById('intel-search-input');
    if (!input) return;
    input.addEventListener('input', function () {
      Intelligence.filterCards(input.value.trim());
    });
    input.addEventListener('keydown', function (e) {
      if (e.key === 'Escape') {
        input.value = '';
        Intelligence.filterCards('');
      }
    });
  }

  function filterCards(query) {
    var q = (query || '').toLowerCase();
    document.querySelectorAll('.intel-card').forEach(function (card) {
      if (!q) { card.style.display = ''; return; }
      var title = (card.dataset.card || '').toLowerCase();
      var body = (card.querySelector('.intel-card-body') || {}).textContent || '';
      card.style.display = (title.includes(q) || body.toLowerCase().includes(q)) ? '' : 'none';
    });
  }

  // ─── Public API ───────────────────────────────────────────────────────────

  var Intelligence = {
    activeSection: null,

    init: function () {
      // Wire card clicks
      document.querySelectorAll('.intel-card').forEach(function (card) {
        card.addEventListener('click', function (e) {
          if (e.target.classList.contains('intel-card-open') ||
              e.target.closest('.intel-card-open')) return;
          var btn = card.querySelector('.intel-card-open');
          if (btn) Intelligence.openSection(btn.dataset.target);
        });
      });

      // Wire Open buttons
      document.querySelectorAll('.intel-card-open').forEach(function (btn) {
        btn.addEventListener('click', function (e) {
          e.stopPropagation();
          Intelligence.openSection(btn.dataset.target);
        });
      });

      initSearch();
      Intelligence.renderAllCards();
      renderActiveThesisStatus();
    },

    renderAllCards: function () {
      var renderers = {
        today:        renderCardToday,
        signals:      renderCardSignals,
        regime:       renderCardRegime,
        market:       renderCardMarket,
        correlations: renderCardCorrelations,
        forecasts:    renderCardForecasts,
        volatility:   renderCardVolatility,
        scenarios:    renderCardScenarios,
      };
      Object.keys(renderers).forEach(function (name) {
        var el = document.getElementById('intel-card-' + name);
        if (!el) return;
        try {
          renderers[name](el);
        } catch (err) {
          console.error('[Intelligence] card error:', name, err);
          el.innerHTML = '<div class="intel-empty">Data unavailable</div>';
        }
      });
    },

    openSection:  openSection,
    backToHub:    backToHub,
    filterCards:  filterCards,
  };

  window.Intelligence = Intelligence;

})();
