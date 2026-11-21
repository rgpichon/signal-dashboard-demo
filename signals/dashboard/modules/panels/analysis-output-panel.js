/**
 * signals/dashboard/modules/panels/analysis-output-panel.js
 * SIGNAL Analysis Output Panel — Phase 3, Spec 12c
 *
 * Displays a pinned analysis result (impact table, factor bars,
 * forecast table, or correlation matrix).
 * In this spec, renders a placeholder — real data
 * is pinned from the Analysis tab in Spec 12e.
 *
 * panel.config shape:
 * {
 *   output_type: string,  — 'impact'|'factors'|'forecast'|'correlation'
 *   data: object,         — the analysis result data
 *   label: string,        — display label
 * }
 */

(function () {
  'use strict';

  function esc(str) {
    if (str == null) return '';
    return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }

  function render(contentEl, panel) {
    if (!panel.config) panel.config = {};
    var outputType = panel.config.output_type;
    var data = panel.config.data;
    var label = panel.config.label || 'Analysis output';

    if (!outputType || !data) {
      contentEl.innerHTML =
        '<div class="aop-placeholder">' +
          '<div class="aop-placeholder-icon">▤</div>' +
          '<div class="aop-placeholder-label">Analysis output</div>' +
          '<div class="aop-placeholder-desc">Pin an analysis result from the Analysis tab to populate this panel.</div>' +
        '</div>';
      return;
    }

    var html = '<div class="aop-header"><span class="aop-label">' + esc(label) + '</span></div>';

    if (outputType === 'impact' && typeof window.renderImpactEmbedHTML === 'function') {
      html += window.renderImpactEmbedHTML(data, panel.config.shock_pct || 10);
    } else if (outputType === 'factors' && typeof window.renderFactorsEmbedHTML === 'function') {
      html += window.renderFactorsEmbedHTML(data);
    } else if (outputType === 'correlation' && typeof window.renderCorrelationEmbedHTML === 'function') {
      html += window.renderCorrelationEmbedHTML(data, panel.config.ids || []);
    } else {
      html += '<div class="aop-raw"><pre>' + esc(JSON.stringify(data, null, 2).slice(0, 500)) + '</pre></div>';
    }

    contentEl.innerHTML = html;
  }

  if (window.PanelRegistry) {
    window.PanelRegistry.register(
      'analysis_output',
      { render: render },
      { label: 'Analysis output', defaultW: 8, defaultH: 4, icon: '▤' }
    );
  } else {
    console.warn('[AnalysisOutputPanel] PanelRegistry not available');
  }

})();
