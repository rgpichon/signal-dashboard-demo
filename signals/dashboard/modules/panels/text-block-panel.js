/**
 * signals/dashboard/modules/panels/text-block-panel.js
 * SIGNAL Text Block Panel — Phase 3, Spec 12c
 *
 * A contenteditable writing panel for notes and analysis.
 * Content saved in panel.config.content as HTML string.
 *
 * panel.config shape:
 * { content: string }  — HTML content (default: '')
 */

(function () {
  'use strict';

  function render(contentEl, panel) {
    if (!panel.config) panel.config = {};
    var content = panel.config.content || '';

    contentEl.innerHTML =
      '<div class="tbp-editor" contenteditable="true" spellcheck="true" ' +
        'data-placeholder="Type your notes here...">' +
        content +
      '</div>';

    var editor = contentEl.querySelector('.tbp-editor');

    // Debounced save
    var saveTimer = null;
    editor.addEventListener('input', function () {
      if (saveTimer) clearTimeout(saveTimer);
      saveTimer = setTimeout(function () {
        panel.config.content = editor.innerHTML;
        var canvasCt = document.getElementById('thesis-canvas-container');
        if (canvasCt && canvasCt._canvasInstance && window.ThesisManager) {
          window.ThesisManager.setCanvasLayout(canvasCt._canvasInstance.getLayout());
        }
      }, 800);
    });
  }

  if (window.PanelRegistry) {
    window.PanelRegistry.register(
      'text_block',
      { render: render },
      { label: 'Text block', defaultW: 6, defaultH: 3, icon: '✎' }
    );
  } else {
    console.warn('[TextBlockPanel] PanelRegistry not available');
  }

})();
