/**
 * signals/dashboard/modules/canvas.js
 * SIGNAL Canvas Grid Engine — Phase 0, Spec 9b
 *
 * Implements a 12-column panel grid with drag-to-reposition and
 * drag-to-resize. Panels snap to grid on mouseup.
 *
 * Public API (exposed as window.CanvasEngine):
 *   CanvasEngine.mount(containerEl, layout, callbacks) → instance
 *   instance.update(layout)
 *   instance.getLayout() → layout object
 *   instance.destroy()
 *
 * Layout schema (matches canvas_layout in research_theses table):
 * {
 *   version: 1,
 *   panels: [{ id, type, x, y, w, h, config }],
 *   grid: { cols: 12, row_height_px: 80, gap_px: 8 }
 * }
 *
 * Callbacks:
 * {
 *   onLayoutChange(layout) — called after every drag/resize completes
 *   onPanelClose(panelId)  — called when panel close button is clicked
 *   renderPanel(panelEl, panel) — called to render panel content
 *                                 (no-op until Spec 9c wires panel registry)
 * }
 */

(function () {
  'use strict';

  // ─── Constants ────────────────────────────────────────────────────────────

  var COLS = 12;
  var ROW_HEIGHT = 80;
  var GAP = 8;
  var MIN_W = 2;
  var MIN_H = 2;

  // ─── Grid math ────────────────────────────────────────────────────────────

  function colWidth(containerWidth) {
    return (containerWidth - (COLS - 1) * GAP) / COLS;
  }

  function toPixels(panel, containerWidth) {
    var cw = Math.round(colWidth(containerWidth));
    return {
      left:   panel.x * (cw + GAP),
      top:    panel.y * (ROW_HEIGHT + GAP),
      width:  panel.w * cw + (panel.w - 1) * GAP,
      height: panel.h * ROW_HEIGHT + (panel.h - 1) * GAP,
    };
  }

  function toGrid(px, containerWidth) {
    var cw = Math.round(colWidth(containerWidth));
    return {
      x: Math.round(px.left / (cw + GAP)),
      y: Math.round(px.top / (ROW_HEIGHT + GAP)),
      w: Math.max(MIN_W, Math.round((px.width + GAP) / (cw + GAP))),
      h: Math.max(MIN_H, Math.round((px.height + GAP) / (ROW_HEIGHT + GAP))),
    };
  }

  function clampPanel(panel) {
    var p = Object.assign({}, panel);
    p.x = Math.max(0, Math.floor(p.x));
    p.y = Math.max(0, Math.floor(p.y));
    p.w = Math.max(MIN_W, Math.min(COLS, Math.floor(p.w)));
    p.h = Math.max(MIN_H, Math.floor(p.h));
    if (p.x + p.w > COLS) p.x = COLS - p.w;
    return p;
  }

  // ─── Canvas height ─────────────────────────────────────────────────────────
  // Canvas height = bottom edge of the lowest panel + one empty row of padding

  function canvasHeight(panels) {
    var maxBottom = 0;
    panels.forEach(function (p) {
      var bottom = p.y + p.h;
      if (bottom > maxBottom) maxBottom = bottom;
    });
    return (maxBottom + 1) * (ROW_HEIGHT + GAP);
  }

  // ─── DOM helpers ──────────────────────────────────────────────────────────

  function createElement(tag, className, style) {
    var el = document.createElement(tag);
    if (className) el.className = className;
    if (style) Object.assign(el.style, style);
    return el;
  }

  // ─── Panel DOM ────────────────────────────────────────────────────────────

  function buildPanelEl(panel, containerWidth, callbacks) {
    var px = toPixels(panel, containerWidth);
    var el = createElement('div', 'canvas-panel', {
      position: 'absolute',
      left:   px.left   + 'px',
      top:    px.top    + 'px',
      width:  px.width  + 'px',
      height: px.height + 'px',
      boxSizing: 'border-box',
    });
    el.dataset.panelId = panel.id;
    el.dataset.panelType = panel.type;

    // Header (drag handle)
    var header = createElement('div', 'canvas-panel-header');
    var typeLabel = createElement('span', 'canvas-panel-type');
    typeLabel.textContent = panel.type.replace(/_/g, ' ');
    var closeBtn = createElement('button', 'canvas-panel-close');
    closeBtn.textContent = '×';
    closeBtn.title = 'Remove panel';
    closeBtn.addEventListener('click', function (e) {
      e.stopPropagation();
      if (typeof callbacks.onPanelClose === 'function') {
        callbacks.onPanelClose(panel.id);
      }
    });
    header.appendChild(typeLabel);
    header.appendChild(closeBtn);
    el.appendChild(header);

    // Content area
    var content = createElement('div', 'canvas-panel-content');
    el.appendChild(content);

    // Resize handle (bottom-right corner)
    var resizeHandle = createElement('div', 'canvas-panel-resize-handle');
    el.appendChild(resizeHandle);

    return el;
  }

  // ─── Drag to reposition ───────────────────────────────────────────────────

  function wireDrag(panelEl, panel, instance) {
    var header = panelEl.querySelector('.canvas-panel-header');
    if (!header) return;

    var dragging = false;
    var startMouseX, startMouseY, startLeft, startTop;

    header.addEventListener('mousedown', function (e) {
      if (e.target.classList.contains('canvas-panel-close')) return;
      e.preventDefault();
      dragging = true;
      startMouseX = e.clientX;
      startMouseY = e.clientY;
      startLeft = parseInt(panelEl.style.left, 10);
      startTop  = parseInt(panelEl.style.top,  10);
      panelEl.classList.add('canvas-panel--dragging');

      function onMouseMove(e) {
        if (!dragging) return;
        var dx = e.clientX - startMouseX;
        var dy = e.clientY - startMouseY;
        panelEl.style.left = Math.max(0, startLeft + dx) + 'px';
        panelEl.style.top  = Math.max(0, startTop  + dy) + 'px';
      }

      function onMouseUp() {
        if (!dragging) return;
        dragging = false;
        panelEl.classList.remove('canvas-panel--dragging');
        document.removeEventListener('mousemove', onMouseMove);
        document.removeEventListener('mouseup', onMouseUp);

        // Snap to grid
        var containerWidth = instance._containerEl.offsetWidth;
        var snapped = toGrid(
          { left: parseInt(panelEl.style.left, 10),
            top:  parseInt(panelEl.style.top,  10),
            width:  parseInt(panelEl.style.width,  10),
            height: parseInt(panelEl.style.height, 10) },
          containerWidth
        );
        var clamped = clampPanel(
          Object.assign({}, panel, { x: snapped.x, y: snapped.y })
        );
        panel.x = clamped.x;
        panel.y = clamped.y;

        // Apply snapped position
        var px = toPixels(panel, containerWidth);
        panelEl.style.left = px.left + 'px';
        panelEl.style.top  = px.top  + 'px';

        // Update canvas height and notify
        instance._updateCanvasHeight();
        instance._notifyLayoutChange();
      }

      document.addEventListener('mousemove', onMouseMove);
      document.addEventListener('mouseup',   onMouseUp);
    });
  }

  // ─── Drag to resize ───────────────────────────────────────────────────────

  function wireResize(panelEl, panel, instance) {
    var handle = panelEl.querySelector('.canvas-panel-resize-handle');
    if (!handle) return;

    var resizing = false;
    var startMouseX, startMouseY, startWidth, startHeight;

    handle.addEventListener('mousedown', function (e) {
      e.preventDefault();
      e.stopPropagation();
      resizing = true;
      startMouseX = e.clientX;
      startMouseY = e.clientY;
      startWidth  = parseInt(panelEl.style.width,  10);
      startHeight = parseInt(panelEl.style.height, 10);
      panelEl.classList.add('canvas-panel--resizing');

      function onMouseMove(e) {
        if (!resizing) return;
        var newW = Math.max(100, startWidth  + (e.clientX - startMouseX));
        var newH = Math.max(80,  startHeight + (e.clientY - startMouseY));
        panelEl.style.width  = newW + 'px';
        panelEl.style.height = newH + 'px';
      }

      function onMouseUp() {
        if (!resizing) return;
        resizing = false;
        panelEl.classList.remove('canvas-panel--resizing');
        document.removeEventListener('mousemove', onMouseMove);
        document.removeEventListener('mouseup', onMouseUp);

        // Snap to grid
        var containerWidth = instance._containerEl.offsetWidth;
        var snapped = toGrid(
          { left:   parseInt(panelEl.style.left,   10),
            top:    parseInt(panelEl.style.top,    10),
            width:  parseInt(panelEl.style.width,  10),
            height: parseInt(panelEl.style.height, 10) },
          containerWidth
        );
        var clamped = clampPanel(
          Object.assign({}, panel, { w: snapped.w, h: snapped.h })
        );
        panel.w = clamped.w;
        panel.h = clamped.h;

        // Apply snapped size
        var px = toPixels(panel, containerWidth);
        panelEl.style.width  = px.width  + 'px';
        panelEl.style.height = px.height + 'px';

        // Update canvas height and notify
        instance._updateCanvasHeight();
        instance._notifyLayoutChange();
      }

      document.addEventListener('mousemove', onMouseMove);
      document.addEventListener('mouseup',   onMouseUp);
    });
  }

  // ─── Canvas instance ──────────────────────────────────────────────────────

  function CanvasInstance(containerEl, layout, callbacks) {
    this._containerEl = containerEl;
    this._callbacks   = callbacks || {};
    this._panels      = [];  // array of panel data objects (mutable)
    this._panelEls    = {};  // map of panelId -> DOM element
    this._mounted     = false;

    // Apply container styles
    containerEl.style.position = 'relative';
    containerEl.classList.add('canvas-grid-container');

    this._init(layout);
  }

  CanvasInstance.prototype._init = function (layout) {
    var self = this;
    if (!layout || !Array.isArray(layout.panels)) return;

    // Deep copy panels to avoid mutating the caller's layout object
    this._panels = layout.panels.map(function (p) {
      return Object.assign({}, p, { config: Object.assign({}, p.config || {}) });
    });

    this._render();
    this._mounted = true;
  };

  CanvasInstance.prototype._render = function () {
    var self = this;
    var containerWidth = this._containerEl.offsetWidth || 800;

    // Remove any existing panel elements
    Object.values(this._panelEls).forEach(function (el) {
      if (el.parentNode) el.parentNode.removeChild(el);
    });
    this._panelEls = {};

    // Build and insert panel elements
    this._panels.forEach(function (panel) {
      var el = buildPanelEl(panel, containerWidth, self._callbacks);
      wireDrag(el, panel, self);
      wireResize(el, panel, self);
      self._containerEl.appendChild(el);
      self._panelEls[panel.id] = el;

      // Call renderPanel if provided (no-op until Spec 9c)
      if (typeof self._callbacks.renderPanel === 'function') {
        var content = el.querySelector('.canvas-panel-content');
        self._callbacks.renderPanel(content, panel);
      }
    });

    this._updateCanvasHeight();
  };

  CanvasInstance.prototype._updateCanvasHeight = function () {
    this._containerEl.style.minHeight = canvasHeight(this._panels) + 'px';
  };

  CanvasInstance.prototype._notifyLayoutChange = function () {
    if (typeof this._callbacks.onLayoutChange === 'function') {
      this._callbacks.onLayoutChange(this.getLayout());
    }
  };

  CanvasInstance.prototype.update = function (layout) {
    if (!layout || !Array.isArray(layout.panels)) return;
    this._panels = layout.panels.map(function (p) {
      return Object.assign({}, p, { config: Object.assign({}, p.config || {}) });
    });
    this._render();
  };

  CanvasInstance.prototype.getLayout = function () {
    return {
      version: 1,
      panels: this._panels.map(function (p) {
        return Object.assign({}, p);
      }),
      grid: { cols: COLS, row_height_px: ROW_HEIGHT, gap_px: GAP },
    };
  };

  CanvasInstance.prototype.addPanel = function (panel) {
    var p = clampPanel(Object.assign({
      id:     'panel_' + Date.now(),
      type:   'macro_context',
      x: 0, y: 0, w: 4, h: 3,
      config: {}
    }, panel));
    this._panels.push(p);
    var containerWidth = this._containerEl.offsetWidth || 800;
    var el = buildPanelEl(p, containerWidth, this._callbacks);
    wireDrag(el, p, this);
    wireResize(el, p, this);
    this._containerEl.appendChild(el);
    this._panelEls[p.id] = el;
    if (typeof this._callbacks.renderPanel === 'function') {
      var content = el.querySelector('.canvas-panel-content');
      this._callbacks.renderPanel(content, p);
    }
    this._updateCanvasHeight();
    this._notifyLayoutChange();
    return p.id;
  };

  CanvasInstance.prototype.removePanel = function (panelId) {
    var el = this._panelEls[panelId];
    if (el && el.parentNode) el.parentNode.removeChild(el);
    delete this._panelEls[panelId];
    this._panels = this._panels.filter(function (p) { return p.id !== panelId; });
    this._updateCanvasHeight();
    this._notifyLayoutChange();
  };

  CanvasInstance.prototype.destroy = function () {
    var self = this;
    Object.values(this._panelEls).forEach(function (el) {
      if (el.parentNode) el.parentNode.removeChild(el);
    });
    this._panelEls = {};
    this._panels   = [];
    this._mounted  = false;
    this._containerEl.classList.remove('canvas-grid-container');
    this._containerEl.style.position = '';
    this._containerEl.style.minHeight = '';
  };

  // ─── Public API ───────────────────────────────────────────────────────────

  var CanvasEngine = {
    /**
     * Mount a canvas grid into containerEl with the given layout.
     * Returns a CanvasInstance.
     *
     * @param {HTMLElement} containerEl - the container to mount into
     * @param {object}      layout      - canvas_layout object from DB
     * @param {object}      callbacks   - { onLayoutChange, onPanelClose, renderPanel }
     * @returns {CanvasInstance}
     */
    mount: function (containerEl, layout, callbacks) {
      if (!containerEl) {
        throw new Error('CanvasEngine.mount: containerEl is required');
      }
      return new CanvasInstance(containerEl, layout || { version: 1, panels: [], grid: {} }, callbacks || {});
    },

    // Expose internals for testing only
    _toPixels:   toPixels,
    _toGrid:     toGrid,
    _clampPanel: clampPanel,
    _colWidth:   colWidth,
    _canvasHeight: canvasHeight,
    COLS:        COLS,
    ROW_HEIGHT:  ROW_HEIGHT,
    GAP:         GAP,
  };

  window.CanvasEngine = CanvasEngine;

})();
