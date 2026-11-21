/**
 * signals/dashboard/modules/panel-registry.js
 * SIGNAL Panel Registry — Phase 0, Spec 9c
 *
 * Dispatches renderPanel calls to the correct panel renderer.
 * Panel renderers register themselves via PanelRegistry.register().
 *
 * Public API (exposed as window.PanelRegistry):
 *   PanelRegistry.register(type, renderer)
 *   PanelRegistry.render(contentEl, panel)
 *   PanelRegistry.getMeta(type) → { type, label, defaultW, defaultH, icon }
 *   PanelRegistry.listTypes() → array of type strings
 */

(function () {
  'use strict';

  var _renderers = {};
  var _meta = {};

  var PanelRegistry = {

    /**
     * Register a panel renderer.
     * @param {string} type      — panel type string e.g. 'macro_context'
     * @param {object} renderer  — must have render(contentEl, panel) method
     * @param {object} meta      — { label, defaultW, defaultH, icon }
     */
    register: function (type, renderer, meta) {
      if (!type || typeof renderer.render !== 'function') {
        console.warn('[PanelRegistry] invalid registration for type:', type);
        return;
      }
      _renderers[type] = renderer;
      _meta[type] = Object.assign(
        { type: type, label: type, defaultW: 4, defaultH: 3, icon: '▪' },
        meta || {}
      );
    },

    /**
     * Render a panel into contentEl.
     * Called by CanvasEngine via the renderPanel callback.
     * @param {HTMLElement} contentEl
     * @param {object}      panel — { id, type, x, y, w, h, config }
     */
    render: function (contentEl, panel) {
      var renderer = _renderers[panel.type];
      if (!renderer) {
        contentEl.innerHTML =
          '<div style="padding:12px;font-size:11px;color:var(--text-muted);">' +
          'No renderer for panel type: ' + panel.type + '</div>';
        return;
      }
      try {
        renderer.render(contentEl, panel);
      } catch (err) {
        console.error('[PanelRegistry] render error for type', panel.type, err);
        contentEl.innerHTML =
          '<div style="padding:12px;font-size:11px;color:var(--red);">' +
          'Render error: ' + err.message + '</div>';
      }
    },

    /**
     * Get metadata for a panel type.
     * @param {string} type
     * @returns {{ type, label, defaultW, defaultH, icon } | null}
     */
    getMeta: function (type) {
      return _meta[type] || null;
    },

    /**
     * List all registered panel types.
     * @returns {string[]}
     */
    listTypes: function () {
      return Object.keys(_renderers);
    },

  };

  window.PanelRegistry = PanelRegistry;

})();
