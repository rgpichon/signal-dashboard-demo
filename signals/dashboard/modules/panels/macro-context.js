/**
 * signals/dashboard/modules/panels/macro-context.js
 * SIGNAL MacroContext Panel — Phase 0, Spec 9c
 *
 * Renders current macro regime, key rates, and top signals
 * into a canvas panel content element.
 *
 * Reads from window.STATE (populated by app.js on init).
 * No API calls — uses already-fetched STATE data only.
 *
 * Registered as panel type: 'macro_context'
 */

(function () {
  'use strict';

  // ─── Helpers ──────────────────────────────────────────────────────────────

  function esc(str) {
    if (str == null) return '';
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;');
  }

  function fmt(val, decimals) {
    if (val == null || isNaN(val)) return '—';
    return Number(val).toFixed(decimals != null ? decimals : 2);
  }

  function fmtPct(val) {
    if (val == null || isNaN(val)) return '—';
    var n = Number(val);
    return (n >= 0 ? '+' : '') + n.toFixed(2) + '%';
  }

  // ─── Regime badge colour ──────────────────────────────────────────────────
  // Maps a regime indicator state string to a CSS colour variable.

  var STATE_COLORS = {
    high:       'var(--red)',
    elevated:   'var(--red)',
    stress:     'var(--red)',
    rising:     'var(--orange, var(--teal))',
    moderate:   'var(--teal)',
    normal:     'var(--green)',
    low:        'var(--green)',
    flat:       'var(--text-secondary)',
    inverted:   'var(--red)',
    steep:      'var(--green)',
    strong:     'var(--red)',
    weak:       'var(--green)',
  };

  function regimeColor(state) {
    if (!state) return 'var(--text-secondary)';
    return STATE_COLORS[state.toLowerCase()] || 'var(--text-secondary)';
  }

  // ─── Render ───────────────────────────────────────────────────────────────

  function render(contentEl, panel) {
    var regime = (window.STATE && window.STATE.regime) || null;
    var latestPrices = (window.STATE && window.STATE.latestPrices) || {};
    var signals = (window.STATE && window.STATE.signals) || [];

    var html = '<div class="mcp-root">';

    // ── Section 1: Regime indicators ─────────────────────────────────────
    html += '<div class="mcp-section">';
    html += '<div class="mcp-section-label">Macro regime</div>';

    if (!regime) {
      html += '<div class="mcp-empty">No regime data</div>';
    } else {
      var indicators = [
        { key: 'growth_pulse',   label: 'GRW' },
        { key: 'credit_stress',  label: 'CRD' },
        { key: 'real_yield',     label: 'RY'  },
        { key: 'dollar_strength',label: 'USD' },
        { key: 'rates_vol',      label: 'RV'  },
        { key: 'equity_vol',     label: 'EV'  },
        { key: 'curve_shape',    label: 'CRV' },
      ];
      html += '<div class="mcp-badges">';
      indicators.forEach(function (ind) {
        var state = regime[ind.key] || '—';
        var color = regimeColor(state);
        html += '<div class="mcp-badge" style="border-color:' + color + ';color:' + color + '">' +
          '<span class="mcp-badge-label">' + esc(ind.label) + '</span>' +
          '<span class="mcp-badge-state">' + esc(state) + '</span>' +
          '</div>';
      });
      html += '</div>';

      if (regime.fingerprint) {
        html += '<div class="mcp-fingerprint">' + esc(regime.fingerprint) + '</div>';
      }
    }
    html += '</div>';

    // ── Section 2: Key rates and prices ──────────────────────────────────
    var keyPrices = [
      { id: 'RATES.US10Y',  label: 'US 10Y',   decimals: 2 },
      { id: 'RATES.US2Y',   label: 'US 2Y',    decimals: 2 },
      { id: 'EQ.SPX',       label: 'S&P 500',  decimals: 0 },
      { id: 'FX.DXY',       label: 'DXY',      decimals: 2 },
      { id: 'CM.BRENT',     label: 'Brent',    decimals: 2 },
      { id: 'EQ.VIX',       label: 'VIX',      decimals: 2 },
    ];

    html += '<div class="mcp-section">';
    html += '<div class="mcp-section-label">Key prices</div>';
    html += '<div class="mcp-prices">';
    keyPrices.forEach(function (item) {
      var p = latestPrices[item.id];
      var val = p ? fmt(p.value, item.decimals) : '—';
      var chg = p ? p.pct_chg : null;
      var chgClass = chg == null ? '' : (chg >= 0 ? 'mcp-pos' : 'mcp-neg');
      var chgStr = chg != null ? fmtPct(chg) : '—';
      html += '<div class="mcp-price-row">' +
        '<span class="mcp-price-label">' + esc(item.label) + '</span>' +
        '<span class="mcp-price-val">' + esc(val) + '</span>' +
        '<span class="mcp-price-chg ' + chgClass + '">' + esc(chgStr) + '</span>' +
        '</div>';
    });
    html += '</div>';
    html += '</div>';

    // ── Section 3: Top signals ────────────────────────────────────────────
    var topSignals = signals
      .filter(function (s) { return s && s.topic; })
      .slice(0, 3);

    if (topSignals.length > 0) {
      html += '<div class="mcp-section">';
      html += '<div class="mcp-section-label">Top signals</div>';
      html += '<div class="mcp-signals">';
      topSignals.forEach(function (s) {
        var sent = s.sentiment_avg;
        var sentClass = sent == null ? '' : (sent > 0.1 ? 'mcp-pos' : sent < -0.1 ? 'mcp-neg' : '');
        html += '<div class="mcp-signal-row">' +
          '<span class="mcp-signal-topic">' + esc(s.topic) + '</span>' +
          '<span class="mcp-signal-count">' + (s.article_count || 0) + ' art.</span>' +
          (sent != null ?
            '<span class="mcp-signal-sent ' + sentClass + '">' + fmt(sent, 2) + '</span>' : '') +
          '</div>';
      });
      html += '</div>';
      html += '</div>';
    }

    html += '</div>'; // .mcp-root

    contentEl.innerHTML = html;
  }

  // ─── Register ─────────────────────────────────────────────────────────────

  // Registration is deferred until PanelRegistry is available.
  // canvas.js loads before app.js, panel-registry.js loads after canvas.js.
  // All scripts are synchronous so by the time this runs, PanelRegistry exists.

  if (window.PanelRegistry) {
    window.PanelRegistry.register(
      'macro_context',
      { render: render },
      {
        label:    'Macro context',
        defaultW: 4,
        defaultH: 5,
        icon:     '◎',
      }
    );
  } else {
    console.warn('[MacroContextPanel] PanelRegistry not available — registration skipped');
  }

})();
