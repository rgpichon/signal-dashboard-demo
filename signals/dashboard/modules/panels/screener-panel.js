/**
 * signals/dashboard/modules/panels/screener-panel.js
 * SIGNAL Screener Panel — Phase 3, Spec 12c
 *
 * Renders the market overview (from ResearchOverview) inside a panel.
 * Reuses the same renderer as the R tab market overview.
 *
 * panel.config shape: {} (no config needed — always shows live data)
 */

(function () {
  'use strict';

  function render(contentEl, panel) {
    if (typeof window.ResearchOverview !== 'undefined' &&
        typeof window.ResearchOverview.render === 'function') {
      window.ResearchOverview.render(contentEl);
    } else {
      contentEl.innerHTML =
        '<div style="padding:12px;font-size:11px;color:var(--text-muted);">' +
        'Market overview not available</div>';
    }
  }

  if (window.PanelRegistry) {
    window.PanelRegistry.register(
      'screener',
      { render: render },
      { label: 'Screener', defaultW: 12, defaultH: 4, icon: '◫' }
    );
  } else {
    console.warn('[ScreenerPanel] PanelRegistry not available');
  }

})();
