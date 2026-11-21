/**
 * signals/dashboard/modules/panels/chart-panel.js
 * SIGNAL Chart Panel — Phase 3, Spec 12c
 *
 * Renders a price chart inside a canvas panel.
 * Uses renderChartIntoEmbed() from app.js.
 *
 * panel.config shape:
 * {
 *   instrument_y: string,  — primary instrument ID (required)
 *   instrument_x: string,  — comparison instrument ID (optional)
 *   chart_type: string,    — 'overlaid'|'forecast'|'impact'|'correlation'|'factors' (default: 'overlaid')
 *   period: number,        — days (default: 90)
 * }
 */

(function () {
  'use strict';

  function esc(str) {
    if (str == null) return '';
    return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }

  function getInstrumentName(id) {
    var universe = (window.STATE && window.STATE.universe) || [];
    var inst = universe.find(function (u) { return u.id === id; });
    return inst ? (inst.name || id) : id;
  }

  function renderSelector(contentEl, panel, onSelect) {
    var universe = (window.STATE && window.STATE.universe) || [];
    var options = universe
      .filter(function (u) { return u.id && u.name; })
      .map(function (u) {
        return '<option value="' + esc(u.id) + '">' + esc(u.name) + ' (' + esc(u.id) + ')</option>';
      }).join('');

    contentEl.innerHTML =
      '<div class="cp-selector">' +
        '<div class="cp-selector-label">Select instrument</div>' +
        '<select class="cp-selector-select">' +
          '<option value="">— choose —</option>' +
          options +
        '</select>' +
        '<div class="cp-selector-types">' +
          '<label><input type="radio" name="cp-type-' + esc(panel.id) + '" value="overlaid" checked> Overlaid</label>' +
          '<label><input type="radio" name="cp-type-' + esc(panel.id) + '" value="forecast"> Forecast</label>' +
          '<label><input type="radio" name="cp-type-' + esc(panel.id) + '" value="factors"> Factors</label>' +
        '</div>' +
      '</div>';

    var sel = contentEl.querySelector('.cp-selector-select');
    sel.addEventListener('change', function () {
      if (!sel.value) return;
      var chartType = contentEl.querySelector('input[name="cp-type-' + panel.id + '"]:checked');
      onSelect(sel.value, chartType ? chartType.value : 'overlaid');
    });
  }

  function renderChart(contentEl, panel) {
    var y = panel.config.instrument_y;
    var x = panel.config.instrument_x || '';
    var chartType = panel.config.chart_type || 'overlaid';
    var period = panel.config.period || 90;
    var yName = getInstrumentName(y);
    var xName = x ? getInstrumentName(x) : '';

    // Create a synthetic embed element with the dataset attributes
    // that renderChartIntoEmbed expects
    contentEl.innerHTML = '<div class="cp-embed-wrap"></div>';
    var wrap = contentEl.querySelector('.cp-embed-wrap');

    var embedEl = document.createElement('div');
    embedEl.className = 'thesis-chart-embed';
    embedEl.dataset.type = 'chart';
    embedEl.dataset.chartType = chartType;
    embedEl.dataset.x = x;
    embedEl.dataset.y = y;
    embedEl.dataset.period = String(period);
    embedEl.dataset.shockPct = '10';
    embedEl.dataset.instruments = x ? (x + ',' + y) : y;

    // Add chart canvas placeholder
    var canvas = document.createElement('div');
    canvas.className = 'chart-embed-canvas';
    embedEl.appendChild(canvas);

    wrap.appendChild(embedEl);

    // Add sub-header showing instrument name + controls
    var subheader = document.createElement('div');
    subheader.className = 'cp-subheader';
    subheader.innerHTML =
      '<span class="cp-subheader-title">' + esc(yName) +
        (xName ? ' vs ' + esc(xName) : '') + '</span>' +
      '<button type="button" class="cp-change-btn" title="Change instrument">⚙</button>';
    contentEl.insertBefore(subheader, wrap);

    subheader.querySelector('.cp-change-btn').addEventListener('click', function () {
      panel.config.instrument_y = '';
      render(contentEl, panel);
    });

    // Call the existing renderChartIntoEmbed
    if (typeof window.renderChartIntoEmbed === 'function') {
      var params = {
        type: 'chart',
        chartType: chartType,
        x: x,
        y: y,
        period: period,
        shockPct: 10,
        instruments: x ? (x + ',' + y) : y,
      };
      window.renderChartIntoEmbed(embedEl, params);
    } else {
      contentEl.innerHTML += '<div class="cp-error">Chart renderer not available</div>';
    }
  }

  function render(contentEl, panel) {
    if (!panel.config) panel.config = {};
    if (!panel.config.instrument_y) {
      renderSelector(contentEl, panel, function (instrumentId, chartType) {
        panel.config.instrument_y = instrumentId;
        panel.config.chart_type = chartType;
        // Notify canvas to persist
        var canvasCt = document.getElementById('thesis-canvas-container');
        if (canvasCt && canvasCt._canvasInstance && window.ThesisManager) {
          window.ThesisManager.setCanvasLayout(canvasCt._canvasInstance.getLayout());
        }
        render(contentEl, panel);
      });
    } else {
      renderChart(contentEl, panel);
    }
  }

  if (window.PanelRegistry) {
    window.PanelRegistry.register(
      'chart',
      { render: render },
      { label: 'Chart', defaultW: 6, defaultH: 4, icon: '📈' }
    );
  } else {
    console.warn('[ChartPanel] PanelRegistry not available');
  }

})();
