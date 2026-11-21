/**
 * signals/dashboard/modules/panels/factor-view-panel.js
 * SIGNAL Factor View Panel — Phase 3, Spec 12c
 *
 * Renders macro factor decomposition for a selected instrument.
 * Uses fetchFactorDecomposition() and renderFactorsEmbedHTML()
 * from app.js (both exposed on window).
 *
 * panel.config shape:
 * { instrument: string }  — instrument ID (required)
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
    // Only show instruments that can have factor decomposition
    // (equities, ETFs, and key macro series)
    var options = universe
      .filter(function (u) { return u.id && u.name; })
      .map(function (u) {
        return '<option value="' + esc(u.id) + '">' + esc(u.name) + ' (' + esc(u.id) + ')</option>';
      }).join('');

    contentEl.innerHTML =
      '<div class="cp-selector">' +
        '<div class="cp-selector-label">Select instrument for factor decomposition</div>' +
        '<select class="cp-selector-select">' +
          '<option value="">— choose —</option>' +
          options +
        '</select>' +
      '</div>';

    contentEl.querySelector('.cp-selector-select').addEventListener('change', function (e) {
      if (!e.target.value) return;
      onSelect(e.target.value);
    });
  }

  function renderFactors(contentEl, panel) {
    var instrumentId = panel.config.instrument;
    var name = getInstrumentName(instrumentId);

    contentEl.innerHTML =
      '<div class="fvp-header">' +
        '<span class="fvp-title">' + esc(name) + '</span>' +
        '<button type="button" class="cp-change-btn" title="Change instrument">⚙</button>' +
      '</div>' +
      '<div class="fvp-body"><div class="fvp-loading">Loading factor decomposition...</div></div>';

    contentEl.querySelector('.cp-change-btn').addEventListener('click', function () {
      panel.config.instrument = '';
      render(contentEl, panel);
    });

    var body = contentEl.querySelector('.fvp-body');

    if (typeof window.fetchFactorDecomposition !== 'function') {
      body.innerHTML = '<div class="cp-error">Factor decomposition not available</div>';
      return;
    }

    window.fetchFactorDecomposition(instrumentId).then(function (data) {
      if (data.error) {
        body.innerHTML = '<div class="cp-error">No decomposition data: ' + esc(data.error) + '</div>';
        return;
      }
      if (typeof window.renderFactorsEmbedHTML === 'function') {
        body.innerHTML = window.renderFactorsEmbedHTML(data);
      } else {
        // Fallback: render factor bars manually
        var factors = data.factors || [];
        var html = '<div class="fvp-factors">';
        factors.forEach(function (f) {
          var r2Pct = Math.round((f.r2 || 0) * 100);
          var sigClass = f.significant ? 'fvp-factor-sig' : 'fvp-factor-insig';
          html +=
            '<div class="fvp-factor-row ' + sigClass + '">' +
              '<span class="fvp-factor-name">' + esc(f.name || f.id || f.factor) + '</span>' +
              '<span class="fvp-factor-beta">β=' + Number(f.beta || 0).toFixed(3) + '</span>' +
              '<div class="fvp-factor-bar-wrap">' +
                '<div class="fvp-factor-bar" style="width:' + Math.min(100, r2Pct) + '%"></div>' +
              '</div>' +
              '<span class="fvp-factor-r2">' + r2Pct + '%</span>' +
            '</div>';
        });
        html += '</div>';
        if (data.model) {
          html += '<div class="fvp-stats">R²=' + Number(data.model.r_squared || 0).toFixed(3) +
            ' · n=' + (data.model.observations || '—') + '</div>';
        }
        body.innerHTML = html;
      }
    }).catch(function (err) {
      body.innerHTML = '<div class="cp-error">Error: ' + esc(err.message) + '</div>';
    });
  }

  function render(contentEl, panel) {
    if (!panel.config) panel.config = {};
    if (!panel.config.instrument) {
      renderSelector(contentEl, panel, function (instrumentId) {
        panel.config.instrument = instrumentId;
        var canvasCt = document.getElementById('thesis-canvas-container');
        if (canvasCt && canvasCt._canvasInstance && window.ThesisManager) {
          window.ThesisManager.setCanvasLayout(canvasCt._canvasInstance.getLayout());
        }
        render(contentEl, panel);
      });
    } else {
      renderFactors(contentEl, panel);
    }
  }

  if (window.PanelRegistry) {
    window.PanelRegistry.register(
      'factor_view',
      { render: render },
      { label: 'Factor view', defaultW: 5, defaultH: 5, icon: '⬡' }
    );
  } else {
    console.warn('[FactorViewPanel] PanelRegistry not available');
  }

})();
