(function () {
  'use strict';

  // ——— 1. CONFIG ———
  // Same-origin when served from the API (demo / production). Local split:
  // dashboard :3000 → API :8000. Override anytime with window.SIGNAL_API_BASE.
  const CONFIG = {
    API_BASE:
      typeof window.SIGNAL_API_BASE !== 'undefined'
        ? window.SIGNAL_API_BASE
        : window.location.port === '3000'
          ? 'http://localhost:8000'
          : '',
    POLL_INTERVAL_MS: 60000,
    DEMO:
      window.SIGNAL_DEMO === true ||
      window.SIGNAL_DEMO === 1 ||
      window.SIGNAL_DEMO === '1',
  };

  // ——— 2. STATE ———
  const STATE = {
    status: null,
    signals: [],
    universe: [],
    marketData: {},
    correlations: [],
    regime: null,
    anomalies: [],
    theses: [],
    briefing: null,
    marketSeriesId: null,
    marketDays: 30,
    assetFilter: 'ALL',
    topicFilter: '',
    thesesView: 'active',
    signalsSurfaceMode: 'notable',
    selectedTopic: null,
    topicDetail: null,
    regimeHistory: null,
    correlationsLagFilter: 'all',
    universeSort: 'signal',
    watchedConditions: (function () {
      try {
        var s = localStorage.getItem('signal_watched_conditions');
        return s ? JSON.parse(s) : [];
      } catch (e) { return []; }
    })(),
    latestPrices: {},
    sparklines7d: {},
    builderTopicData: null,
    research: { lastExport: null },
  };
  window.STATE = STATE;

  // ——— 3. API MODULE ———
  const API = {
    async getStatus() {
      try {
        const r = await fetch(CONFIG.API_BASE + '/api/status');
        if (!r.ok) throw new Error(r.statusText);
        return await r.json();
      } catch (e) {
        console.error('API getStatus', e);
        return null;
      }
    },
    async getSignalsLatest() {
      try {
        const r = await fetch(CONFIG.API_BASE + '/api/signals/latest');
        if (!r.ok) throw new Error(r.statusText);
        return await r.json();
      } catch (e) {
        console.error('API getSignalsLatest', e);
        return [];
      }
    },
    async getUniverse() {
      try {
        const r = await fetch(CONFIG.API_BASE + '/api/universe');
        if (!r.ok) throw new Error(r.statusText);
        return await r.json();
      } catch (e) {
        console.error('API getUniverse', e);
        return [];
      }
    },
    async getMarketData(seriesId, days) {
      try {
        const r = await fetch(CONFIG.API_BASE + '/api/market_data/' + encodeURIComponent(seriesId) + '?days=' + (days || 30));
        if (!r.ok) throw new Error(r.statusText);
        return await r.json();
      } catch (e) {
        console.error('API getMarketData', e);
        return [];
      }
    },
    async getCorrelations() {
      try {
        const r = await fetch(CONFIG.API_BASE + '/api/correlations');
        if (!r.ok) throw new Error(r.statusText);
        return await r.json();
      } catch (e) {
        console.error('API getCorrelations', e);
        return [];
      }
    },
    async getRegimeLatest() {
      try {
        const r = await fetch(CONFIG.API_BASE + '/api/regime/latest');
        if (!r.ok) throw new Error(r.statusText);
        return await r.json();
      } catch (e) {
        console.error('API getRegimeLatest', e);
        return null;
      }
    },
    async getAnomaliesRecent() {
      try {
        const r = await fetch(CONFIG.API_BASE + '/api/anomalies/recent');
        if (!r.ok) throw new Error(r.statusText);
        return await r.json();
      } catch (e) {
        console.error('API getAnomaliesRecent', e);
        return [];
      }
    },
    async runPipeline() {
      try {
        const r = await fetch(CONFIG.API_BASE + '/api/pipeline/run', { method: 'POST' });
        if (!r.ok) throw new Error(r.statusText);
        return await r.json();
      } catch (e) {
        console.error('API runPipeline', e);
        return null;
      }
    },
    async getTheses() {
      try {
        const r = await fetch(CONFIG.API_BASE + '/api/theses');
        if (!r.ok) throw new Error(r.statusText);
        return await r.json();
      } catch (e) {
        console.error('API getTheses', e);
        return [];
      }
    },
    async getBriefing() {
      try {
        const r = await fetch(CONFIG.API_BASE + '/api/briefing');
        if (!r.ok) throw new Error(r.statusText);
        return await r.json();
      } catch (e) {
        console.error('API getBriefing', e);
        return { highlights: [], signal_watch: [], market_snapshot: [] };
      }
    },
    async getSignalsTopic(topic) {
      try {
        const r = await fetch(CONFIG.API_BASE + '/api/signals/topic/' + encodeURIComponent(topic));
        if (!r.ok) throw new Error(r.statusText);
        return await r.json();
      } catch (e) {
        console.error('API getSignalsTopic', e);
        return null;
      }
    },
    async getRegimeHistory(days) {
      try {
        const r = await fetch(CONFIG.API_BASE + '/api/regime/history?days=' + (days || 90));
        if (!r.ok) throw new Error(r.statusText);
        return await r.json();
      } catch (e) {
        console.error('API getRegimeHistory', e);
        return {};
      }
    },
    async getMarketDataLatestAll() {
      try {
        const r = await fetch(CONFIG.API_BASE + '/api/market_data/latest/all');
        if (!r.ok) throw new Error(r.statusText);
        return await r.json();
      } catch (e) {
        console.error('API getMarketDataLatestAll', e);
        return {};
      }
    },
    async getMarketDataSparklines(days) {
      try {
        const r = await fetch(CONFIG.API_BASE + '/api/market_data/sparklines?days=' + (days || 7));
        if (!r.ok) throw new Error(r.statusText);
        return await r.json();
      } catch (e) {
        console.error('API getMarketDataSparklines', e);
        return {};
      }
    },
    async createThesis(body) {
      try {
        const r = await fetch(CONFIG.API_BASE + '/api/theses', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(body || {}),
        });
        if (!r.ok) throw new Error(r.statusText);
        return await r.json();
      } catch (e) {
        console.error('API createThesis', e);
        return null;
      }
    },
    async getResearchOverview(days) {
      try {
        const r = await fetch(CONFIG.API_BASE + '/api/research/overview?days=' + (days || 90));
        if (!r.ok) throw new Error(r.statusText);
        return await r.json();
      } catch (e) {
        console.error('API getResearchOverview', e);
        return { error: String(e.message) };
      }
    },
    async getResearchSeries(seriesIds, days) {
      try {
        const ids = Array.isArray(seriesIds) ? seriesIds.join(',') : String(seriesIds);
        const r = await fetch(CONFIG.API_BASE + '/api/research/series?series_ids=' + encodeURIComponent(ids) + '&days=' + (days || 90));
        if (!r.ok) throw new Error(r.statusText);
        return await r.json();
      } catch (e) {
        console.error('API getResearchSeries', e);
        return { series: {}, error: String(e.message) };
      }
    },
    async getCorrelationMatrix(seriesIds, days) {
      try {
        const r = await fetch(CONFIG.API_BASE + '/api/research/correlation_matrix?series_ids=' + encodeURIComponent(seriesIds.join(',')) + '&days=' + (days || 90));
        if (!r.ok) throw new Error(r.statusText);
        return await r.json();
      } catch (e) {
        console.error('API getCorrelationMatrix', e);
        return { error: String(e.message) };
      }
    },
    async getRollingCorrelation(seriesA, seriesB, window, days) {
      try {
        const r = await fetch(CONFIG.API_BASE + '/api/research/rolling_correlation?series_a=' + encodeURIComponent(seriesA) + '&series_b=' + encodeURIComponent(seriesB) + '&window=' + (window || 30) + '&days=' + (days || 180));
        if (!r.ok) throw new Error(r.statusText);
        return await r.json();
      } catch (e) {
        console.error('API getRollingCorrelation', e);
        return { error: String(e.message) };
      }
    },
    async getImpact(baseSeries, targetSeries, shockPct, days) {
      try {
        const targets = Array.isArray(targetSeries) ? targetSeries.join(',') : targetSeries;
        const r = await fetch(CONFIG.API_BASE + '/api/research/impact?base_series=' + encodeURIComponent(baseSeries) + '&target_series=' + encodeURIComponent(targets) + '&shock_pct=' + (shockPct ?? 10) + '&days=' + (days || 90));
        if (!r.ok) throw new Error(r.statusText);
        return await r.json();
      } catch (e) {
        console.error('API getImpact', e);
        return { error: String(e.message) };
      }
    },
    async getMomentum(seriesIds, days) {
      try {
        const r = await fetch(CONFIG.API_BASE + '/api/research/momentum?series_ids=' + encodeURIComponent(seriesIds.join(',')) + '&days=' + (days || 180));
        if (!r.ok) throw new Error(r.statusText);
        return await r.json();
      } catch (e) {
        console.error('API getMomentum', e);
        return { instruments: [] };
      }
    },
    async getMomentumCrossAsset(days) {
      try {
        const r = await fetch(CONFIG.API_BASE + '/api/research/momentum/cross_asset?days=' + (days || 180));
        if (!r.ok) throw new Error(r.statusText);
        return await r.json();
      } catch (e) {
        console.error('API getMomentumCrossAsset', e);
        return { instruments: [] };
      }
    },
    async getVolSurface(seriesIds, days) {
      try {
        const r = await fetch(CONFIG.API_BASE + '/api/research/volatility/surface?series_ids=' + encodeURIComponent(seriesIds.join(',')) + '&days=' + (days || 90));
        if (!r.ok) throw new Error(r.statusText);
        return await r.json();
      } catch (e) {
        console.error('API getVolSurface', e);
        return { instruments: [] };
      }
    },
    async getFactorDecomposition(targetSeries, days) {
      try {
        const r = await fetch(CONFIG.API_BASE + '/api/research/factor_decomposition?target_series=' + encodeURIComponent(targetSeries) + '&days=' + (days || 90));
        if (!r.ok) throw new Error(r.statusText);
        return await r.json();
      } catch (e) {
        console.error('API getFactorDecomposition', e);
        return { error: String(e.message) };
      }
    },
    async getFactorComparison(targetSeriesList, days) {
      try {
        const r = await fetch(CONFIG.API_BASE + '/api/research/factor_comparison?target_series=' + encodeURIComponent(targetSeriesList.join(',')) + '&days=' + (days || 90));
        if (!r.ok) throw new Error(r.statusText);
        return await r.json();
      } catch (e) {
        console.error('API getFactorComparison', e);
        return { error: String(e.message) };
      }
    },
    async getForecast(seriesId, daysForward, daysHistory, model) {
      try {
        const r = await fetch(CONFIG.API_BASE + '/api/research/forecast?series_id=' + encodeURIComponent(seriesId) + '&days_forward=' + (daysForward || 30) + '&days_history=' + (daysHistory || 90) + '&model=' + (model || 'both'));
        if (!r.ok) throw new Error(r.statusText);
        return await r.json();
      } catch (e) {
        console.error('API getForecast', e);
        return { error: String(e.message) };
      }
    },
    async getForecastDecompose(seriesId, days) {
      try {
        const r = await fetch(CONFIG.API_BASE + '/api/research/forecast/decompose?series_id=' + encodeURIComponent(seriesId) + '&days=' + (days || 180));
        if (!r.ok) throw new Error(r.statusText);
        return await r.json();
      } catch (e) {
        console.error('API getForecastDecompose', e);
        return { error: String(e.message) };
      }
    },
    async getVolatility(seriesId, days) {
      try {
        const r = await fetch(CONFIG.API_BASE + '/api/research/volatility?series_id=' + encodeURIComponent(seriesId) + '&days=' + (days || 90));
        if (!r.ok) throw new Error(r.statusText);
        return await r.json();
      } catch (e) {
        console.error('API getVolatility', e);
        return { error: String(e.message) };
      }
    },
    async getScenarios() {
      try {
        const r = await fetch(CONFIG.API_BASE + '/api/research/scenarios');
        if (!r.ok) throw new Error(r.statusText);
        return await r.json();
      } catch (e) {
        console.error('API getScenarios', e);
        return [];
      }
    },
    async postScenarioRun(body) {
      try {
        const r = await fetch(CONFIG.API_BASE + '/api/research/scenario/run', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(body || {}),
        });
        if (!r.ok) throw new Error(r.statusText);
        return await r.json();
      } catch (e) {
        console.error('API postScenarioRun', e);
        return { error: String(e.message) };
      }
    },
    async getYieldCurve(dateParam) {
      try {
        const q = 'date=' + encodeURIComponent(dateParam || 'latest') + '&compare_dates=1m,3m';
        const r = await fetch(CONFIG.API_BASE + '/api/research/yield_curve?' + q);
        if (!r.ok) throw new Error(r.statusText);
        return await r.json();
      } catch (e) {
        console.error('API getYieldCurve', e);
        return { error: String(e.message) };
      }
    },
    async getYieldCurveHistory(days) {
      try {
        const r = await fetch(CONFIG.API_BASE + '/api/research/yield_curve/history?days=' + (days || 90));
        if (!r.ok) throw new Error(r.statusText);
        return await r.json();
      } catch (e) {
        console.error('API getYieldCurveHistory', e);
        return { error: String(e.message) };
      }
    },
    async getRatesDecomposition(days) {
      try {
        const r = await fetch(CONFIG.API_BASE + '/api/research/rates/decomposition?days=' + (days || 90));
        if (!r.ok) throw new Error(r.statusText);
        return await r.json();
      } catch (e) {
        console.error('API getRatesDecomposition', e);
        return { error: String(e.message) };
      }
    },
  };

  // ——— 3b. RESEARCH MODULE ———
  const Research = {
    state: {
      primarySeries: null,
      compareSeries: [],
      days: 90,
      activeSubview: 'overview',
      lastExport: null,
      data: {},
      overviewSort: { col: 'zscore_90d', dir: 'desc' },
      momentumSortStrongestFirst: true,
      rollingPair: null,
      impactShockPct: 10,
      forecastHorizon: 30,
      forecastHistory: 90,
      forecastModel: 'both',
      scenarioPresets: null,
    },
    init() {
      const self = this;
      const universe = (STATE.universe || []).filter(function (i) { return i.id; });
      const byClass = {};
      universe.forEach(function (i) {
        const ac = (i.asset_class || 'Other').replace(/\s/g, '_');
        if (!byClass[ac]) byClass[ac] = [];
        byClass[ac].push(i);
      });
      const order = ['equity', 'fixed_income', 'commodity', 'fx', 'rates'];
      let primaryOpts = '<option value="">Select primary</option>';
      let compareOpts = '<option value="">+ Add series</option>';
      order.forEach(function (ac) {
        const items = byClass[ac] || byClass[ac.replace('_', ' ')] || [];
        if (items.length === 0) return;
        primaryOpts += '<optgroup label="' + escapeHtml(ac) + '">' + items.map(function (i) {
          return '<option value="' + escapeHtml(i.id) + '">' + escapeHtml(i.name || i.id) + '</option>';
        }).join('') + '</optgroup>';
        compareOpts += '<optgroup label="' + escapeHtml(ac) + '">' + items.map(function (i) {
          return '<option value="' + escapeHtml(i.id) + '">' + escapeHtml(i.name || i.id) + '</option>';
        }).join('') + '</optgroup>';
      });
      const primSel = document.getElementById('research-primary');
      const addSel = document.getElementById('research-compare-add');
      if (primSel) { primSel.innerHTML = primaryOpts; }
      if (addSel) { addSel.innerHTML = compareOpts; }
      if (primSel && self.state.primarySeries) primSel.value = self.state.primarySeries;
      self.renderComparePills();
      document.querySelectorAll('#screen-research .period-btn').forEach(function (btn) {
        btn.classList.toggle('active', parseInt(btn.getAttribute('data-days'), 10) === self.state.days);
      });
      primSel && primSel.addEventListener('change', function () {
        self.state.primarySeries = primSel.value || null;
      });
      addSel && addSel.addEventListener('change', function () {
        const v = addSel.value;
        if (!v || self.state.compareSeries.length >= 5) return;
        if (self.state.compareSeries.indexOf(v) < 0) {
          self.state.compareSeries.push(v);
          self.renderComparePills();
        }
        addSel.value = '';
      });
      document.querySelectorAll('#screen-research .period-btn').forEach(function (btn) {
        btn.addEventListener('click', function () {
          document.querySelectorAll('#screen-research .period-btn').forEach(function (b) { b.classList.remove('active'); });
          btn.classList.add('active');
          self.state.days = parseInt(btn.getAttribute('data-days'), 10);
        });
      });
      const analyseBtn = document.getElementById('research-analyse-btn');
      if (analyseBtn) {
        analyseBtn.addEventListener('click', function () {
          if (self.state.primarySeries && typeof ResearchWorkspace !== 'undefined' && ResearchWorkspace.addInstrument) ResearchWorkspace.addInstrument(self.state.primarySeries);
          self.fetchAndRender(self.state.activeSubview);
        });
      }
      const thesisBtn = document.getElementById('research-thesis-btn');
      if (thesisBtn) {
        thesisBtn.addEventListener('click', function () {
          sendToThesisBuilder(self.state.activeSubview, self.state.data, self.getSelections());
        });
      }
      document.querySelectorAll('#screen-research .subnav-btn').forEach(function (btn) {
        btn.addEventListener('click', function () {
          self.state.activeSubview = btn.getAttribute('data-subview') || 'overview';
        });
      });
    },
    renderComparePills() {
      const container = document.getElementById('research-compare-pills');
      if (!container) return;
      const self = this;
      container.innerHTML = this.state.compareSeries.map(function (id) {
        const name = (STATE.universe || []).find(function (i) { return i.id === id; });
        return '<span class="compare-pill" data-id="' + escapeHtml(id) + '">' + escapeHtml((name && (name.name || name.id)) || id) + ' <span class="remove-pill" aria-label="Remove">×</span></span>';
      }).join('');
      container.querySelectorAll('.remove-pill').forEach(function (el) {
        el.addEventListener('click', function () {
          const pill = el.closest('.compare-pill');
          if (pill) {
            const id = pill.getAttribute('data-id');
            self.state.compareSeries = self.state.compareSeries.filter(function (x) { return x !== id; });
            self.renderComparePills();
          }
        });
      });
    },
    getSelections() {
      const p = this.state.primarySeries;
      const c = this.state.compareSeries;
      return {
        primary: p,
        compare: c,
        allSeries: [p].concat(c).filter(Boolean),
        days: this.state.days
      };
    },
    showLoading(containerId) {
      const el = document.getElementById(containerId);
      if (el) el.innerHTML = '<div class="research-loading"><span class="loading-dot"></span> Computing...</div>';
    },
    showError(containerId, message) {
      const el = document.getElementById(containerId);
      if (el) el.innerHTML = '<div class="research-error">[!] ' + escapeHtml(message) + '</div>';
    },
    async fetchAndRender(subview) {
      const self = this;
      const days = this.state.days;
      const sel = this.getSelections();
      const containerId = 'rsv-' + subview;
      this.showLoading(containerId);
      try {
        if (subview === 'overview') {
          const data = await API.getResearchOverview(days);
          if (data && data.error) throw new Error(data.error);
          self.state.data.overview = data;
          self.state.lastExport = data;
          STATE.research.lastExport = data;
          self.renderOverview(data, containerId);
        } else if (subview === 'momentum') {
          const data = await API.getMomentumCrossAsset(180);
          if (data && data.error) throw new Error(data.error);
          self.state.data.momentumCross = data;
          let deep = null;
          let priceHistory = null;
          if (self.state.primarySeries) {
            deep = await API.getMomentum([self.state.primarySeries], 180);
            if (deep && !deep.error) {
              self.state.data.momentumDeep = deep;
              priceHistory = await API.getMarketData(self.state.primarySeries, 180);
              self.state.data.momentumPriceHistory = priceHistory;
            }
          }
          self.renderMomentum(data, deep, priceHistory || self.state.data.momentumPriceHistory, containerId);
        } else if (subview === 'correlation') {
          const allIds = sel.allSeries;
          if (allIds.length < 2) {
            self.showError(containerId, 'Add comparison series above to compute correlations');
            return;
          }
          const [corrData, impactData] = await Promise.all([
            API.getCorrelationMatrix(allIds, days),
            API.getImpact(sel.primary, sel.compare, 10, days)
          ]);
          if (corrData && corrData.error) throw new Error(corrData.error);
          self.state.data.correlation = corrData;
          self.state.data.impact = impactData;
          let rollingData = null;
          if (sel.primary && sel.compare.length) {
            rollingData = await API.getRollingCorrelation(sel.primary, sel.compare[0], 30, days);
            self.state.rollingPair = { a: sel.primary, b: sel.compare[0] };
          }
          self.renderCorrelation(corrData, impactData, rollingData, containerId);
        } else if (subview === 'factors') {
          if (!sel.primary) {
            self.showError(containerId, 'Select a primary instrument');
            return;
          }
          const [decompData, compData] = await Promise.all([
            API.getFactorDecomposition(sel.primary, days),
            sel.allSeries.length > 1 ? API.getFactorComparison(sel.allSeries, days) : Promise.resolve(null)
          ]);
          if (decompData && decompData.error) throw new Error(decompData.error);
          self.state.data.factorDecomp = decompData;
          self.state.data.factorComparison = compData && !compData.error ? compData : null;
          const rollPromises = [30, 45, 60, 75, 90].map(function (d) { return API.getFactorDecomposition(sel.primary, d); });
          const rollResults = await Promise.all(rollPromises);
          self.state.data.factorRolling = rollResults.filter(function (r) { return r && !r.error && r.factors; });
          self.renderFactors(decompData, compData, rollResults, containerId);
        } else if (subview === 'forecast') {
          if (!sel.primary) {
            self.showError(containerId, 'Select a primary instrument');
            return;
          }
          const data = await API.getForecast(sel.primary, self.state.forecastHorizon, self.state.forecastHistory, self.state.forecastModel);
          if (data && data.error) throw new Error(data.error);
          self.state.data.forecast = data;
          self.renderForecast(data, containerId);
        } else if (subview === 'volatility') {
          if (!sel.primary) {
            self.showError(containerId, 'Select a primary instrument');
            return;
          }
          const data = await API.getVolatility(sel.primary, 90);
          if (data && data.error) throw new Error(data.error);
          self.state.data.volatility = data;
          self.renderVolatility(data, containerId);
        } else if (subview === 'scenario') {
          let presets = self.state.scenarioPresets;
          if (!presets) {
            const data = await API.getScenarios();
            presets = (data && (data.presets || (Array.isArray(data) ? data : []))) || [];
            self.state.scenarioPresets = presets;
          }
          self.renderScenario(presets, self.state.data.scenarioResult, containerId);
        } else if (subview === 'rates') {
          const [yc, ycHist, decomp] = await Promise.all([
            API.getYieldCurve('latest'),
            API.getYieldCurveHistory(90),
            API.getRatesDecomposition(90)
          ]);
          if (yc && yc.error) throw new Error(yc.error);
          self.state.data.yieldCurve = yc;
          self.state.data.yieldCurveHistory = ycHist;
          self.state.data.ratesDecomp = decomp;
          self.renderRates(yc, ycHist, decomp, containerId);
        } else {
          document.getElementById(containerId).innerHTML = '<p class="text-muted">Not implemented yet.</p>';
        }
      } catch (e) {
        self.showError(containerId, e.message || String(e));
      }
      if (typeof ResearchWorkspace !== 'undefined' && ResearchWorkspace.attachEvidenceButtons) ResearchWorkspace.attachEvidenceButtons(subview);
    },
    onShow() {
      if (!this._inited) {
        this._inited = true;
        this.init();
      }
      if (typeof ResearchWorkspace !== 'undefined' && ResearchWorkspace.init) ResearchWorkspace.init();
      if (this.state.activeSubview === 'overview' && !this.state.data.overview) {
        this.fetchAndRender('overview');
      }
    },
    renderOverview(data, containerId) {
      const instruments = (data && data.instruments) || [];
      const summary = (data && data.cross_asset_summary) || {};
      const riskOn = summary.risk_on_count != null ? summary.risk_on_count : (summary.risk_on != null ? summary.risk_on : 0);
      const riskOff = summary.risk_off_count != null ? summary.risk_off_count : (summary.risk_off != null ? summary.risk_off : 0);
      const neutral = summary.neutral_count != null ? summary.neutral_count : (summary.neutral != null ? summary.neutral : 0);
      const total = riskOn + riskOff + neutral || 1;
      const dominant = summary.dominant_theme || '—';
      let sorted = instruments.slice();
      const sortCol = this.state.overviewSort.col;
      const dir = this.state.overviewSort.dir === 'desc' ? -1 : 1;
      sorted.sort(function (a, b) {
        const va = a[sortCol] != null ? Math.abs(Number(a[sortCol])) : 0;
        const vb = b[sortCol] != null ? Math.abs(Number(b[sortCol])) : 0;
        return dir * (vb - va);
      });
      const self = this;
      const fmtPct = function (v) {
        if (v == null || Number.isNaN(Number(v))) return '—';
        const n = Number(v);
        return (n >= 0 ? '+' : '') + n.toFixed(2) + '%';
      };
      const signalClass = function (s) {
        const u = (s || '').toUpperCase();
        if (u === 'BULLISH') return 'signal-badge-BULLISH';
        if (u === 'BEARISH') return 'signal-badge-BEARISH';
        return 'signal-badge-NEUTRAL';
      };
      const zscoreClass = function (z) {
        const n = Number(z);
        if (Number.isNaN(n)) return '';
        const a = Math.abs(n);
        if (a > 2) return ' research-z-extreme';
        if (a > 1.5) return ' research-z-notable';
        return '';
      };
      const sortDir = this.state.overviewSort.dir;
      const arrow = function (col) {
        if (col !== sortCol) return '';
        return sortDir === 'desc' ? ' ▼' : ' ▲';
      };
      let tableHtml = '<table class="research-matrix-table"><thead><tr><th data-col="instrument">Instrument</th><th>Current</th><th data-col="chg_1d_pct">1D%' + arrow('chg_1d_pct') + '</th><th data-col="chg_5d_pct">5D%' + arrow('chg_5d_pct') + '</th><th data-col="chg_20d_pct">20D%' + arrow('chg_20d_pct') + '</th><th>Vol 21D</th><th data-col="zscore_90d">Z-score' + arrow('zscore_90d') + '</th><th>Momentum</th><th>Signal</th></tr></thead><tbody>';
      sorted.forEach(function (row) {
        const id = row.instrument_id || row.id || row.series_id || '—';
        const name = row.name || id;
        const cur = (row.current != null ? row.current : row.current_value) != null ? Number(row.current_value != null ? row.current_value : row.current).toFixed(2) : '—';
        const chg1 = row.chg_1d_pct != null ? Number(row.chg_1d_pct) : null;
        const chg5 = row.chg_5d_pct != null ? Number(row.chg_5d_pct) : null;
        const chg20 = row.chg_20d_pct != null ? Number(row.chg_20d_pct) : null;
        const vol = row.vol_21d_ann != null ? Number(row.vol_21d_ann).toFixed(2) : '—';
        const z = row.zscore_90d != null ? Number(row.zscore_90d) : null;
        const zStr = z != null ? (z >= 0 ? '+' : '') + z.toFixed(2) : '—';
        const mom = row.momentum_score != null ? Number(row.momentum_score) : 0;
        const momW = Math.min(60, Math.abs(mom) * 60);
        const momColor = mom >= 0 ? '#16a34a' : '#dc2626';
        const momVal = row.momentum_score != null ? Number(row.momentum_score) : 0;
        const sig = row.signal || (momVal > 0.1 ? 'BULLISH' : momVal < -0.1 ? 'BEARISH' : 'NEUTRAL');
        tableHtml += '<tr class="research-row-clickable" data-instrument="' + escapeHtml(id) + '"><td>' + escapeHtml(name) + '</td><td>' + cur + '</td>';
        tableHtml += '<td class="' + (chg1 != null && chg1 >= 0 ? 'positive' : 'negative') + '">' + fmtPct(chg1) + '</td><td class="' + (chg5 != null && chg5 >= 0 ? 'positive' : 'negative') + '">' + fmtPct(chg5) + '</td><td class="' + (chg20 != null && chg20 >= 0 ? 'positive' : 'negative') + '">' + fmtPct(chg20) + '</td>';
        tableHtml += '<td>' + vol + '</td><td class="' + zscoreClass(z) + '">' + zStr + '</td>';
        tableHtml += '<td><span style="display:inline-block;width:' + momW + 'px;height:6px;background:' + momColor + ';vertical-align:middle"></span> ' + (mom != null ? mom.toFixed(2) : '—') + '</td><td><span class="' + signalClass(sig) + '">' + escapeHtml(sig) + '</span></td></tr>';
      });
      tableHtml += '</tbody></table>';
      const summaryStrip = 'Risk-on: ' + riskOn + ' | Risk-off: ' + riskOff + ' | Neutral: ' + neutral + ' | Dominant: ' + escapeHtml(dominant);
      const avgVol = instruments.length ? instruments.reduce(function (s, i) { return s + (Number(i.vol_21d_ann) || 0); }, 0) / instruments.length : 0;
      const narrative = this.buildOverviewNarrative(data, sorted, avgVol);
      const scatterId = 'research-scatter-' + (containerId || 'overview');
      const volSurfId = 'research-vol-surf-' + (containerId || 'overview');
      let html = '<section class="panel"><h3 class="panel-header">PERFORMANCE MATRIX</h3><div class="panel-body">' + tableHtml + '<div class="cross-asset-summary">' + summaryStrip + '</div></div></section>';
      html += '<div class="research-panel-row"><div class="panel" style="width:380px"><h3 class="panel-header">Risk/Return</h3><div class="panel-body" style="height:280px"><div id="' + scatterId + '"></div></div></div>';
      html += '<div class="panel" style="flex:1;min-width:280px"><h3 class="panel-header">Vol surface</h3><div class="panel-body" style="height:200px"><div id="' + volSurfId + '"></div></div></div>';
      html += '<div class="panel" style="min-width:260px"><h3 class="panel-header">Narrative</h3><div class="panel-body"><div class="research-narrative">' + escapeHtml(narrative) + '</div></div></div></div>';
      const el = document.getElementById(containerId);
      if (el) {
        el.innerHTML = html;
        Research.charts.renderScatter(sorted, scatterId, avgVol);
        Research.charts.renderVolSurface(sorted, volSurfId);
        el.querySelectorAll('.research-row-clickable').forEach(function (tr) {
          tr.addEventListener('click', function () {
            const id = tr.getAttribute('data-instrument');
            if (id) {
              self.state.primarySeries = id;
              const primSel = document.getElementById('research-primary');
              if (primSel) primSel.value = id;
              document.querySelectorAll('#screen-research .subnav-btn').forEach(function (b) {
                b.classList.toggle('active', b.getAttribute('data-subview') === 'correlation');
              });
              document.querySelectorAll('#screen-research .research-subview').forEach(function (s) {
                s.classList.toggle('active', s.getAttribute('data-subview') === 'correlation');
              });
              self.state.activeSubview = 'correlation';
              self.fetchAndRender('correlation');
            }
          });
        });
        const thead = el.querySelector('.research-matrix-table thead');
        if (thead) {
          thead.querySelectorAll('th[data-col]').forEach(function (th) {
            th.addEventListener('click', function () {
              const col = th.getAttribute('data-col');
              if (!col) return;
              self.state.overviewSort.dir = self.state.overviewSort.col === col && self.state.overviewSort.dir === 'desc' ? 'asc' : 'desc';
              self.state.overviewSort.col = col;
              self.renderOverview(self.state.data.overview, containerId);
            });
          });
        }
      }
    },
    buildOverviewNarrative(data, sorted, avgVol) {
      const instruments = (data && data.instruments) || [];
      const summary = (data && data.cross_asset_summary) || {};
      const total = instruments.length;
      const theme = summary.dominant_theme || 'mixed';
      const riskOn = summary.risk_on != null ? summary.risk_on : 0;
      const top = sorted[0];
      const topName = top ? (top.name || top.instrument_id || top.id) : '—';
      const topZ = top && top.zscore_90d != null ? Number(top.zscore_90d).toFixed(2) : '—';
      const extreme = top && Math.abs(Number(top.zscore_90d)) > 2 ? 'extreme' : 'notable';
      const momSorted = instruments.slice().sort(function (a, b) {
        return (Number(b.momentum_score) || 0) - (Number(a.momentum_score) || 0);
      });
      const highMom = momSorted[0];
      const lowMom = momSorted[momSorted.length - 1];
      const highName = highMom ? (highMom.name || highMom.instrument_id) : '—';
      const lowName = lowMom ? (lowMom.name || lowMom.instrument_id) : '—';
      const volRegimes = instruments.filter(function (i) { return (i.vol_regime || '').toUpperCase() === 'ELEVATED'; }).length;
      const volSummary = volRegimes > total / 2 ? 'Volatility is elevated across many instruments.' : (volRegimes > 0 ? 'Some instruments show elevated volatility.' : 'Volatility is broadly normal or suppressed.');
      return 'Markets are showing a ' + theme + ' bias (' + riskOn + ' of ' + total + ' instruments in positive momentum). ' + topName + ' is the largest outlier (' + topZ + 'σ — statistically ' + extreme + '). ' + highName + ' leads momentum while ' + lowName + ' is the weakest. ' + volSummary;
    },
    renderMomentum(data, deepData, priceHistory, containerId) {
      const instruments = ((data && data.instruments) || []).slice();
      const strongestFirst = this.state.momentumSortStrongestFirst;
      instruments.sort(function (a, b) {
        const sa = Number(a.momentum_score) || 0;
        const sb = Number(b.momentum_score) || 0;
        return strongestFirst ? (sb - sa) : (sa - sb);
      });
      const fmtPct = function (v) {
        if (v == null || Number.isNaN(Number(v))) return '—';
        const n = Number(v);
        return (n >= 0 ? '+' : '') + n.toFixed(2) + '%';
      };
      const trendClass = function (t) {
        const u = (t || '').toUpperCase().replace(/\s/g, '_');
        return 'trend-badge-' + u;
      };
      const signalClass = function (s) {
        const u = (s || '').toUpperCase();
        if (u === 'BULLISH') return 'signal-badge-BULLISH';
        if (u === 'BEARISH') return 'signal-badge-BEARISH';
        return 'signal-badge-NEUTRAL';
      };
      let tableHtml = '<div class="research-momentum-toggle"><button type="button" class="' + (strongestFirst ? 'active' : '') + '" data-dir="strongest">↓ Strongest first</button><button type="button" class="' + (!strongestFirst ? 'active' : '') + '" data-dir="weakest">↑ Weakest first</button></div>';
      tableHtml += '<table class="research-matrix-table"><thead><tr><th>Instrument</th><th>1M</th><th>3M</th><th>6M</th><th>Score</th><th>Trend</th><th>RSI</th><th>Signal</th></tr></thead><tbody>';
      const self = this;
      instruments.forEach(function (row) {
        const id = row.instrument_id || row.series_id || row.id || '—';
        const name = row.name || id;
        const m1 = row.chg_1m_pct != null ? row.chg_1m_pct : (row.momentum_1m != null ? Number(row.momentum_1m) * 100 : null);
        const m3 = row.chg_3m_pct != null ? row.chg_3m_pct : (row.momentum_3m != null ? Number(row.momentum_3m) * 100 : null);
        const m6 = row.chg_6m_pct != null ? row.chg_6m_pct : (row.momentum_6m != null ? Number(row.momentum_6m) * 100 : null);
        const mom = row.momentum_score != null ? Number(row.momentum_score) : 0;
        const momW = Math.min(60, Math.abs(mom) * 60);
        const momColor = mom >= 0 ? '#16a34a' : '#dc2626';
        const rsi = row.rsi != null ? Number(row.rsi) : (row.rsi_14 != null ? Number(row.rsi_14) : null);
        let rsiCls = '';
        if (rsi != null) { if (rsi > 70) rsiCls = 'negative'; else if (rsi < 30) rsiCls = 'positive'; else rsiCls = ''; }
        tableHtml += '<tr><td>' + escapeHtml(name) + '</td><td class="' + (m1 != null && m1 >= 0 ? 'positive' : 'negative') + '">' + fmtPct(m1) + '</td><td class="' + (m3 != null && m3 >= 0 ? 'positive' : 'negative') + '">' + fmtPct(m3) + '</td><td class="' + (m6 != null && m6 >= 0 ? 'positive' : 'negative') + '">' + fmtPct(m6) + '</td>';
        tableHtml += '<td><span style="display:inline-block;width:' + momW + 'px;height:6px;background:' + momColor + ';vertical-align:middle"></span> ' + (mom != null ? mom.toFixed(2) : '—') + '</td><td><span class="' + trendClass(row.trend || 'NEUTRAL') + '">' + escapeHtml((row.trend || 'NEUTRAL').replace(/_/g, ' ')) + '</span></td><td class="' + rsiCls + '">' + (rsi != null ? rsi.toFixed(0) : '—') + '</td><td><span class="' + signalClass(row.signal || 'NEUTRAL') + '">' + escapeHtml(row.signal || 'NEUTRAL') + '</span></td></tr>';
      });
      tableHtml += '</tbody></table>';
      const posCount = instruments.filter(function (i) { return (Number(i.momentum_score) || 0) > 0; }).length;
      const pct = instruments.length ? Math.round(posCount / instruments.length * 100) : 0;
      let breadth = 'mixed';
      if (pct > 60) breadth = 'trending';
      else if (pct < 40) breadth = 'mean-reverting';
      const breadthStrip = posCount + ' of ' + instruments.length + ' in positive momentum (' + pct + '%). Market breadth: ' + breadth + '.';
      let html = '<section class="panel"><h3 class="panel-header">MOMENTUM HEATMAP — ALL INSTRUMENTS</h3><div class="panel-body">' + tableHtml + '<div class="cross-asset-summary">' + breadthStrip + '</div></div></section>';
      if (this.state.primarySeries && deepData && deepData.instruments && deepData.instruments.length) {
        const inst = deepData.instruments[0];
        const name = inst.name || inst.series_id || this.state.primarySeries;
        html += '<section class="panel"><h3 class="panel-header">' + escapeHtml(name) + ' — Technical Analysis</h3><div class="panel-body"><div id="research-technicals-chart"></div><div class="research-indicator-row" id="research-indicator-row"></div><p class="research-signal-summary" id="research-signal-summary"></p></div></section>';
      }
      const el = document.getElementById(containerId);
      if (el) {
        el.innerHTML = html;
        el.querySelectorAll('.research-momentum-toggle button').forEach(function (btn) {
          btn.addEventListener('click', function () {
            self.state.momentumSortStrongestFirst = btn.getAttribute('data-dir') === 'strongest';
            document.querySelectorAll('.research-momentum-toggle button').forEach(function (b) { b.classList.remove('active'); });
            btn.classList.add('active');
            self.renderMomentum(self.state.data.momentumCross, self.state.data.momentumDeep, self.state.data.momentumPriceHistory, containerId);
          });
        });
        if (this.state.primarySeries && deepData && deepData.instruments && deepData.instruments.length) {
          const inst = deepData.instruments[0];
          if (priceHistory && priceHistory.length) {
            const chrono = priceHistory.slice().reverse();
            inst.prices = chrono.map(function (r) { return { date: r.date, value: r.value }; });
            const vals = chrono.map(function (r) { return parseFloat(r.value); });
            const validVals = vals.filter(function (v) { return !Number.isNaN(v); });
            if (validVals.length >= 20) {
              const sma20 = [];
              for (let i = 0; i < vals.length; i++) {
                if (i < 19) sma20.push(null);
                else sma20.push(vals.slice(i - 19, i + 1).reduce(function (a, b) { return a + (Number.isNaN(b) ? 0 : b); }, 0) / 20);
              }
              inst.sma20 = sma20;
            }
            if (validVals.length >= 50) {
              const sma50 = [];
              for (let i = 0; i < vals.length; i++) {
                if (i < 49) sma50.push(null);
                else sma50.push(vals.slice(i - 49, i + 1).reduce(function (a, b) { return a + (Number.isNaN(b) ? 0 : b); }, 0) / 50);
              }
              inst.sma50 = sma50;
            }
          }
          Research.charts.renderTechnicalsChart(inst, 'research-technicals-chart');
          const ind = deepData.instruments[0];
          const rsi = ind.rsi_14 != null ? Number(ind.rsi_14) : ind.rsi;
          const macd = ind.macd;
          const atr = ind.atr_14;
          const pctB = ind.pct_b != null ? Number(ind.pct_b) : (ind.bollinger && ind.bollinger.pct_b != null ? Number(ind.bollinger.pct_b) : null);
          let indHtml = '<div class="research-indicator-panel"><label>RSI(14)</label><span class="' + (rsi > 70 ? 'negative' : rsi < 30 ? 'positive' : '') + '">' + (rsi != null ? rsi.toFixed(0) : '—') + '</span><div class="research-indicator-bar" style="width:100px"><div class="research-indicator-bar-fill" style="width:' + Math.min(100, Math.max(0, rsi || 0)) + '%;background:' + (rsi > 70 ? '#dc2626' : rsi < 30 ? '#16a34a' : '#0d9488') + '"></div></div><span class="text-muted">' + (rsi > 70 ? 'Overbought' : rsi < 30 ? 'Oversold' : '') + '</span></div>';
          indHtml += '<div class="research-indicator-panel"><label>MACD</label><span>' + (macd && macd.value != null ? Number(macd.value).toFixed(4) : '—') + '</span> Histogram: ' + (macd && macd.histogram != null ? Number(macd.histogram).toFixed(4) : '—') + '<br><span class="text-muted">' + escapeHtml((macd && (macd.crossover || macd.last_crossover)) || 'No recent crossover') + '</span></div>';
          indHtml += '<div class="research-indicator-panel"><label>ATR(14)</label><span>' + (atr != null ? Number(atr).toFixed(4) : '—') + '</span><br><span class="text-muted">Daily range proxy</span></div>';
          indHtml += '<div class="research-indicator-panel"><label>Bollinger %B</label><span>' + (pctB != null ? pctB.toFixed(2) : '—') + '</span><div class="research-indicator-bar" style="width:80px"><div class="research-indicator-bar-fill" style="width:' + Math.min(100, Math.max(0, (pctB != null ? pctB : 0.5) * 100)) + '%;background:#0d9488"></div></div><span class="text-muted">' + (pctB != null && pctB > 0.8 ? 'Near upper band' : pctB != null && pctB < 0.2 ? 'Near lower band' : '') + '</span></div>';
          const rowEl = document.getElementById('research-indicator-row');
          if (rowEl) rowEl.innerHTML = indHtml;
          const sumEl = document.getElementById('research-signal-summary');
          if (sumEl && ind.signal_text) sumEl.textContent = ind.signal_text;
        }
      }
    },
    renderCorrelation(corrData, impactData, rollingData, containerId) {
      const self = this;
      const sel = this.getSelections();
      const primaryName = (STATE.universe || []).find(function (i) { return i.id === sel.primary; });
      const primaryLabel = primaryName ? (primaryName.name || primaryName.id) : sel.primary || 'Primary';
      let html = '<div class="research-correlation-layout"><div class="research-correlation-left"><section class="panel"><h3 class="panel-header">Correlation matrix</h3><div class="panel-body"><div id="research-corr-matrix"></div><div id="research-rolling-corr" style="margin-top:16px;height:160px"></div></div></section></div><div class="research-correlation-right"><section class="panel"><h3 class="panel-header">IMPACT CALCULATOR</h3><div class="panel-body"><p>If ' + escapeHtml(primaryLabel) + ' moves <input type="number" id="research-shock-input" class="research-impact-input" value="10" step="0.5" min="-50" max="50"> % <button type="button" id="research-impact-calc-btn">Calculate Impact</button></p><div id="research-impact-table-wrap"></div><p class="research-impact-footnote" id="research-impact-footnote"></p></div></section></div></div>';
      const el = document.getElementById(containerId);
      if (!el) return;
      el.innerHTML = html;
      if (corrData && corrData.series && corrData.matrix) {
        Research.charts.renderCorrelationMatrix(corrData, 'research-corr-matrix', self);
      }
      if (rollingData && !rollingData.error) {
        Research.charts.renderRollingCorr(rollingData, 'research-rolling-corr');
      }
      if (impactData && !impactData.error && impactData.impacts) {
        Research.charts.renderImpactTable(impactData, 'research-impact-table-wrap');
        const fn = document.getElementById('research-impact-footnote');
        if (fn) fn.textContent = 'OLS with HC3 robust errors | ' + (impactData.n_observations || '') + ' observations | ' + (impactData.date_range || '');
      }
      document.getElementById('research-impact-calc-btn').addEventListener('click', function () {
        const shock = parseFloat(document.getElementById('research-shock-input').value) || 10;
        self.state.impactShockPct = shock;
        API.getImpact(sel.primary, sel.compare, shock, self.state.days).then(function (data) {
          if (data && !data.error) {
            Research.charts.renderImpactTable(data, 'research-impact-table-wrap');
            const fn = document.getElementById('research-impact-footnote');
            if (fn) fn.textContent = 'OLS with HC3 robust errors | ' + (data.n_observations || '') + ' observations | ' + (data.date_range || '');
          }
        });
      });
    },
    renderFactors(decompData, compData, rollResults, containerId) {
      const FACTOR_LABELS = { f_rates: 'US Rates (10Y yield chg)', f_dollar: 'USD Strength (DXY)', f_risk: 'Risk Sentiment (VIX inv.)', f_growth: 'Growth Pulse (Copper)', f_credit: 'Credit Stress (HY OAS)', f_inflation: 'Inflation (Breakeven)' };
      const primaryName = (STATE.universe || []).find(function (i) { return i.id === Research.state.primarySeries; });
      const instrumentName = primaryName ? (primaryName.name || primaryName.id) : Research.state.primarySeries || '—';
      const factors = (decompData && decompData.factors) || [];
      const model = decompData && decompData.model ? decompData.model : {};
      const maxAbsBeta = Math.max(0.01, Math.max.apply(null, factors.map(function (f) { return Math.abs(Number(f.beta) || 0); })));
      let rows = '';
      factors.forEach(function (f) {
        const beta = Number(f.beta) || 0;
        const sig = f.significant !== false && (f.p_value == null || f.p_value < 0.05);
        const stars = f.p_value != null ? (f.p_value < 0.01 ? '**' : f.p_value < 0.05 ? '*' : 'ns') : 'ns';
        const contrib = sig && f.contribution_pct != null ? f.contribution_pct.toFixed(1) + '% var.' : '—';
        const barW = (Math.abs(beta) / maxAbsBeta) * 100;
        const barStyle = beta >= 0
          ? 'left:100px;width:' + barW + 'px;background:' + (sig ? '#16a34a' : '#94a3b8') + ';opacity:' + (sig ? 1 : 0.35)
          : 'left:' + (100 - barW) + 'px;width:' + barW + 'px;background:' + (sig ? '#dc2626' : '#94a3b8') + ';opacity:' + (sig ? 1 : 0.35);
        const betaCls = sig ? (beta >= 0 ? 'positive' : 'negative') : '';
        rows += '<div class="factor-row"><span class="factor-label">' + escapeHtml(FACTOR_LABELS[f.factor] || f.name || f.factor) + '</span><div class="factor-bar-wrap"><div class="factor-bar-center"></div><div class="factor-bar" style="' + barStyle + '"></div></div><span class="factor-beta ' + betaCls + '">' + (beta != null ? beta.toFixed(3) : '—') + '</span><span class="factor-stars">' + stars + '</span><span class="factor-contrib">' + contrib + '</span></div>';
      });
      const statsStr = 'R² = ' + (model.r_squared != null ? Number(model.r_squared).toFixed(3) : '—') + ' | Adj. R² = ' + (model.adj_r_squared != null ? Number(model.adj_r_squared).toFixed(3) : '—') + ' | F = ' + (model.f_statistic != null ? Number(model.f_statistic).toFixed(1) : '—') + ' (p=' + (model.f_pvalue != null ? Number(model.f_pvalue).toFixed(4) : '—') + ') | N = ' + (model.observations != null ? model.observations : '—') + ' | AIC = ' + (model.aic != null ? Number(model.aic).toFixed(1) : '—');
      let html = '<section class="panel"><h3 class="panel-header">MACRO FACTOR EXPOSURE — ' + escapeHtml(instrumentName) + '</h3><div class="panel-body">' + rows + '<p class="factor-model-stats">' + statsStr + '</p>' + (decompData && decompData.interpretation ? '<div class="research-factor-interp">' + escapeHtml(decompData.interpretation) + '</div>' : '') + '</div></section>';
      if (compData && compData.targets && Object.keys(compData.targets).length > 1) {
        const factorKeys = compData.factors || factors.map(function (f) { return f.factor; });
        let compTable = '<table class="research-factor-comp-table"><thead><tr><th></th>';
        Object.keys(compData.targets).forEach(function (tid) {
          const n = (STATE.universe || []).find(function (i) { return i.id === tid; });
          compTable += '<th>' + escapeHtml((n && (n.name || n.id)) || tid) + '</th>';
        });
        compTable += '</tr></thead><tbody>';
        factorKeys.forEach(function (fkey) {
          compTable += '<tr><th class="factor-comp-label">' + escapeHtml(FACTOR_LABELS[fkey] || fkey) + '</th>';
          Object.keys(compData.targets).forEach(function (tid) {
            const beta = compData.targets[tid][fkey];
            const val = beta != null ? Number(beta).toFixed(3) : '—';
            const rho = Math.max(-1, Math.min(1, (beta || 0) / 2));
            const bg = Research.charts.rhoToColor(rho);
            compTable += '<td class="factor-comp-cell" style="background:' + bg + '" title="β=' + val + '">' + val + '</td>';
          });
          compTable += '</tr>';
        });
        compTable += '</tbody></table>';
        html += '<section class="panel"><h3 class="panel-header">FACTOR COMPARISON</h3><div class="panel-body">' + compTable + '</div></section>';
      }
      const rollData = rollResults && rollResults.filter(function (r) { return r && !r.error && r.factors; });
      if (rollData && rollData.length >= 2) {
        html += '<section class="panel"><h3 class="panel-header">ROLLING FACTOR BETAS (60D WINDOW)</h3><div class="panel-body"><div id="research-rolling-betas-chart"></div></div></section>';
      }
      const contribList = (decompData && decompData.factors) || [];
      const has20d = contribList.some(function (f) { var v = f.factor_contribution_20d != null ? Number(f.factor_contribution_20d) : (f.contribution_pct != null ? Number(f.contribution_pct) : 0); return !Number.isNaN(v) && v > 0; });
      const hasContrib = contribList.some(function (f) { return f.contribution_pct != null && f.contribution_pct > 0; });
      if (contribList.length) {
        html += '<section class="panel"><h3 class="panel-header">WHAT DROVE THE LAST 20 DAYS</h3><div class="panel-body"><div id="research-waterfall-chart"></div></div></section>';
      }
      const el = document.getElementById(containerId);
      if (el) {
        el.innerHTML = html;
        if (rollData && rollData.length >= 2) {
          Research.charts.renderRollingBetas(rollData, 'research-rolling-betas-chart');
        }
        if (contribList.length) {
          const waterfallEl = document.getElementById('research-waterfall-chart');
          if (waterfallEl) {
            const contribs = contribList.map(function (f) {
              var val = f.factor_contribution_20d != null ? Number(f.factor_contribution_20d) : (f.contribution_pct != null ? Number(f.contribution_pct) : 0);
              return { label: FACTOR_LABELS[f.factor] || f.factor, value: Number.isNaN(val) ? 0 : val, color: (Number(f.beta) || 0) >= 0 ? '#16a34a' : '#dc2626' };
            }).filter(function (c) { return c.value > 0; });
            const resVal = decompData.residual_pct != null ? Number(decompData.residual_pct) : 0;
            if (!Number.isNaN(resVal)) contribs.push({ label: 'Residual', value: resVal, color: '#94a3b8' });
            if (contribs.length && contribs.some(function (c) { return c.value > 0; })) {
              Research.charts.renderWaterfall(contribs, 'research-waterfall-chart');
            } else {
              waterfallEl.textContent = 'Insufficient data for 20D contribution analysis';
              waterfallEl.className = 'research-waterfall-empty';
            }
          }
        }
      }
    },
    renderForecast(data, containerId) {
      const self = this;
      const horizon = this.state.forecastHorizon;
      let html = '<div class="research-forecast-controls"><label>Horizon:</label><div class="btn-group">';
      [7, 14, 30, 60].forEach(function (d) {
        html += '<button type="button" class="period-btn ' + (horizon === d ? 'active' : '') + '" data-horizon="' + d + '">' + d + 'D</button>';
      });
      html += '</div><label>History:</label><div class="btn-group">';
      [30, 60, 90].forEach(function (d) {
        html += '<button type="button" class="period-btn ' + (self.state.forecastHistory === d ? 'active' : '') + '" data-history="' + d + '">' + d + 'D</button>';
      });
      html += '</div><label>Model:</label><div class="btn-group">';
      ['arima', 'linear', 'both'].forEach(function (m) {
        html += '<button type="button" class="period-btn ' + (self.state.forecastModel === m ? 'active' : '') + '" data-model="' + m + '">' + (m === 'arima' ? 'ARIMA' : m === 'linear' ? 'Linear' : 'Both') + '</button>';
      });
      html += '</div></div>';
      html += '<section class="panel"><h3 class="panel-header">Forecast</h3><div class="panel-body"><div id="research-forecast-chart"></div><div id="research-forecast-summary"></div><div class="research-forecast-stl-panel"><h4 class="research-collapse-header">TREND DECOMPOSITION (STL) <span class="research-collapse-toggle">+ expand</span></h4><div class="research-collapse-body" id="research-forecast-stl"></div></div><div class="research-forecast-diagnostics-panel"><h4 class="research-collapse-header">MODEL DIAGNOSTICS <span class="research-collapse-toggle">+ expand</span></h4><div class="research-collapse-body" id="research-forecast-diagnostics"></div></div><div class="research-forecast-caveats">[!] ARIMA models extrapolate historical patterns and assume no structural breaks. Confidence intervals widen rapidly beyond 14 days. Use as directional guidance only — not as a price target.</div></div></section>';
      const el = document.getElementById(containerId);
      if (el) {
        el.innerHTML = html;
        Research.charts.renderForecastChart(data, 'research-forecast-chart');
        Research.charts.renderForecastSummary(data, 'research-forecast-summary', horizon);
        el.querySelectorAll('[data-horizon]').forEach(function (btn) {
          btn.addEventListener('click', function () { self.state.forecastHorizon = parseInt(btn.getAttribute('data-horizon'), 10); document.querySelectorAll('.research-forecast-controls [data-horizon]').forEach(function (b) { b.classList.toggle('active', b.getAttribute('data-horizon') === btn.getAttribute('data-horizon')); }); });
        });
        el.querySelectorAll('[data-history]').forEach(function (btn) {
          btn.addEventListener('click', function () { self.state.forecastHistory = parseInt(btn.getAttribute('data-history'), 10); document.querySelectorAll('.research-forecast-controls [data-history]').forEach(function (b) { b.classList.toggle('active', b.getAttribute('data-history') === btn.getAttribute('data-history')); }); });
        });
        el.querySelectorAll('[data-model]').forEach(function (btn) {
          btn.addEventListener('click', function () { self.state.forecastModel = btn.getAttribute('data-model'); document.querySelectorAll('.research-forecast-controls [data-model]').forEach(function (b) { b.classList.toggle('active', b.getAttribute('data-model') === btn.getAttribute('data-model')); }); });
        });
        el.querySelectorAll('.research-forecast-stl-panel .research-collapse-toggle').forEach(function (t) {
          t.addEventListener('click', function () {
            const body = document.getElementById('research-forecast-stl');
            if (body && body.innerHTML === '') {
              API.getForecastDecompose(Research.state.primarySeries, self.state.forecastHistory).then(function (stl) {
                if (stl && !stl.error) Research.charts.renderSTL(stl, 'research-forecast-stl');
              });
            }
            el.querySelector('.research-forecast-stl-panel .research-collapse-body').classList.toggle('open');
          });
        });
        el.querySelectorAll('.research-forecast-diagnostics-panel .research-collapse-toggle').forEach(function (t) {
          t.addEventListener('click', function () {
            const body = document.getElementById('research-forecast-diagnostics');
            if (body && body.innerHTML === '') Research.charts.renderForecastDiagnostics(data, 'research-forecast-diagnostics');
            el.querySelector('.research-forecast-diagnostics-panel .research-collapse-body').classList.toggle('open');
          });
        });
      }
    },
    renderVolatility(data, containerId) {
      let html = '<div class="research-vol-row"><div class="panel"><h3 class="panel-header">Returns & Realised Vol</h3><div class="panel-body"><div id="research-returns-vol-chart"></div></div></div><div class="panel"><h3 class="panel-header">GARCH</h3><div class="panel-body"><div id="research-garch-chart"></div></div></div></div>';
      html += '<div id="research-vol-summary"></div><p class="research-vol-stats" id="research-vol-stats"></p><table class="research-garch-table" id="research-garch-table"></table><p class="research-garch-interp" id="research-garch-interp"></p>';
      const el = document.getElementById(containerId);
      if (el) {
        el.innerHTML = html;
        Research.charts.renderReturnsVol(data, 'research-returns-vol-chart');
        Research.charts.renderGARCH(data, 'research-garch-chart');
        Research.charts.renderVolSummary(data, 'research-vol-summary');
        const statsEl = document.getElementById('research-vol-stats');
        if (statsEl && data.summary) {
          const s = data.summary;
          statsEl.textContent = 'VIX: ' + (s.vix_current != null ? s.vix_current + '%' : '—') + ' | Vol premium vs VIX: ' + (s.vol_risk_premium != null ? (s.vol_risk_premium >= 0 ? '+' : '') + s.vol_risk_premium + 'pp' : '—') + ' | GARCH half-life: ' + (data.garch_params && data.garch_params.half_life_days != null ? data.garch_params.half_life_days + 'd' : '—') + ' | Long-run vol: ' + (data.garch_params && data.garch_params.long_run_vol != null ? data.garch_params.long_run_vol + '%' : '—');
        }
        Research.charts.renderGARCHTable(data, 'research-garch-table', 'research-garch-interp');
      }
    },
    renderScenario(presets, resultData, containerId) {
      const self = this;
      const sel = this.getSelections();
      const presetsList = (presets && (presets.presets || (Array.isArray(presets) ? presets : []))) || [];
      const defaultTargets = ['EQ.SPX', 'EQ.SX7E', 'CM.GOLD', 'FX.EURUSD', 'FX.USDJPY', 'RATES.US10Y', 'CM.BRENT', 'EQ.DAX', 'CREDIT.HY_OAS', 'FX.DXY'];
      const targets = sel.allSeries.length ? sel.allSeries : defaultTargets;
      let html = '<div class="research-scenario-layout"><div class="research-scenario-left">';
      presetsList.forEach(function (p, idx) {
        const pills = (p.shocks || []).map(function (s) {
          const label = (s.change_pct != null ? (s.change_pct >= 0 ? '+' : '') + s.change_pct + '%' : (s.change_bps != null ? (s.change_bps >= 0 ? '+' : '') + s.change_bps + 'bps' : ''));
          return '<span class="shock-pill">' + escapeHtml(s.series_id || '') + ' ' + label + '</span>';
        }).join('');
        html += '<div class="scenario-card" data-preset-idx="' + idx + '"><div class="scenario-card-name">' + escapeHtml(p.name || '') + '</div><div class="scenario-card-desc">' + escapeHtml(p.description || '') + '</div><div class="scenario-shock-pills">' + pills + '</div></div>';
      });
      html += '<section class="panel"><h3 class="panel-header">CUSTOM SCENARIO</h3><div class="panel-body"><div id="research-custom-shocks"></div><button type="button" id="research-scenario-add-shock">+ Add shock</button><button type="button" id="research-scenario-run" class="primary">Run</button></div></section></div><div class="research-scenario-right"><div id="research-scenario-result"></div></div></div>';
      const el = document.getElementById(containerId);
      if (el) {
        el.innerHTML = html;
        el.querySelectorAll('.scenario-card').forEach(function (card) {
          card.addEventListener('click', function () {
            el.querySelectorAll('.scenario-card').forEach(function (c) { c.classList.remove('active'); });
            card.classList.add('active');
            const idx = parseInt(card.getAttribute('data-preset-idx'), 10);
            const preset = presetsList[idx];
            if (!preset || !preset.shocks) return;
            const shockBody = preset.shocks.map(function (s) {
              if (s.change_pct != null) return { series_id: s.series_id, change_pct: s.change_pct };
              return { series_id: s.series_id, change_bps: s.change_bps };
            });
            document.getElementById('research-scenario-result').innerHTML = '<div class="research-loading"><span class="loading-dot"></span> Computing...</div>';
            API.postScenarioRun({ shocks: shockBody, target_series: targets, days: self.state.days }).then(function (res) {
              if (res && res.error) {
                document.getElementById('research-scenario-result').innerHTML = '<div class="research-error">[!] ' + escapeHtml(res.error) + '</div>';
                return;
              }
              self.state.data.scenarioResult = res;
              Research.renderScenario(self.state.scenarioPresets, res, containerId);
            });
          });
        });
        let customRows = 1;
        function renderCustomShocks() {
          const wrap = document.getElementById('research-custom-shocks');
          if (!wrap) return;
          let h = '';
          for (let i = 0; i < customRows; i++) {
            h += '<div class="research-custom-shock-row"><select class="research-custom-series"><option value="">Select series</option>' + (STATE.universe || []).slice(0, 30).map(function (u) { return '<option value="' + escapeHtml(u.id) + '">' + escapeHtml(u.name || u.id) + '</option>'; }).join('') + '</select><input type="number" step="0.5" placeholder="% or bps" class="research-custom-val"><button type="button" class="research-remove-shock">×</button></div>';
          }
          wrap.innerHTML = h;
        }
        renderCustomShocks();
        document.getElementById('research-scenario-add-shock').addEventListener('click', function () { customRows++; renderCustomShocks(); });
        document.getElementById('research-scenario-run').addEventListener('click', function () {
          const rows = document.querySelectorAll('.research-custom-shock-row');
          const shocks = [];
          rows.forEach(function (row) {
            const sid = row.querySelector('.research-custom-series').value;
            const val = parseFloat(row.querySelector('.research-custom-val').value);
            if (sid && !Number.isNaN(val)) shocks.push({ series_id: sid, change_pct: val });
          });
          if (!shocks.length) return;
          document.getElementById('research-scenario-result').innerHTML = '<div class="research-loading"><span class="loading-dot"></span> Computing...</div>';
          API.postScenarioRun({ shocks: shocks, target_series: targets, days: self.state.days }).then(function (res) {
            if (res && res.error) {
              document.getElementById('research-scenario-result').innerHTML = '<div class="research-error">[!] ' + escapeHtml(res.error) + '</div>';
              return;
            }
            self.state.data.scenarioResult = res;
            Research.renderScenario(self.state.scenarioPresets, res, containerId);
          });
        });
        if (resultData && resultData.impacts) {
          const resEl = document.getElementById('research-scenario-result');
          if (resEl) {
            var scenarioTitle = resultData.scenario || 'Scenario';
            if (scenarioTitle === 'Custom') scenarioTitle = 'Custom Scenario';
            var pills = (resultData.shocks_applied || []).map(function (s) {
              var label = (s.name || s.series_id || '') + (s.change_pct != null ? (s.change_pct >= 0 ? '+' : '') + s.change_pct + '%' : (s.change_bps != null ? (s.change_bps >= 0 ? '+' : '') + s.change_bps + 'bps' : ''));
              return '<span class="shock-pill">[' + escapeHtml(label) + ']</span>';
            }).join(' ');
            resEl.innerHTML = '<section class="panel"><h3 class="panel-header">' + escapeHtml(scenarioTitle) + (pills ? ' ' + pills : '') + '</h3><div class="panel-body"><div id="research-scenario-table-wrap"></div><div id="research-scenario-chart-wrap"></div><p class="research-methodology-note"></p></div></section>';
            Research.charts.renderScenarioTable(resultData, 'research-scenario-table-wrap');
            Research.charts.renderScenarioChart(resultData.impacts || [], 'research-scenario-chart-wrap');
            const note = resEl.querySelector('.research-methodology-note');
            if (note) note.textContent = 'Multivariate OLS | ' + (resultData.observations || '') + ' observations | ' + (resultData.date_range ? resultData.date_range.from + ' to ' + resultData.date_range.to : '') + ' | Assumes linear relationships and historical betas hold.';
            if (typeof ResearchWorkspace !== 'undefined' && ResearchWorkspace.attachEvidenceButtons) ResearchWorkspace.attachEvidenceButtons('scenario');
          }
        }
      }
    },
    renderRates(yc, ycHist, decomp, containerId) {
      let html = '<div class="research-rates-row"><div class="panel"><h3 class="panel-header">Yield Curve</h3><div class="panel-body"><div id="research-yield-curve-chart"></div><p class="research-yield-curve-footnote" id="research-yield-curve-footnote"></p></div></div><div class="panel"><h3 class="panel-header">Rates Decomposition</h3><div class="panel-body"><div id="research-rates-decomp-chart"></div></div></div><div class="panel"><h3 class="panel-header">Spread Monitor</h3><div class="panel-body"><div id="research-spread-table"></div></div></div></div>';
      html += '<div class="research-rates-history-row"><div class="panel"><h3 class="panel-header">2s10s Spread (bps)</h3><div class="panel-body"><div id="research-2s10s-chart"></div></div></div><div class="panel"><h3 class="panel-header">Credit Spreads: IG & HY OAS (bps)</h3><div class="panel-body"><div id="research-credit-chart"></div></div></div></div>';
      const el = document.getElementById(containerId);
      if (el) {
        el.innerHTML = html;
        if (yc && !yc.error) {
          Research.charts.renderYieldCurve(yc, 'research-yield-curve-chart');
          const fn = document.getElementById('research-yield-curve-footnote');
          if (fn && yc.spreads) fn.textContent = 'Shape: ' + (yc.spreads.curve_shape || '—') + ' | 2s10s: ' + (yc.spreads['2s10s'] != null ? (yc.spreads['2s10s'] * 100).toFixed(0) + 'bps' : '—');
        }
        if (decomp && !decomp.error) Research.charts.renderRatesDecomp(decomp, 'research-rates-decomp-chart');
        Research.charts.renderSpreadTable(yc, ycHist, decomp, 'research-spread-table');
        if (ycHist && ycHist.series) {
          Research.charts.render2s10sHistory(ycHist, 'research-2s10s-chart');
          Research.charts.renderCreditHistory(ycHist, 'research-credit-chart');
        }
      }
    },
  };

  Research.charts = {
    createSVGCanvas(width, height, margins) {
      margins = margins || { top: 20, right: 20, bottom: 40, left: 50 };
      const innerW = width - margins.left - margins.right;
      const innerH = height - margins.top - margins.bottom;
      const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
      svg.setAttribute('viewBox', '0 0 ' + width + ' ' + height);
      svg.setAttribute('width', '100%');
      svg.setAttribute('height', '100%');
      svg.style.display = 'block';
      return { svg, innerWidth: innerW, innerHeight: innerH, margins, width, height };
    },
    linearScale(domain, range) {
      const [d0, d1] = domain;
      const [r0, r1] = range;
      return function (v) { return r0 + (v - d0) / (d1 - d0 || 1) * (r1 - r0); };
    },
    drawAxes(svg, xScale, yScale, margins, xTicks, yTicks, formatX, formatY) {
      const w = parseFloat(svg.getAttribute('viewBox').split(' ')[2]);
      const h = parseFloat(svg.getAttribute('viewBox').split(' ')[3]);
      const g = document.createElementNS('http://www.w3.org/2000/svg', 'g');
      yTicks.forEach(function (v) {
        const y = yScale(v);
        const line = document.createElementNS('http://www.w3.org/2000/svg', 'line');
        line.setAttribute('x1', margins.left);
        line.setAttribute('x2', w - margins.right);
        line.setAttribute('y1', y);
        line.setAttribute('y2', y);
        line.setAttribute('stroke', '#f1f5f9');
        line.setAttribute('stroke-width', '1');
        g.appendChild(line);
      });
      xTicks.forEach(function (v, i) {
        const x = xScale(v);
        const text = document.createElementNS('http://www.w3.org/2000/svg', 'text');
        text.setAttribute('x', x);
        text.setAttribute('y', h - 8);
        text.setAttribute('text-anchor', 'middle');
        text.setAttribute('font-size', '10');
        text.setAttribute('fill', '#64748b');
        text.textContent = typeof formatX === 'function' ? formatX(v) : v;
        g.appendChild(text);
      });
      yTicks.forEach(function (v) {
        const y = yScale(v);
        const text = document.createElementNS('http://www.w3.org/2000/svg', 'text');
        text.setAttribute('x', margins.left - 4);
        text.setAttribute('y', y + 3);
        text.setAttribute('text-anchor', 'end');
        text.setAttribute('font-size', '10');
        text.setAttribute('fill', '#64748b');
        text.textContent = typeof formatY === 'function' ? formatY(v) : v;
        g.appendChild(text);
      });
      svg.appendChild(g);
    },
    drawLine(svg, data, xScale, yScale, color, strokeWidth, dashed) {
      if (!data || data.length === 0) return;
      const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
      let d = 'M ' + xScale(data[0].x) + ' ' + yScale(data[0].y);
      for (let i = 1; i < data.length; i++) d += ' L ' + xScale(data[i].x) + ' ' + yScale(data[i].y);
      path.setAttribute('d', d);
      path.setAttribute('fill', 'none');
      path.setAttribute('stroke', color || '#0d9488');
      path.setAttribute('stroke-width', strokeWidth || 2);
      if (dashed) path.setAttribute('stroke-dasharray', dashed);
      svg.appendChild(path);
    },
    renderScatter(instruments, containerId, avgVol) {
      const el = document.getElementById(containerId);
      if (!el || !instruments.length) return;
      const w = 380;
      const h = 280;
      const margins = { top: 20, right: 20, bottom: 40, left: 50 };
      const innerW = w - margins.left - margins.right;
      const innerH = h - margins.top - margins.bottom;
      const xs = instruments.map(function (i) { return Number(i.chg_20d_pct) || 0; });
      const ys = instruments.map(function (i) { return Number(i.vol_21d_ann) || 0; });
      const xMin = Math.min.apply(null, xs);
      const xMax = Math.max.apply(null, xs);
      const yMin = Math.min.apply(null, ys);
      const yMax = Math.max.apply(null, ys);
      const xPad = (xMax - xMin) * 0.1 || 1;
      const yPad = (yMax - yMin) * 0.1 || 1;
      const xScale = this.linearScale([xMin - xPad, xMax + xPad], [margins.left, margins.left + innerW]);
      const yScale = this.linearScale([yMin - yPad, yMax + yPad], [margins.top + innerH, margins.top]);
      const assetColor = function (ac) {
        const u = (ac || '').toLowerCase();
        if (u === 'equity') return '#0d9488';
        if (u.indexOf('fixed') >= 0) return '#3b82f6';
        if (u === 'commodity') return '#f97316';
        if (u === 'fx') return '#8b5cf6';
        return '#64748b';
      };
      let svgStr = '<svg viewBox="0 0 ' + w + ' ' + h + '" width="100%" height="100%" style="display:block"><g>';
      const x0 = xScale(0);
      const yAvg = yScale(avgVol || (yMin + yMax) / 2);
      if (x0 >= margins.left && x0 <= w - margins.right) {
        svgStr += '<line x1="' + x0 + '" y1="' + margins.top + '" x2="' + x0 + '" y2="' + (h - margins.bottom) + '" stroke="#94a3b8" stroke-width="1" stroke-dasharray="4,2"/>';
      }
      svgStr += '<line x1="' + margins.left + '" y1="' + yAvg + '" x2="' + (w - margins.right) + '" y2="' + yAvg + '" stroke="#94a3b8" stroke-width="1" stroke-dasharray="4,2"/>';
      const xTicks = [xMin - xPad, 0, xMax + xPad].filter(function (v, i, a) { return a.indexOf(v) === i; });
      const yTicks = [yMin - yPad, (yMin + yMax) / 2, yMax + yPad];
      xTicks.forEach(function (v) {
        const x = xScale(v);
        svgStr += '<line x1="' + x + '" y1="' + (h - margins.bottom) + '" x2="' + x + '" y2="' + (h - margins.bottom) + '" stroke="#e2e8f0" stroke-width="1"/>';
      });
      yTicks.forEach(function (v) {
        const y = yScale(v);
        svgStr += '<line x1="' + margins.left + '" y1="' + y + '" x2="' + (w - margins.right) + '" y2="' + y + '" stroke="#f1f5f9" stroke-width="1"/>';
      });
      instruments.forEach(function (i) {
        const x = Number(i.chg_20d_pct) || 0;
        const y = Number(i.vol_21d_ann) || 0;
        const r = Math.min(12, 5 + Math.abs(x) * 0.5);
        const cx = xScale(x);
        const cy = yScale(y);
        const color = assetColor(i.asset_class);
        svgStr += '<circle cx="' + cx + '" cy="' + cy + '" r="' + r + '" fill="' + color + '"><title>' + escapeHtml(i.name || i.instrument_id || i.id) + ': 20d ' + (x).toFixed(2) + '%, Vol ' + (y).toFixed(2) + '%</title></circle>';
      });
      svgStr += '<text x="' + (margins.left + innerW / 2) + '" y="' + (h - 4) + '" text-anchor="middle" font-size="10" fill="#64748b">20D Return %</text>';
      svgStr += '<text x="' + (margins.left - 20) + '" y="' + (margins.top + innerH / 2) + '" text-anchor="middle" font-size="10" fill="#64748b" transform="rotate(-90 ' + (margins.left - 20) + ' ' + (margins.top + innerH / 2) + ')">Realised Vol % (21D)</text>';
      svgStr += '<rect x="' + (w - 100) + '" y="' + (h - 60) + '" width="90" height="50" fill="#fff" stroke="#e2e8f0"/>';
      svgStr += '<rect x="' + (w - 92) + '" y="' + (h - 52) + '" width="8" height="8" fill="#0d9488"/><text x="' + (w - 80) + '" y="' + (h - 46) + '" font-size="9" fill="#334155">equity</text>';
      svgStr += '<rect x="' + (w - 92) + '" y="' + (h - 40) + '" width="8" height="8" fill="#3b82f6"/><text x="' + (w - 80) + '" y="' + (h - 34) + '" font-size="9" fill="#334155">fixed_income</text>';
      svgStr += '<rect x="' + (w - 92) + '" y="' + (h - 28) + '" width="8" height="8" fill="#f97316"/><text x="' + (w - 80) + '" y="' + (h - 22) + '" font-size="9" fill="#334155">commodity</text>';
      svgStr += '<rect x="' + (w - 92) + '" y="' + (h - 16) + '" width="8" height="8" fill="#8b5cf6"/><text x="' + (w - 80) + '" y="' + (h - 10) + '" font-size="9" fill="#334155">fx</text>';
      svgStr += '</g></svg>';
      el.innerHTML = svgStr;
    },
    renderVolSurface(instruments, containerId) {
      const el = document.getElementById(containerId);
      if (!el) return;
      const list = (instruments || []).slice(0, 10);
      const maxVol = Math.max(1, Math.max.apply(null, list.map(function (i) { return Number(i.vol_21d_ann) || 0; })));
      const w = 380;
      const h = 200;
      const barH = Math.max(14, (h - 40) / list.length);
      const color = function (regime) {
        const u = (regime || '').toUpperCase();
        if (u === 'ELEVATED') return '#dc2626';
        if (u === 'SUPPRESSED') return '#3b82f6';
        return '#0d9488';
      };
      let svgStr = '<svg viewBox="0 0 ' + w + ' ' + h + '" width="100%" height="100%" style="display:block">';
      list.forEach(function (i, idx) {
        const vol = Number(i.vol_21d_ann) || 0;
        const name = i.name || i.instrument_id || i.id;
        const barW = (vol / maxVol) * (w - 120);
        const y = 20 + idx * barH;
        svgStr += '<text x="4" y="' + (y + barH / 2 + 4) + '" font-size="11" fill="#334155">' + escapeHtml(String(name).slice(0, 12)) + '</text>';
        svgStr += '<rect x="80" y="' + (y + 2) + '" width="' + barW + '" height="' + (barH - 4) + '" fill="' + color(i.vol_regime) + '"/>';
        svgStr += '<text x="' + (86 + barW) + '" y="' + (y + barH / 2 + 4) + '" font-size="10" fill="#64748b">' + vol.toFixed(2) + '</text>';
      });
      el.innerHTML = svgStr;
    },
    renderTechnicalsChart(instData, containerId) {
      const el = document.getElementById(containerId);
      if (!el || !instData) return;
      const prices = (instData.prices || instData.history || []).slice();
      if (prices.length < 2) { el.innerHTML = '<p class="text-muted">Insufficient data</p>'; return; }
      const w = 600;
      const h = 280;
      const margins = { top: 20, right: 20, bottom: 32, left: 50 };
      const innerW = w - margins.left - margins.right;
      const innerH = h - margins.top - margins.bottom;
      const dates = prices.map(function (p) { return typeof p.date === 'string' ? p.date : p.x; });
      const values = prices.map(function (p) { return Number(p.value != null ? p.value : p.y) || 0; });
      const minV = Math.min.apply(null, values);
      const maxV = Math.max.apply(null, values);
      const range = maxV - minV || 1;
      const xScale = this.linearScale([0, dates.length - 1], [margins.left, margins.left + innerW]);
      const yScale = this.linearScale([minV - range * 0.02, maxV + range * 0.02], [margins.top + innerH, margins.top]);
      let path = 'M ' + xScale(0) + ' ' + yScale(values[0]);
      for (let i = 1; i < values.length; i++) path += ' L ' + xScale(i) + ' ' + yScale(values[i]);
      const sma20 = (instData.sma20 || []).slice();
      const sma50 = (instData.sma50 || []).slice();
      let svgStr = '<svg viewBox="0 0 ' + w + ' ' + h + '" width="100%" height="100%" style="display:block"><g stroke="#f1f5f9" stroke-width="1">';
      for (let i = 0; i < 6; i++) {
        const y = margins.top + (innerH / 5) * i;
        svgStr += '<line x1="' + margins.left + '" y1="' + y + '" x2="' + (w - margins.right) + '" y2="' + y + '"/>';
      }
      svgStr += '</g><path d="' + path + '" fill="none" stroke="#0d9488" stroke-width="2"/>';
      if (sma20.length === values.length) {
        let p20 = 'M ' + xScale(0) + ' ' + yScale(sma20[0]);
        for (let i = 1; i < sma20.length; i++) p20 += ' L ' + xScale(i) + ' ' + yScale(sma20[i]);
        svgStr += '<path d="' + p20 + '" fill="none" stroke="#ea580c" stroke-width="1.5" stroke-dasharray="4,2"/>';
      }
      if (sma50.length === values.length) {
        let p50 = 'M ' + xScale(0) + ' ' + yScale(sma50[0]);
        for (let i = 1; i < sma50.length; i++) p50 += ' L ' + xScale(i) + ' ' + yScale(sma50[i]);
        svgStr += '<path d="' + p50 + '" fill="none" stroke="#8b5cf6" stroke-width="1.5" stroke-dasharray="4,2"/>';
      }
      const bbUpper = instData.bollinger_upper || [];
      const bbLower = instData.bollinger_lower || [];
      let hasBollinger = bbUpper.length === values.length && bbLower.length === values.length;
      if (!hasBollinger && values.length >= 20) {
        const upper = [];
        const lower = [];
        for (let i = 0; i < values.length; i++) {
          if (i < 19) { upper.push(null); lower.push(null); }
          else {
            const slice = values.slice(i - 19, i + 1);
            const mean = slice.reduce(function (a, b) { return a + b; }, 0) / 20;
            const variance = slice.reduce(function (s, v) { return s + (v - mean) * (v - mean); }, 0) / 20;
            const std = Math.sqrt(variance) || 0;
            upper.push(mean + 2 * std);
            lower.push(mean - 2 * std);
          }
        }
        hasBollinger = true;
        let area = '';
        for (let i = 19; i < values.length; i++) {
          if (area) area += ' L ' + xScale(i) + ' ' + yScale(upper[i]);
          else area = 'M ' + xScale(i) + ' ' + yScale(upper[i]);
        }
        for (let i = values.length - 1; i >= 19; i--) area += ' L ' + xScale(i) + ' ' + yScale(lower[i]);
        area += ' Z';
        svgStr += '<path d="' + area + '" fill="rgba(100,116,139,0.1)" stroke="none"/>';
      } else if (hasBollinger) {
        let area = 'M ' + xScale(0) + ' ' + yScale(bbUpper[0]);
        for (let i = 1; i < values.length; i++) area += ' L ' + xScale(i) + ' ' + yScale(bbUpper[i]);
        for (let i = values.length - 1; i >= 0; i--) area += ' L ' + xScale(i) + ' ' + yScale(bbLower[i]);
        area += ' Z';
        svgStr += '<path d="' + area + '" fill="rgba(100,116,139,0.1)" stroke="none"/>';
      }
      const step = Math.max(1, Math.floor(dates.length / 6));
      for (let i = 0; i < dates.length; i += step) {
        const d = dates[i];
        svgStr += '<text x="' + xScale(i) + '" y="' + (h - 8) + '" text-anchor="middle" font-size="9" fill="#64748b">' + (d ? d.slice(0, 10) : '') + '</text>';
      }
      for (let i = 0; i <= 4; i++) {
        const v = minV + (maxV - minV) * (i / 4);
        svgStr += '<text x="' + (margins.left - 4) + '" y="' + yScale(v) + '" text-anchor="end" font-size="9" fill="#64748b">' + v.toFixed(2) + '</text>';
      }
      svgStr += '</svg>';
      el.innerHTML = svgStr;
    },
    rhoToColor(rho) {
      if (rho >= 0) {
        const r = Math.round(255 - rho * (255 - 22));
        const g = Math.round(255 - rho * (255 - 163));
        const b = Math.round(255 - rho * (255 - 74));
        return 'rgb(' + r + ',' + g + ',' + b + ')';
      }
      const t = -rho;
      const r = Math.round(220 + t * (255 - 220));
      const g = Math.round(38 + t * (255 - 38));
      const b = Math.round(38 + t * (255 - 38));
      return 'rgb(' + r + ',' + g + ',' + b + ')';
    },
    renderCorrelationMatrix(data, containerId, researchRef) {
      const el = document.getElementById(containerId);
      if (!el) return;
      const series = (data.series || []).slice();
      const matrix = data.matrix || [];
      const pValues = data.p_values || [];
      const N = series.length;
      if (N === 0) { el.innerHTML = ''; return; }
      const cellSize = Math.max(60, Math.min(90, Math.floor(400 / N)));
      let table = '<table class="research-corr-table" style="border-collapse:collapse;font-size:' + (cellSize > 70 ? 12 : 10) + 'px"><thead><tr><th></th>';
      series.forEach(function (s) {
        table += '<th>' + escapeHtml(String(s).slice(0, 10)) + '</th>';
      });
      table += '</tr></thead><tbody>';
      const self = this;
      for (let i = 0; i < N; i++) {
        table += '<tr><th>' + escapeHtml(String(series[i]).slice(0, 10)) + '</th>';
        for (let j = 0; j < N; j++) {
          const rho = matrix[i] && matrix[i][j] != null ? Number(matrix[i][j]) : (i === j ? 1 : 0);
          const p = (pValues[i] && pValues[i][j] != null) ? pValues[i][j] : null;
          const bg = i === j ? '#0d9488' : self.rhoToColor(rho);
          const textColor = i === j ? '#fff' : (Math.abs(rho) > 0.5 ? '#fff' : '#1a1a1a');
          const muted = p != null && p > 0.05;
          table += '<td class="research-corr-cell" data-i="' + i + '" data-j="' + j + '" style="width:' + cellSize + 'px;height:' + cellSize + 'px;background:' + bg + ';color:' + (muted ? '#94a3b8' : textColor) + ';text-align:center;cursor:pointer" title="' + escapeHtml(series[i]) + ' vs ' + escapeHtml(series[j]) + ': ρ=' + rho.toFixed(3) + (p != null ? ', p=' + Number(p).toFixed(3) : '') + '">' + (i === j ? '1.00' : rho.toFixed(2)) + '</td>';
        }
        table += '</tr>';
      }
      table += '</tbody></table>';
      el.innerHTML = table;
      el.querySelectorAll('.research-corr-cell').forEach(function (td) {
        const i = parseInt(td.getAttribute('data-i'), 10);
        const j = parseInt(td.getAttribute('data-j'), 10);
        if (i === j) return;
        td.addEventListener('click', function () {
          if (researchRef && series[i] && series[j]) {
            API.getRollingCorrelation(series[i], series[j], 30, researchRef.state.days).then(function (rollData) {
              if (rollData && !rollData.error) {
                const rollEl = document.getElementById('research-rolling-corr');
                if (rollEl) {
                  researchRef.state.rollingPair = { a: series[i], b: series[j] };
                  Research.charts.renderRollingCorr(rollData, 'research-rolling-corr');
                }
              }
            });
          }
        });
      });
    },
    renderRollingCorr(data, containerId) {
      const el = document.getElementById(containerId);
      if (!el || !data.rolling || !data.rolling.length) return;
      const w = 500;
      const h = 160;
      const margins = { top: 16, right: 16, bottom: 24, left: 40 };
      const innerW = w - margins.left - margins.right;
      const innerH = h - margins.top - margins.bottom;
      const points = data.rolling.map(function (r) { return { x: r.date || r.x, y: Number(r.correlation) || 0 }; });
      const xs = points.map(function (p, i) { return i; });
      const ys = points.map(function (p) { return p.y; });
      const yScale = this.linearScale([-1, 1], [margins.top + innerH, margins.top]);
      const xScale = this.linearScale([0, xs.length - 1], [margins.left, margins.left + innerW]);
      let path = 'M ' + xScale(0) + ' ' + yScale(ys[0]);
      for (let i = 1; i < ys.length; i++) path += ' L ' + xScale(i) + ' ' + yScale(ys[i]);
      const current = data.current != null ? Number(data.current).toFixed(3) : '—';
      const minY = Math.min.apply(null, ys);
      const maxY = Math.max.apply(null, ys);
      let svgStr = '<svg viewBox="0 0 ' + w + ' ' + h + '" width="100%" height="100%" style="display:block"><line x1="' + margins.left + '" y1="' + yScale(0) + '" x2="' + (w - margins.right) + '" y2="' + yScale(0) + '" stroke="#94a3b8" stroke-dasharray="4,2" stroke-width="1"/>';
      svgStr += '<path d="' + path + '" fill="none" stroke="#0d9488" stroke-width="2"/>';
      svgStr += '<text x="' + margins.left + '" y="' + (h - 4) + '" font-size="10" fill="#64748b">Current: ' + current + ' | 90d range: ' + minY.toFixed(2) + ' to ' + maxY.toFixed(2) + '</text>';
      svgStr += '</svg>';
      el.innerHTML = svgStr;
    },
    renderImpactTable(data, containerId) {
      const el = document.getElementById(containerId);
      if (!el) return;
      const impacts = (data.impacts || []).slice();
      impacts.sort(function (a, b) {
        const pa = Math.abs(Number(a.predicted) || 0);
        const pb = Math.abs(Number(b.predicted) || 0);
        return pb - pa;
      });
      const confClass = function (c) {
        const u = (c || '').toUpperCase();
        if (u === 'HIGH') return 'confidence-HIGH';
        if (u === 'MEDIUM') return 'confidence-MEDIUM';
        return 'confidence-LOW';
      };
      let table = '<table class="research-impact-table"><thead><tr><th>Instrument</th><th>β</th><th>Predicted</th><th>CI 95%</th><th>R²</th><th>Conf</th></tr></thead><tbody>';
      impacts.forEach(function (row) {
        const pred = row.predicted != null ? Number(row.predicted) : 0;
        const predStr = (pred >= 0 ? '+' : '') + pred.toFixed(2) + '%';
        const r2 = row.r2 != null ? Number(row.r2) : 0;
        const r2W = Math.min(60, r2 * 60);
        const r2Color = r2 > 0.5 ? '#16a34a' : r2 > 0.2 ? '#f97316' : '#dc2626';
        table += '<tr class="expandable"><td>' + escapeHtml(row.instrument_id || row.instrument || row.target || '—') + '</td><td>' + (row.beta != null ? Number(row.beta).toFixed(3) : '—') + '</td>';
        table += '<td class="' + (pred >= 0 ? 'positive' : 'negative') + '" style="position:relative"><span style="position:absolute;left:0;top:0;height:100%;width:' + (Math.min(100, Math.abs(pred) * 5) + '%') + ';background:' + (pred >= 0 ? 'rgba(22,163,74,0.15)' : 'rgba(220,38,38,0.15)') + ';z-index:-1"></span>' + predStr + '</td>';
        table += '<td>' + (row.ci_low != null ? Number(row.ci_low).toFixed(2) : '—') + '% to ' + (row.ci_high != null ? Number(row.ci_high).toFixed(2) : '—') + '%</td>';
        table += '<td><span style="display:inline-block;width:' + r2W + 'px;height:4px;background:' + r2Color + '"></span> ' + r2.toFixed(2) + '</td><td><span class="' + confClass(row.confidence) + '">' + escapeHtml((row.confidence || '—').toUpperCase()) + '</span></td></tr>';
        table += '<tr><td colspan="6" class="expand-detail">' + escapeHtml(row.interpretation || '') + ' ' + escapeHtml(row.historical_observations || '') + '</td></tr>';
      });
      table += '</tbody></table>';
      el.innerHTML = table;
      el.querySelectorAll('tr.expandable').forEach(function (tr) {
        tr.addEventListener('click', function () {
          const next = tr.nextElementSibling;
          if (next && next.classList.contains('expand-detail')) next.classList.toggle('open');
        });
      });
    },
    renderRollingBetas(rollResults, containerId) {
      const el = document.getElementById(containerId);
      if (!el || !rollResults || rollResults.length < 2) return;
      const FACTOR_LABELS = { f_rates: 'Rates', f_dollar: 'Dollar', f_risk: 'Risk', f_growth: 'Growth', f_credit: 'Credit', f_inflation: 'Inflation' };
      const colors = ['#0d9488', '#3b82f6', '#f97316', '#8b5cf6', '#dc2626', '#64748b'];
      const w = 700;
      const h = 200;
      const margins = { top: 20, right: 80, bottom: 32, left: 40 };
      const innerW = w - margins.left - margins.right;
      const innerH = h - margins.top - margins.bottom;
      const allBetas = [];
      rollResults.forEach(function (r) {
        (r.factors || []).forEach(function (f) {
          if (f.beta != null) allBetas.push(Number(f.beta));
        });
      });
      const minB = Math.min.apply(null, allBetas.length ? allBetas : [0]);
      const maxB = Math.max.apply(null, allBetas.length ? allBetas : [0]);
      const pad = (maxB - minB) * 0.1 || 0.1;
      const yScale = this.linearScale([minB - pad, maxB + pad], [margins.top + innerH, margins.top]);
      const xScale = this.linearScale([0, rollResults.length - 1], [margins.left, margins.left + innerW]);
      let svgStr = '<svg viewBox="0 0 ' + w + ' ' + h + '" width="100%" style="display:block">';
      svgStr += '<line x1="' + margins.left + '" y1="' + yScale(0) + '" x2="' + (w - margins.right) + '" y2="' + yScale(0) + '" stroke="#94a3b8" stroke-dasharray="4,2" stroke-width="1"/>';
      const factorKeys = (rollResults[0] && rollResults[0].factors) ? rollResults[0].factors.map(function (f) { return f.factor; }) : [];
      factorKeys.forEach(function (fkey, fi) {
        const pts = rollResults.map(function (r, xi) {
          const f = (r.factors || []).find(function (x) { return x.factor === fkey; });
          return { x: xi, y: f && f.beta != null ? Number(f.beta) : null };
        }).filter(function (p) { return p.y !== null; });
        if (pts.length < 2) return;
        let path = 'M ' + xScale(pts[0].x) + ' ' + yScale(pts[0].y);
        for (let i = 1; i < pts.length; i++) path += ' L ' + xScale(pts[i].x) + ' ' + yScale(pts[i].y);
        svgStr += '<path d="' + path + '" fill="none" stroke="' + (colors[fi] || '#64748b') + '" stroke-width="2"/>';
      });
      for (let i = 0; i < rollResults.length; i++) {
        svgStr += '<text x="' + xScale(i) + '" y="' + (h - 8) + '" text-anchor="middle" font-size="9" fill="#64748b">' + (i + 1) + '</text>';
      }
      svgStr += '<text x="' + (w - 70) + '" y="' + (margins.top + 12) + '" font-size="9" fill="#64748b">' + factorKeys.map(function (k, i) { return '<tspan fill="' + (colors[i] || '#64748b') + '">' + (FACTOR_LABELS[k] || k) + '</tspan>'; }).join(' ') + '</text>';
      svgStr += '</svg>';
      el.innerHTML = svgStr;
    },
    renderWaterfall(contributions, containerId) {
      const el = document.getElementById(containerId);
      if (!el || !contributions.length) return;
      const w = 600;
      const h = 220;
      const total = contributions.reduce(function (s, c) { return s + Math.abs(c.value); }, 0);
      const maxVal = Math.max(total, 1);
      const barH = 24;
      const y0 = h / 2 - barH / 2;
      let running = 0;
      let svgStr = '<svg viewBox="0 0 ' + w + ' ' + h + '" width="100%" style="display:block">';
      const scale = (w - 80) / maxVal;
      contributions.forEach(function (c, i) {
        const ww = Math.abs(c.value) * scale;
        const x = 40 + running * scale;
        running += Math.abs(c.value);
        const fill = c.color || '#94a3b8';
        svgStr += '<rect x="' + x + '" y="' + y0 + '" width="' + ww + '" height="' + barH + '" fill="' + fill + '"/>';
        svgStr += '<text x="' + (x + ww / 2) + '" y="' + (y0 - 4) + '" text-anchor="middle" font-size="10" fill="#334155">' + escapeHtml(String(c.label).slice(0, 12)) + '</text>';
        svgStr += '<text x="' + (x + ww / 2) + '" y="' + (y0 + barH + 14) + '" text-anchor="middle" font-size="10" fill="#64748b">' + (c.value >= 0 ? '+' : '') + c.value.toFixed(1) + '%</text>';
      });
      svgStr += '</svg>';
      el.innerHTML = svgStr;
    },
    renderForecastChart(data, containerId) {
      const el = document.getElementById(containerId);
      if (!el || !data) return;
      const history = (data.history || []).slice();
      const arima = Array.isArray(data.arima_forecast) ? data.arima_forecast : [];
      if (!history.length) return;
      const arimaOnly = arima.length === 0;
      const linearFc = (data.linear_forecast || []);
      let allDates = history.map(function (d) { return d.date; }).concat(arima.map(function (d) { return d.date; }));
      const allVals = history.map(function (d) { return Number(d.value); });
      arima.forEach(function (d) { allVals.push(Number(d.value)); });
      if (arimaOnly && linearFc.length) {
        linearFc.forEach(function (d) { allVals.push(Number(d.value)); });
        allDates = allDates.concat(linearFc.map(function (d) { return d.date; }));
      }
      const ci95Low = arima.map(function (d) { return d.ci_95_low != null ? Number(d.ci_95_low) : Number(d.value); });
      const ci95High = arima.map(function (d) { return d.ci_95_high != null ? Number(d.ci_95_high) : Number(d.value); });
      const minV = Math.min.apply(null, allVals.concat(ci95Low).concat(ci95High));
      const maxV = Math.max.apply(null, allVals.concat(ci95Low).concat(ci95High));
      const range = (maxV - minV) * 0.1 || 1;
      const w = 700;
      const h = 360;
      const margins = { top: 24, right: 100, bottom: 36, left: 52 };
      const innerW = w - margins.left - margins.right;
      const innerH = h - margins.top - margins.bottom;
      const xScale = this.linearScale([0, allDates.length - 1], [margins.left, margins.left + innerW]);
      const yScale = this.linearScale([minV - range, maxV + range], [margins.top + innerH, margins.top]);
      let pathHist = 'M ' + xScale(0) + ' ' + yScale(history[0].value);
      for (let i = 1; i < history.length; i++) pathHist += ' L ' + xScale(i) + ' ' + yScale(Number(history[i].value));
      let pathArima = '';
      if (arima.length) {
        pathArima = 'M ' + xScale(history.length) + ' ' + yScale(Number(arima[0].value));
        for (let i = 1; i < arima.length; i++) pathArima += ' L ' + xScale(history.length + i) + ' ' + yScale(Number(arima[i].value));
      }
      let poly95 = '';
      if (arima.length && ci95Low.length && ci95High.length) {
        poly95 = 'M ' + xScale(history.length) + ' ' + yScale(ci95Low[0]);
        for (let i = 1; i < arima.length; i++) poly95 += ' L ' + xScale(history.length + i) + ' ' + yScale(ci95Low[i]);
        poly95 += ' L ' + xScale(history.length + arima.length - 1) + ' ' + yScale(ci95High[arima.length - 1]);
        for (let i = arima.length - 2; i >= 0; i--) poly95 += ' L ' + xScale(history.length + i) + ' ' + yScale(ci95High[i]);
        poly95 += ' Z';
      }
      let svgStr = '<svg viewBox="0 0 ' + w + ' ' + h + '" width="100%" style="display:block">';
      if (poly95) svgStr += '<path d="' + poly95 + '" fill="rgba(13,148,136,0.08)" stroke="none"/>';
      if (pathArima) svgStr += '<path d="' + pathArima + '" fill="none" stroke="#0f5b54" stroke-width="2"/>';
      svgStr += '<path d="' + pathHist + '" fill="none" stroke="#0d9488" stroke-width="2"/>';
      if (data.linear_forecast && data.linear_forecast.length) {
        let pathLin = 'M ' + xScale(history.length) + ' ' + yScale(Number(data.linear_forecast[0].value));
        for (let i = 1; i < data.linear_forecast.length; i++) pathLin += ' L ' + xScale(history.length + i) + ' ' + yScale(Number(data.linear_forecast[i].value));
        svgStr += '<path d="' + pathLin + '" fill="none" stroke="#94a3b8" stroke-width="1.5" stroke-dasharray="4,2"/>';
      }
      svgStr += '<line x1="' + xScale(history.length - 1) + '" y1="' + margins.top + '" x2="' + xScale(history.length - 1) + '" y2="' + (h - margins.bottom) + '" stroke="#94a3b8" stroke-dasharray="4,2"/>';
      svgStr += '<text x="' + xScale(history.length - 1) + '" y="' + (margins.top - 4) + '" text-anchor="middle" font-size="10" fill="#64748b">Today</text>';
      svgStr += '</svg>';
      if (arimaOnly) {
        el.innerHTML = '<p class="research-forecast-fallback-msg">ARIMA forecast unavailable — showing linear trend only.</p>' + svgStr;
      } else {
        el.innerHTML = svgStr;
      }
    },
    renderForecastSummary(data, containerId, horizon) {
      const el = document.getElementById(containerId);
      if (!el) return;
      const s = data.summary || {};
      const arimaLast = data.arima_forecast && data.arima_forecast.length ? data.arima_forecast[data.arima_forecast.length - 1] : null;
      const currentVal = (s.current != null && s.current !== undefined) ? Number(s.current).toFixed(2) : '—';
      const arima30Val = (s.arima_30d != null && s.arima_30d !== undefined) ? Number(s.arima_30d).toFixed(2) : '—';
      const arimaPct = s.arima_pct_change || '';
      const rangeStr = (arimaLast && arimaLast.ci_95_low != null && arimaLast.ci_95_high != null) ? Number(arimaLast.ci_95_low).toFixed(2) + ' to ' + Number(arimaLast.ci_95_high).toFixed(2) : '—';
      const agreement = (s.model_agreement === 'aligned' ? '↑ Aligned' : '↕ Divergent');
      let html = '<div class="research-forecast-cards">';
      html += '<div class="regime-card"><div class="name">Current</div><div class="value">' + currentVal + '</div></div>';
      html += '<div class="regime-card"><div class="name">ARIMA ' + horizon + 'D</div><div class="value ' + (arimaPct && arimaPct.indexOf('+') === 0 ? 'positive' : 'negative') + '">' + arima30Val + ' ' + arimaPct + '</div></div>';
      html += '<div class="regime-card"><div class="name">95% Range</div><div class="value">' + rangeStr + '</div></div>';
      html += '<div class="regime-card"><div class="name">Agreement</div><div class="value ' + (s.model_agreement === 'aligned' ? 'positive' : '') + '">' + agreement + '</div></div>';
      html += '</div>';
      if (data.arima_model && data.arima_model.order) {
        html += '<p class="research-forecast-model">Model: ARIMA(' + (data.arima_model.order.join(',')) + ')</p>';
      }
      el.innerHTML = html;
    },
    renderSTL(data, containerId) {
      const el = document.getElementById(containerId);
      if (!el || !data.decomposition || !data.decomposition.length) return;
      const dec = data.decomposition;
      const w = 700;
      const hEach = 70;
      const totalH = hEach * 3;
      let svgStr = '<svg viewBox="0 0 ' + w + ' ' + totalH + '" width="100%" style="display:block">';
      ['trend', 'seasonal', 'residual'].forEach(function (key, idx) {
        const vals = dec.map(function (d) { return Number(d[key]) || 0; });
        const minV = Math.min.apply(null, vals);
        const maxV = Math.max.apply(null, vals);
        const yScale = (maxV - minV) ? function (v) { return idx * hEach + 12 + (1 - (v - minV) / (maxV - minV)) * (hEach - 24); } : function () { return idx * hEach + hEach / 2; };
        const xScale = function (i) { return 60 + (i / (vals.length - 1 || 1)) * (w - 80); };
        svgStr += '<text x="8" y="' + (idx * hEach + hEach / 2 + 4) + '" font-size="11" fill="#64748b">' + (key.charAt(0).toUpperCase() + key.slice(1)) + '</text>';
        if (key === 'residual') {
          vals.forEach(function (v, i) {
            const x = xScale(i);
            const barH = Math.min(20, Math.abs(v) * 2);
            svgStr += '<rect x="' + (x - 2) + '" y="' + (yScale(0) - barH / 2) + '" width="4" height="' + barH + '" fill="#ea580c"/>';
          });
        } else {
          let path = 'M ' + xScale(0) + ' ' + yScale(vals[0]);
          for (let i = 1; i < vals.length; i++) path += ' L ' + xScale(i) + ' ' + yScale(vals[i]);
          svgStr += '<path d="' + path + '" fill="none" stroke="' + (key === 'trend' ? '#0d9488' : '#94a3b8') + '" stroke-width="1.5"/>';
        }
      });
      svgStr += '<text x="' + (w / 2) + '" y="' + (totalH - 4) + '" text-anchor="middle" font-size="10" fill="#64748b">Trend direction: ' + (data.trend_direction || '—') + ' | Seasonality: ' + (data.seasonality_strength != null ? (data.seasonality_strength * 100).toFixed(1) : '—') + '% of variance | Residual std: ' + (data.residual_std != null ? Number(data.residual_std).toFixed(2) : '—') + '</text>';
      svgStr += '</svg>';
      el.innerHTML = svgStr;
    },
    renderForecastDiagnostics(data, containerId) {
      const el = document.getElementById(containerId);
      if (!el) return;
      const m = data.arima_model || {};
      const order = m.order ? 'ARIMA(' + m.order.join(',') + ')' : '—';
      let table = '<table class="data-table"><thead><tr><th>Metric</th><th>Value</th><th>Status</th></tr></thead><tbody>';
      table += '<tr><td>Model</td><td>' + order + '</td><td>—</td></tr>';
      table += '<tr><td>AIC</td><td>' + (m.aic != null ? Number(m.aic).toFixed(1) : '—') + '</td><td>lower = better</td></tr>';
      table += '<tr><td>BIC</td><td>' + (m.bic != null ? Number(m.bic).toFixed(1) : '—') + '</td><td>—</td></tr>';
      table += '<tr><td>In-sample RMSE</td><td>' + (m.in_sample_rmse != null ? Number(m.in_sample_rmse).toFixed(2) : '—') + '</td><td>—</td></tr>';
      table += '<tr><td>Ljung-Box p</td><td>' + (m.ljung_box_p != null ? Number(m.ljung_box_p).toFixed(2) : '—') + '</td><td>' + (m.ljung_box_p != null && m.ljung_box_p > 0.05 ? 'OK p>0.05 (clean)' : '--') + '</td></tr>';
      table += '<tr><td>Fallback used</td><td>' + (m.fallback ? 'Yes' : 'No') + '</td><td>' + (m.fallback ? '[!]' : '—') + '</td></tr></tbody></table>';
      el.innerHTML = table;
    },
    renderReturnsVol(data, containerId) {
      const el = document.getElementById(containerId);
      if (!el || !data) return;
      const returns = data.returns || [];
      const realised = data.realised_vol || [];
      if (!returns.length) { el.innerHTML = '<p class="text-muted">No data</p>'; return; }
      const w = 420;
      const h = 240;
      const margins = { top: 20, right: 44, bottom: 28, left: 44 };
      const innerW = w - margins.left - margins.right;
      const innerH = h - margins.top - margins.bottom;
      const retVals = returns.map(function (r) { return Number(r.return_pct) || 0; });
      const volVals = realised.map(function (r) { return Number(r.vol_21d_ann) || 0; });
      const maxRet = Math.max(1, Math.max.apply(null, retVals.map(Math.abs)));
      const maxVol = Math.max(0.1, Math.max.apply(null, volVals));
      const yRetScale = function (v) { return margins.top + innerH / 2 - (v / maxRet) * (innerH / 2 - 4); };
      const yVolScale = function (v) { return margins.top + innerH - (v / maxVol) * innerH; };
      const xScale = this.linearScale([0, returns.length - 1], [margins.left, margins.left + innerW]);
      let svgStr = '<svg viewBox="0 0 ' + w + ' ' + h + '" width="100%" style="display:block">';
      svgStr += '<line x1="' + margins.left + '" y1="' + (margins.top + innerH / 2) + '" x2="' + (w - margins.right) + '" y2="' + (margins.top + innerH / 2) + '" stroke="#e2e8f0" stroke-width="1"/>';
      returns.forEach(function (r, i) {
        const v = Number(r.return_pct) || 0;
        const barH = Math.abs(v) / maxRet * (innerH / 2 - 4);
        const y = v >= 0 ? margins.top + innerH / 2 - barH : margins.top + innerH / 2;
        svgStr += '<rect x="' + (xScale(i) - 2) + '" y="' + y + '" width="4" height="' + barH + '" fill="' + (v >= 0 ? '#16a34a' : '#dc2626') + '"/>';
      });
      let pathVol = '';
      volVals.forEach(function (v, i) {
        if (i === 0) pathVol = 'M ' + xScale(i) + ' ' + yVolScale(v);
        else pathVol += ' L ' + xScale(i) + ' ' + yVolScale(v);
      });
      if (pathVol) svgStr += '<path d="' + pathVol + '" fill="none" stroke="#0d9488" stroke-width="2"/>';
      svgStr += '</svg>';
      el.innerHTML = svgStr;
    },
    renderGARCH(data, containerId) {
      const el = document.getElementById(containerId);
      if (!el) return;
      if (!data.garch_available) {
        el.innerHTML = '<p class="research-error">GARCH model unavailable: ' + escapeHtml(data.garch_params && data.garch_params.reason ? data.garch_params.reason : 'convergence failed') + '</p>';
        return;
      }
      const fitted = data.garch_fitted || [];
      const forecast = data.garch_forecast || [];
      const w = 420;
      const h = 240;
      const margins = { top: 20, right: 20, bottom: 28, left: 44 };
      const allV = fitted.map(function (d) { return Number(d.conditional_vol) || 0; }).concat(forecast.map(function (d) { return Number(d.forecast_vol) || 0; }));
      const maxV = Math.max(0.1, Math.max.apply(null, allV));
      const xScale = this.linearScale([0, fitted.length + forecast.length - 1], [margins.left, 420 - margins.right]);
      const yScale = this.linearScale([0, maxV * 1.1], [h - margins.bottom, margins.top]);
      let pathFit = '';
      fitted.forEach(function (d, i) {
        if (i === 0) pathFit = 'M ' + xScale(i) + ' ' + yScale(Number(d.conditional_vol));
        else pathFit += ' L ' + xScale(i) + ' ' + yScale(Number(d.conditional_vol));
      });
      let pathFc = '';
      forecast.forEach(function (d, i) {
        if (i === 0) pathFc = 'M ' + xScale(fitted.length + i) + ' ' + yScale(Number(d.forecast_vol));
        else pathFc += ' L ' + xScale(fitted.length + i) + ' ' + yScale(Number(d.forecast_vol));
      });
      let svgStr = '<svg viewBox="0 0 420 240" width="100%" style="display:block">';
      svgStr += '<path d="' + pathFit + '" fill="none" stroke="#0d9488" stroke-width="2"/>';
      if (pathFc) svgStr += '<path d="' + pathFc + '" fill="none" stroke="#0d9488" stroke-width="1.5" stroke-dasharray="4,2"/>';
      svgStr += '<line x1="' + xScale(fitted.length - 1) + '" y1="' + margins.top + '" x2="' + xScale(fitted.length - 1) + '" y2="' + (h - margins.bottom) + '" stroke="#94a3b8" stroke-dasharray="2,2"/>';
      svgStr += '</svg>';
      el.innerHTML = svgStr;
    },
    renderVolSummary(data, containerId) {
      const el = document.getElementById(containerId);
      if (!el || !data.summary) return;
      const s = data.summary;
      const regimeCls = (s.vol_regime || '').toUpperCase() === 'ELEVATED' ? 'state-elevated' : (s.vol_regime || '').toUpperCase() === 'SUPPRESSED' ? 'state-suppressed' : 'state-normal';
      let html = '<div class="research-vol-cards">';
      html += '<div class="regime-card"><div class="name">Current Vol (21D)</div><div class="value">' + (s.current_realised_21d != null ? Number(s.current_realised_21d).toFixed(1) : '—') + '% ann.</div></div>';
      html += '<div class="regime-card"><div class="name">Vol Regime</div><div class="state ' + regimeCls + '">' + (s.vol_regime || '—') + '</div></div>';
      html += '<div class="regime-card"><div class="name">Percentile (90D)</div><div class="value">' + (s.vol_percentile_90d != null ? s.vol_percentile_90d : '—') + 'th</div></div>';
      html += '<div class="regime-card"><div class="name">GARCH Persistence</div><div class="value">' + (data.garch_params && data.garch_params.persistence != null ? 'α+β = ' + Number(data.garch_params.persistence).toFixed(3) : '—') + '</div></div>';
      html += '</div>';
      el.innerHTML = html;
    },
    renderGARCHTable(data, tableId, interpId) {
      const tableEl = document.getElementById(tableId);
      const interpEl = document.getElementById(interpId);
      if (!tableEl) return;
      const p = data.garch_params || {};
      const omega = p.omega != null ? Number(p.omega).toFixed(2) : '—';
      const alpha = p.alpha != null ? Number(p.alpha).toFixed(2) : '—';
      const beta = p.beta != null ? Number(p.beta).toFixed(2) : '—';
      const persistence = p.persistence != null ? Number(p.persistence).toFixed(2) : '—';
      const halfLife = p.half_life_days != null ? p.half_life_days + 'd' : '—';
      const longRun = p.long_run_vol != null ? p.long_run_vol + '%' : '—';
      let table = '<table class="data-table"><thead><tr><th>Parameter</th><th>Value</th><th>Interpretation</th></tr></thead><tbody>';
      table += '<tr><td>ω (omega)</td><td>' + omega + '</td><td>Base variance floor</td></tr>';
      table += '<tr><td>α (alpha)</td><td>' + alpha + '</td><td>Shock impact (ARCH)</td></tr>';
      table += '<tr><td>β (beta)</td><td>' + beta + '</td><td>Vol persistence (GARCH)</td></tr>';
      table += '<tr><td>α + β</td><td>' + persistence + '</td><td>Total persistence</td></tr>';
      table += '<tr><td>Half-life</td><td>' + halfLife + '</td><td>Days to half-decay</td></tr>';
      table += '<tr><td>Long-run</td><td>' + longRun + '</td><td>Unconditional ann. vol</td></tr></tbody></table>';
      tableEl.innerHTML = table;
      if (interpEl) {
        const pers = (p.persistence != null && p.persistence !== undefined) ? Number(p.persistence) : 0;
        if (pers > 0.95) interpEl.textContent = 'High persistence — vol shocks are long-lived. A spike today takes ~' + (p.half_life_days || '') + ' days to half-decay. Current environment favours strategies that benefit from sustained vol.';
        else if (pers > 0.85) interpEl.textContent = 'Moderate persistence — vol mean-reverts at a moderate pace.';
        else interpEl.textContent = 'Low persistence — vol shocks are short-lived. Mean-reversion is relatively fast.';
      }
    },
    renderScenarioTable(data, containerId) {
      const el = document.getElementById(containerId);
      if (!el) return;
      const impacts = (data.impacts || []).slice().sort(function (a, b) { return Math.abs(b.predicted_move_pct || 0) - Math.abs(a.predicted_move_pct || 0); });
      let table = '<table class="research-impact-table"><thead><tr><th>Instrument</th><th>Dir</th><th>Predicted</th><th>CI 95%</th><th>β</th><th>R²</th><th>Conf</th></tr></thead><tbody>';
      impacts.forEach(function (row) {
        const pred = row.predicted_move_pct != null ? Number(row.predicted_move_pct) : 0;
        const dir = pred >= 0 ? '<span style="color:#16a34a;font-size:20px">▲</span>' : '<span style="color:#dc2626;font-size:20px">▼</span>';
        const predStr = (pred >= 0 ? '+' : '') + pred.toFixed(2) + '%';
        const r2 = row.r_squared != null ? Number(row.r_squared) : 0;
        const r2W = Math.min(60, r2 * 60);
        const contribs = (row.individual_contributions || []).map(function (c) { return (c.shock || '') + ': ' + (c.contribution_pct != null ? c.contribution_pct + '%' : ''); }).join('; ');
        table += '<tr class="expandable ' + (pred >= 0 ? 'positive-row' : 'negative-row') + '"><td>' + escapeHtml(row.name || row.series_id || '') + '</td><td>' + dir + '</td><td class="' + (pred >= 0 ? 'positive' : 'negative') + '" style="font-size:16px">' + predStr + '</td><td class="text-muted" style="font-size:11px">' + (row.ci_95_low != null ? row.ci_95_low.toFixed(1) : '—') + '% to ' + (row.ci_95_high != null ? row.ci_95_high.toFixed(1) : '—') + '%</td><td style="font-family:monospace">' + '—' + '</td><td><span style="display:inline-block;width:' + r2W + 'px;height:4px;background:#0d9488"></span> ' + r2.toFixed(2) + '</td><td><span class="confidence-' + (row.confidence || 'LOW') + '">' + (row.confidence || '—') + '</span></td></tr>';
        table += '<tr><td colspan="7" class="expand-detail">' + escapeHtml(contribs) + '</td></tr>';
      });
      table += '</tbody></table>';
      el.innerHTML = table;
      el.querySelectorAll('tr.expandable').forEach(function (tr) {
        tr.addEventListener('click', function () {
          const next = tr.nextElementSibling;
          if (next && next.classList.contains('expand-detail')) next.classList.toggle('open');
        });
      });
    },
    renderScenarioChart(impacts, containerId) {
      const el = document.getElementById(containerId);
      if (!el || !impacts.length) return;
      const maxAbs = Math.max(0.01, Math.max.apply(null, impacts.map(function (i) { return Math.abs(i.predicted_move_pct || 0); })));
      const w = 500;
      const h = 220;
      const barW = 200;
      const scale = barW / maxAbs;
      const margins = { left: 100, right: 60 };
      const centerX = 250;
      let svgStr = '<svg viewBox="0 0 500 220" width="100%" style="display:block">';
      svgStr += '<line x1="' + centerX + '" y1="20" x2="' + centerX + '" y2="' + (h - 20) + '" stroke="#1a1a1a" stroke-width="2"/>';
      impacts.slice(0, 10).forEach(function (row, i) {
        const pred = row.predicted_move_pct != null ? Number(row.predicted_move_pct) : 0;
        const ww = Math.abs(pred) * scale;
        const y = 28 + i * 18;
        const x = pred >= 0 ? centerX : centerX - ww;
        svgStr += '<rect x="' + x + '" y="' + (y - 6) + '" width="' + ww + '" height="12" fill="' + (pred >= 0 ? '#16a34a' : '#dc2626') + '"/>';
        svgStr += '<text x="' + (margins.left - 4) + '" y="' + (y + 4) + '" text-anchor="end" font-size="10" fill="#334155">' + escapeHtml(String(row.name || row.series_id).slice(0, 14)) + '</text>';
        svgStr += '<text x="' + (pred >= 0 ? centerX + ww + 4 : centerX - ww - 4) + '" y="' + (y + 4) + '" text-anchor="' + (pred >= 0 ? 'start' : 'end') + '" font-size="10" fill="#334155">' + (pred >= 0 ? '+' : '') + pred.toFixed(2) + '%</text>';
      });
      svgStr += '</svg>';
      el.innerHTML = svgStr;
    },
    renderYieldCurve(data, containerId) {
      const el = document.getElementById(containerId);
      if (!el || !data || !data.curve) return;
      const tenors = ['3M', '2Y', '5Y', '10Y', '30Y'];
      const w = 320;
      const h = 240;
      const margins = { top: 24, right: 20, bottom: 44, left: 36 };
      const curves = [
        { arr: data.curve, stroke: '#0d9488', width: 2.5, dash: '', label: 'Today' },
        { arr: data.one_month_ago || [], stroke: '#64748b', width: 1.5, dash: '4,2', label: '1M ago' },
        { arr: data.three_months_ago || [], stroke: '#94a3b8', width: 1, dash: '2,2', label: '3M ago' }
      ];
      let allY = [];
      curves.forEach(function (cr) {
        if (cr.arr && cr.arr.length) {
          cr.arr.forEach(function (c) { if (c.yield != null) allY.push(Number(c.yield)); });
        }
      });
      const maxY = (allY.length ? Math.max.apply(null, allY) : 0) + 0.5;
      const minY = Math.min(0, (allY.length ? Math.min.apply(null, allY) : 0) - 0.2);
      const xScale = function (i) { return margins.left + (i / (tenors.length - 1)) * (w - margins.left - margins.right); };
      const yScale = this.linearScale([minY, maxY], [h - margins.bottom, margins.top]);
      function pointsFromCurve(arr) {
        if (!arr || !arr.length) return [];
        return arr.filter(function (c) { return c.yield != null; }).map(function (c) {
          const idx = tenors.indexOf(c.tenor);
          return { x: xScale(idx >= 0 ? idx : 0), y: yScale(Number(c.yield)) };
        });
      }
      let svgStr = '<svg viewBox="0 0 320 260" width="100%" style="display:block">';
      curves.forEach(function (cr) {
        const pts = pointsFromCurve(cr.arr);
        if (pts.length >= 2) {
          let path = 'M ' + pts[0].x + ' ' + pts[0].y;
          for (let i = 1; i < pts.length; i++) path += ' L ' + pts[i].x + ' ' + pts[i].y;
          svgStr += '<path d="' + path + '" fill="none" stroke="' + cr.stroke + '" stroke-width="' + cr.width + '"' + (cr.dash ? ' stroke-dasharray="' + cr.dash + '"' : '') + '/>';
        }
      });
      const pointsToday = pointsFromCurve(data.curve);
      if (pointsToday.length >= 2) {
        pointsToday.forEach(function (p) { svgStr += '<circle cx="' + p.x + '" cy="' + p.y + '" r="4" fill="#0d9488"/>'; });
      }
      tenors.forEach(function (t, i) {
        svgStr += '<text x="' + xScale(i) + '" y="' + (h - 8) + '" text-anchor="middle" font-size="10" fill="#64748b">' + t + '</text>';
      });
      var legY = h + 14;
      curves.forEach(function (cr, i) {
        var lx = margins.left + i * 95;
        svgStr += '<line x1="' + lx + '" y1="' + legY + '" x2="' + (lx + 24) + '" y2="' + legY + '" stroke="' + cr.stroke + '" stroke-width="' + (cr.width || 1.5) + '"' + (cr.dash ? ' stroke-dasharray="' + cr.dash + '"' : '') + '/>';
        svgStr += '<text x="' + (lx + 28) + '" y="' + (legY + 4) + '" font-size="10" fill="#334155">' + (cr.label || '') + '</text>';
      });
      svgStr += '</svg>';
      el.innerHTML = svgStr;
    },
    renderRatesDecomp(data, containerId) {
      const el = document.getElementById(containerId);
      if (!el || !data.history || !data.history.length) return;
      const h = data.history;
      const w = 380;
      const height = 240;
      const margins = { top: 20, right: 20, bottom: 28, left: 44 };
      const dates = h.map(function (d) { return d.date; });
      const nominals = h.map(function (d) { return Number(d.nominal) || 0; });
      const reals = h.map(function (d) { return Number(d.real) || 0; });
      const breakevens = h.map(function (d) { return Number(d.breakeven) || 0; });
      const maxV = Math.max.apply(null, nominals);
      const minV = Math.min.apply(null, reals);
      const xScale = this.linearScale([0, dates.length - 1], [margins.left, w - margins.right]);
      const yScale = this.linearScale([minV - 0.5, maxV + 0.5], [height - margins.bottom, margins.top]);
      let areaReal = 'M ' + xScale(0) + ' ' + yScale(0);
      for (let i = 0; i < reals.length; i++) areaReal += ' L ' + xScale(i) + ' ' + yScale(reals[i]);
      for (let i = reals.length - 1; i >= 0; i--) areaReal += ' L ' + xScale(i) + ' ' + yScale(0);
      areaReal += ' Z';
      let areaBE = 'M ' + xScale(0) + ' ' + yScale(reals[0]);
      for (let i = 0; i < breakevens.length; i++) areaBE += ' L ' + xScale(i) + ' ' + yScale(reals[i] + breakevens[i]);
      for (let i = breakevens.length - 1; i >= 0; i--) areaBE += ' L ' + xScale(i) + ' ' + yScale(reals[i]);
      areaBE += ' Z';
      let pathNom = 'M ' + xScale(0) + ' ' + yScale(nominals[0]);
      for (let i = 1; i < nominals.length; i++) pathNom += ' L ' + xScale(i) + ' ' + yScale(nominals[i]);
      let svgStr = '<svg viewBox="0 0 380 240" width="100%" style="display:block"><path d="' + areaReal + '" fill="#3b82f6" opacity="0.6"/><path d="' + areaBE + '" fill="#f97316" opacity="0.6"/><path d="' + pathNom + '" fill="none" stroke="#1a1a1a" stroke-width="2"/></svg>';
      el.innerHTML = svgStr;
    },
    renderSpreadTable(yc, ycHist, decomp, containerId) {
      const el = document.getElementById(containerId);
      if (!el) return;
      const spreads = (yc && yc.spreads) ? yc.spreads : {};
      const series = (ycHist && ycHist.series) ? ycHist.series : {};
      const igArr = series['CREDIT.IG_OAS'] || [];
      const hyArr = series['CREDIT.HY_OAS'] || [];
      const igCurrent = igArr.length && igArr[igArr.length - 1].value != null ? Number(igArr[igArr.length - 1].value) : null;
      const hyCurrent = hyArr.length && hyArr[hyArr.length - 1].value != null ? Number(hyArr[hyArr.length - 1].value) : null;
      let table = '<table class="data-table"><thead><tr><th>Spread</th><th>Current</th><th>1M Δ</th><th>3M Δ</th><th>Z-score</th><th>Signal</th></tr></thead><tbody>';
      table += '<tr><td>2s10s</td><td>' + (spreads['2s10s'] != null ? (spreads['2s10s'] * 100).toFixed(0) + 'bps' : '—') + '</td><td>—</td><td>—</td><td>—</td><td>' + (spreads.curve_shape || '—') + '</td></tr>';
      table += '<tr><td>5s30s</td><td>' + (spreads['5s30s'] != null ? (spreads['5s30s'] * 100).toFixed(0) + 'bps' : '—') + '</td><td>—</td><td>—</td><td>—</td><td>stable</td></tr>';
      table += '<tr><td>IG OAS</td><td>' + (igCurrent != null ? igCurrent.toFixed(0) + 'bps' : '—') + '</td><td>—</td><td>—</td><td>—</td><td>—</td></tr>';
      table += '<tr><td>HY OAS</td><td>' + (hyCurrent != null ? hyCurrent.toFixed(0) + 'bps' : '—') + '</td><td>—</td><td>—</td><td>—</td><td>—</td></tr>';
      table += '</tbody></table>';
      el.innerHTML = table;
    },
    render2s10sHistory(data, containerId) {
      const el = document.getElementById(containerId);
      const series = (data && data.series) ? data.series['RATES.2S10S'] : null;
      if (!el || !series || !Array.isArray(series)) return;
      const arr = series.map(function (d) { return { date: d.date, value: (Number(d.value) || 0) * 100 }; });
      if (!arr.length) return;
      const w = 460;
      const h = 160;
      const margins = { top: 16, right: 16, bottom: 24, left: 40 };
      const vals = arr.map(function (d) { return d.value; });
      const xScale = this.linearScale([0, arr.length - 1], [margins.left, w - margins.right]);
      const yScale = this.linearScale([Math.min(0, Math.min.apply(null, vals) - 5), Math.max(20, Math.max.apply(null, vals) + 5)], [h - margins.bottom, margins.top]);
      let path = 'M ' + xScale(0) + ' ' + yScale(arr[0].value);
      for (let i = 1; i < arr.length; i++) path += ' L ' + xScale(i) + ' ' + yScale(arr[i].value);
      let svgStr = '<svg viewBox="0 0 460 160" width="100%" style="display:block"><line x1="' + margins.left + '" y1="' + yScale(0) + '" x2="' + (w - margins.right) + '" y2="' + yScale(0) + '" stroke="#dc2626" stroke-dasharray="4,2"/><path d="' + path + '" fill="none" stroke="#0d9488" stroke-width="2"/></svg>';
      el.innerHTML = svgStr;
    },
    renderCreditHistory(data, containerId) {
      const el = document.getElementById(containerId);
      if (!el || !data || !data.series) return;
      const ig = (data.series['CREDIT.IG_OAS'] || data.series['RATES.IG_OAS']) || [];
      const hy = (data.series['CREDIT.HY_OAS'] || data.series['RATES.HY_OAS']) || [];
      if (!ig.length && !hy.length) return;
      const w = 460;
      const h = 160;
      const margins = { top: 16, right: 44, bottom: 24, left: 44 };
      const igV = ig.map(function (d) { return Number(d.value); });
      const hyV = hy.map(function (d) { return Number(d.value); });
      const minIG = igV.length ? Math.min.apply(null, igV) : 0;
      const maxIG = igV.length ? Math.max.apply(null, igV) : 100;
      const minHY = hyV.length ? Math.min.apply(null, hyV) : 0;
      const maxHY = hyV.length ? Math.max.apply(null, hyV) : 100;
      const n = Math.max(ig.length, hy.length, 1);
      const xScale = this.linearScale([0, n - 1], [margins.left, w - margins.right]);
      const yScaleLeft = this.linearScale([minIG - 5, maxIG + 5], [h - margins.bottom, margins.top]);
      const yScaleRight = this.linearScale([minHY - 5, maxHY + 5], [h - margins.bottom, margins.top]);
      let pathIG = '';
      ig.forEach(function (d, i) { if (i === 0) pathIG = 'M ' + xScale(i) + ' ' + yScaleLeft(Number(d.value)); else pathIG += ' L ' + xScale(i) + ' ' + yScaleLeft(Number(d.value)); });
      let pathHY = '';
      hy.forEach(function (d, i) { if (i === 0) pathHY = 'M ' + xScale(i) + ' ' + yScaleRight(Number(d.value)); else pathHY += ' L ' + xScale(i) + ' ' + yScaleRight(Number(d.value)); });
      let svgStr = '<svg viewBox="0 0 460 160" width="100%" style="display:block">';
      if (pathIG) svgStr += '<path d="' + pathIG + '" fill="none" stroke="#3b82f6" stroke-width="2"/>';
      if (pathHY) svgStr += '<path d="' + pathHY + '" fill="none" stroke="#f97316" stroke-width="2"/>';
      svgStr += '<text x="' + (margins.left - 4) + '" y="' + (margins.top + 4) + '" text-anchor="end" font-size="9" fill="#3b82f6">IG</text>';
      svgStr += '<text x="' + (w - margins.right + 4) + '" y="' + (margins.top + 4) + '" text-anchor="start" font-size="9" fill="#f97316">HY</text>';
      svgStr += '</svg>';
      el.innerHTML = svgStr;
    },
  };

  // ——— Research workspace (U2–U7) ———
  function researchCollapseSidebar() {
    /* S2: global #sidebar removed — no-op until S5 */
  }
  function researchRestoreSidebar() {
    /* S2: global #sidebar removed — no-op until S5 */
  }

  var AtPicker = {
    isOpen: false,
    anchorEl: null,
    onSelect: null,
    query: '',
    dropdownEl: null,
    _ignoreNextOutsideClick: false,
    _outsideClickBound: false,
    _externalInstrumentsByQuery: {},
    _externalLookupPending: {},
    open: function (anchorEl, onSelect) {
      this.anchorEl = anchorEl;
      this.onSelect = onSelect;
      this.query = '';
      this.isOpen = true;
      this.render();
    },

    filter: function (query) {
      this.query = query;
      this.render();
    },

    getResults: function (query) {
      var rawQuery = (query || '').trim();
      if (rawQuery.length < 2) {
        return { instruments: [], topics: [], charts: [] };
      }
      var q = rawQuery.toLowerCase();
      var queryUpper = rawQuery.toUpperCase();
      var looksLikeTicker = queryUpper.length >= 2 && queryUpper.length <= 6 && /^[A-Z]{2,6}$/.test(queryUpper);
      var allInstruments = (STATE.universe || []).map(function (inst) {
        var price = STATE.latestPrices && STATE.latestPrices[inst.id];
        return {
          type: 'instrument',
          id: inst.id,
          name: inst.name || inst.id,
          asset_class: inst.asset_class || inst.type || '',
          sector: inst.sector || null,
          source: 'db',
          value: price && price.value,
          chg: price && price.pct_chg
        };
      });
      var filtered = allInstruments.filter(function (inst) {
        return (inst.name || '').toLowerCase().indexOf(q) !== -1 || (inst.id || '').toLowerCase().indexOf(q) !== -1;
      }).slice(0, 10);

      // Opportunistic live lookup for ticker-like queries (non-blocking)
      var cachedExternal = this._externalInstrumentsByQuery[queryUpper] || [];
      if (looksLikeTicker && cachedExternal.length) {
        var existingIds = new Set(filtered.map(function (i) { return i.id; }));
        cachedExternal.forEach(function (ext) {
          if (!existingIds.has(ext.id)) filtered.push(ext);
        });
        filtered = filtered.slice(0, 10);
      }

      var hasExternalCache = Object.prototype.hasOwnProperty.call(this._externalInstrumentsByQuery, queryUpper);
      if (looksLikeTicker && filtered.length < 3 && !this._externalLookupPending[queryUpper] && !hasExternalCache) {
        this._externalLookupPending[queryUpper] = true;
        var self = this;
        (function (snapshotQuery, snapshotUpper) {
          fetch(CONFIG.API_BASE + '/api/instruments/search?q=' + encodeURIComponent(snapshotUpper))
            .then(function (r) { return r.json(); })
            .then(function (apiResults) {
              self._externalLookupPending[snapshotUpper] = false;
              var ext = (apiResults || [])
                .filter(function (x) { return x && (x.source === 'openbb_lookup' || x.source === 'yfinance_lookup'); })
                .map(function (x) {
                  var ticker = x.yfinance_ticker || x.ticker || snapshotUpper;
                  return {
                    type: 'instrument',
                    id: ticker,
                    yfinance_ticker: ticker,
                    name: x.name || ticker,
                    asset_class: x.asset_class || 'equity',
                    sector: x.sector || null,
                    source: x.source
                  };
                });
              self._externalInstrumentsByQuery[snapshotUpper] = ext;

              if (self.isOpen && (self.query || '').trim() === snapshotQuery) {
                self.render();
              }
            })
            .catch(function () {
              self._externalLookupPending[snapshotUpper] = false;
            });
        })(rawQuery, queryUpper);
      }
      var topics = (STATE.signals || [])
        .filter(function (sig) { return !q || (sig.topic || '').toLowerCase().indexOf(q) !== -1; })
        .slice(0, 3)
        .map(function (sig) {
          return {
            type: 'topic',
            id: sig.topic,
            name: sig.topic,
            count: sig.article_count,
            sentiment: sig.sentiment_avg
          };
        });

      var results = { instruments: filtered, topics: topics, charts: [] };
      var state = typeof ResearchV2 !== 'undefined' ? ResearchV2.state : {};
      var xSeries = state.xSeries;
      var ySeries = state.ySeries && state.ySeries[0] ? state.ySeries[0] : null;
      var xName = (xSeries && (xSeries.name || xSeries.id)) || '';
      var yName = (ySeries && (ySeries.name || ySeries.id)) || '';
      var hasXY = !!(xSeries && ySeries);
      var charts = [];

      if (hasXY) {
        charts.push({ type: 'chart', chartType: 'overlaid', x: xSeries.id, y: ySeries.id, period: 90, shockPct: 10, instruments: [xSeries.id, ySeries.id].join(','), label: xName + ' vs ' + yName + ' — Overlaid' });
        charts.push({ type: 'chart', chartType: 'impact', x: xSeries.id, y: ySeries.id, period: 90, shockPct: 10, instruments: '', label: 'Impact: ' + xName + ' -> ' + yName });
        charts.push({ type: 'chart', chartType: 'forecast', x: '', y: ySeries.id, period: 90, shockPct: 10, instruments: '', label: yName + ' — 30D Forecast' });
        charts.push({ type: 'chart', chartType: 'factors', x: '', y: ySeries.id, period: 90, shockPct: 10, instruments: '', label: 'What drives ' + yName });
      }
      var firstTwo = (STATE.universe || []).slice(0, 2).map(function (i) { return i.id; }).join(',');
      var corrInstruments = hasXY ? [xSeries.id, ySeries.id].join(',') : firstTwo;
      charts.push({ type: 'chart', chartType: 'correlation', x: '', y: '', period: 90, shockPct: 10, instruments: corrInstruments, label: 'Correlation Matrix' });
      charts.push({ type: 'chart', chartType: 'regime', x: '', y: '', period: 90, shockPct: 10, instruments: '', label: 'Regime Fingerprint' });

      var chartResults = !q ? charts : charts.filter(function (c) { return (c.label || '').toLowerCase().indexOf(q) !== -1; });
      results.charts = chartResults.slice(0, 6);
      if (results.charts.length > 0) {
        results.instruments = results.instruments.slice(0, 4);
      }
      return results;
    },

    render: function () {
      var existing = document.getElementById('at-picker-dropdown');
      if (existing && existing.parentNode) existing.parentNode.removeChild(existing);
      try {
        var results = this.getResults(this.query);
        var total = results.instruments.length + results.topics.length + (results.charts && results.charts.length ? results.charts.length : 0);
        if (total === 0) return;
        var el = document.createElement('div');
      el.className = 'at-picker-dropdown';
      el.id = 'at-picker-dropdown';
      var sel = window.getSelection();
      var top, left;
      if (sel && sel.rangeCount) {
        var rect = sel.getRangeAt(0).getBoundingClientRect();
        top = rect.bottom + (window.scrollY || window.pageYOffset) + 4;
        left = rect.left + (window.scrollX || window.pageXOffset);
      } else if (this.anchorEl) {
        var r = this.anchorEl.getBoundingClientRect();
        top = r.bottom + (window.scrollY || window.pageYOffset) + 4;
        left = r.left + (window.scrollX || window.pageXOffset);
      } else {
        top = 100;
        left = 100;
      }
      el.style.cssText = 'position:fixed;top:' + top + 'px;left:' + left + 'px;z-index:2000;';
      var html = '';
      if (results.charts && results.charts.length > 0) {
        html += '<div class="at-group-label">CHARTS</div>';
        results.charts.forEach(function (item) {
          var ct = (item && item.chartType != null) ? String(item.chartType) : '';
          var cx = (item && item.x != null) ? String(item.x) : '';
          var cy = (item && item.y != null) ? String(item.y) : '';
          var ci = (item && item.instruments != null) ? String(item.instruments) : '';
          var cl = (item && item.label != null) ? String(item.label) : '';
          html += '<div class="at-result-row" data-type="chart" data-chart-type="' + escapeHtml(ct) + '" data-chart-x="' + escapeHtml(cx) + '" data-chart-y="' + escapeHtml(cy) + '" data-chart-period="' + (item.period != null ? item.period : 90) + '" data-chart-shock="' + (item.shockPct != null ? item.shockPct : 10) + '" data-chart-instruments="' + escapeHtml(ci) + '" data-chart-label="' + escapeHtml(cl) + '"><span class="at-result-name">' + escapeHtml(cl) + '</span><span class="at-result-id">' + escapeHtml(ct) + '</span></div>';
        });
      }
      if (results.instruments.length) {
        html += '<div class="at-group-label">INSTRUMENTS</div>';
        results.instruments.forEach(function (item) {
          var chgClass = item.chg >= 0 ? 'at-chg-pos' : 'at-chg-neg';
          var chgStr = item.chg != null ? (item.chg >= 0 ? '+' : '') + Number(item.chg).toFixed(2) + '%' : '';
          var isExternal = item.source && item.source !== 'db';
          var externalCls = isExternal ? ' at-picker-result--external' : '';
          var metaText = isExternal
            ? 'Add from Yahoo Finance'
            : (item.sector ? (item.asset_class || '') + ' · ' + item.sector : (item.asset_class || ''));
          html += '<div class="at-result-row' + externalCls + '" data-type="instrument" data-source="' + escapeHtml(item.source || 'db') + '" data-id="' + escapeHtml(item.id) + '" data-name="' + escapeHtml(item.name) + '"><span class="at-result-name">' + escapeHtml(item.name) + '</span><span class="at-result-id">' + escapeHtml(item.id) + '</span><span class="at-picker-result-meta">' + escapeHtml(metaText) + '</span>';
          if (item.value != null) html += '<span class="at-result-value">' + Number(item.value).toFixed(2) + '</span><span class="at-result-chg ' + chgClass + '">' + escapeHtml(chgStr) + '</span>';
          html += '</div>';
        });
      }
      if (results.topics.length) {
        html += '<div class="at-group-label">SIGNALS</div>';
        results.topics.forEach(function (item) {
          html += '<div class="at-result-row" data-type="topic" data-id="' + escapeHtml(item.id) + '" data-name="' + escapeHtml(item.name) + '"><span class="at-result-name">' + escapeHtml(item.name) + '</span><span class="at-result-count">' + (item.count != null ? item.count : '—') + ' articles</span></div>';
        });
      }
      el.innerHTML = html;
      document.body.appendChild(el);
      this.dropdownEl = el;
      var self = this;
      el.addEventListener('mousedown', function (e) {
        e.preventDefault();
        e.stopPropagation();
      });
      el.addEventListener('click', function (e) {
        var row = e.target.closest('.at-result-row');
        if (!row) return;
        e.preventDefault();
        e.stopPropagation();
        if (row.dataset.type === 'chart') {
          self.select({
            type: 'chart',
            chartType: row.dataset.chartType || '',
            x: row.dataset.chartX || '',
            y: row.dataset.chartY || '',
            period: parseInt(row.dataset.chartPeriod, 10) || 90,
            shockPct: parseFloat(row.dataset.chartShock) || 10,
            instruments: row.dataset.chartInstruments || '',
            label: row.dataset.chartLabel || ''
          });
        } else {
          if (row.dataset.type === 'instrument' && row.dataset.source && row.dataset.source !== 'db') return;
          self.select({ type: row.dataset.type, id: row.dataset.id, name: row.dataset.name });
        }
      });
      if (!AtPicker._outsideClickBound) {
        AtPicker._outsideClickBound = true;
        document.addEventListener('click', function globalOutsideClick (e) {
          if (!AtPicker.isOpen) return;
          if (AtPicker._ignoreNextOutsideClick) {
            AtPicker._ignoreNextOutsideClick = false;
            return;
          }
          if (!document.contains(e.target)) return;
          var dd = document.getElementById('at-picker-dropdown');
          if (!dd || !dd.contains(e.target)) {
            AtPicker.close();
          }
        });
      }
      } catch (err) {
        console.error('[AtPicker.render] error:', err);
      }
    },

    select: function (item) {
      if (item.type === 'chart') {
        if (typeof ResearchV2 !== 'undefined' && typeof ResearchV2.insertChartEmbedFromPicker === 'function') {
          ResearchV2.insertChartEmbedFromPicker(item);
        }
      } else {
        if (this.onSelect) this.onSelect(item);
      }
      this.close();
    },

    close: function () {
      var existing = document.getElementById('at-picker-dropdown');
      if (existing) existing.remove();
      this.isOpen = false;
      this.dropdownEl = null;
      this._ignoreNextOutsideClick = false;
      if (typeof AtPickerFlow !== 'undefined') {
        AtPickerFlow.active = false;
        AtPickerFlow.step = 0;
      }
    },

    _instrumentRowHtml: function (item) {
      var chgClass = (item.chg != null) ? (item.chg >= 0 ? 'at-chg-pos' : 'at-chg-neg') : '';
      var chgStr = (item.chg != null) ? (item.chg >= 0 ? '+' : '') + Number(item.chg).toFixed(2) + '%' : '';
      var isExternal = item.source && item.source !== 'db';
      var externalCls = isExternal ? ' at-picker-result--external' : '';
      var metaText = isExternal
        ? 'Add from Yahoo Finance'
        : (item.sector ? (item.asset_class || '') + ' · ' + item.sector : (item.asset_class || ''));
      return '<div class="at-result-row' + externalCls + '" '
        + 'data-type="' + escapeHtml(item.type || 'instrument') + '" '
        + 'data-source="' + escapeHtml(item.source || 'db') + '" '
        + 'data-id="' + escapeHtml(item.id) + '" '
        + 'data-name="' + escapeHtml(item.name) + '" '
        + (item.value != null ? 'data-value="' + item.value + '" ' : '')
        + (item.chg != null ? 'data-chg="' + item.chg + '" ' : '')
        + '>'
        + '<span class="at-result-name">' + escapeHtml(item.name) + '</span>'
        + '<span class="at-result-id">' + escapeHtml(item.id) + '</span>'
        + '<span class="at-picker-result-meta">' + escapeHtml(metaText) + '</span>'
        + (item.value != null ? '<span class="at-result-value">' + Number(item.value).toFixed(2) + '</span><span class="at-result-chg ' + chgClass + '">' + chgStr + '</span>' : '')
        + '</div>';
    },

    _topicRowHtml: function (item) {
      return '<div class="at-result-row" '
        + 'data-type="topic" '
        + 'data-id="' + escapeHtml(item.id) + '" '
        + 'data-name="' + escapeHtml(item.name) + '">'
        + '<span class="at-result-name">' + escapeHtml(item.name) + '</span>'
        + '<span class="at-result-count">' + (item.count != null ? item.count : 0) + ' articles</span>'
        + '</div>';
    },

    _chartRowHtml: function (item) {
      return '<div class="at-flow-chart-row" '
        + 'data-chart-type="' + escapeHtml(item.chartType) + '" '
        + 'data-label="' + escapeHtml(item.label) + '" '
        + 'data-x="' + escapeHtml(item.x || '') + '" '
        + 'data-y="' + escapeHtml(item.y || '') + '" '
        + 'data-instruments="' + escapeHtml(item.instruments || '') + '">'
        + '<span class="at-flow-chart-name">' + escapeHtml(item.label) + '</span>'
        + '<span class="at-flow-chart-sub">' + escapeHtml(item.sub || '') + '</span>'
        + '</div>';
    },

    renderFlow: function (config) {
      this.isOpen = true;
      var existing = document.getElementById('at-picker-dropdown');

      var self = this;
      var el = document.createElement('div');
      el.className = 'at-picker-dropdown at-picker-dropdown--flow';
      el.id = 'at-picker-dropdown-next';
      el.setAttribute('tabindex', '-1');

      var sel = window.getSelection();
      var top, left;
      if (sel && sel.rangeCount) {
        var rect = sel.getRangeAt(0).getBoundingClientRect();
        top = rect.bottom + 4;
        left = Math.min(rect.left, window.innerWidth - 320);
      } else if (this.anchorEl) {
        var aRect = this.anchorEl.getBoundingClientRect();
        top = aRect.bottom + 4;
        left = Math.min(aRect.left, window.innerWidth - 320);
      } else {
        top = 200;
        left = 200;
      }
      el.style.cssText = 'position:fixed;top:' + top + 'px;left:' + left + 'px;z-index:10000;';

      var html = '<div class="at-flow-header">'
        + '<button class="at-flow-back-btn" type="button" id="at-flow-back-btn">&larr;</button>'
        + '<span class="at-flow-header-text">' + escapeHtml(config.header || '') + '</span>'
        + '</div>';

      if (config.showSearch) {
        html += '<div class="at-flow-search-wrap">'
          + '<input type="text" class="at-flow-search-input" id="at-flow-search-input" '
          + 'placeholder="' + escapeHtml(config.searchPlaceholder || 'Search...') + '" autocomplete="off" />'
          + '</div>';
      }

      (config.groups || []).forEach(function (group) {
        if (!group.items || group.items.length === 0) return;
        html += '<div class="at-group-label">' + escapeHtml(group.label) + '</div>';
        group.items.forEach(function (item) {
          if (group.isChart) {
            html += AtPicker._chartRowHtml(item);
          } else {
            html += AtPicker._instrumentRowHtml(item);
          }
        });
      });

      var hasItems = (config.groups || []).some(function (g) {
        return g.items && g.items.length > 0;
      });
      if (!hasItems) {
        html += '<div class="at-empty">No results</div>';
      }

      el.innerHTML = html;
      document.body.appendChild(el);
      if (existing) existing.remove();
      el.id = 'at-picker-dropdown';
      el.focus();

      var searchInput = el.querySelector('#at-flow-search-input');
      if (searchInput) {
        var currentQuery = (typeof AtPickerFlow !== 'undefined' && AtPickerFlow && AtPickerFlow._lastSearchQuery)
          ? String(AtPickerFlow._lastSearchQuery)
          : '';
        if (currentQuery) {
          searchInput.value = currentQuery;
          searchInput.setSelectionRange(currentQuery.length, currentQuery.length);
        }
        searchInput.focus();
        searchInput.addEventListener('input', function () {
          var q = searchInput.value.trim();
          if (typeof AtPickerFlow !== 'undefined' && AtPickerFlow) AtPickerFlow._lastSearchQuery = q;
          if (config.onSearch) config.onSearch(q);
        });
        searchInput.addEventListener('keydown', function (e) {
          if (e.key === 'Escape') {
            e.preventDefault();
            AtPickerFlow.handleEscape();
          }
          if (e.key === 'Tab') {
            e.preventDefault();
            var first = el.querySelector('.at-result-row, .at-flow-chart-row');
            if (first) first.click();
          }
        });
      }

      var backBtn = el.querySelector('#at-flow-back-btn');
      if (backBtn) {
        backBtn.addEventListener('click', function (e) {
          e.preventDefault();
          e.stopPropagation();
          AtPicker._ignoreNextOutsideClick = true;
          setTimeout(function () { if (config.onBack) config.onBack(); }, 0);
        });
      }

      el.querySelectorAll('.at-result-row').forEach(function (row) {
        row.addEventListener('click', function (e) {
          e.preventDefault();
          e.stopPropagation();
          AtPicker._ignoreNextOutsideClick = true;
          var payload = {
            type: row.dataset.type,
            id: row.dataset.id,
            name: row.dataset.name,
            value: row.dataset.value ? parseFloat(row.dataset.value) : null,
            chg: row.dataset.chg ? parseFloat(row.dataset.chg) : null
          };
          setTimeout(function () {
            if (config.onSelect) config.onSelect(payload);
          }, 0);
        });
      });
      el.querySelectorAll('.at-flow-chart-row').forEach(function (row) {
        row.addEventListener('click', function (e) {
          e.preventDefault();
          e.stopPropagation();
          AtPicker._ignoreNextOutsideClick = true;
          var payload = {
            chartType: row.dataset.chartType,
            label: row.dataset.label,
            x: row.dataset.x || '',
            y: row.dataset.y || '',
            instruments: row.dataset.instruments || ''
          };
          setTimeout(function () {
            if (config.onSelect) config.onSelect(payload);
          }, 0);
        });
      });

      el.addEventListener('mousedown', function (e) {
        e.preventDefault();
        e.stopPropagation();
        if (e.target.closest('.at-result-row, .at-flow-chart-row, #at-flow-back-btn, #at-flow-insert-chart-btn')) {
          AtPicker._ignoreNextOutsideClick = true;
        }
      });

      if (!AtPicker._outsideClickBound) {
        AtPicker._outsideClickBound = true;
        document.addEventListener('click', function globalOutsideClick (e) {
          if (!AtPicker.isOpen) return;
          if (AtPicker._ignoreNextOutsideClick) {
            AtPicker._ignoreNextOutsideClick = false;
            return;
          }
          if (!document.contains(e.target)) return;
          var dd = document.getElementById('at-picker-dropdown');
          if (!dd || !dd.contains(e.target)) {
            AtPicker.close();
          }
        });
      }
    },

    renderStep0: function () {
      this.isOpen = true;
      var existing = document.getElementById('at-picker-dropdown');
      if (existing) existing.remove();

      var self = this;
      var el = document.createElement('div');
      el.className = 'at-picker-dropdown';
      el.id = 'at-picker-dropdown';

      var sel = window.getSelection();
      var top, left;
      if (sel && sel.rangeCount) {
        var rect = sel.getRangeAt(0).getBoundingClientRect();
        top = rect.bottom + 4;
        left = Math.min(rect.left, window.innerWidth - 320);
      } else if (this.anchorEl) {
        var aRect = this.anchorEl.getBoundingClientRect();
        top = aRect.bottom + 4;
        left = Math.min(aRect.left, window.innerWidth - 320);
      } else {
        top = 200;
        left = 200;
      }
      el.style.cssText = 'position:fixed;top:' + top + 'px;left:' + left + 'px;z-index:10000;';

      var results = this.getResults(this.query || '');
      var html = '<div class="at-flow-insert-chart-btn-wrap">'
        + '<button class="at-flow-insert-chart-btn" type="button" id="at-flow-insert-chart-btn">+ Insert chart</button>'
        + '</div>';

      if (results.instruments && results.instruments.length) {
        html += '<div class="at-group-label">INSTRUMENTS</div>';
        results.instruments.forEach(function (item) {
          html += AtPicker._instrumentRowHtml(item);
        });
      }
      if (results.topics && results.topics.length) {
        html += '<div class="at-group-label">SIGNALS</div>';
        results.topics.forEach(function (item) {
          html += AtPicker._topicRowHtml(item);
        });
      }
      if (!(results.instruments && results.instruments.length) && !(results.topics && results.topics.length)) {
        html += '<div class="at-empty">Type to search...</div>';
      }

      el.innerHTML = html;
      document.body.appendChild(el);

      el.querySelector('#at-flow-insert-chart-btn') && el.querySelector('#at-flow-insert-chart-btn').addEventListener('click', function (e) {
        e.preventDefault();
        e.stopPropagation();
        AtPicker._ignoreNextOutsideClick = true;
        setTimeout(function () { AtPickerFlow.startChartFlow(); }, 0);
      });

      el.querySelectorAll('.at-result-row').forEach(function (row) {
        row.addEventListener('click', function (e) {
          e.preventDefault();
          e.stopPropagation();
          AtPicker._ignoreNextOutsideClick = true;
          self.select({
            type: row.dataset.type,
            id: row.dataset.id,
            name: row.dataset.name
          });
        });
      });

      el.addEventListener('mousedown', function (e) {
        e.preventDefault();
        e.stopPropagation();
        if (e.target.closest('.at-result-row, #at-flow-insert-chart-btn')) {
          AtPicker._ignoreNextOutsideClick = true;
        }
      });

      if (!AtPicker._outsideClickBound) {
        AtPicker._outsideClickBound = true;
        document.addEventListener('click', function globalOutsideClick (e) {
          if (!AtPicker.isOpen) return;
          if (AtPicker._ignoreNextOutsideClick) {
            AtPicker._ignoreNextOutsideClick = false;
            return;
          }
          if (!document.contains(e.target)) return;
          var dd = document.getElementById('at-picker-dropdown');
          if (!dd || !dd.contains(e.target)) {
            AtPicker.close();
          }
        });
      }
    }
  };
  window.AtPicker = AtPicker;

  var AtPickerFlow = {
    step: 0,
    xInstrument: null,
    yInstrument: null,
    active: false,

    startChartFlow: function () {
      this.step = 1;
      this.xInstrument = null;
      this.yInstrument = null;
      this.active = true;
      AtPicker.renderFlow(this.buildStep1());
    },

    buildStep1: function () {
      return {
        step: 1,
        header: 'Select X instrument',
        showSearch: true,
        searchPlaceholder: 'Search instruments...',
        groups: AtPickerFlow._instrumentGroups(''),
        onSelect: function (item) {
          AtPickerFlow.xInstrument = item;
          AtPickerFlow.step = 2;
          AtPicker.renderFlow(AtPickerFlow.buildStep2());
        },
        onBack: function () {
          AtPickerFlow.active = false;
          AtPickerFlow.step = 0;
          AtPicker.renderStep0();
        },
        onSearch: function (query) {
          AtPicker.renderFlow({
            step: 1,
            header: 'Select X instrument',
            showSearch: true,
            searchPlaceholder: 'Search instruments...',
            groups: AtPickerFlow._instrumentGroups(query),
            onSelect: AtPickerFlow.buildStep1().onSelect,
            onBack: AtPickerFlow.buildStep1().onBack,
            onSearch: AtPickerFlow.buildStep1().onSearch
          });
        }
      };
    },

    buildStep2: function () {
      var x = AtPickerFlow.xInstrument;
      return {
        step: 2,
        header: x.name + ' →  Select Y',
        showSearch: true,
        searchPlaceholder: 'Search instruments...',
        groups: AtPickerFlow._instrumentGroups('', x.id),
        onSelect: function (item) {
          AtPickerFlow.yInstrument = item;
          AtPickerFlow.step = 3;
          AtPicker.renderFlow(AtPickerFlow.buildStep3());
        },
        onBack: function () {
          AtPickerFlow.xInstrument = null;
          AtPickerFlow.step = 1;
          AtPicker.renderFlow(AtPickerFlow.buildStep1());
        },
        onSearch: function (query) {
          AtPicker.renderFlow({
            step: 2,
            header: x.name + ' →  Select Y',
            showSearch: true,
            searchPlaceholder: 'Search instruments...',
            groups: AtPickerFlow._instrumentGroups(query, x.id),
            onSelect: AtPickerFlow.buildStep2().onSelect,
            onBack: AtPickerFlow.buildStep2().onBack,
            onSearch: AtPickerFlow.buildStep2().onSearch
          });
        }
      };
    },

    buildStep3: function () {
      var x = AtPickerFlow.xInstrument;
      var y = AtPickerFlow.yInstrument;
      return {
        step: 3,
        header: x.name + ' → ' + y.name,
        showSearch: true,
        searchPlaceholder: 'Search chart types...',
        groups: AtPickerFlow._chartGroups('', x, y),
        onSelect: function (item) {
          AtPickerFlow.active = false;
          AtPickerFlow.step = 0;
          AtPicker.close();
          if (typeof ResearchV2 !== 'undefined') {
            ResearchV2.insertChartEmbedFromPicker({
              type: 'chart',
              chartType: item.chartType,
              x: item.x,
              y: item.y,
              period: 90,
              shockPct: 10,
              instruments: item.instruments || '',
              label: item.label
            });
          }
        },
        onBack: function () {
          AtPickerFlow.yInstrument = null;
          AtPickerFlow.step = 2;
          AtPicker.renderFlow(AtPickerFlow.buildStep2());
        },
        onSearch: function (query) {
          AtPicker.renderFlow({
            step: 3,
            header: x.name + ' → ' + y.name,
            showSearch: true,
            searchPlaceholder: 'Search chart types...',
            groups: AtPickerFlow._chartGroups(query, x, y),
            onSelect: AtPickerFlow.buildStep3().onSelect,
            onBack: AtPickerFlow.buildStep3().onBack,
            onSearch: AtPickerFlow.buildStep3().onSearch
          });
        }
      };
    },

    handleEscape: function () {
      if (!this.active) {
        AtPicker.close();
        return;
      }
      if (this.step === 3) {
        this.yInstrument = null;
        this.step = 2;
        AtPicker.renderFlow(this.buildStep2());
      } else if (this.step === 2) {
        this.xInstrument = null;
        this.step = 1;
        AtPicker.renderFlow(this.buildStep1());
      } else {
        this.active = false;
        this.step = 0;
        AtPicker.close();
      }
    },

    _instrumentGroups: function (query, excludeId) {
      var q = (query || '').toLowerCase();
      var all = (STATE.universe || []).filter(function (inst) {
        if (excludeId && inst.id === excludeId) return false;
        if (!q) return true;
        return (inst.name || '').toLowerCase().includes(q) || (inst.id || '').toLowerCase().includes(q);
      });
      var instruments;
      if (!q) {
        var byClass = {};
        all.forEach(function (inst) {
          var cls = inst.asset_class || inst.type || 'other';
          if (!byClass[cls]) byClass[cls] = [];
          if (byClass[cls].length < 2) byClass[cls].push(inst);
        });
        instruments = Object.keys(byClass).reduce(function (acc, k) { return acc.concat(byClass[k]); }, []).slice(0, 10);
      } else {
        instruments = all.slice(0, 10);
      }
      var items = instruments.map(function (inst) {
        var price = (STATE.latestPrices || {})[inst.id];
        return {
          type: 'instrument',
          id: inst.id,
          name: inst.name || inst.id,
          value: price != null && price.value != null ? price.value : null,
          chg: price != null && price.pct_chg != null ? price.pct_chg : null
        };
      });
      return items.length > 0 ? [{ label: 'INSTRUMENTS', items: items }] : [];
    },

    _chartGroups: function (query, x, y) {
      var q = (query || '').toLowerCase();
      var charts = [
        { chartType: 'overlaid', label: x.name + ' vs ' + y.name + ' — Overlaid', sub: 'X vs Y normalised', x: x.id, y: y.id, instruments: x.id + ',' + y.id },
        { chartType: 'impact', label: 'Impact: ' + x.name + ' → ' + y.name, sub: 'If X moves, Y moves by...', x: x.id, y: y.id, instruments: '' },
        { chartType: 'forecast', label: y.name + ' — 30D Forecast', sub: 'ARIMA projection', x: '', y: y.id, instruments: '' },
        { chartType: 'factors', label: 'What drives ' + y.name, sub: 'Factor decomposition', x: '', y: y.id, instruments: '' },
        { chartType: 'correlation', label: 'Correlation Matrix', sub: x.name + ', ' + y.name + ' + others', x: '', y: '', instruments: x.id + ',' + y.id },
        { chartType: 'volatility', label: y.name + ' — Volatility', sub: 'GARCH volatility', x: '', y: y.id, instruments: '' },
        { chartType: 'regime', label: 'Regime Fingerprint', sub: 'Current market state', x: '', y: '', instruments: '' }
      ];
      var filtered = q ? charts.filter(function (c) {
        return (c.label || '').toLowerCase().includes(q) || (c.sub || '').toLowerCase().includes(q) || (c.chartType || '').toLowerCase().includes(q);
      }) : charts;
      return filtered.length > 0 ? [{ label: 'CHARTS', items: filtered, isChart: true }] : [];
    }
  };
  window.AtPickerFlow = AtPickerFlow;

  /*
   * D2 Audit (Phase D2 Chart Settings Panel — Spec 6):
   * - Board UI removed (Spec 14); chart settings/impact use thesis embed contexts only.
   * - Settings button (thesis embed): app.js buildEmbedShell() line ~3111, class .chart-embed-settings; wired in wireEmbedButtons() ~3516.
   * - Current Settings click (embed): openEmbedSettingsPopover(btn, embedEl) — period/shock popover; D2 replaces with inline panel for overlaid/forecast.
   * - Chart series on board card: card.data (object with .series key for overlaid); no customSeries yet — D2 adds card.customSeries and card.timeRange.
   * - Embed metadata: embedEl.dataset (embedId, type, x, y, period, shockPct, instruments, width, height); serialised via getThesisHtmlForSave() (clone innerHTML). D2 adds customSeries, timeRangeFrom, timeRangeTo, timeRangePreset.
   * - Instrument list for @ picker: STATE.universe (array of { id, name, asset_class }); AtPicker getResults() uses it.
   * - CSS variables present: --bg-primary, --bg-secondary, --bg-tertiary, --text-primary, --text-secondary, --text-muted, --teal, --orange, --accent (var(--teal)), --border. D2 adds --surface-2/3/4, --border-subtle, --text-tertiary in styles.css.
   */

  const EXTRA_SERIES_COLORS = ['#7B61FF', '#FF6B6B', '#F7C948', '#4ECDC4', '#A8E6CF'];

  async function fetchPriceSeries(ids, fromDate, toDate) {
    var from = fromDate || (function () {
      var d = new Date();
      d.setFullYear(d.getFullYear() - 1);
      return d.toISOString().split('T')[0];
    }());
    var to = toDate || new Date().toISOString().split('T')[0];
    var res = await fetch(CONFIG.API_BASE + '/api/price-series?ids=' + (Array.isArray(ids) ? ids.join(',') : ids) + '&from=' + from + '&to=' + to);
    if (!res.ok) throw new Error('price-series fetch failed: ' + res.status);
    var arr = await res.json();
    var map = {};
    for (var i = 0; i < arr.length; i++) map[arr[i].id] = arr[i];
    return map;
  }

  var _factorDecompositionCache = {};
  async function fetchFactorDecomposition(instrumentId) {
    if (_factorDecompositionCache[instrumentId]) return _factorDecompositionCache[instrumentId];
    var res = await fetch(CONFIG.API_BASE + '/api/factors?instrument=' + encodeURIComponent(instrumentId));
    if (!res.ok) throw new Error('factors fetch failed: ' + res.status);
    var data = await res.json();
    if (!data.error) _factorDecompositionCache[instrumentId] = data;
    return data;
  }

  var _factorMap = null;
  async function getFactorMap() {
    if (_factorMap) return _factorMap;
    var res = await fetch(CONFIG.API_BASE + '/api/factor-map');
    if (!res.ok) throw new Error('factor-map fetch failed: ' + res.status);
    _factorMap = await res.json();
    return _factorMap;
  }
  async function getInstrumentFactor(instrumentId) {
    var map = await getFactorMap();
    return map[instrumentId] || null;
  }
  if (typeof window !== 'undefined') {
    window.fetchPriceSeries = fetchPriceSeries;
    window.fetchFactorDecomposition = fetchFactorDecomposition;
    window.getFactorMap = getFactorMap;
    window.getInstrumentFactor = getInstrumentFactor;
  }

  async function computeImpactForSeries(seriesId, shockRows) {
    var decomposition = await fetchFactorDecomposition(seriesId);
    if (decomposition.error) return { seriesId: seriesId, error: decomposition.error };
    var totalImpactPct = 0;
    var worstResidualStdErr = 0;
    var bestR2 = 0;
    for (var r = 0; r < shockRows.length; r++) {
      var row = shockRows[r];
      var shockedId = row.dataset.selectedId;
      var pctInput = row.querySelector('.chart-impact-shock-pct');
      var shockPct = pctInput ? parseFloat(pctInput.value) : 0;
      if (!shockedId || isNaN(shockPct) || shockPct === 0) continue;
      var factorId = await getInstrumentFactor(shockedId);
      if (!factorId) continue;
      var factor = (decomposition.factors || []).find(function (f) { return f.id === factorId; });
      if (!factor) continue;
      totalImpactPct += (shockPct / 100) * factor.beta;
      worstResidualStdErr = Math.max(worstResidualStdErr, factor.residual_std_error || 0);
      bestR2 = Math.max(bestR2, factor.r2 || 0);
    }
    return { seriesId: seriesId, totalImpactPct: totalImpactPct, residualStdErr: worstResidualStdErr, bestR2: bestR2 };
  }

  function buildForwardOverlayPoints(seriesData, impactResult) {
    var dates = seriesData.dates || [];
    var values = seriesData.values || [];
    if (dates.length === 0 || values.length === 0) return [];
    var lastDate = new Date(dates[dates.length - 1]);
    var lastPrice = values[values.length - 1];
    var targetPrice = lastPrice * (1 + impactResult.totalImpactPct);
    var se = impactResult.residualStdErr || 0;
    var upperPrice = lastPrice * (1 + impactResult.totalImpactPct + se);
    var lowerPrice = lastPrice * (1 + impactResult.totalImpactPct - se);
    var points = [];
    for (var i = 0; i <= 30; i++) {
      var d = new Date(lastDate);
      d.setDate(d.getDate() + i);
      var t = i / 30;
      points.push({
        date: d,
        value: lastPrice + t * (targetPrice - lastPrice),
        upper: lastPrice + t * (upperPrice - lastPrice),
        lower: lastPrice + t * (lowerPrice - lastPrice)
      });
    }
    return points;
  }

  async function buildCounterfactualPoints(targetSeriesData, shocks, decomposition) {
    var shockHistories = {};
    for (var s = 0; s < shocks.length; s++) {
      var shock = shocks[s];
      var fromDate = targetSeriesData.dates[0];
      var toDate = targetSeriesData.dates[targetSeriesData.dates.length - 1];
      var result = await fetchPriceSeries([shock.instrumentId], fromDate, toDate);
      shockHistories[shock.instrumentId] = result[shock.instrumentId];
    }
    var counterfactualValues = [];
    var dates = targetSeriesData.dates;
    var actualValues = targetSeriesData.values;
    for (var i = 0; i < dates.length; i++) {
      var date = dates[i];
      var dateStr = (date && (date.toISOString || date)) ? (typeof date === 'string' ? date : date.toISOString().split('T')[0]) : String(date).slice(0, 10);
      var actualPrice = actualValues[i];
      var additionalReturn = 0;
      for (var s = 0; s < shocks.length; s++) {
        var shock = shocks[s];
        var factorId = await getInstrumentFactor(shock.instrumentId);
        var factor = (decomposition.factors || []).find(function (f) { return f.id === factorId; });
        if (!factor) continue;
        var hist = shockHistories[shock.instrumentId];
        if (!hist || hist.error) continue;
        var hDates = hist.dates || [];
        var idx = -1;
        for (var k = 0; k < hDates.length; k++) {
          var hd = (hDates[k] && (hDates[k].toISOString || hDates[k])) ? (typeof hDates[k] === 'string' ? hDates[k] : hDates[k].toISOString().split('T')[0]) : String(hDates[k]).slice(0, 10);
          if (hd === dateStr) { idx = k; break; }
        }
        if (idx <= 0) continue;
        var prevVal = (hist.values || [])[idx - 1];
        var currVal = (hist.values || [])[idx];
        if (prevVal == null || currVal == null || prevVal === 0) continue;
        var dailyReturn = (currVal - prevVal) / prevVal;
        additionalReturn += (shock.shockPct / 100) * factor.beta;
      }
      counterfactualValues.push(actualPrice * (1 + additionalReturn));
    }
    return { dates: dates, values: counterfactualValues };
  }

  function removeImpactOverlays(container) {
    if (!container) return;
    container.querySelectorAll('.chart-impact-overlay').forEach(function (el) { el.remove(); });
  }

  async function rehydrateImpactOverlay(chartContainerEl, seriesList, shocks, impactMode, getSeriesData, getDecomposition) {
    if (!shocks || shocks.length === 0 || !impactMode) return;
    var fakeRows = shocks.map(function (s) {
      return {
        dataset: { selectedId: s.instrumentId },
        querySelector: function () { return { value: String(s.shockPct) }; }
      };
    });
    var impactResults = {};
    for (var i = 0; i < seriesList.length; i++) {
      var ent = seriesList[i];
      var decomposition = await getDecomposition(ent.id);
      if (!decomposition || decomposition.error) continue;
      var impactResult = await computeImpactForSeries(ent.id, fakeRows);
      if (!impactResult || impactResult.error) continue;
      impactResults[ent.id] = impactResult;
    }
    if (impactMode === 'forward') {
      renderForwardOverlay(chartContainerEl, seriesList, impactResults, getSeriesData);
    } else if (impactMode === 'counterfactual') {
      renderCounterfactualOverlay(chartContainerEl, seriesList, shocks, getSeriesData, getDecomposition);
    }
  }

  var OVERLAY_WARNING = '#F7C948';
  var OVERLAY_BORDER_SUBTLE = 'var(--border-subtle)';
  function getOverlayBorderSubtle() {
    if (typeof document === 'undefined' || !document.documentElement) return '#e2e8f0';
    var v = getComputedStyle(document.documentElement).getPropertyValue('--border-subtle').trim();
    return v || '#e2e8f0';
  }

  function renderForwardOverlay(container, seriesList, impactResults, getSeriesData) {
    var svg = container && container.querySelector ? container.querySelector('svg') : null;
    if (!svg) return;
    var vb = (svg.getAttribute('viewBox') || '').split(/\s+/);
    var w = vb.length >= 4 ? parseFloat(vb[2]) : (container.offsetWidth || 500);
    var h = vb.length >= 4 ? parseFloat(vb[3]) : 220;
    var margins = { top: 20, right: 80, bottom: 28, left: 44 };
    var innerW = w - margins.left - margins.right;
    var innerH = h - margins.top - margins.bottom;
    var minNorm = 80;
    var maxNorm = 120;
    function yScaleNorm(norm) { return margins.top + innerH - (norm - minNorm) / (maxNorm - minNorm) * innerH; }
    var nData = 0;
    var lastDateX = 0;
    var ns = svg.namespaceURI || 'http://www.w3.org/2000/svg';
    for (var s = 0; s < seriesList.length; s++) {
      var ent = seriesList[s];
      var sd = getSeriesData(ent.id);
      if (!sd || !sd.dates || !sd.values || sd.values.length === 0) continue;
      nData = sd.dates.length;
      var res = impactResults[ent.id];
      if (!res || res.error) continue;
      var v0 = null;
      for (var vi = 0; vi < sd.values.length; vi++) { if (sd.values[vi] != null) { v0 = sd.values[vi]; break; } }
      if (v0 == null || v0 === 0) continue;
      var points = buildForwardOverlayPoints(sd, res);
      if (points.length === 0) continue;
      var totalLen = nData + 30;
      function xScaleExt(i) { return margins.left + (i / (totalLen - 1)) * innerW; }
      lastDateX = xScaleExt(nData - 1);
      var bandPath = '';
      var linePath = '';
      for (var i = 0; i < points.length; i++) {
        var idx = nData - 1 + i;
        var x = xScaleExt(idx);
        var normV = (points[i].value / v0) * 100;
        var normU = (points[i].upper / v0) * 100;
        var normL = (points[i].lower / v0) * 100;
        var yV = yScaleNorm(Math.max(minNorm, Math.min(maxNorm, normV)));
        var yU = yScaleNorm(Math.max(minNorm, Math.min(maxNorm, normU)));
        var yL = yScaleNorm(Math.max(minNorm, Math.min(maxNorm, normL)));
        if (i === 0) {
          bandPath = 'M ' + x + ' ' + yU + ' L ' + x + ' ' + yL;
          linePath = 'M ' + x + ' ' + yV;
        } else {
          bandPath += ' L ' + x + ' ' + yL;
          linePath += ' L ' + x + ' ' + yV;
        }
      }
      for (var j = points.length - 1; j >= 0; j--) {
        var idx2 = nData - 1 + j;
        var x2 = xScaleExt(idx2);
        var normU2 = (points[j].upper / v0) * 100;
        bandPath += ' L ' + x2 + ' ' + yScaleNorm(Math.max(minNorm, Math.min(maxNorm, normU2)));
      }
      bandPath += ' Z';
      var band = document.createElementNS(ns, 'path');
      band.setAttribute('class', 'chart-impact-overlay chart-impact-overlay-band');
      band.setAttribute('d', bandPath);
      band.setAttribute('fill', OVERLAY_WARNING);
      band.setAttribute('fill-opacity', '0.10');
      band.setAttribute('stroke', 'none');
      svg.appendChild(band);
      var line = document.createElementNS(ns, 'path');
      line.setAttribute('class', 'chart-impact-overlay chart-impact-overlay-line');
      line.setAttribute('d', linePath);
      line.setAttribute('stroke', OVERLAY_WARNING);
      line.setAttribute('stroke-width', '1.5');
      line.setAttribute('stroke-dasharray', '4,3');
      line.setAttribute('fill', 'none');
      svg.appendChild(line);
      var anchor = document.createElementNS(ns, 'circle');
      anchor.setAttribute('class', 'chart-impact-overlay');
      anchor.setAttribute('r', '3');
      anchor.setAttribute('fill', OVERLAY_WARNING);
      anchor.setAttribute('cx', String(lastDateX));
      anchor.setAttribute('cy', String(yScaleNorm((points[0].value / v0) * 100)));
      svg.appendChild(anchor);
    }
    if (nData > 0) {
      var totalLen = nData + 30;
      function xScaleExt(i) { return margins.left + (i / (totalLen - 1)) * innerW; }
      var todayX = xScaleExt(nData - 1);
      var todayLine = document.createElementNS(ns, 'line');
      todayLine.setAttribute('class', 'chart-impact-overlay chart-impact-overlay-today');
      todayLine.setAttribute('x1', String(todayX));
      todayLine.setAttribute('x2', String(todayX));
      todayLine.setAttribute('y1', String(margins.top));
      todayLine.setAttribute('y2', String(h - margins.bottom));
      todayLine.setAttribute('stroke', getOverlayBorderSubtle());
      todayLine.setAttribute('stroke-dasharray', '2,2');
      todayLine.setAttribute('stroke-width', '1');
      svg.appendChild(todayLine);
    }
  }

  async function renderCounterfactualOverlay(container, seriesList, shocks, getSeriesData, getDecomposition) {
    if (!shocks || shocks.length === 0) return;
    var svg = container && container.querySelector ? container.querySelector('svg') : null;
    if (!svg) return;
    var vb = (svg.getAttribute('viewBox') || '').split(/\s+/);
    var w = vb.length >= 4 ? parseFloat(vb[2]) : (container.offsetWidth || 500);
    var h = vb.length >= 4 ? parseFloat(vb[3]) : 220;
    var margins = { top: 20, right: 80, bottom: 28, left: 44 };
    var innerW = w - margins.left - margins.right;
    var innerH = h - margins.top - margins.bottom;
    var minNorm = 80;
    var maxNorm = 120;
    function yScaleNorm(norm) { return margins.top + innerH - (norm - minNorm) / (maxNorm - minNorm) * innerH; }
    var ns = svg.namespaceURI || 'http://www.w3.org/2000/svg';
    for (var s = 0; s < seriesList.length; s++) {
      var ent = seriesList[s];
      var sd = getSeriesData(ent.id);
      if (!sd || !sd.dates || !sd.values) continue;
      var decomp = await getDecomposition(ent.id);
      if (!decomp || decomp.error) continue;
      var cf = await buildCounterfactualPoints(sd, shocks, decomp);
      var v0 = null;
      for (var vi = 0; vi < sd.values.length; vi++) { if (sd.values[vi] != null) { v0 = sd.values[vi]; break; } }
      if (v0 == null || v0 === 0) continue;
      var path = '';
      for (var i = 0; i < cf.dates.length; i++) {
        var norm = (cf.values[i] / v0) * 100;
        var x = margins.left + (i / (cf.dates.length - 1 || 1)) * innerW;
        var y = yScaleNorm(Math.max(minNorm, Math.min(maxNorm, norm)));
        path += (path ? ' L ' : 'M ') + x + ' ' + y;
      }
      var pathEl = document.createElementNS(ns, 'path');
      pathEl.setAttribute('class', 'chart-impact-overlay chart-impact-overlay-counterfactual');
      pathEl.setAttribute('d', path);
      pathEl.setAttribute('stroke', OVERLAY_WARNING);
      pathEl.setAttribute('stroke-width', '1.5');
      pathEl.setAttribute('stroke-dasharray', '4,3');
      pathEl.setAttribute('fill', 'none');
      svg.appendChild(pathEl);
    }
  }

  // ——— C1: Standalone chart/embed render functions (SIGNAL Thesis Chart Embeds) ———
  function renderOverlaidSVG(seriesData, xId, yId, width, height, xName, yName, correlationText) {
    var seriesById = (seriesData && seriesData.series) || {};
    var rawX = seriesById[xId];
    var rawY = seriesById[yId];
    if (!rawX && Array.isArray(seriesData.series)) {
      var sx = seriesData.series.find(function (s) { return (s.series_id || s.id) === xId; });
      rawX = sx && (sx.data || sx.points || sx.values) ? (sx.data || sx.points || sx.values) : sx;
    }
    if (!rawY && Array.isArray(seriesData.series)) {
      var sy = seriesData.series.find(function (s) { return (s.series_id || s.id) === yId; });
      rawY = sy && (sy.data || sy.points || sy.values) ? (sy.data || sy.points || sy.values) : sy;
    }
    var arrX = (Array.isArray(rawX) ? rawX : []).map(function (d) { return d.value != null ? Number(d.value) : null; });
    var arrY = (Array.isArray(rawY) ? rawY : []).map(function (d) { return d.value != null ? Number(d.value) : null; });
    var dates = (Array.isArray(rawX) ? rawX : []).map(function (d) { return d.date; });
    var normX = [];
    var normY = [];
    if (arrX.length && arrY.length && arrX[0] != null && arrY[0] != null) {
      var v0x = arrX[0];
      var v0y = arrY[0];
      for (var i = 0; i < Math.min(arrX.length, arrY.length, dates.length); i++) {
        normX.push((arrX[i] != null && v0x) ? (arrX[i] / v0x) * 100 : null);
        normY.push((arrY[i] != null && v0y) ? (arrY[i] / v0y) * 100 : null);
      }
    }
    var w = width || 500;
    var h = height || 220;
    var margins = { top: 20, right: 80, bottom: 28, left: 44 };
    var innerW = w - margins.left - margins.right;
    var innerH = h - margins.top - margins.bottom;
    var minNorm = 80;
    var maxNorm = 120;
    var yScale = function (v) { return margins.top + innerH - (v - minNorm) / (maxNorm - minNorm) * innerH; };
    var xScale = function (i) { return margins.left + (i / (normX.length - 1 || 1)) * innerW; };
    var pathX = '';
    var pathY = '';
    for (var i = 0; i < normX.length; i++) {
      if (normX[i] != null) pathX += (pathX ? ' L ' : 'M ') + xScale(i) + ' ' + yScale(normX[i]);
      if (normY[i] != null) pathY += (pathY ? ' L ' : 'M ') + xScale(i) + ' ' + yScale(normY[i]);
    }
    if (normX.length === 0) return '<p class="canvas-loading">No series data for selected instruments.</p>';
    var axisLabels = '';
    var stepAmount = Math.max(1, Math.floor(dates.length / 6));
    for (var step = 0; step < dates.length; step += stepAmount) {
      if (dates[step]) axisLabels += '<text x="' + xScale(step) + '" y="' + (h - 4) + '" text-anchor="middle" font-size="9" fill="#94a3b8">' + (dates[step].toString().slice(0, 10)) + '</text>';
    }
    var xLabel = (xName != null && xName !== '') ? xName : xId;
    var yLabel = (yName != null && yName !== '') ? yName : yId;
    var svgStr = '<svg viewBox="0 0 ' + w + ' ' + h + '" width="' + w + '" height="' + h + '" style="max-width:100%;display:block"><rect width="' + w + '" height="' + h + '" fill="#fff"/>' + (pathX ? '<path d="' + pathX + '" fill="none" stroke="#0d9488" stroke-width="2"/>' : '') + (pathY ? '<path d="' + pathY + '" fill="none" stroke="#f97316" stroke-width="2"/>' : '') + '<line x1="' + margins.left + '" y1="' + margins.top + '" x2="' + margins.left + '" y2="' + (h - margins.bottom) + '" stroke="#e2e8f0"/><line x1="' + margins.left + '" y1="' + (h - margins.bottom) + '" x2="' + (w - margins.right) + '" y2="' + (h - margins.bottom) + '" stroke="#e2e8f0"/>' + axisLabels + '<text x="' + (w - margins.right - 4) + '" y="' + (margins.top + 12) + '" text-anchor="end" font-size="9" fill="#0d9488">' + escapeHtml(String(xLabel).slice(0, 20)) + '</text><text x="' + (w - margins.right - 4) + '" y="' + (margins.top + 24) + '" text-anchor="end" font-size="9" fill="#f97316">' + escapeHtml(String(yLabel).slice(0, 20)) + '</text></svg>';
    var strip = (correlationText != null && correlationText !== '') ? '<div class="analysis-correlation-sep" style="border-top:1px solid #e2e8f0;margin-top:10px;padding-top:8px"></div><p class="analysis-correlation-strip" style="margin-top:8px;font-size:11px;color:#64748b">' + escapeHtml(correlationText) + '</p>' : '';
    return svgStr + strip;
  }

  function renderOverlaidSVGMulti(seriesData, seriesList, width, height) {
    if (!seriesList || seriesList.length === 0) return '<p class="canvas-loading">No series</p>';
    var seriesById = (seriesData && seriesData.series) || {};
    var firstId = seriesList[0].id;
    var rawFirst = seriesById[firstId];
    var arrFirst = Array.isArray(rawFirst) ? rawFirst : (rawFirst && (rawFirst.data || rawFirst.values)) ? (rawFirst.data || rawFirst.values) : [];
    var dates = arrFirst.map(function (d) { return (d && d.date != null) ? String(d.date).slice(0, 10) : null; });
    var w = width || 500;
    var h = height || 220;
    var margins = { top: 20, right: 80, bottom: 28, left: 44 };
    var innerW = w - margins.left - margins.right;
    var innerH = h - margins.top - margins.bottom;
    var minNorm = 80;
    var maxNorm = 120;
    var yScale = function (v) { return margins.top + innerH - (v - minNorm) / (maxNorm - minNorm) * innerH; };
    var xScale = function (i) { return margins.left + (i / (dates.length - 1 || 1)) * innerW; };
    var paths = [];
    var labels = [];
    for (var s = 0; s < seriesList.length; s++) {
      var ent = seriesList[s];
      var raw = seriesById[ent.id];
      var arr = Array.isArray(raw) ? raw : (raw && (raw.data || raw.values)) ? (raw.data || raw.values) : [];
      var byDate = {};
      arr.forEach(function (d) {
        var k = (d && d.date != null) ? String(d.date).slice(0, 10) : '';
        if (k) byDate[k] = d.value != null ? Number(d.value) : null;
      });
      var vals = dates.map(function (d) { return byDate[d] != null ? byDate[d] : null; });
      var v0 = null;
      for (var i = 0; i < vals.length; i++) { if (vals[i] != null) { v0 = vals[i]; break; } }
      var norm = vals.map(function (v) { return (v != null && v0) ? (v / v0) * 100 : null; });
      var path = '';
      for (var i = 0; i < norm.length; i++) {
        if (norm[i] != null) path += (path ? ' L ' : 'M ') + xScale(i) + ' ' + yScale(norm[i]);
      }
      var color = ent.color || 'var(--teal)';
      if (color.indexOf('var(') !== -1 && document.documentElement) {
        var v = color.replace(/var\(([^)]+)\)/, '$1').trim();
        var res = getComputedStyle(document.documentElement).getPropertyValue(v).trim();
        if (res) color = res;
      }
      paths.push(path ? '<path d="' + path + '" fill="none" stroke="' + color + '" stroke-width="2"/>' : '');
      labels.push('<text x="' + (w - margins.right - 4) + '" y="' + (margins.top + 12 + s * 12) + '" text-anchor="end" font-size="9" fill="' + color + '">' + escapeHtml(String(ent.name || ent.id).slice(0, 20)) + '</text>');
    }
    if (dates.length === 0) return '<p class="canvas-loading">No series data</p>';
    var axisLabels = '';
    var stepAmount = Math.max(1, Math.floor(dates.length / 6));
    for (var step = 0; step < dates.length; step += stepAmount) {
      if (dates[step]) axisLabels += '<text x="' + xScale(step) + '" y="' + (h - 4) + '" text-anchor="middle" font-size="9" fill="#94a3b8">' + (dates[step].toString().slice(0, 10)) + '</text>';
    }
    var svgStr = '<svg viewBox="0 0 ' + w + ' ' + h + '" width="' + w + '" height="' + h + '" style="max-width:100%;display:block"><rect width="' + w + '" height="' + h + '" fill="#fff"/>' + paths.join('') + '<line x1="' + margins.left + '" y1="' + margins.top + '" x2="' + margins.left + '" y2="' + (h - margins.bottom) + '" stroke="#e2e8f0"/><line x1="' + margins.left + '" y1="' + (h - margins.bottom) + '" x2="' + (w - margins.right) + '" y2="' + (h - margins.bottom) + '" stroke="#e2e8f0"/>' + axisLabels + labels.join('') + '</svg>';
    return svgStr;
  }

  function renderForecastSVG(forecastData, width, height) {
    var hist = (forecastData && forecastData.history) ? forecastData.history.slice() : [];
    var arima = Array.isArray(forecastData && forecastData.arima_forecast) ? forecastData.arima_forecast : [];
    if (!hist.length) return '<p class="canvas-loading">No forecast data available.</p>';
    var fw = width || 500;
    var fh = height || 380;
    var fm = { top: 24, right: 80, bottom: 36, left: 52 };
    var fiW = fw - fm.left - fm.right;
    var fiH = fh - fm.top - fm.bottom;
    var historyPoints = hist.map(function (d) { return Number(d.value); }).filter(function (v) { return v != null && !isNaN(v); });
    var forecastPoints = arima.map(function (d) { return Number(d.value); }).filter(function (v) { return v != null && !isNaN(v); });
    var ci95High = (arima.map(function (d) { return d.ci_95_high != null ? Number(d.ci_95_high) : null; }).filter(Boolean));
    var ci95Low = (arima.map(function (d) { return d.ci_95_low != null ? Number(d.ci_95_low) : null; }).filter(Boolean));
    var allValues = historyPoints.concat(forecastPoints).concat(ci95High).concat(ci95Low);
    var yMin = allValues.length ? Math.min.apply(null, allValues) * 0.98 : 0;
    var yMax = allValues.length ? Math.max.apply(null, allValues) * 1.02 : 1;
    var ci80L = arima.map(function (d) { return d.ci_80_low != null ? Number(d.ci_80_low) : Number(d.value); });
    var ci80H = arima.map(function (d) { return d.ci_80_high != null ? Number(d.ci_80_high) : Number(d.value); });
    var ci95L = arima.map(function (d) { return d.ci_95_low != null ? Number(d.ci_95_low) : Number(d.value); });
    var ci95H = arima.map(function (d) { return d.ci_95_high != null ? Number(d.ci_95_high) : Number(d.value); });
    var fxScale = function (i) { return fm.left + (i / (hist.length + arima.length - 1 || 1)) * fiW; };
    var fyScale = function (v) { return fm.top + fiH - (Number(v) - yMin) / (yMax - yMin || 1) * fiH; };
    var pathHist = hist.length ? 'M ' + fxScale(0) + ' ' + fyScale(Number(hist[0].value)) : '';
    for (var k = 1; k < hist.length; k++) pathHist += ' L ' + fxScale(k) + ' ' + fyScale(Number(hist[k].value));
    var pathArima = '';
    if (arima.length && hist.length) {
      pathArima = 'M ' + fxScale(hist.length - 1) + ' ' + fyScale(Number(hist[hist.length - 1].value)) + ' L ' + fxScale(hist.length) + ' ' + fyScale(Number(arima[0].value));
      for (var k = 1; k < arima.length; k++) pathArima += ' L ' + fxScale(hist.length + k) + ' ' + fyScale(Number(arima[k].value));
    }
    var poly95 = '';
    var poly80 = '';
    if (arima.length && ci95L.length && ci95H.length) {
      poly95 = 'M ' + fxScale(hist.length) + ' ' + fyScale(ci95L[0]);
      for (var k = 1; k < arima.length; k++) poly95 += ' L ' + fxScale(hist.length + k) + ' ' + fyScale(ci95L[k]);
      poly95 += ' L ' + fxScale(hist.length + arima.length - 1) + ' ' + fyScale(ci95H[arima.length - 1]);
      for (var k = arima.length - 2; k >= 0; k--) poly95 += ' L ' + fxScale(hist.length + k) + ' ' + fyScale(ci95H[k]) + ' Z';
    }
    if (arima.length && ci80L.length && ci80H.length) {
      poly80 = 'M ' + fxScale(hist.length) + ' ' + fyScale(ci80L[0]);
      for (var k = 1; k < arima.length; k++) poly80 += ' L ' + fxScale(hist.length + k) + ' ' + fyScale(ci80L[k]);
      poly80 += ' L ' + fxScale(hist.length + arima.length - 1) + ' ' + fyScale(ci80H[arima.length - 1]);
      for (var k = arima.length - 2; k >= 0; k--) poly80 += ' L ' + fxScale(hist.length + k) + ' ' + fyScale(ci80H[k]) + ' Z';
    }
    var todayX = hist.length > 0 ? fxScale(hist.length) : 0;
    var svgStr = '<svg viewBox="0 0 ' + fw + ' ' + fh + '" width="' + fw + '" height="' + fh + '" style="max-width:100%;display:block;height:' + fh + 'px"><rect width="' + fw + '" height="' + fh + '" fill="#fff"/>' + (poly95 ? '<path d="' + poly95 + '" fill="rgba(13,148,136,0.08)" stroke="none"/>' : '') + (poly80 ? '<path d="' + poly80 + '" fill="rgba(13,148,136,0.15)" stroke="none"/>' : '') + (pathHist ? '<path d="' + pathHist + '" fill="none" stroke="#0d9488" stroke-width="2"/>' : '') + (pathArima ? '<path d="' + pathArima + '" fill="none" stroke="#0f5b54" stroke-width="2"/>' : '') + (hist.length ? '<line x1="' + todayX + '" y1="' + fm.top + '" x2="' + todayX + '" y2="' + (fh - fm.bottom) + '" stroke="#94a3b8" stroke-dasharray="4,2"/><text x="' + todayX + '" y="' + (fm.top - 4) + '" text-anchor="middle" font-size="10" fill="#64748b">Today</text>' : '') + '</svg>';
    var summary = (forecastData.summary || {});
    var orderStr = (forecastData.arima_model && forecastData.arima_model.order) ? 'ARIMA(' + forecastData.arima_model.order.join(',') + ')' : '';
    var sumHtml = '<p class="analysis-forecast-summary" style="margin-top:8px;font-size:12px;color:#334155">Current: ' + escapeHtml(summary.current != null ? String(summary.current) : '—') + ' | 30D: ' + escapeHtml(summary.arima_30d != null ? String(summary.arima_30d) : '—') + ' (' + escapeHtml(summary.arima_pct_change || '') + ') | Model: ' + escapeHtml(orderStr) + '</p>';
    return svgStr + sumHtml;
  }

  function toIsoDateString(val) {
    if (val == null) return null;
    if (val instanceof Date) return val.toISOString();
    var s = String(val);
    return s.length > 0 ? s : null;
  }

  function datesFromOverlaidData(seriesData, xId) {
    if (!seriesData || !xId) return [];
    var seriesById = (seriesData.series && typeof seriesData.series === 'object') ? seriesData.series : {};
    var raw = seriesById[xId];
    var arr = Array.isArray(raw) ? raw : (raw && (raw.data || raw.points || raw.values)) ? (raw.data || raw.points || raw.values) : [];
    return (arr || []).map(function (d) { return d && d.date != null ? d.date : null; });
  }

  function filterOverlaidDataByDateRange(seriesData, startDate, endDate) {
    if (!seriesData || !startDate || !endDate) return seriesData;
    var seriesById = (seriesData.series && typeof seriesData.series === 'object') ? seriesData.series : {};
    var keys = Object.keys(seriesById);
    var filtered = {};
    keys.forEach(function (id) {
      var raw = seriesById[id];
      var arr = Array.isArray(raw) ? raw : (raw && (raw.data || raw.points || raw.values)) ? (raw.data || raw.points || raw.values) : [];
      var slice = arr.filter(function (d) {
        var dStr = (d && d.date != null) ? String(d.date).slice(0, 10) : '';
        return dStr >= String(startDate).slice(0, 10) && dStr <= String(endDate).slice(0, 10);
      });
      if (Array.isArray(raw)) filtered[id] = slice;
      else filtered[id] = Object.assign({}, raw, { data: slice });
    });
    return { series: filtered };
  }

  function filterForecastByIndexRange(forecastData, startIndex, endIndex) {
    if (!forecastData || startIndex == null || endIndex == null) return forecastData;
    var hist = (forecastData.history && forecastData.history.slice()) || [];
    var arima = Array.isArray(forecastData.arima_forecast) ? forecastData.arima_forecast.slice() : [];
    var n = hist.length + arima.length;
    var s = Math.max(0, Math.floor(startIndex));
    var e = Math.min(n - 1, Math.ceil(endIndex));
    if (s >= hist.length) {
      return {
        history: [],
        arima_forecast: arima.slice(s - hist.length, e - hist.length + 1),
        summary: forecastData.summary,
        arima_model: forecastData.arima_model
      };
    }
    if (e < hist.length) {
      return {
        history: hist.slice(s, e + 1),
        arima_forecast: [],
        summary: forecastData.summary,
        arima_model: forecastData.arima_model
      };
    }
    return {
      history: hist.slice(s, hist.length),
      arima_forecast: arima.slice(0, e - hist.length + 1),
      summary: forecastData.summary,
      arima_model: forecastData.arima_model
    };
  }

  function filterForecastByDateRange(forecastData, startDate, endDate) {
    if (!forecastData || !startDate || !endDate) return forecastData;
    var hist = (forecastData.history && forecastData.history.slice()) || [];
    var arima = Array.isArray(forecastData.arima_forecast) ? forecastData.arima_forecast.slice() : [];
    var startStr = String(startDate).slice(0, 10);
    var endStr = String(endDate).slice(0, 10);
    var startIndex = -1;
    var endIndex = -1;
    for (var i = 0; i < hist.length; i++) {
      var d = (hist[i].date != null) ? String(hist[i].date).slice(0, 10) : '';
      if (d >= startStr && startIndex < 0) startIndex = i;
      if (d <= endStr) endIndex = i;
    }
    for (var j = 0; j < arima.length; j++) {
      var d2 = (arima[j].date != null) ? String(arima[j].date).slice(0, 10) : '';
      if (startIndex < 0 && d2 >= startStr) startIndex = hist.length + j;
      if (d2 <= endStr) endIndex = hist.length + j;
    }
    if (startIndex < 0 || endIndex < 0 || startIndex > endIndex) return forecastData;
    return filterForecastByIndexRange(forecastData, startIndex, endIndex);
  }

  function addBrushOverlay(container, opts) {
    var margins = opts.margins || { top: 20, right: 80, bottom: 28, left: 44 };
    var w = opts.width || 500;
    var h = opts.height || 220;
    var nPoints = opts.nPoints || 0;
    var getDateAtIndex = opts.getDateAtIndex;
    var onZoom = opts.onZoom;
    var isZoomed = opts.isZoomed === true;
    var onReset = opts.onReset;
    if (!container || !onZoom || nPoints < 2) return;
    var svgEl = container.querySelector && container.querySelector('svg');
    if (!svgEl) return;
    var innerW = w - margins.left - margins.right;
    var innerH = h - margins.top - margins.bottom;
    var leftPct = (margins.left / w) * 100;
    var topPct = (margins.top / h) * 100;
    var overlay = document.createElement('div');
    overlay.className = 'chart-brush-overlay';
    overlay.setAttribute('aria-hidden', 'true');
    overlay.style.cssText = 'position:absolute;left:' + leftPct + '%;top:' + topPct + '%;width:' + (innerW / w * 100) + '%;height:' + (innerH / h * 100) + '%;cursor:crosshair;z-index:1';
    if (opts && opts.isThesisEmbed) {
      container.style.position = 'relative';
      container.appendChild(overlay);
    } else {
      var wrap = document.createElement('div');
      wrap.className = 'chart-brush-wrap';
      wrap.style.cssText = 'position:relative;display:block;width:100%';
      while (container.firstChild) wrap.appendChild(container.firstChild);
      container.appendChild(wrap);
      wrap.appendChild(overlay);
    }
    if (isZoomed && typeof onReset === 'function') {
      var resetBtn = document.createElement('button');
      resetBtn.type = 'button';
      resetBtn.className = 'chart-zoom-reset-btn';
      resetBtn.textContent = 'Reset';
      resetBtn.style.cssText = 'position:absolute;top:' + (margins.top + 4) + 'px;right:' + (margins.right + 4) + 'px;z-index:2;pointer-events:auto';
      resetBtn.addEventListener('click', function (e) {
        e.preventDefault();
        e.stopPropagation();
        onReset();
      });
      var parent = opts.isThesisEmbed ? container : overlay.parentNode;
      parent.appendChild(resetBtn);
    }
    var highlight = document.createElement('div');
    highlight.className = 'chart-brush-highlight';
    highlight.style.cssText = 'position:absolute;top:0;bottom:0;background:var(--teal);opacity:0.15;pointer-events:none;display:none';
    overlay.appendChild(highlight);
    var startX = 0;
    var currentX = 0;
    var dragging = false;

    function toLocalX(clientX) {
      var r = overlay.getBoundingClientRect();
      return clientX - r.left;
    }

    function onDown(e) {
      if (e.button !== 0) return;
      startX = toLocalX(e.clientX);
      currentX = startX;
      dragging = true;
      highlight.style.display = 'block';
      highlight.style.left = startX + 'px';
      highlight.style.width = '0';
      document.addEventListener('mousemove', onMove);
      document.addEventListener('mouseup', onUp);
    }

    function onMove(e) {
      if (!dragging) return;
      currentX = Math.max(0, Math.min(overlay.offsetWidth, toLocalX(e.clientX)));
      var l = Math.min(startX, currentX);
      var ww = Math.abs(currentX - startX);
      highlight.style.left = l + 'px';
      highlight.style.width = ww + 'px';
    }

    function onUp(e) {
      document.removeEventListener('mousemove', onMove);
      document.removeEventListener('mouseup', onUp);
      if (!dragging) return;
      dragging = false;
      currentX = Math.max(0, Math.min(overlay.offsetWidth, toLocalX(e.clientX)));
      highlight.style.display = 'none';
      var dist = Math.abs(currentX - startX);
      if (dist < 10) return;
      var ow = overlay.offsetWidth;
      if (!ow || nPoints < 2) return;
      var startIndex = Math.max(0, Math.min(nPoints - 1, Math.round((Math.min(startX, currentX) / ow) * (nPoints - 1))));
      var endIndex = Math.max(0, Math.min(nPoints - 1, Math.round((Math.max(startX, currentX) / ow) * (nPoints - 1))));
      if (startIndex === endIndex) return;
      if (getDateAtIndex) {
        var startDate = getDateAtIndex(startIndex);
        var endDate = getDateAtIndex(endIndex);
        if (startDate != null && endDate != null) onZoom({ startDate: startDate, endDate: endDate });
      } else {
        onZoom({ startIndex: startIndex, endIndex: endIndex });
      }
    }

    overlay.addEventListener('mousedown', onDown);
  }

  function renderFactorsEmbedHTML(factorData) {
    var factors = (factorData && factorData.factors) || [];
    var model = (factorData && factorData.model) || {};
    var maxAbsBeta = Math.max(0.001, Math.max.apply(null, factors.map(function (f) { return Math.abs(Number(f.beta) || 0); })));
    var factorRows = '';
    factors.forEach(function (f) {
      var beta = Number(f.beta) || 0;
      var sig = f.significant !== false && (f.p_value == null || f.p_value < 0.05);
      var stars = f.p_value != null ? (f.p_value < 0.01 ? '**' : f.p_value < 0.05 ? '*' : '') : '';
      var contrib = sig && f.contribution_pct != null ? f.contribution_pct.toFixed(1) + '% var.' : '—';
      var barWidthPct = Math.min((Math.abs(beta) / maxAbsBeta) * 100, 100);
      var barPctOfContainer = barWidthPct / 2;
      var barStyle = 'width:' + barPctOfContainer + '%;background:' + (beta >= 0 ? '#16a34a' : '#dc2626') + ';' + (beta >= 0 ? 'left:50%;' : 'right:50%;left:auto;');
      factorRows += '<div class="factor-row ' + (sig ? '' : 'non-significant') + '"><span class="factor-label">' + escapeHtml(f.factor || f.name || '') + '</span><div class="factor-bar-wrap"><div class="factor-bar" style="' + barStyle + '"></div></div><span class="factor-beta ' + (beta >= 0 ? 'positive' : 'negative') + '">' + beta.toFixed(3) + stars + '</span><span class="factor-contrib">' + contrib + '</span></div>';
    });
    var statsStr = 'R² = ' + (model.r_squared != null ? Number(model.r_squared).toFixed(3) : '—') + ' | N = ' + (model.observations != null ? model.observations : '—') + ' | AIC = ' + (model.aic != null ? Number(model.aic).toFixed(1) : '—');
    return factorRows + '<p class="factor-model-stats" style="margin-top:10px;font-size:11px;color:#64748b">' + escapeHtml(statsStr) + '</p>' + (factorData.interpretation ? '<p class="factor-interpretation">' + escapeHtml(factorData.interpretation) + '</p>' : '');
  }

  function renderImpactEmbedHTML(impactData, shockPct) {
    var impacts = (impactData && impactData.impacts) ? impactData.impacts : [];
    var rows = impacts.map(function (imp) {
      var pred = imp.predicted_move_pct != null ? Number(imp.predicted_move_pct) : null;
      var predStr = pred != null ? (pred >= 0 ? '+' : '') + pred.toFixed(2) + '%' : '—';
      var predCls = pred != null ? (pred >= 0 ? 'positive' : 'negative') : '';
      var ciStr = (imp.ci_95_low != null && imp.ci_95_high != null) ? Number(imp.ci_95_low).toFixed(2) + '% to ' + Number(imp.ci_95_high).toFixed(2) + '%' : '—';
      var r2 = imp.r_squared != null ? Number(imp.r_squared) : 0;
      var conf = imp.p_value != null ? (imp.p_value < 0.01 ? 'HIGH' : imp.p_value < 0.05 ? 'MEDIUM' : 'LOW') : '—';
      var confCls = conf === 'HIGH' ? 'conf-high' : conf === 'MEDIUM' ? 'conf-medium' : conf === 'LOW' ? 'conf-low' : '';
      return '<tr><td>' + escapeHtml(imp.name || imp.series_id || imp.instrument_id || '') + '</td><td>' + (imp.beta != null ? Number(imp.beta).toFixed(3) : '—') + '</td><td><span class="' + predCls + '">' + predStr + '</span></td><td>' + escapeHtml(ciStr) + '</td><td><div class="r2-bar-wrap" style="display:inline-block;width:40px;height:6px;background:#e2e8f0;border-radius:2px"><div style="width:' + Math.min(100, r2 * 100) + '%;height:100%;background:#0d9488;border-radius:2px"></div></div> ' + (imp.r_squared != null ? Number(imp.r_squared).toFixed(2) : '—') + '</td><td><span class="conf-badge ' + confCls + '">' + escapeHtml(conf) + '</span></td></tr>';
    }).join('');
    if (impacts.length === 0) rows = '<tr><td colspan="6" class="impact-empty">' + (impactData.error ? escapeHtml(impactData.error) : 'No impact data.') + '</td></tr>';
    return '<table class="analysis-impact-table"><thead><tr><th>Instrument</th><th>β</th><th>Predicted</th><th>95% CI</th><th>R²</th><th>Conf</th></tr></thead><tbody>' + rows + '</tbody></table>';
  }

  function rhoToColorEmbed(rho) {
    var t = (rho + 1) / 2;
    var r = Math.round(38 + (1 - t) * (255 - 38));
    var g = Math.round(38 + t * (255 - 38));
    var b = Math.round(38 + t * (255 - 38));
    return 'rgb(' + r + ',' + g + ',' + b + ')';
  }
  function renderCorrelationEmbedHTML(corrData, ids) {
    var series = (corrData && corrData.series) ? (ids && ids.length ? ids : corrData.series.slice()) : [];
    var matrix = (corrData && corrData.matrix) || [];
    var N = series.length;
    if (N === 0) return '<p class="canvas-loading">No correlation data.</p>';
    var cellSize = Math.max(40, Math.min(70, Math.floor(360 / N)));
    var table = '<table class="research-corr-table" style="border-collapse:collapse;font-size:' + (cellSize > 50 ? 11 : 10) + 'px"><thead><tr><th></th>';
    for (var i = 0; i < N; i++) table += '<th>' + escapeHtml(String(series[i]).slice(0, 10)) + '</th>';
    table += '</tr></thead><tbody>';
    for (var i = 0; i < N; i++) {
      table += '<tr><th>' + escapeHtml(String(series[i]).slice(0, 10)) + '</th>';
      for (var j = 0; j < N; j++) {
        var rho = (matrix[i] && matrix[i][j] != null) ? Number(matrix[i][j]) : (i === j ? 1 : 0);
        var bg = i === j ? '#0d9488' : rhoToColorEmbed(rho);
        var textColor = i === j ? '#fff' : (Math.abs(rho) > 0.5 ? '#fff' : '#1a1a1a');
        table += '<td style="width:' + cellSize + 'px;height:' + cellSize + 'px;background:' + bg + ';color:' + textColor + ';text-align:center">' + (i === j ? '1.00' : rho.toFixed(2)) + '</td>';
      }
      table += '</tr>';
    }
    table += '</tbody></table>';
    return table;
  }
  if (typeof window !== 'undefined') {
    window.renderOverlaidSVG = renderOverlaidSVG;
    window.renderForecastSVG = renderForecastSVG;
    window.renderFactorsEmbedHTML = renderFactorsEmbedHTML;
    window.renderImpactEmbedHTML = renderImpactEmbedHTML;
    window.renderCorrelationEmbedHTML = renderCorrelationEmbedHTML;
  }

  // ——— C2: Chart embed infrastructure (SIGNAL Thesis Chart Embeds) ———
  function generateEmbedId() {
    return 'embed_' + Date.now() + '_' + Math.random().toString(36).slice(2, 7);
  }

  function generateThesisId() {
    return 'thesis_' + Date.now() + '_' + Math.random().toString(36).slice(2, 7);
  }

  function buildEmbedShell(params) {
    var el = document.createElement('div');
    el.className = 'thesis-chart-embed';
    el.contentEditable = 'false';
    el.dataset.embedId = params.embedId || generateEmbedId();
    el.dataset.type = params.type || '';
    el.dataset.x = params.x || '';
    el.dataset.y = params.y || '';
    el.dataset.period = String(params.period != null ? params.period : 90);
    el.dataset.shockPct = String(params.shockPct != null ? params.shockPct : 10);
    el.dataset.instruments = params.instruments || '';
    var w = params.width != null ? Math.max(300, parseInt(params.width, 10)) : 600;
    var h = params.height != null ? Math.max(160, parseInt(params.height, 10)) : 280;
    el.dataset.width = String(w);
    el.dataset.height = String(h);
    var label = (params.label != null && params.label !== '') ? escapeHtml(params.label) : '';
    el.innerHTML = '<div class="chart-embed-header"><span class="chart-embed-label">' + label + '</span><div class="chart-embed-actions"><button type="button" class="chart-embed-btn chart-embed-settings">Settings</button><button type="button" class="chart-embed-btn chart-embed-impact">Impact</button><button type="button" class="chart-embed-btn chart-embed-refresh">Refresh</button><button type="button" class="chart-embed-btn chart-embed-remove">Remove</button></div></div><div class="chart-embed-canvas"><div class="chart-embed-loading">Loading...</div></div><div class="chart-embed-meta"></div>';
    return el;
  }

  function readParamsFromEmbed(embedEl) {
    var labelEl = embedEl.querySelector('.chart-embed-label');
    var w = parseInt(embedEl.dataset.width, 10);
    var h = parseInt(embedEl.dataset.height, 10);
    var type = embedEl.dataset.type || embedEl.dataset.chartType || '';
    return {
      embedId: embedEl.dataset.embedId || '',
      type: type,
      x: embedEl.dataset.x || embedEl.dataset.chartX || '',
      y: embedEl.dataset.y || embedEl.dataset.chartY || '',
      period: parseInt(embedEl.dataset.period, 10) || 90,
      shockPct: parseFloat(embedEl.dataset.shockPct) || 10,
      instruments: embedEl.dataset.instruments || '',
      label: labelEl ? (labelEl.textContent || '').trim() : '',
      width: (w >= 300 ? w : 600),
      height: (h >= 160 ? h : 280)
    };
  }

  var THESIS_EMBED_MIN_W = 300;
  var THESIS_EMBED_MIN_H = 160;

  function createThesisChartEmbedResizeWrapper(embedEl, w, h) {
    var wrapper = document.createElement('div');
    wrapper.className = 'thesis-chart-embed-resize-wrapper';
    var width = Math.max(THESIS_EMBED_MIN_W, parseInt(String(w), 10) || 600);
    var height = Math.max(THESIS_EMBED_MIN_H, parseInt(String(h), 10) || 280);
    wrapper.style.width = width + 'px';
    wrapper.style.height = height + 'px';
    ['n', 's', 'e', 'w', 'nw', 'ne', 'sw', 'se'].forEach(function (dir) {
      var handle = document.createElement('div');
      handle.className = 'thesis-chart-embed-resize-handle thesis-chart-embed-resize-handle--' + dir;
      handle.setAttribute('data-handle', dir);
      wrapper.appendChild(handle);
    });
    wrapper.appendChild(embedEl);
    return wrapper;
  }

  function wireThesisChartEmbedResize(wrapper) {
    var embedEl = wrapper.querySelector('.thesis-chart-embed');
    if (!embedEl) return;
    var minW = THESIS_EMBED_MIN_W;
    var minH = THESIS_EMBED_MIN_H;
    wrapper.querySelectorAll('.thesis-chart-embed-resize-handle').forEach(function (handle) {
      handle.addEventListener('mousedown', function (e) {
        e.preventDefault();
        var dir = handle.getAttribute('data-handle');
        var startX = e.clientX;
        var startY = e.clientY;
        var startW = wrapper.offsetWidth;
        var startH = wrapper.offsetHeight;
        function onMove(e) {
          var dx = e.clientX - startX;
          var dy = e.clientY - startY;
          var newW = startW;
          var newH = startH;
          if (dir.indexOf('e') !== -1) newW = Math.max(minW, startW + dx);
          if (dir.indexOf('w') !== -1) newW = Math.max(minW, startW - dx);
          if (dir.indexOf('s') !== -1) newH = Math.max(minH, startH + dy);
          if (dir.indexOf('n') !== -1) newH = Math.max(minH, startH - dy);
          wrapper.style.width = newW + 'px';
          wrapper.style.height = newH + 'px';
        }
        function onUp() {
          document.removeEventListener('mousemove', onMove);
          document.removeEventListener('mouseup', onUp);
          embedEl.dataset.width = String(wrapper.offsetWidth);
          embedEl.dataset.height = String(wrapper.offsetHeight);
          if (typeof ThesisManager !== 'undefined' && ThesisManager.markDirty) ThesisManager.markDirty();
        }
        document.addEventListener('mousemove', onMove);
        document.addEventListener('mouseup', onUp);
      });
    });
    var ro = new ResizeObserver(function () {
      var embed = wrapper.querySelector('.thesis-chart-embed');
      if (embed && typeof renderChartIntoEmbed === 'function') {
        renderChartIntoEmbed(embed, readParamsFromEmbed(embed));
      }
    });
    ro.observe(wrapper);
    wrapper._thesisEmbedResizeObserver = ro;
  }

  function wrapThesisChartEmbedIfNeeded(embedEl) {
    // Guard: if already inside a resize wrapper at any depth, do not wrap again
    var existingWrapper = embedEl.closest && embedEl.closest('.thesis-chart-embed-resize-wrapper');
    if (existingWrapper) {
      return existingWrapper;
    }
    var w = parseInt(embedEl.dataset.width, 10) || 600;
    var h = parseInt(embedEl.dataset.height, 10) || 280;
    w = Math.max(THESIS_EMBED_MIN_W, w);
    h = Math.max(THESIS_EMBED_MIN_H, h);
    var wrapper = createThesisChartEmbedResizeWrapper(embedEl, w, h);
    var parent = embedEl.parentNode;
    if (parent) {
      parent.insertBefore(wrapper, embedEl);
      wrapper.appendChild(embedEl);
    }
    return wrapper;
  }

  function _popoverPosition(btn) {
    var rect = btn.getBoundingClientRect();
    var popoverHeight = 300;
    var spaceBelow = window.innerHeight - rect.bottom;
    var top = spaceBelow >= popoverHeight ? rect.bottom + 4 : rect.top - popoverHeight - 4;
    var left = Math.min(rect.left, window.innerWidth - 300);
    return 'position:fixed;top:' + top + 'px;left:' + left + 'px;';
  }

  function _buildPopoverFields(params) {
    var html = '';
    if (params.type !== 'regime') {
      var periods = [30, 60, 90, 180];
      html += '<div class="popover-field"><label>Period</label><select name="period">';
      periods.forEach(function (p) {
        html += '<option value="' + p + '"' + (params.period === p ? ' selected' : '') + '>' + p + 'D</option>';
      });
      html += '</select></div>';
    }
    if (params.type === 'impact') {
      html += '<div class="popover-field"><label>Shock %</label><input type="number" name="shockPct" value="' + (params.shockPct != null ? params.shockPct : 10) + '" min="-100" max="100" step="1" /></div>';
    }
    if (params.type === 'volatility') {
      html += '<div class="popover-field"><label>Instrument</label><select name="volatilityInstrument">';
      (STATE.universe || []).forEach(function (inst) {
        var id = (inst.id || '').replace(/"/g, '&quot;');
        html += '<option value="' + id + '"' + (params.y === inst.id ? ' selected' : '') + '>' + escapeHtml(inst.name || inst.id) + '</option>';
      });
      html += '</select></div>';
    }
    if (params.type === 'correlation') {
      var selected = (params.instruments || '').split(',').map(function (s) { return s.trim(); }).filter(Boolean);
      html += '<div class="popover-field"><label>Instruments (select 2–8)</label><div class="popover-instrument-list">';
      (STATE.universe || []).forEach(function (inst) {
        var checked = selected.indexOf(inst.id) !== -1 ? ' checked' : '';
        var id = (inst.id || '').replace(/"/g, '&quot;');
        html += '<label class="popover-instrument-item"><input type="checkbox" value="' + id + '"' + checked + ' /> ' + escapeHtml(inst.name || inst.id) + ' <span style="color:#94a3b8;font-size:10px;">' + escapeHtml(inst.id) + '</span></label>';
      });
      html += '</div><div class="popover-selected-count" id="popover-sel-count">' + selected.length + ' instruments selected</div></div>';
    }
    return html;
  }

  function _applyPopoverSettings(popover, embedEl, type) {
    var periodEl = popover.querySelector('[name="period"]');
    if (periodEl) embedEl.dataset.period = String(parseInt(periodEl.value, 10) || 90);
    var shockEl = popover.querySelector('[name="shockPct"]');
    if (shockEl) embedEl.dataset.shockPct = String(parseFloat(shockEl.value) || 10);
    var volEl = popover.querySelector('[name="volatilityInstrument"]');
    if (volEl) {
      embedEl.dataset.y = volEl.value;
      var labelEl = embedEl.querySelector('.chart-embed-label');
      var inst = (STATE.universe || []).find(function (i) { return i.id === volEl.value; });
      if (labelEl && inst) labelEl.textContent = (inst.name || inst.id) + ' — Volatility';
    }
    if (type === 'correlation') {
      var checkedBoxes = popover.querySelectorAll('.popover-instrument-list input:checked');
      var checked = [];
      for (var i = 0; i < checkedBoxes.length; i++) checked.push(checkedBoxes[i].value);
      embedEl.dataset.instruments = checked.join(',');
    }
    var newParams = readParamsFromEmbed(embedEl);
    renderChartIntoEmbed(embedEl, newParams);
    if (typeof ThesisManager !== 'undefined' && ThesisManager.markDirty) ThesisManager.markDirty();
  }

  function _addPopoverOutsideClose(popover) {
    setTimeout(function () {
      function outsideClick(e) {
        if (!popover.contains(e.target)) {
          popover.remove();
          document.removeEventListener('mousedown', outsideClick);
        }
      }
      document.addEventListener('mousedown', outsideClick);
    }, 0);
  }

  function openEmbedSettingsPopover(btn, embedEl) {
    var existing = document.getElementById('chart-embed-popover');
    if (existing) existing.remove();
    var params = readParamsFromEmbed(embedEl);
    if (params.type === 'regime') {
      var tip = document.createElement('div');
      tip.className = 'chart-embed-popover';
      tip.id = 'chart-embed-popover';
      tip.style.cssText = _popoverPosition(btn);
      tip.innerHTML = '<div class="popover-title">Regime Fingerprint</div><div style="font-size:12px;color:#64748b;">Regime reflects current market state only. No configuration available.</div><div class="popover-actions"><button type="button" class="popover-cancel">Close</button></div>';
      document.body.appendChild(tip);
      var closeBtn = tip.querySelector('.popover-cancel');
      if (closeBtn) closeBtn.addEventListener('click', function () { tip.remove(); });
      _addPopoverOutsideClose(tip);
      return;
    }
    var fieldsHtml = _buildPopoverFields(params);
    var popover = document.createElement('div');
    popover.className = 'chart-embed-popover';
    popover.id = 'chart-embed-popover';
    popover.style.cssText = _popoverPosition(btn);
    popover.innerHTML = '<div class="popover-title">Chart settings</div><div class="popover-fields">' + fieldsHtml + '</div><div class="popover-actions"><button type="button" class="popover-cancel">Cancel</button><button type="button" class="popover-apply">Apply and Refresh</button></div>';
    document.body.appendChild(popover);
    var cancelBtn = popover.querySelector('.popover-cancel');
    if (cancelBtn) cancelBtn.addEventListener('click', function () { popover.remove(); });
    var applyBtn = popover.querySelector('.popover-apply');
    if (applyBtn) applyBtn.addEventListener('click', function () {
      _applyPopoverSettings(popover, embedEl, params.type);
      popover.remove();
    });
    _addPopoverOutsideClose(popover);
    if (params.type === 'correlation') {
      var list = popover.querySelector('.popover-instrument-list');
      var countEl = popover.querySelector('#popover-sel-count');
      if (list && countEl) {
        list.addEventListener('change', function () {
          var n = list.querySelectorAll('input:checked').length;
          countEl.textContent = n + ' instruments selected';
        });
      }
    }
  }

  function renderChartIntoEmbed(embedEl, params) {
    var canvas = embedEl.querySelector('.chart-embed-canvas');
    var meta = embedEl.querySelector('.chart-embed-meta');
    if (!canvas) return Promise.resolve();

    canvas.innerHTML = '<div class="chart-embed-loading">Loading...</div>';

    if (params.type !== 'regime' && params.type !== 'correlation') {
      var targetId = params.y || params.x;
      if (targetId) {
        var exists = (STATE.universe || []).some(function (i) { return i.id === targetId; });
        if (!exists) {
          canvas.innerHTML = '<div class="chart-embed-error">Series no longer available</div>';
          return Promise.resolve();
        }
      }
    }

    var w = Math.max(canvas.offsetWidth || 0, 600);

    function run() {
      switch (params.type) {
        case 'overlaid': {
          return API.getResearchSeries([params.x, params.y], params.period).then(function (data) {
            if (data && data.error) {
              canvas.innerHTML = '<div class="chart-embed-error">' + (data.error || 'Failed to load') + '</div>';
              return;
            }
            embedEl._chartDataFull = data;
            embedEl._chartParams = params;
            if (embedEl.dataset.timeRangeFrom && embedEl.dataset.timeRangeTo) {
              embedEl._chartData = filterOverlaidDataByDateRange(data, embedEl.dataset.timeRangeFrom, embedEl.dataset.timeRangeTo);
            } else {
              embedEl._chartData = data;
            }
            var corrText = '';
            canvas.innerHTML = renderOverlaidSVG(embedEl._chartData, params.x, params.y, w, 220, params.x, params.y, corrText);
            var dates = datesFromOverlaidData(embedEl._chartData, params.x);
            if (dates.length >= 2) {
              var chartIdEmbed = embedEl.dataset.embedId || null;
              addBrushOverlay(canvas, { isThesisEmbed: true, isZoomed: false, margins: { top: 20, right: 80, bottom: 28, left: 44 }, width: w, height: 220, nPoints: dates.length, getDateAtIndex: function (i) { return datesFromOverlaidData(embedEl._chartData, embedEl._chartParams.x)[i]; }, onZoom: function overlaidZoom(r) {
                embedEl._chartData = filterOverlaidDataByDateRange(embedEl._chartData, r.startDate, r.endDate);
                if (typeof ThesisManager !== 'undefined' && chartIdEmbed) ThesisManager.setLastBrushedRange({ chartId: chartIdEmbed, start: toIsoDateString(r.startDate), end: toIsoDateString(r.endDate) });
                var p = embedEl._chartParams;
                canvas.innerHTML = renderOverlaidSVG(embedEl._chartData, p.x, p.y, w, 220, p.x, p.y, '');
                var nextDates = datesFromOverlaidData(embedEl._chartData, p.x);
                if (nextDates.length >= 2) addBrushOverlay(canvas, { isThesisEmbed: true, isZoomed: true, margins: { top: 20, right: 80, bottom: 28, left: 44 }, width: w, height: 220, nPoints: nextDates.length, getDateAtIndex: function (i) { return nextDates[i]; }, onZoom: overlaidZoom, onReset: buildEmbedOverlaidReset(embedEl) });
              } });
            }
          });
        }
        case 'impact': {
          return API.getImpact(params.x, params.y, params.shockPct, params.period).then(function (data) {
            if (data && data.error) {
              canvas.innerHTML = '<div class="chart-embed-error">' + (data.error || 'Failed to load') + '</div>';
              return;
            }
            canvas.innerHTML = renderImpactEmbedHTML(data, params.shockPct);
          });
        }
        case 'factors': {
          return API.getFactorDecomposition(params.y, params.period).then(function (data) {
            if (data && data.error) {
              canvas.innerHTML = '<div class="chart-embed-error">' + (data.error || 'Failed to load') + '</div>';
              return;
            }
            canvas.innerHTML = renderFactorsEmbedHTML(data);
          });
        }
        case 'forecast': {
          return API.getForecast(params.y, 30, params.period, 'both').then(function (data) {
            if (data && data.error) {
              canvas.innerHTML = '<div class="chart-embed-error">' + (data.error || 'Failed to load') + '</div>';
              return;
            }
            embedEl._chartDataFull = data;
            embedEl._chartParams = params;
            if (embedEl.dataset.timeRangeFrom && embedEl.dataset.timeRangeTo) {
              embedEl._chartData = filterForecastByDateRange(data, embedEl.dataset.timeRangeFrom, embedEl.dataset.timeRangeTo);
            } else {
              embedEl._chartData = data;
            }
            canvas.innerHTML = renderForecastSVG(embedEl._chartData, w, 220);
            var hist = (embedEl._chartData.history && embedEl._chartData.history.slice()) || [];
            var arima = Array.isArray(embedEl._chartData.arima_forecast) ? embedEl._chartData.arima_forecast : [];
            var allDates = hist.map(function (d) { return d.date; }).concat(arima.map(function (d) { return d.date; }));
            var nPoints = hist.length + arima.length;
            if (nPoints >= 2 && allDates.filter(Boolean).length >= 2) {
              var chartIdForecast = embedEl.dataset.embedId || null;
              addBrushOverlay(canvas, { isThesisEmbed: true, isZoomed: false, margins: { top: 24, right: 80, bottom: 36, left: 52 }, width: w, height: 220, nPoints: nPoints, getDateAtIndex: function (i) { return allDates[i]; }, onZoom: function forecastZoom(r) {
                embedEl._chartData = filterForecastByDateRange(embedEl._chartData, r.startDate, r.endDate);
                if (typeof ThesisManager !== 'undefined' && chartIdForecast) ThesisManager.setLastBrushedRange({ chartId: chartIdForecast, start: toIsoDateString(r.startDate), end: toIsoDateString(r.endDate) });
                canvas.innerHTML = renderForecastSVG(embedEl._chartData, w, 220);
                var h2 = (embedEl._chartData.history && embedEl._chartData.history.slice()) || [];
                var a2 = Array.isArray(embedEl._chartData.arima_forecast) ? embedEl._chartData.arima_forecast : [];
                var nextDates = h2.map(function (d) { return d.date; }).concat(a2.map(function (d) { return d.date; }));
                var nextN = h2.length + a2.length;
                if (nextN >= 2) addBrushOverlay(canvas, { isThesisEmbed: true, isZoomed: true, margins: { top: 24, right: 80, bottom: 36, left: 52 }, width: w, height: 220, nPoints: nextN, getDateAtIndex: function (i) { return nextDates[i]; }, onZoom: forecastZoom, onReset: buildEmbedForecastReset(embedEl) });
              } });
            }
          });
        }
        case 'correlation': {
          var ids = (params.instruments || '').split(',').map(function (s) { return s.trim(); }).filter(Boolean);
          if (ids.length < 2) {
            canvas.innerHTML = '<div class="chart-embed-error">Select at least 2 instruments in Settings</div>';
            return Promise.resolve();
          }
          return API.getCorrelationMatrix(ids, params.period).then(function (data) {
            if (data && data.error) {
              canvas.innerHTML = '<div class="chart-embed-error">' + (data.error || 'Failed to load') + '</div>';
              return;
            }
            canvas.innerHTML = renderCorrelationEmbedHTML(data, ids);
          });
        }
        case 'volatility': {
          if (!params.y) {
            canvas.innerHTML = '<div class="chart-embed-error">Select an instrument in Settings</div>';
            return Promise.resolve();
          }
          return API.getVolatility(params.y, params.period).then(function (data) {
            if (data && data.error) {
              canvas.innerHTML = '<div class="chart-embed-error">' + (data.error || 'Failed to load') + '</div>';
              return;
            }
            canvas.innerHTML = (typeof renderVolatilitySVG === 'function')
              ? renderVolatilitySVG(data, w, 180)
              : '<div class="chart-embed-error">Volatility render not available</div>';
          });
        }
        case 'regime': {
          canvas.innerHTML = (typeof renderRegimeEmbedHTML === 'function')
            ? renderRegimeEmbedHTML(STATE.regime)
            : '<div class="chart-embed-error">Regime render not available</div>';
          return Promise.resolve();
        }
        default:
          canvas.innerHTML = '<div class="chart-embed-error">Unknown chart type. Use Settings to reconfigure or remove and re-add the chart.</div>';
          return Promise.resolve();
      }
    }

    return run().then(function () {
      var now = new Date();
      var hh = String(now.getHours()).padStart(2, '0');
      var mm = String(now.getMinutes()).padStart(2, '0');
      if (meta) meta.textContent = 'Last updated ' + hh + ':' + mm + ' · ' + (params.label || '');
    }).catch(function (err) {
      console.error('[renderChartIntoEmbed]', err);
      canvas.innerHTML = '<div class="chart-embed-error">Failed to load. <button type="button" class="chart-embed-retry">Retry</button></div>';
      var retryBtn = canvas.querySelector('.chart-embed-retry');
      if (retryBtn) retryBtn.addEventListener('click', function () {
        renderChartIntoEmbed(embedEl, readParamsFromEmbed(embedEl));
      });
    });
  }

  function wireEmbedButtons(embedEl) {
    var refreshBtn = embedEl.querySelector('.chart-embed-refresh');
    if (refreshBtn) refreshBtn.addEventListener('click', function () {
      renderChartIntoEmbed(embedEl, readParamsFromEmbed(embedEl));
    });
    var removeBtn = embedEl.querySelector('.chart-embed-remove');
    if (removeBtn) removeBtn.addEventListener('click', function () {
      var wrapper = embedEl.closest && embedEl.closest('.thesis-chart-embed-resize-wrapper');
      var toRemove = wrapper || embedEl;
      var next = toRemove.nextElementSibling;
      if (next && next.tagName === 'P' && next.innerHTML === '<br>') next.remove();
      toRemove.remove();
      if (typeof ThesisManager !== 'undefined' && ThesisManager.markDirty) ThesisManager.markDirty();
    });
    var settingsBtn = embedEl.querySelector('.chart-embed-settings');
    if (settingsBtn) settingsBtn.addEventListener('click', function (e) {
      e.stopPropagation();
      var params = readParamsFromEmbed(embedEl);
      if (params.type === 'overlaid' || params.type === 'forecast') {
        openChartSettingsPanel(e.currentTarget, getEmbedChartSettingsContext(embedEl));
      } else {
        openEmbedSettingsPopover(e.currentTarget, embedEl);
      }
    });
    var impactBtn = embedEl.querySelector('.chart-embed-impact');
    if (impactBtn) {
      var params0 = readParamsFromEmbed(embedEl);
      impactBtn.style.display = (params0.type === 'overlaid') ? '' : 'none';
      impactBtn.addEventListener('click', function (e) {
        e.stopPropagation();
        var p = readParamsFromEmbed(embedEl);
        if (p.type === 'overlaid') {
          openChartImpactPanel(e.currentTarget, getEmbedChartImpactContext(embedEl));
        }
      });
    }
  }

  function getEmbedChartSettingsContext(embedEl) {
    var params = readParamsFromEmbed(embedEl);
    var headerEl = embedEl.querySelector('.chart-embed-header');
    return {
      type: 'embed',
      chartId: embedEl.dataset.embedId || '',
      headerEl: headerEl,
      chartType: params.type,
      getSeries: function () {
        var raw = embedEl.dataset.customSeries;
        if (raw) {
          try { return JSON.parse(raw); } catch (e) { }
        }
        if (params.type === 'overlaid' && params.x && params.y) {
          var u = STATE.universe || [];
          var nx = u.find(function (i) { return i.id === params.x; });
          var ny = u.find(function (i) { return i.id === params.y; });
          return [
            { id: params.x, name: (nx && nx.name) || params.x, color: 'var(--teal)' },
            { id: params.y, name: (ny && ny.name) || params.y, color: 'var(--orange)' }
          ];
        }
        if (params.type === 'forecast' && params.y) {
          var u = STATE.universe || [];
          var ny = u.find(function (i) { return i.id === params.y; });
          return [{ id: params.y, name: (ny && ny.name) || params.y, color: 'var(--teal)' }];
        }
        return [];
      },
      setSeries: function (list) {
        embedEl.dataset.customSeries = JSON.stringify(list);
      },
      getTimeRange: function () {
        var from = embedEl.dataset.timeRangeFrom;
        var to = embedEl.dataset.timeRangeTo;
        var preset = embedEl.dataset.timeRangePreset || '';
        if (from && to) return { from: from, to: to, preset: preset || null };
        return null;
      },
      setTimeRange: function (tr) {
        embedEl.dataset.timeRangeFrom = tr ? tr.from : '';
        embedEl.dataset.timeRangeTo = tr ? tr.to : '';
        embedEl.dataset.timeRangePreset = (tr && tr.preset) ? tr.preset : '';
      },
      reRender: function () { renderChartIntoEmbed(embedEl, readParamsFromEmbed(embedEl)); },
      rescaleToRange: function (from, to) {
        embedEl.dataset.timeRangeFrom = from;
        embedEl.dataset.timeRangeTo = to;
        embedEl.dataset.timeRangePreset = '';
        if (params.type === 'overlaid' && embedEl._chartDataFull) {
          embedEl._chartData = filterOverlaidDataByDateRange(embedEl._chartDataFull, from, to);
          var p = embedEl._chartParams;
          var canvas = embedEl.querySelector('.chart-embed-canvas');
          if (canvas && p) {
            canvas.innerHTML = renderOverlaidSVG(embedEl._chartData, p.x, p.y, canvas.offsetWidth || 600, 220, p.x, p.y, '');
            var dates = datesFromOverlaidData(embedEl._chartData, p.x);
            if (dates.length >= 2) {
              function overlaidZoom(r) {
                embedEl._chartData = filterOverlaidDataByDateRange(embedEl._chartData, r.startDate, r.endDate);
                if (typeof ThesisManager !== 'undefined') ThesisManager.setLastBrushedRange({ chartId: embedEl.dataset.embedId, start: toIsoDateString(r.startDate), end: toIsoDateString(r.endDate) });
                canvas.innerHTML = renderOverlaidSVG(embedEl._chartData, p.x, p.y, canvas.offsetWidth || 600, 220, p.x, p.y, '');
                var nextDates = datesFromOverlaidData(embedEl._chartData, p.x);
                if (nextDates.length >= 2) addBrushOverlay(canvas, { isThesisEmbed: true, isZoomed: true, margins: { top: 20, right: 80, bottom: 28, left: 44 }, width: canvas.offsetWidth || 600, height: 220, nPoints: nextDates.length, getDateAtIndex: function (i) { return nextDates[i]; }, onZoom: overlaidZoom, onReset: buildEmbedOverlaidReset(embedEl) });
              }
              addBrushOverlay(canvas, { isThesisEmbed: true, isZoomed: false, margins: { top: 20, right: 80, bottom: 28, left: 44 }, width: canvas.offsetWidth || 600, height: 220, nPoints: dates.length, getDateAtIndex: function (i) { return dates[i]; }, onZoom: overlaidZoom });
            }
          }
        } else if (params.type === 'forecast' && embedEl._chartDataFull) {
          embedEl._chartData = filterForecastByDateRange(embedEl._chartDataFull, from, to);
          var canvas = embedEl.querySelector('.chart-embed-canvas');
          if (canvas) {
            canvas.innerHTML = renderForecastSVG(embedEl._chartData, canvas.offsetWidth || 600, 220);
            var hist = (embedEl._chartData.history && embedEl._chartData.history.slice()) || [];
            var arima = Array.isArray(embedEl._chartData.arima_forecast) ? embedEl._chartData.arima_forecast : [];
            var allDates = hist.map(function (d) { return d.date; }).concat(arima.map(function (d) { return d.date; }));
            if (hist.length + arima.length >= 2) {
              function forecastZoom(r) {
                embedEl._chartData = filterForecastByDateRange(embedEl._chartData, r.startDate, r.endDate);
                canvas.innerHTML = renderForecastSVG(embedEl._chartData, canvas.offsetWidth || 600, 220);
                var h2 = (embedEl._chartData.history && embedEl._chartData.history.slice()) || [];
                var a2 = Array.isArray(embedEl._chartData.arima_forecast) ? embedEl._chartData.arima_forecast : [];
                var nextDates = h2.map(function (d) { return d.date; }).concat(a2.map(function (d) { return d.date; }));
                if (nextDates.length >= 2) addBrushOverlay(canvas, { isThesisEmbed: true, isZoomed: true, margins: { top: 24, right: 80, bottom: 36, left: 52 }, width: canvas.offsetWidth || 600, height: 220, nPoints: nextDates.length, getDateAtIndex: function (i) { return nextDates[i]; }, onZoom: forecastZoom, onReset: buildEmbedForecastReset(embedEl) });
              }
              addBrushOverlay(canvas, { isThesisEmbed: true, isZoomed: false, margins: { top: 24, right: 80, bottom: 36, left: 52 }, width: canvas.offsetWidth || 600, height: 220, nPoints: allDates.length, getDateAtIndex: function (i) { return allDates[i]; }, onZoom: forecastZoom });
            }
          }
        } else {
          renderChartIntoEmbed(embedEl, readParamsFromEmbed(embedEl));
        }
      },
      getFullData: function () { return embedEl._chartDataFull; },
      getParams: function () { return params; },
      getEarliestDate: function () {
        var full = embedEl._chartDataFull;
        if (!full) return null;
        if (params.type === 'overlaid' && full.series) {
          var ids = Object.keys(full.series);
          var earliest = null;
          ids.forEach(function (id) {
            var raw = full.series[id];
            var arr = Array.isArray(raw) ? raw : (raw && (raw.data || raw.values)) ? (raw.data || raw.values) : [];
            arr.forEach(function (d) {
              var dStr = (d && d.date != null) ? String(d.date).slice(0, 10) : '';
              if (dStr && (!earliest || dStr < earliest)) earliest = dStr;
            });
          });
          return earliest;
        }
        if (params.type === 'forecast' && full.history && full.history.length) {
          var d = full.history[0].date;
          return d ? String(d).slice(0, 10) : null;
        }
        return null;
      }
    };
  }

  function buildEmbedOverlaidReset(embedEl) {
    return function () {
      if (typeof ThesisManager !== 'undefined') ThesisManager.setLastBrushedRange({ chartId: embedEl.dataset.embedId, start: null, end: null });
      var tr = embedEl.dataset.timeRangeFrom && embedEl.dataset.timeRangeTo ? { from: embedEl.dataset.timeRangeFrom, to: embedEl.dataset.timeRangeTo } : null;
      if (tr) {
        embedEl._chartData = filterOverlaidDataByDateRange(embedEl._chartDataFull, tr.from, tr.to);
      } else {
        embedEl._chartData = embedEl._chartDataFull;
      }
      var p = embedEl._chartParams;
      var canvas = embedEl.querySelector('.chart-embed-canvas');
      if (canvas && p) {
        canvas.innerHTML = renderOverlaidSVG(embedEl._chartData, p.x, p.y, canvas.offsetWidth || 600, 220, p.x, p.y, '');
        var resetDates = datesFromOverlaidData(embedEl._chartData, p.x);
        if (resetDates.length >= 2) {
          function overlaidZoom(r) {
            embedEl._chartData = filterOverlaidDataByDateRange(embedEl._chartData, r.startDate, r.endDate);
            if (typeof ThesisManager !== 'undefined') ThesisManager.setLastBrushedRange({ chartId: embedEl.dataset.embedId, start: toIsoDateString(r.startDate), end: toIsoDateString(r.endDate) });
            canvas.innerHTML = renderOverlaidSVG(embedEl._chartData, p.x, p.y, canvas.offsetWidth || 600, 220, p.x, p.y, '');
            var nextDates = datesFromOverlaidData(embedEl._chartData, p.x);
            if (nextDates.length >= 2) addBrushOverlay(canvas, { isThesisEmbed: true, isZoomed: true, margins: { top: 20, right: 80, bottom: 28, left: 44 }, width: canvas.offsetWidth || 600, height: 220, nPoints: nextDates.length, getDateAtIndex: function (i) { return nextDates[i]; }, onZoom: overlaidZoom, onReset: buildEmbedOverlaidReset(embedEl) });
          }
          addBrushOverlay(canvas, { isThesisEmbed: true, isZoomed: false, margins: { top: 20, right: 80, bottom: 28, left: 44 }, width: canvas.offsetWidth || 600, height: 220, nPoints: resetDates.length, getDateAtIndex: function (i) { return resetDates[i]; }, onZoom: overlaidZoom });
        }
      }
    };
  }

  function buildEmbedForecastReset(embedEl) {
    return function () {
      if (typeof ThesisManager !== 'undefined') ThesisManager.setLastBrushedRange({ chartId: embedEl.dataset.embedId, start: null, end: null });
      var tr = embedEl.dataset.timeRangeFrom && embedEl.dataset.timeRangeTo ? { from: embedEl.dataset.timeRangeFrom, to: embedEl.dataset.timeRangeTo } : null;
      if (tr) {
        embedEl._chartData = filterForecastByDateRange(embedEl._chartDataFull, tr.from, tr.to);
      } else {
        embedEl._chartData = embedEl._chartDataFull;
      }
      var canvas = embedEl.querySelector('.chart-embed-canvas');
      if (canvas) {
        canvas.innerHTML = renderForecastSVG(embedEl._chartData, canvas.offsetWidth || 600, 220);
        var hist = (embedEl._chartData.history && embedEl._chartData.history.slice()) || [];
        var arima = Array.isArray(embedEl._chartData.arima_forecast) ? embedEl._chartData.arima_forecast : [];
        var resetDates = hist.map(function (d) { return d.date; }).concat(arima.map(function (d) { return d.date; }));
        if (resetDates.length >= 2) {
          function forecastZoom(r) {
            embedEl._chartData = filterForecastByDateRange(embedEl._chartData, r.startDate, r.endDate);
            canvas.innerHTML = renderForecastSVG(embedEl._chartData, canvas.offsetWidth || 600, 220);
            var h2 = (embedEl._chartData.history && embedEl._chartData.history.slice()) || [];
            var a2 = Array.isArray(embedEl._chartData.arima_forecast) ? embedEl._chartData.arima_forecast : [];
            var nextDates = h2.map(function (d) { return d.date; }).concat(a2.map(function (d) { return d.date; }));
            if (nextDates.length >= 2) addBrushOverlay(canvas, { isThesisEmbed: true, isZoomed: true, margins: { top: 24, right: 80, bottom: 36, left: 52 }, width: canvas.offsetWidth || 600, height: 220, nPoints: nextDates.length, getDateAtIndex: function (i) { return nextDates[i]; }, onZoom: forecastZoom, onReset: buildEmbedForecastReset(embedEl) });
          }
          addBrushOverlay(canvas, { isThesisEmbed: true, isZoomed: false, margins: { top: 24, right: 80, bottom: 36, left: 52 }, width: canvas.offsetWidth || 600, height: 220, nPoints: resetDates.length, getDateAtIndex: function (i) { return resetDates[i]; }, onZoom: forecastZoom });
        }
      }
    };
  }

  function openChartSettingsPanel(settingsBtn, context) {
    if (!context || !context.headerEl) return;
    var headerEl = context.headerEl;
    document.querySelectorAll('.chart-settings-panel--open, .chart-impact-panel--open').forEach(function (el) {
      el.classList.remove('chart-settings-panel--open', 'chart-impact-panel--open');
    });
    var existing = headerEl.nextElementSibling;
    if (existing && existing.classList && existing.classList.contains('chart-settings-panel')) {
      existing.classList.toggle('chart-settings-panel--open');
      return;
    }
    var panel = buildChartSettingsPanelDOM(context);
    headerEl.parentNode.insertBefore(panel, headerEl.nextSibling);
    panel.classList.add('chart-settings-panel--open');
    var docListener = function (e) {
      if (panel.contains(e.target) || e.target === settingsBtn) return;
      panel.classList.remove('chart-settings-panel--open');
      document.removeEventListener('click', docListener);
    };
    setTimeout(function () { document.addEventListener('click', docListener); }, 0);
  }

  function getEmbedChartImpactContext(embedEl) {
    var headerEl = embedEl.querySelector('.chart-embed-header');
    var params = readParamsFromEmbed(embedEl);
    function getSeries() {
      var raw = embedEl.dataset.customSeries;
      if (raw) { try { return JSON.parse(raw); } catch (e) { } }
      if (params.type === 'overlaid' && params.x && params.y) {
        var u = STATE.universe || [];
        var nx = u.find(function (i) { return i.id === params.x; });
        var ny = u.find(function (i) { return i.id === params.y; });
        return [
          { id: params.x, name: (nx && nx.name) || params.x, color: 'var(--teal)' },
          { id: params.y, name: (ny && ny.name) || params.y, color: 'var(--orange)' }
        ];
      }
      if (params.type === 'forecast' && params.y) {
        var u = STATE.universe || [];
        var ny = u.find(function (i) { return i.id === params.y; });
        return [{ id: params.y, name: (ny && ny.name) || params.y, color: 'var(--teal)' }];
      }
      return [];
    }
    function getSeriesData(seriesId) {
      var data = embedEl._chartData;
      if (!data || !data.series) return null;
      var raw = data.series[seriesId];
      var arr = Array.isArray(raw) ? raw : (raw && (raw.data || raw.values)) ? (raw.data || raw.values) : [];
      return { dates: arr.map(function (d) { return d && d.date; }), values: arr.map(function (d) { return d && d.value != null ? Number(d.value) : null; }) };
    }
    return {
      chartId: embedEl.dataset.embedId || '',
      headerEl: headerEl,
      chartType: params.type,
      getSeries: getSeries,
      getChartContainer: function () { return embedEl.querySelector('.chart-embed-canvas'); },
      getSeriesData: getSeriesData,
      chartRef: embedEl,
      getDecomposition: function (id) { return fetchFactorDecomposition(id); }
    };
  }

  function buildChartImpactPanelDOM(context) {
    var chartId = context.chartId || '';
    var panel = document.createElement('div');
    panel.className = 'chart-impact-panel';
    panel.setAttribute('data-chart-id', chartId);
    panel.style.display = 'none';
    panel.innerHTML = '<div class="chart-impact-header"><span class="chart-impact-title">Event Impact</span><div class="chart-impact-mode-toggle"><button type="button" class="chart-impact-mode-btn chart-impact-mode-btn--active" data-mode="forward">Forward</button><button type="button" class="chart-impact-mode-btn" data-mode="counterfactual">Counterfactual</button></div><button type="button" class="chart-impact-clear">Clear</button></div><div class="chart-impact-shocks"></div><button type="button" class="chart-impact-add-shock">+ Add shock</button><div class="chart-impact-divider"></div><div class="chart-impact-results" style="display:none;"></div><button type="button" class="chart-impact-run">Run</button>';
    var shocksEl = panel.querySelector('.chart-impact-shocks');
    var resultsEl = panel.querySelector('.chart-impact-results');
    var runBtn = panel.querySelector('.chart-impact-run');
    var clearBtn = panel.querySelector('.chart-impact-clear');
    var addShockBtn = panel.querySelector('.chart-impact-add-shock');
    var modeBtns = panel.querySelectorAll('.chart-impact-mode-btn');
    var chartRef = context.chartRef;
    var universe = (STATE.universe || []).filter(function (i) { return i.id; });

    function addOneShockRow(index) {
      var row = document.createElement('div');
      row.className = 'chart-impact-shock-row';
      row.setAttribute('data-shock-index', String(index));
      row.innerHTML = '<div class="chart-impact-shock-instrument"><input type="text" class="chart-impact-shock-input" placeholder="Instrument..." autocomplete="off" /><div class="chart-impact-shock-autocomplete" style="display:none;"></div></div><div class="chart-impact-shock-pct-wrap"><input type="number" class="chart-impact-shock-pct" placeholder="0" step="0.5" /><span class="chart-impact-shock-pct-label">%</span></div><button type="button" class="chart-impact-shock-remove">×</button>';
      var input = row.querySelector('.chart-impact-shock-input');
      var ac = row.querySelector('.chart-impact-shock-autocomplete');
      var pctInput = row.querySelector('.chart-impact-shock-pct');
      var removeBtn = row.querySelector('.chart-impact-shock-remove');
      var debounceT;
      input.addEventListener('input', function () {
        clearTimeout(debounceT);
        var q = input.value.trim();
        ac.style.display = 'none';
        ac.innerHTML = '';
        if (!q || q.length < 2) return;
        debounceT = setTimeout(function () {
          var lower = q.toLowerCase();
          var filtered = universe.filter(function (i) {
            return (String(i.id || '').toLowerCase().indexOf(lower) !== -1) || (String(i.name || '').toLowerCase().indexOf(lower) !== -1);
          }).slice(0, 8);
          ac.innerHTML = '';
          filtered.forEach(function (inst) {
            var div = document.createElement('div');
            div.className = 'chart-impact-shock-autocomplete-item';
            div.setAttribute('data-instrument-id', inst.id);
            var assetCls = inst.asset_class || inst.type || '';
            var meta = inst.sector ? assetCls + ' · ' + inst.sector : assetCls;
            div.innerHTML = '<span class="chart-settings-autocomplete-id">' + escapeHtml(inst.id) + '</span><span class="chart-settings-autocomplete-name">' + escapeHtml(inst.name || inst.id) + '</span><span class="chart-impact-autocomplete-meta">' + escapeHtml(meta) + '</span>';
            div.addEventListener('click', function () {
              if (!inst.id) return;
              row.dataset.selectedId = inst.id;
              input.value = inst.name || inst.id;
              ac.style.display = 'none';
            });
            ac.appendChild(div);
          });

          // Opportunistic live lookup for ticker-like queries (non-blocking)
          var queryUpper = q.toUpperCase();
          var looksLikeTicker = queryUpper.length >= 2 && queryUpper.length <= 6 && /^[A-Z]{2,6}$/.test(queryUpper);
          if (looksLikeTicker && filtered.length < 3) {
            var existingYf = new Set(filtered.map(function (i) { return i.yfinance_ticker; }).filter(Boolean));
            var remaining = Math.max(0, 8 - filtered.length);
            var appended = 0;
            if (remaining > 0) {
              fetch(CONFIG.API_BASE + '/api/instruments/search?q=' + encodeURIComponent(queryUpper))
                .then(function (r) { return r.json(); })
                .then(function (apiResults) {
                  if (input.value.trim() !== q) return;
                  (apiResults || [])
                    .filter(function (x) { return x && (x.source === 'openbb_lookup' || x.source === 'yfinance_lookup'); })
                    .forEach(function (x) {
                      if (appended >= remaining) return;
                      var yf = x.yfinance_ticker || '';
                      if (!yf || existingYf.has(yf)) return;
                      existingYf.add(yf);
                      appended += 1;
                      var div = document.createElement('div');
                      div.className = 'chart-impact-shock-autocomplete-item chart-impact-autocomplete-item--external';
                      div.setAttribute('data-instrument-id', '');
                      div.innerHTML = '<span class="chart-settings-autocomplete-id">' + escapeHtml(yf) + '</span><span class="chart-settings-autocomplete-name">' + escapeHtml(x.name || yf) + '</span><span class="chart-impact-autocomplete-meta">Add from Yahoo Finance</span>';
                      div.addEventListener('click', function () {
                        ac.style.display = 'none';
                        ac.innerHTML = '';
                        var resolvedBody = {
                          ticker: yf,
                          name: x.name || yf,
                          asset_class: x.asset_class || 'equity',
                          sector: x.sector || null,
                          country: x.country || null,
                          currency: x.currency || null
                        };

                        fetch(CONFIG.API_BASE + '/api/instruments/resolve', {
                          method: 'POST',
                          headers: { 'Content-Type': 'application/json' },
                          body: JSON.stringify(resolvedBody)
                        }).then(function (r) { return r.json(); })
                          .then(function (resolved) {
                            if (!resolved || !resolved.id) return;
                            row.dataset.selectedId = resolved.id;
                            input.value = resolved.name || resolved.id;
                            if (!STATE.universe) STATE.universe = [];
                            var exists = STATE.universe.some(function (u) { return u.id === resolved.id; });
                            if (!exists) STATE.universe.push(resolved);

                            var noticeEl = document.createElement('div');
                            noticeEl.textContent = 'Added ' + (resolved.name || resolved.id);
                            noticeEl.style.color = 'var(--accent)';
                            noticeEl.style.fontSize = '12px';
                            noticeEl.style.marginTop = '6px';
                            shocksEl.appendChild(noticeEl);
                            setTimeout(function () { if (noticeEl.parentNode) noticeEl.remove(); }, 2000);
                          });
                      });
                      ac.appendChild(div);
                    });
                  ac.style.display = 'block';
                })
                .catch(function () { /* ignore */ });
            }
          }

          ac.style.display = filtered.length ? 'block' : 'none';
        }, 200);
      });
      input.addEventListener('keydown', function (e) {
        if (e.key === 'Escape') { ac.style.display = 'none'; return; }
        if (e.key === 'Enter' || e.key === 'Tab') {
          if (row.dataset.selectedId) return;
          var typed = (input.value || '').trim();
          var upper = typed.toUpperCase();
          if (!typed) return;
          if (!/^[A-Z]{2,6}$/.test(upper)) return;
          e.preventDefault();
          ac.style.display = 'none';
          ac.innerHTML = '';

          var showNotice = function (text, color) {
            var noticeEl = document.createElement('div');
            noticeEl.textContent = text;
            noticeEl.style.color = color || 'var(--accent)';
            noticeEl.style.fontSize = '12px';
            noticeEl.style.marginTop = '6px';
            shocksEl.appendChild(noticeEl);
            setTimeout(function () { if (noticeEl.parentNode) noticeEl.remove(); }, 2000);
          };

          fetch(CONFIG.API_BASE + '/api/instruments/search?q=' + encodeURIComponent(upper))
            .then(function (r) { return r.json(); })
            .then(function (results) {
              var pick = (results || []).find(function (x) { return x && (x.source === 'openbb_lookup' || x.source === 'yfinance_lookup'); });
              if (!pick) pick = (results || []).find(function (x) { return x && x.id; });
              if (!pick) {
                showNotice('Instrument not found', 'var(--accent)');
                setTimeout(function () { if (input.value.trim() === typed) input.value = ''; }, 2000);
                return;
              }

              // DB match: use id directly
              if (pick.id) {
                row.dataset.selectedId = pick.id;
                input.value = pick.name || pick.id;
                var exists = (STATE.universe || []).some(function (u) { return u.id === pick.id; });
                if (!exists) (STATE.universe = STATE.universe || []).push(pick);
                showNotice('Added ' + (pick.name || pick.id));
                return;
              }

              // Lookup match: resolve lazily then add
              return fetch(CONFIG.API_BASE + '/api/instruments/resolve', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                  ticker: upper,
                  name: pick.name || upper,
                  asset_class: pick.asset_class || 'equity',
                  sector: pick.sector || null,
                  country: pick.country || null,
                  currency: pick.currency || null
                })
              })
                .then(function (r) { return r.json(); })
                .then(function (resolved) {
                  if (!resolved || !resolved.id) {
                    showNotice('Instrument not found', 'var(--accent)');
                    setTimeout(function () { if (input.value.trim() === typed) input.value = ''; }, 2000);
                    return;
                  }
                  row.dataset.selectedId = resolved.id;
                  input.value = resolved.name || resolved.id;
                  var exists = (STATE.universe || []).some(function (u) { return u.id === resolved.id; });
                  if (!exists) (STATE.universe = STATE.universe || []).push(resolved);
                  showNotice('Added ' + (resolved.name || resolved.id));
                });
            })
            .catch(function () {
              showNotice('Instrument not found', 'var(--accent)');
              setTimeout(function () { if (input.value.trim() === typed) input.value = ''; }, 2000);
            });
        }
      });
      removeBtn.addEventListener('click', function () {
        if (shocksEl.querySelectorAll('.chart-impact-shock-row').length <= 1) return;
        row.remove();
        shocksEl.querySelectorAll('.chart-impact-shock-remove').forEach(function (btn) {
          btn.classList.toggle('chart-impact-shock-remove--disabled', shocksEl.querySelectorAll('.chart-impact-shock-row').length <= 1);
        });
      });
      shocksEl.appendChild(row);
      return row;
    }

    var savedShocks = chartRef.shocks || [];
    if (!savedShocks.length && chartRef.dataset && chartRef.dataset.shocks) {
      try { savedShocks = JSON.parse(chartRef.dataset.shocks || '[]'); } catch (e) { savedShocks = []; }
    }
    if (savedShocks.length) {
      shocksEl.innerHTML = '';
      savedShocks.forEach(function (s, idx) {
        var row = addOneShockRow(idx);
        row.dataset.selectedId = s.instrumentId;
        var inst = universe.find(function (i) { return i.id === s.instrumentId; });
        row.querySelector('.chart-impact-shock-input').value = (inst && inst.name) || s.instrumentId || '';
        row.querySelector('.chart-impact-shock-pct').value = String(s.shockPct);
      });
      shocksEl.querySelectorAll('.chart-impact-shock-remove').forEach(function (btn) {
        btn.classList.toggle('chart-impact-shock-remove--disabled', shocksEl.querySelectorAll('.chart-impact-shock-row').length <= 1);
      });
    } else {
      addOneShockRow(0);
      shocksEl.querySelector('.chart-impact-shock-remove').classList.add('chart-impact-shock-remove--disabled');
    }

    addShockBtn.addEventListener('click', function () {
      var rows = shocksEl.querySelectorAll('.chart-impact-shock-row');
      if (rows.length >= 5) return;
      var idx = rows.length;
      addOneShockRow(idx);
      shocksEl.querySelectorAll('.chart-impact-shock-remove').forEach(function (btn) {
        btn.classList.remove('chart-impact-shock-remove--disabled');
      });
    });

    function collectShockRows() {
      var rows = shocksEl.querySelectorAll('.chart-impact-shock-row');
      var out = [];
      for (var i = 0; i < rows.length; i++) {
        var id = rows[i].dataset.selectedId;
        var pct = parseFloat(rows[i].querySelector('.chart-impact-shock-pct').value);
        if (id && !isNaN(pct) && pct !== 0) out.push({ instrumentId: id, shockPct: pct });
      }
      return out;
    }

    function validateShockRows() {
      var rows = shocksEl.querySelectorAll('.chart-impact-shock-row');
      var valid = true;
      rows.forEach(function (row) {
        var hasId = !!row.dataset.selectedId;
        var pct = row.querySelector('.chart-impact-shock-pct');
        var val = pct ? parseFloat(pct.value) : NaN;
        var hasPct = !isNaN(val) && val !== 0;
        row.querySelector('.chart-impact-shock-input').classList.toggle('chart-impact-shock-input--error', !hasId);
        if (pct) pct.classList.toggle('chart-impact-shock-pct--error', !hasPct);
        if ((hasId && !hasPct) || (!hasId && hasPct)) valid = false;
      });
      return valid && rows.length > 0 && !!rows[0].dataset.selectedId && !isNaN(parseFloat(rows[0].querySelector('.chart-impact-shock-pct').value));
    }

    function renderResultsTable(seriesList, impactResults) {
      var header = '<div class="chart-impact-results-header"><span>Instrument</span><span>Impact</span><span>Conf</span></div>';
      var rows = '';
      for (var i = 0; i < seriesList.length; i++) {
        var ent = seriesList[i];
        var res = impactResults[ent.id];
        var name = ent.name || ent.id;
        var impactStr = '—';
        var impactCls = '';
        var confStr = 'N/A';
        var confCls = 'low';
        if (res && res.error) {
          impactStr = '—';
          confStr = 'N/A';
        } else if (res) {
          var pct = res.totalImpactPct * 100;
          impactStr = (pct >= 0 ? '+' : '') + pct.toFixed(2) + '%';
          impactCls = pct >= 0 ? 'positive' : 'negative';
          var r2 = res.bestR2 != null ? res.bestR2 : 0;
          if (r2 >= 0.5) { confStr = 'HIGH'; confCls = 'high'; } else if (r2 >= 0.2) { confStr = 'MED'; confCls = 'med'; } else { confStr = 'LOW'; confCls = 'low'; }
        }
        rows += '<div class="chart-impact-results-row"><span class="chart-impact-results-name">' + escapeHtml(name) + '</span><span class="chart-impact-results-impact ' + impactCls + '">' + escapeHtml(impactStr) + '</span><span class="chart-impact-results-conf ' + confCls + '">' + escapeHtml(confStr) + '</span></div>';
      }
      resultsEl.innerHTML = '<div class="chart-impact-results-table">' + header + rows + '</div>';
      resultsEl.style.display = 'block';
    }

    runBtn.addEventListener('click', function () {
      if (!validateShockRows()) return;
      var seriesList = context.getSeries();
      if (!seriesList || seriesList.length === 0) return;
      var shockRows = shocksEl.querySelectorAll('.chart-impact-shock-row');
      runBtn.disabled = true;
      (async function () {
        var impactResults = {};
        for (var i = 0; i < seriesList.length; i++) {
          var ent = seriesList[i];
          impactResults[ent.id] = await computeImpactForSeries(ent.id, shockRows);
        }
        chartRef.impactResults = impactResults;
        chartRef.shocks = collectShockRows();
        chartRef.impactMode = 'forward';
        if (context.type === 'board' && typeof ThesisManager !== 'undefined' && ThesisManager.persistBoard) ThesisManager.persistBoard();
        if (context.type === 'embed' && chartRef.dataset) {
          chartRef.dataset.shocks = JSON.stringify(chartRef.shocks);
          chartRef.dataset.impactMode = chartRef.impactMode || '';
          if (typeof ThesisManager !== 'undefined' && ThesisManager.markDirty) ThesisManager.markDirty();
        }
        renderResultsTable(seriesList, impactResults);
        var container = context.getChartContainer();
        removeImpactOverlays(container);
        renderForwardOverlay(container, seriesList, impactResults, context.getSeriesData);
        runBtn.disabled = false;
      })();
    });

    modeBtns.forEach(function (btn) {
      btn.addEventListener('click', function () {
        var mode = btn.getAttribute('data-mode');
        if (!chartRef.impactResults || !chartRef.shocks || chartRef.shocks.length === 0) return;
        modeBtns.forEach(function (b) { b.classList.remove('chart-impact-mode-btn--active'); });
        btn.classList.add('chart-impact-mode-btn--active');
        chartRef.impactMode = mode;
        if (context.type === 'board' && typeof ThesisManager !== 'undefined' && ThesisManager.persistBoard) ThesisManager.persistBoard();
        if (context.type === 'embed' && chartRef.dataset) {
          chartRef.dataset.shocks = JSON.stringify(chartRef.shocks);
          chartRef.dataset.impactMode = chartRef.impactMode || '';
          if (typeof ThesisManager !== 'undefined' && ThesisManager.markDirty) ThesisManager.markDirty();
        }
        var container = context.getChartContainer();
        removeImpactOverlays(container);
        var seriesList = context.getSeries();
        if (mode === 'forward') {
          renderForwardOverlay(container, seriesList, chartRef.impactResults, context.getSeriesData);
        } else {
          renderCounterfactualOverlay(container, seriesList, chartRef.shocks, context.getSeriesData, context.getDecomposition);
        }
      });
    });

    clearBtn.addEventListener('click', function () {
      var container = context.getChartContainer();
      removeImpactOverlays(container);
      resultsEl.style.display = 'none';
      resultsEl.innerHTML = '';
      shocksEl.innerHTML = '';
      addOneShockRow(0);
      shocksEl.querySelector('.chart-impact-shock-remove').classList.add('chart-impact-shock-remove--disabled');
      chartRef.impactMode = null;
      chartRef.impactResults = {};
      chartRef.shocks = [];
      if (context.type === 'board' && typeof ThesisManager !== 'undefined' && ThesisManager.persistBoard) ThesisManager.persistBoard();
      if (context.type === 'embed' && chartRef.dataset) {
        chartRef.dataset.shocks = '[]';
        chartRef.dataset.impactMode = '';
        if (typeof ThesisManager !== 'undefined' && ThesisManager.markDirty) ThesisManager.markDirty();
      }
      panel.classList.remove('chart-impact-panel--open');
      panel.style.display = 'none';
    });

    return panel;
  }

  function openChartImpactPanel(impactBtn, context) {
    if (!context || !context.headerEl) return;
    var headerEl = context.headerEl;
    document.querySelectorAll('.chart-settings-panel--open, .chart-impact-panel--open').forEach(function (el) {
      el.classList.remove('chart-settings-panel--open', 'chart-impact-panel--open');
    });
    var existing = headerEl.nextElementSibling;
    if (existing && existing.classList && existing.classList.contains('chart-impact-panel')) {
      existing.style.display = '';
      existing.classList.add('chart-impact-panel--open');
      return;
    }
    var panel = buildChartImpactPanelDOM(context);
    panel.style.display = '';
    headerEl.parentNode.insertBefore(panel, headerEl.nextSibling);
    panel.classList.add('chart-impact-panel--open');
    var docListener = function (e) {
      if (panel.contains(e.target) || e.target === impactBtn) return;
      panel.classList.remove('chart-impact-panel--open');
      document.removeEventListener('click', docListener);
    };
    setTimeout(function () { document.addEventListener('click', docListener); }, 0);
  }

  function buildChartSettingsPanelDOM(context) {
    var chartId = context.chartId || '';
    var panel = document.createElement('div');
    panel.className = 'chart-settings-panel';
    panel.setAttribute('data-chart-id', chartId);
    panel.innerHTML = '<div class="chart-settings-section"><div class="chart-settings-section-title">Series</div><div class="chart-settings-series-list"></div><div class="chart-settings-add-series"><input type="text" class="chart-settings-add-input" placeholder="Add instrument..." autocomplete="off" /><div class="chart-settings-autocomplete" style="display:none;"></div></div></div><div class="chart-settings-divider"></div><div class="chart-settings-section"><div class="chart-settings-section-title">Time Range</div><div class="chart-settings-presets"><button type="button" class="chart-settings-preset" data-preset="1M">1M</button><button type="button" class="chart-settings-preset" data-preset="3M">3M</button><button type="button" class="chart-settings-preset" data-preset="6M">6M</button><button type="button" class="chart-settings-preset" data-preset="1Y">1Y</button><button type="button" class="chart-settings-preset" data-preset="ALL">All</button></div><div class="chart-settings-daterange"><input type="date" class="chart-settings-date-from" /><span class="chart-settings-date-sep">to</span><input type="date" class="chart-settings-date-to" /></div></div>';
    var seriesListEl = panel.querySelector('.chart-settings-series-list');
    var addInput = panel.querySelector('.chart-settings-add-input');
    var autocompleteEl = panel.querySelector('.chart-settings-autocomplete');
    var fromInput = panel.querySelector('.chart-settings-date-from');
    var toInput = panel.querySelector('.chart-settings-date-to');

    function renderSeriesRows() {
      seriesListEl.innerHTML = '';
      var list = context.getSeries();
      for (var i = 0; i < list.length; i++) {
        var s = list[i];
        var row = document.createElement('div');
        row.className = 'chart-settings-series-row';
        row.setAttribute('data-series-id', s.id);
        var color = s.color || 'var(--teal)';
        if (color.indexOf('var(') !== -1) {
          var varName = color.replace(/var\(([^)]+)\)/, '$1').trim();
          var resolved = document.documentElement && getComputedStyle(document.documentElement).getPropertyValue(varName).trim();
          if (resolved) color = resolved;
        }
        row.innerHTML = '<span class="chart-settings-series-color" style="background:' + color + ';"></span><span class="chart-settings-series-name">' + escapeHtml(s.name || s.id) + '</span><button type="button" class="chart-settings-series-remove" aria-label="Remove">×</button>';
        var removeBtn = row.querySelector('.chart-settings-series-remove');
        if (list.length <= 1) removeBtn.classList.add('chart-settings-series-remove--disabled');
        removeBtn.addEventListener('click', function () {
          var id = row.getAttribute('data-series-id');
          var next = list.filter(function (x) { return x.id !== id; });
          if (next.length < 1) return;
          context.setSeries(next);
          context.reRender();
          row.remove();
          panel.querySelectorAll('.chart-settings-series-remove').forEach(function (btn) {
            if (panel.querySelectorAll('.chart-settings-series-row').length <= 1) btn.classList.add('chart-settings-series-remove--disabled');
            else btn.classList.remove('chart-settings-series-remove--disabled');
          });
        });
        seriesListEl.appendChild(row);
      }
    }
    renderSeriesRows();

    var debounceTimer;
    addInput.addEventListener('input', function () {
      clearTimeout(debounceTimer);
      var q = addInput.value.trim();
      debounceTimer = setTimeout(function () {
        autocompleteEl.style.display = 'none';
        autocompleteEl.innerHTML = '';
          if (!q || q.length < 2) return;
        var universe = (STATE.universe || []).filter(function (i) { return i.id; });
        var lower = q.toLowerCase();
        var filtered = universe.filter(function (i) {
          return (String(i.id || '').toLowerCase().indexOf(lower) !== -1) || (String(i.name || '').toLowerCase().indexOf(lower) !== -1);
        }).slice(0, 8);
        filtered.forEach(function (inst) {
          var div = document.createElement('div');
          div.className = 'chart-settings-autocomplete-item';
          div.setAttribute('data-instrument-id', inst.id);
            var assetCls = inst.asset_class || inst.type || '';
            var meta = inst.sector ? assetCls + ' · ' + inst.sector : assetCls;
            div.innerHTML = '<span class="chart-settings-autocomplete-id">' + escapeHtml(inst.id) + '</span><span class="chart-settings-autocomplete-name">' + escapeHtml(inst.name || inst.id) + '</span><span class="chart-settings-autocomplete-meta">' + escapeHtml(meta) + '</span>';
          div.addEventListener('click', function () {
            var instrumentId = div.getAttribute('data-instrument-id');
              if (!instrumentId) return;
            autocompleteEl.style.display = 'none';
            addInput.value = '';
            var list = context.getSeries();
            if (list.some(function (x) { return x.id === instrumentId; })) return;
            addInput.disabled = true;
            var addWrap = panel.querySelector('.chart-settings-add-series');
            var loadingEl = document.createElement('span');
            loadingEl.className = 'chart-settings-add-loading';
            loadingEl.textContent = 'Loading...';
            addWrap.appendChild(loadingEl);
            fetchPriceSeries([instrumentId]).then(function (map) {
              var result = map[instrumentId];
              if (result && result.error) {
                var errEl = document.createElement('div');
                errEl.className = 'chart-settings-add-error';
                errEl.textContent = 'Could not load ' + instrumentId;
                addWrap.appendChild(errEl);
                setTimeout(function () { if (errEl.parentNode) errEl.remove(); }, 4000);
              } else if (result && result.dates && result.values) {
                var list = context.getSeries();
                var idx = Math.max(0, list.length - 2);
                var color = EXTRA_SERIES_COLORS[idx % EXTRA_SERIES_COLORS.length];
                list.push({ id: result.id, name: result.name || result.id, color: color });
                context.setSeries(list);
                if (context.addSeriesData) context.addSeriesData(instrumentId, result);
                context.reRender();
                renderSeriesRows();
              }
            }).catch(function () {
              var errEl = document.createElement('div');
              errEl.className = 'chart-settings-add-error';
              errEl.textContent = 'Could not load ' + instrumentId;
              addWrap.appendChild(errEl);
              setTimeout(function () { if (errEl.parentNode) errEl.remove(); }, 4000);
            }).finally(function () {
              if (loadingEl.parentNode) loadingEl.remove();
              addInput.disabled = false;
            });
          });
          autocompleteEl.appendChild(div);
        });
        // Opportunistic live lookup for ticker-like queries (non-blocking)
        var queryUpper = q.toUpperCase();
        var looksLikeTicker = queryUpper.length >= 2 && queryUpper.length <= 6 && /^[A-Z]{2,6}$/.test(queryUpper);
        if (looksLikeTicker && filtered.length < 3) {
          var existingYf = new Set(filtered.map(function (i) { return i.yfinance_ticker; }).filter(Boolean));
          var remaining = Math.max(0, 8 - filtered.length);
          var appended = 0;
          fetch(CONFIG.API_BASE + '/api/instruments/search?q=' + encodeURIComponent(queryUpper))
            .then(function (r) { return r.json(); })
            .then(function (apiResults) {
              if (addInput.value.trim() !== q) return;
              (apiResults || [])
                .filter(function (x) { return x && (x.source === 'openbb_lookup' || x.source === 'yfinance_lookup'); })
                .forEach(function (x) {
                  if (appended >= remaining) return;
                  var yf = x.yfinance_ticker || '';
                  if (!yf || existingYf.has(yf)) return;
                  existingYf.add(yf);
                  appended += 1;
                  var div = document.createElement('div');
                  div.className = 'chart-settings-autocomplete-item chart-settings-autocomplete-item--external';
                  div.setAttribute('data-instrument-id', '');
                  div.innerHTML = '<span class="chart-settings-autocomplete-id">' + escapeHtml(yf) + '</span><span class="chart-settings-autocomplete-name">' + escapeHtml(x.name || yf) + '</span><span class="chart-settings-autocomplete-meta">Add from Yahoo Finance</span>';
                  div.addEventListener('click', function () {
                    autocompleteEl.style.display = 'none';
                    addInput.value = '';
                    var resolvedBody = {
                      ticker: yf,
                      name: x.name || yf,
                      asset_class: x.asset_class || 'equity',
                      sector: x.sector || null,
                      country: x.country || null,
                      currency: x.currency || null
                    };

                    var addWrap = panel.querySelector('.chart-settings-add-series');
                    var showNotice = function (text) {
                      var noticeEl = document.createElement('div');
                      noticeEl.textContent = text;
                      noticeEl.style.color = 'var(--accent)';
                      noticeEl.style.fontSize = '12px';
                      noticeEl.style.marginTop = '6px';
                      addWrap.appendChild(noticeEl);
                      setTimeout(function () { if (noticeEl.parentNode) noticeEl.remove(); }, 2000);
                    };

                    fetch(CONFIG.API_BASE + '/api/instruments/resolve', {
                      method: 'POST',
                      headers: { 'Content-Type': 'application/json' },
                      body: JSON.stringify(resolvedBody)
                    }).then(function (r) { return r.json(); })
                      .then(function (resolved) {
                        if (!resolved || !resolved.id) return;
                        var list = context.getSeries();
                        if (list.some(function (s) { return s.id === resolved.id; })) {
                          return;
                        }
                        if (!STATE.universe) STATE.universe = [];
                        var exists = STATE.universe.some(function (u) { return u.id === resolved.id; });
                        if (!exists) STATE.universe.push(resolved);

                        addInput.disabled = true;
                        var loadingEl = document.createElement('span');
                        loadingEl.className = 'chart-settings-add-loading';
                        loadingEl.textContent = 'Loading...';
                        addWrap.appendChild(loadingEl);

                        fetchPriceSeries([resolved.id]).then(function (map) {
                          var result = map[resolved.id];
                          if (result && result.error) {
                            var errEl = document.createElement('div');
                            errEl.className = 'chart-settings-add-error';
                            errEl.textContent = 'Could not load ' + resolved.id;
                            addWrap.appendChild(errEl);
                            setTimeout(function () { if (errEl.parentNode) errEl.remove(); }, 4000);
                          } else if (result && result.dates && result.values) {
                            var list2 = context.getSeries();
                            var idx = Math.max(0, list2.length - 2);
                            var color = EXTRA_SERIES_COLORS[idx % EXTRA_SERIES_COLORS.length];
                            list2.push({ id: result.id, name: result.name || result.id, color: color });
                            context.setSeries(list2);
                            if (context.addSeriesData) context.addSeriesData(resolved.id, result);
                            context.reRender();
                            renderSeriesRows();
                            showNotice('Added ' + (result.name || result.id));
                          }
                        }).catch(function () {
                          var errEl = document.createElement('div');
                          errEl.className = 'chart-settings-add-error';
                          errEl.textContent = 'Could not load ' + resolved.id;
                          addWrap.appendChild(errEl);
                          setTimeout(function () { if (errEl.parentNode) errEl.remove(); }, 4000);
                        }).finally(function () {
                          if (loadingEl.parentNode) loadingEl.remove();
                          addInput.disabled = false;
                        });
                      });
                  });
                  autocompleteEl.appendChild(div);
                });
              autocompleteEl.style.display = 'block';
            })
            .catch(function () { /* ignore */ });
        }
        autocompleteEl.style.display = 'block';
      }, 200);
    });
    addInput.addEventListener('keydown', function (e) {
      if (e.key === 'Escape') { autocompleteEl.style.display = 'none'; addInput.blur(); }
      if (e.key === 'Enter' || e.key === 'Tab') {
        var typed = (addInput.value || '').trim();
        var upper = typed.toUpperCase();
        if (!typed) return;
        if (!/^[A-Z]{2,6}$/.test(upper)) return;
        e.preventDefault();
        // Only trigger when user hasn't selected an autocomplete item (input stays non-empty).
        var list = context.getSeries();
        var addWrap = panel.querySelector('.chart-settings-add-series');
        var showNotice = function (text, color) {
          var noticeEl = document.createElement('div');
          noticeEl.textContent = text;
          noticeEl.style.color = color || 'var(--text-secondary)';
          noticeEl.style.fontSize = '12px';
          noticeEl.style.marginTop = '6px';
          addWrap.appendChild(noticeEl);
          setTimeout(function () { if (noticeEl.parentNode) noticeEl.remove(); }, 2000);
        };

        fetch(CONFIG.API_BASE + '/api/instruments/search?q=' + encodeURIComponent(upper))
          .then(function (r) { return r.json(); })
          .then(function (results) {
            var pick = (results || []).find(function (x) { return x && x.yfinance_ticker === upper && (x.source === 'openbb_lookup' || x.source === 'yfinance_lookup'); });
            // If not a lookup result, fall back to any DB match that has an id.
            if (!pick) pick = (results || []).find(function (x) { return x && x.id; });
            if (!pick) {
              showNotice('Instrument not found', 'var(--accent)');
              setTimeout(function () { if (addInput.value.trim() === typed) addInput.value = ''; }, 2000);
              return;
            }

            function addSeriesById(instrumentId, instrumentName) {
              if (!instrumentId) return;
              if (list.some(function (x) { return x.id === instrumentId; })) return;
              addInput.disabled = true;
              addInput.value = '';
              var loadingEl = document.createElement('span');
              loadingEl.className = 'chart-settings-add-loading';
              loadingEl.textContent = 'Loading...';
              addWrap.appendChild(loadingEl);
              fetchPriceSeries([instrumentId]).then(function (map) {
                var result = map[instrumentId];
                if (result && result.error) {
                  var errEl = document.createElement('div');
                  errEl.className = 'chart-settings-add-error';
                  errEl.textContent = 'Could not load ' + instrumentId;
                  addWrap.appendChild(errEl);
                  setTimeout(function () { if (errEl.parentNode) errEl.remove(); }, 4000);
                } else if (result && result.dates && result.values) {
                  var idx = Math.max(0, list.length - 2);
                  var color = EXTRA_SERIES_COLORS[idx % EXTRA_SERIES_COLORS.length];
                  var list2 = context.getSeries();
                  list2.push({ id: result.id, name: result.name || result.id, color: color });
                  context.setSeries(list2);
                  if (context.addSeriesData) context.addSeriesData(instrumentId, result);
                  context.reRender();
                  renderSeriesRows();
                  showNotice('Added ' + (result.name || instrumentName || instrumentId), 'var(--accent)');
                }
              }).catch(function () {
                var errEl = document.createElement('div');
                errEl.className = 'chart-settings-add-error';
                errEl.textContent = 'Could not load ' + instrumentId;
                addWrap.appendChild(errEl);
                setTimeout(function () { if (errEl.parentNode) errEl.remove(); }, 4000);
              }).finally(function () {
                if (loadingEl.parentNode) loadingEl.remove();
                addInput.disabled = false;
              });
            }

            if (pick.id) {
              // DB match: use id directly
              // Push to universe if missing
              var existing = (STATE.universe || []).some(function (u) { return u.id === pick.id; });
              if (!existing) (STATE.universe = STATE.universe || []).push(pick);
              addSeriesById(pick.id, pick.name);
              return;
            }

            // Lookup match: resolve lazily and then add
            return fetch(CONFIG.API_BASE + '/api/instruments/resolve', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                ticker: upper,
                name: pick.name,
                asset_class: pick.asset_class || 'equity',
                sector: pick.sector || null,
                country: pick.country || null,
                currency: pick.currency || null,
              })
            }).then(function (r) { return r.json(); })
              .then(function (resolved) {
                if (!resolved || !resolved.id) return;
                var existing = (STATE.universe || []).some(function (u) { return u.id === resolved.id; });
                if (!existing) (STATE.universe = STATE.universe || []).push(resolved);
                addSeriesById(resolved.id, resolved.name);
              });
          })
          .catch(function () {
            showNotice('Instrument not found', 'var(--accent)');
          });
      }
    });

    var today = new Date();
    function toDateStr(d) { return d.toISOString ? d.toISOString().split('T')[0] : String(d).slice(0, 10); }
    function presetToRange(preset) {
      if (preset === '1M') return { from: toDateStr(new Date(today.getTime() - 30 * 24 * 60 * 60 * 1000)), to: toDateStr(today) };
      if (preset === '3M') return { from: toDateStr(new Date(today.getTime() - 90 * 24 * 60 * 60 * 1000)), to: toDateStr(today) };
      if (preset === '6M') return { from: toDateStr(new Date(today.getTime() - 180 * 24 * 60 * 60 * 1000)), to: toDateStr(today) };
      if (preset === '1Y') return { from: toDateStr(new Date(today.getTime() - 365 * 24 * 60 * 60 * 1000)), to: toDateStr(today) };
      if (preset === 'ALL' && context.getEarliestDate) {
        var ed = context.getEarliestDate();
        return { from: ed || toDateStr(new Date(today.getTime() - 365 * 24 * 60 * 60 * 1000)), to: toDateStr(today) };
      }
      return null;
    }
    panel.querySelectorAll('.chart-settings-preset').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var preset = btn.getAttribute('data-preset');
        panel.querySelectorAll('.chart-settings-preset').forEach(function (b) { b.classList.remove('chart-settings-preset--active'); });
        btn.classList.add('chart-settings-preset--active');
        var range = presetToRange(preset);
        if (range) {
          fromInput.value = range.from;
          toInput.value = range.to;
          fromInput.classList.remove('chart-settings-date-from--error');
          toInput.classList.remove('chart-settings-date-to--error');
          context.setTimeRange({ from: range.from, to: range.to, preset: preset });
          if (context.rescaleToRange) context.rescaleToRange(range.from, range.to);
        }
      });
    });
    fromInput.addEventListener('change', function () {
      var from = fromInput.value;
      var to = toInput.value;
      if (from && to && from >= to) {
        fromInput.classList.add('chart-settings-date-from--error');
        toInput.classList.add('chart-settings-date-to--error');
        return;
      }
      fromInput.classList.remove('chart-settings-date-from--error');
      toInput.classList.remove('chart-settings-date-to--error');
      panel.querySelectorAll('.chart-settings-preset').forEach(function (b) { b.classList.remove('chart-settings-preset--active'); });
      context.setTimeRange(from && to ? { from: from, to: to, preset: null } : null);
      if (from && to && context.rescaleToRange) context.rescaleToRange(from, to);
    });
    toInput.addEventListener('change', function () {
      var from = fromInput.value;
      var to = toInput.value;
      if (from && to && from >= to) {
        fromInput.classList.add('chart-settings-date-from--error');
        toInput.classList.add('chart-settings-date-to--error');
        return;
      }
      fromInput.classList.remove('chart-settings-date-from--error');
      toInput.classList.remove('chart-settings-date-to--error');
      panel.querySelectorAll('.chart-settings-preset').forEach(function (b) { b.classList.remove('chart-settings-preset--active'); });
      context.setTimeRange(from && to ? { from: from, to: to, preset: null } : null);
      if (from && to && context.rescaleToRange) context.rescaleToRange(from, to);
    });
    var tr = context.getTimeRange();
    if (tr) {
      fromInput.value = tr.from || '';
      toInput.value = tr.to || '';
    }

    if (context.chartType === 'forecast') {
      panel.querySelector('.chart-settings-add-series').style.display = 'none';
    }
    return panel;
  }

  function getThesisHtmlForSave() {
    var editor = document.getElementById('thesis-editor');
    if (!editor) return '';
    editor.querySelectorAll('.thesis-chart-embed').forEach(function (embed) {
      embed.dataset.shocks = JSON.stringify(embed.shocks || []);
      embed.dataset.impactMode = embed.impactMode || '';
    });
    var clone = editor.cloneNode(true);
    clone.querySelectorAll('.chart-embed-canvas').forEach(function (c) { c.innerHTML = ''; });
    var popover = clone.querySelector('#chart-embed-popover');
    if (popover) popover.parentNode.removeChild(popover);
    clone.querySelectorAll('.thesis-chart-embed-resize-wrapper').forEach(function (wrap) {
      var embed = wrap.querySelector('.thesis-chart-embed');
      if (embed) {
        var parent = wrap.parentNode;
        if (parent) parent.replaceChild(embed, wrap);
      }
    });
    return clone.innerHTML;
  }

  function collectThesisMetadata() {
    var metadata = { board_cards: [], embed_configs: {} };

    // Board cards
    var boardCards = (typeof ThesisManager !== 'undefined' && ThesisManager._boardCards)
      ? ThesisManager._boardCards
      : (STATE && STATE.boardCards ? STATE.boardCards : []);
    metadata.board_cards = (boardCards || []).map(function (card) {
      return {
        id: card.id,
        type: card.type,
        label: card.label,
        customSeries: card.customSeries || [],
        timeRange: card.timeRange || null,
        shocks: card.shocks || [],
        impactMode: card.impactMode || null,
        width: card.width || null,
        height: card.height || null,
      };
    });

    // Embed configs — read from live DOM
    var editor = document.getElementById('thesis-editor');
    if (editor) {
      editor.querySelectorAll('.thesis-chart-embed').forEach(function (embed) {
        var embedId = embed.dataset.embedId || embed.dataset.id;
        if (!embedId) return;
        metadata.embed_configs[embedId] = {
          type: embed.dataset.type,
          x: embed.dataset.x,
          y: embed.dataset.y,
          customSeries: JSON.parse(embed.dataset.customSeries || '[]'),
          timeRangeFrom: embed.dataset.timeRangeFrom || null,
          timeRangeTo: embed.dataset.timeRangeTo || null,
          timeRangePreset: embed.dataset.timeRangePreset || null,
          shocks: JSON.parse(embed.dataset.shocks || '[]'),
          impactMode: embed.dataset.impactMode || null,
          width: embed.dataset.width || null,
          height: embed.dataset.height || null,
        };
      });
    }

    return metadata;
  }

  async function insertChartEmbed(params) {
    var editor = document.getElementById('thesis-editor');
    if (!editor) {
      console.warn('[insertChartEmbed] thesis editor not found');
      return;
    }
    if (!params.embedId) params.embedId = generateEmbedId();
    var embedEl = buildEmbedShell(params);
    var wrapper = createThesisChartEmbedResizeWrapper(embedEl, params.width || embedEl.dataset.width, params.height || embedEl.dataset.height);

    editor.focus();
    var sel = window.getSelection();
    var blockTags = ['P', 'DIV', 'H1', 'H2', 'H3', 'LI', 'BLOCKQUOTE'];
    function isBlock(el) {
      return el && el.nodeType === Node.ELEMENT_NODE && blockTags.indexOf(el.tagName) !== -1;
    }
    function blockAncestorOrSelf(node) {
      var n = node.nodeType === Node.TEXT_NODE ? node.parentNode : node;
      while (n && n !== editor) {
        if (n.nodeType === Node.ELEMENT_NODE && (isBlock(n) || n.classList && (n.classList.contains('thesis-chart-embed-resize-wrapper') || n.classList.contains('thesis-chart-embed') || n.classList.contains('at-chip')))) return n;
        n = n.parentNode;
      }
      return n && n !== editor ? n : null;
    }
    if (sel && sel.rangeCount) {
      var range = sel.getRangeAt(0);
      range.collapse(true);
      var ref = range.startContainer;
      if (ref.nodeType === Node.TEXT_NODE) ref = ref.parentNode;
      var inside = ref.closest ? ref.closest('.thesis-chart-embed, .at-chip') : null;
      if (inside) {
        var insertAfter = (inside.classList && inside.classList.contains('thesis-chart-embed')) ? inside.parentNode : inside;
        insertAfter.insertAdjacentElement('afterend', wrapper);
      } else {
        var block = blockAncestorOrSelf(ref);
        if (block && block.parentNode === editor) {
          block.insertAdjacentElement('afterend', wrapper);
        } else if (block && block.parentNode) {
          block.parentNode.insertBefore(wrapper, block.nextSibling);
        } else {
          editor.appendChild(wrapper);
        }
      }
    } else {
      editor.appendChild(wrapper);
    }

    var spacer = document.createElement('p');
    spacer.innerHTML = '<br>';
    wrapper.insertAdjacentElement('afterend', spacer);

    var newRange = document.createRange();
    newRange.setStart(spacer, 0);
    newRange.collapse(true);
    var newSel = window.getSelection();
    if (newSel) {
      newSel.removeAllRanges();
      newSel.addRange(newRange);
    }

    await renderChartIntoEmbed(embedEl, params);
    wireEmbedButtons(embedEl);
    wireThesisChartEmbedResize(wrapper);
    if (typeof ThesisManager !== 'undefined' && ThesisManager.markDirty) ThesisManager.markDirty();
  }

  if (typeof window !== 'undefined') {
    window.insertChartEmbed = insertChartEmbed;
    window.renderChartIntoEmbed = renderChartIntoEmbed;
    window.buildEmbedShell = buildEmbedShell;
    window.readParamsFromEmbed = readParamsFromEmbed;
    window.wireEmbedButtons = wireEmbedButtons;
    window.getThesisHtmlForSave = getThesisHtmlForSave;
  }

  var ThesisManager = {
    STORAGE_KEY: 'researchTheses',
    _theses: [],
    _activeThesis: null,
    _autoSaveTimer: null,
    _isDirty: false,
    _boardCards: [],

    loadAll: async function () {
      await this._migrateFromLocalStorage();
      try {
        var res = await fetch(CONFIG.API_BASE + '/api/research-theses');
        var theses = await res.json();
        this._theses = Array.isArray(theses) ? theses : [];
      } catch (e) {
        console.warn('ThesisManager.loadAll failed:', e);
        this._theses = [];
      }
      return this._theses;
    },

    getActive: function () {
      return this._activeThesis;
    },

    getThesisList: function () {
      return this._theses.slice().sort(function (a, b) {
        return new Date(b.updated_at) - new Date(a.updated_at);
      });
    },

    setActive: async function (id) {
      try {
        var res = await fetch(CONFIG.API_BASE + '/api/research-theses/' + id);
        if (!res.ok) throw new Error('not found');
        var thesis = await res.json();
        this._activeThesis = thesis;
        this._isDirty = false;
        this._updateSaveIndicator('');
        return thesis;
      } catch (e) {
        console.warn('ThesisManager.setActive failed:', e);
        return null;
      }
    },

    createNew: async function (title) {
      try {
        var res = await fetch(CONFIG.API_BASE + '/api/research-theses', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ title: title || 'Untitled Thesis' })
        });
        var thesis = await res.json();
        this._theses.unshift(thesis);
        this._activeThesis = thesis;
        this._isDirty = false;
        this._updateSaveIndicator('');
        return thesis;
      } catch (e) {
        console.warn('ThesisManager.createNew failed:', e);
        return null;
      }
    },

    save: async function (id, title, content_html, versionLabel) {
      // Supports existing call signature: save(id, title, content_html)
      // Also supports: save(versionLabel) or save()
      var targetId = null;
      var targetTitle = null;
      var targetHtml = null;
      var label = null;

      if (typeof id === 'string' && id.indexOf('-') !== -1) {
        targetId = id;
        targetTitle = title;
        targetHtml = content_html;
        label = versionLabel || null;
      } else if (typeof id === 'string' || id == null) {
        targetId = this._activeThesis ? this._activeThesis.id : null;
        targetTitle = null;
        targetHtml = null;
        label = typeof id === 'string' ? id : null;
      } else {
        targetId = this._activeThesis ? this._activeThesis.id : null;
      }

      if (!targetId) return null;

      try {
        if (targetTitle !== null && targetTitle !== undefined) {
          await fetch(CONFIG.API_BASE + '/api/research-theses/' + targetId, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ title: targetTitle })
          });
        }

        var html = (targetHtml !== null && targetHtml !== undefined) ? targetHtml : getThesisHtmlForSave();
        var metadata = collectThesisMetadata();
        var body = { content_html: html, metadata: metadata };
        if (this._activeThesis && this._activeThesis.canvas_layout) {
          body.canvas_layout = this._activeThesis.canvas_layout;
        }
        if (label) body.version_label = label;

        var res = await fetch(CONFIG.API_BASE + '/api/research-theses/' + targetId + '/save', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(body)
        });
        var data = await res.json();
        this._activeThesis = data.thesis;
        var idx = this._theses.findIndex(function (t) { return t.id === targetId; });
        if (idx >= 0) this._theses[idx] = data.thesis;
        this._isDirty = false;
        var now = new Date();
        var hh = String(now.getHours()).padStart(2, '0');
        var mm = String(now.getMinutes()).padStart(2, '0');
        if (label) {
          this._updateSaveIndicator('Version saved: ' + label);
          var self = this;
          setTimeout(function () { self._updateSaveIndicator('Saved ' + hh + ':' + mm); }, 1200);
        } else {
          this._updateSaveIndicator('Saved ' + hh + ':' + mm);
        }
        return data;
      } catch (e) {
        console.warn('ThesisManager.save failed:', e);
        return null;
      }
    },

    delete: async function (id) {
      try {
        await fetch(CONFIG.API_BASE + '/api/research-theses/' + id, { method: 'DELETE' });
        this._theses = this._theses.filter(function (t) { return t.id !== id; });
        if (this._activeThesis && this._activeThesis.id === id) {
          this._activeThesis = this._theses.length ? this._theses[0] : null;
        }
        return true;
      } catch (e) {
        console.warn('ThesisManager.delete failed:', e);
        return false;
      }
    },

    updateMeta: async function (fields) {
      if (!this._activeThesis) return null;
      try {
        var res = await fetch(CONFIG.API_BASE + '/api/research-theses/' + this._activeThesis.id, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(fields || {})
        });
        var updated = await res.json();
        this._activeThesis = updated;
        var idx = this._theses.findIndex(function (t) { return t.id === updated.id; });
        if (idx >= 0) this._theses[idx] = updated;
        return updated;
      } catch (e) {
        console.warn('ThesisManager.updateMeta failed:', e);
        return null;
      }
    },

    markDirty: function () {
      this._isDirty = true;
      this._updateSaveIndicator('Unsaved changes');
      this._scheduleAutoSave();
    },

    _scheduleAutoSave: function () {
      if (this._autoSaveTimer) clearTimeout(this._autoSaveTimer);
      var self = this;
      this._autoSaveTimer = setTimeout(function () { self._autoSave(); }, 30000);
    },

    _autoSave: async function () {
      if (!this._activeThesis || !this._isDirty) return;
      this._updateSaveIndicator('Saving...');
      await this.save();
      var now = new Date();
      var hh = String(now.getHours()).padStart(2, '0');
      var mm = String(now.getMinutes()).padStart(2, '0');
      this._updateSaveIndicator('Auto-saved ' + hh + ':' + mm);
    },

    _updateSaveIndicator: function (text) {
      var el = document.getElementById('thesis-save-status');
      if (!el) return;
      el.textContent = text;
    },

    setLastBrushedRange: function (payload) {
      if (!this._activeThesis) return;
      if (!this._activeThesis.lastBrushedRange) {
        this._activeThesis.lastBrushedRange = { chartId: null, start: null, end: null };
      }
      this._activeThesis.lastBrushedRange = {
        chartId: payload && payload.chartId != null ? payload.chartId : null,
        start: payload && payload.start != null ? payload.start : null,
        end: payload && payload.end != null ? payload.end : null
      };
      this.markDirty();
    },

    getActiveChartShocks: function (chartId) {
      var thesis = this.getActive();
      if (!thesis) return null;
      var editor = document.getElementById('thesis-editor');
      if (!editor || !editor.dataset.thesisId || editor.dataset.thesisId !== thesis.id) return null;
      var embeds = editor.querySelectorAll('.thesis-chart-embed');
      for (var i = 0; i < embeds.length; i++) {
        if (embeds[i].dataset.embedId === chartId) {
          var embed = embeds[i];
          var shocks = [];
          try { shocks = JSON.parse(embed.dataset.shocks || '[]'); } catch (e) { }
          return { shocks: shocks, impactMode: (embed.dataset.impactMode || '').trim() || null };
        }
      }
      return null;
    },

    _migrateFromLocalStorage: async function () {
      var raw = null;
      try { raw = localStorage.getItem(this.STORAGE_KEY); } catch (e) { raw = null; }
      var legacyRaw = null;
      try { legacyRaw = localStorage.getItem('researchThesis'); } catch (e) { legacyRaw = null; }
      if (!raw && !legacyRaw) return;

      try {
        var thesesArray = [];
        if (raw) {
          var parsed = JSON.parse(raw);
          if (parsed && parsed.theses) {
            thesesArray = Object.keys(parsed.theses).map(function (k) { return parsed.theses[k]; });
          }
        } else if (legacyRaw) {
          var parsedLegacy = JSON.parse(legacyRaw);
          if (parsedLegacy) thesesArray = [parsedLegacy];
        }

        for (var i = 0; i < thesesArray.length; i++) {
          var t = thesesArray[i];
          var createRes = await fetch(CONFIG.API_BASE + '/api/research-theses', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ title: (t && t.title) ? t.title : 'Untitled Thesis' })
          });
          var created = await createRes.json();
          if (created && created.id && t && t.content_html) {
            await fetch(CONFIG.API_BASE + '/api/research-theses/' + created.id + '/save', {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                content_html: t.content_html,
                metadata: {},
                version_label: 'Migrated from local storage'
              })
            });
          }
        }

        try { localStorage.removeItem(this.STORAGE_KEY); } catch (e) { }
        try { localStorage.removeItem('researchThesis'); } catch (e) { }
        console.log('[ThesisManager] Migrated ' + thesesArray.length + ' theses from localStorage to DB');
      } catch (e) {
        console.warn('[ThesisManager] Migration failed, localStorage preserved:', e);
      }
    },

    export: async function () {
      if (!this._activeThesis) return;
      try {
        var res = await fetch(CONFIG.API_BASE + '/api/research-theses/' + this._activeThesis.id + '/export');
        var blob = await res.blob();
        var url = URL.createObjectURL(blob);
        var a = document.createElement('a');
        a.href = url;
        a.download = 'thesis-export.json';
        a.click();
        URL.revokeObjectURL(url);
      } catch (e) {
        console.warn('ThesisManager.export failed:', e);
      }
    },

    setCanvasLayout: function(layout) {
      if (!this._activeThesis) return;
      this._activeThesis.canvas_layout = layout;
      this.markDirty();
    },

    getCanvasLayout: function() {
      if (!this._activeThesis) return null;
      return this._activeThesis.canvas_layout || null;
    },
  };
  window.ThesisManager = ThesisManager;

  const ResearchV2 = {
    atPicker: AtPicker,
    state: {
      activeView: 'analysis',
      xSeries: null,
      ySeries: [],
      period: 90,
      boardCards: [],
      history: [],
      addingY: false,
      analysisData: null
    },

    init: async function () {
      if (window._researchV2Inited) return;
      window._researchV2Inited = true;
      try {
        this.state.history = [];
        try {
          var rawBrd = localStorage.getItem('researchBoard');
          var parsedBrd = rawBrd ? JSON.parse(rawBrd) : [];
          var minW0 = 280; var minH0 = 180;
          this.state.boardCards = (parsedBrd || []).map(function (c) {
            return Object.assign({}, c, { width: c.width != null ? Math.max(minW0, c.width) : minW0, height: c.height != null ? Math.max(minH0, c.height) : minH0 });
          });
        } catch (eBrd) {
          this.state.boardCards = [];
        }
        if (typeof ThesisManager !== 'undefined') ThesisManager._boardCards = this.state.boardCards || [];
        if (STATE.universe && STATE.universe.length > 0) {
          this.populateSidebar();
        }
        this.initSidebar();
        this.initSearchBar();
        document.querySelectorAll('.research-tab[data-view]').forEach(function (btn) {
          btn.addEventListener('click', function () {
            ResearchV2.navigate(btn.dataset.view);
          });
        });
        // Load theses from API in background (do not block overview render)
        ThesisManager.loadAll().then(function () {
          var list = ThesisManager.getThesisList();
          if (list && list.length > 0) {
            ThesisManager.setActive(list[0].id);
          }
        });
        // Always open Market overview as default landing view
        ResearchV2.navigate('overview');
      } catch (err) {
        console.error('[ResearchV2] init error:', err);
      }
    },

    addAnalysisOutputToCanvas: function (outputType, data, label, opts) {
      opts = opts || {};
      var thesis = typeof ThesisManager !== 'undefined' && ThesisManager.getActive ? ThesisManager.getActive() : null;
      if (!thesis) {
        this.showAddToCanvasNotice('No active thesis — open a thesis first');
        return;
      }
      var canvasCt = document.getElementById('thesis-canvas-container');
      var instance = canvasCt && canvasCt._canvasInstance;
      if (!instance) {
        this.showAddToCanvasNotice('Switch to Canvas mode on your thesis to add panels');
        return;
      }
      var layout = instance.getLayout();
      var maxY = 0;
      (layout.panels || []).forEach(function (p) {
        var bottom = p.y + p.h;
        if (bottom > maxY) maxY = bottom;
      });
      var cfg = {
        output_type: outputType,
        data: data,
        label: label || outputType,
      };
      if (opts.shockPct != null && !isNaN(opts.shockPct)) cfg.shock_pct = opts.shockPct;
      if (opts.ids && opts.ids.length) cfg.ids = opts.ids;
      instance.addPanel({
        type: 'analysis_output',
        x: 0,
        y: maxY,
        w: 8,
        h: 4,
        config: cfg,
      });
      if (typeof ThesisManager !== 'undefined' && ThesisManager.setCanvasLayout) {
        ThesisManager.setCanvasLayout(instance.getLayout());
      }
      this.showAddToCanvasNotice('Added to canvas \u2713');
      // Show writing prompt if thesis has no content yet
      (function () {
        var thesis = ThesisManager.getActive();
        var dismissed = sessionStorage.getItem('canvasWritingPromptDismissed');
        if (dismissed || !thesis) return;
        var content = thesis.content_html || '';
        if (content.trim().length > 20) return; // already has content

        var existing = document.getElementById('canvas-writing-prompt');
        if (existing) return;

        var prompt = document.createElement('div');
        prompt.id = 'canvas-writing-prompt';
        prompt.className = 'canvas-writing-prompt';
        prompt.innerHTML =
          '<span class="cwp-text">Panels added. Switch to <strong>Focus</strong> mode to write your thesis around them.</span>' +
          '<button type="button" class="cwp-focus-btn">Switch to Focus</button>' +
          '<button type="button" class="cwp-dismiss">\u00d7</button>';

        // Insert at top of thesis-canvas-container
        var ct = document.getElementById('thesis-canvas-container');
        if (ct) ct.insertBefore(prompt, ct.firstChild);

        prompt.querySelector('.cwp-focus-btn').addEventListener('click', function () {
          var focusBtn = document.getElementById('thesis-mode-focus');
          if (focusBtn) focusBtn.click();
          prompt.remove();
          sessionStorage.setItem('canvasWritingPromptDismissed', 'true');
        });

        prompt.querySelector('.cwp-dismiss').addEventListener('click', function () {
          prompt.remove();
          sessionStorage.setItem('canvasWritingPromptDismissed', 'true');
        });
      })();
    },

    showAddToCanvasNotice: function (message) {
      var existing = document.getElementById('add-to-canvas-notice');
      if (existing) existing.remove();
      var el = document.createElement('div');
      el.id = 'add-to-canvas-notice';
      el.className = 'add-to-canvas-notice';
      el.textContent = message;
      document.body.appendChild(el);
      setTimeout(function () {
        if (el.parentNode) el.remove();
      }, 2500);
    },

    _maybeInsertBoardMigrationBanner: function () {
      var cards = [];
      try {
        if (typeof localStorage === 'undefined') return;
        if (localStorage.getItem('boardMigrationDone') === 'true') return;
        var raw = localStorage.getItem('researchBoard');
        cards = raw ? JSON.parse(raw) : [];
        if (!Array.isArray(cards) || cards.length === 0) return;
      } catch (e) {
        return;
      }
      var host = document.getElementById('canvas-analysis');
      if (!host) return;
      var existing = document.getElementById('board-migration-banner');
      if (existing) existing.remove();
      var n = cards.length;
      var banner = document.createElement('div');
      banner.className = 'board-migration-banner';
      banner.id = 'board-migration-banner';
      banner.innerHTML =
        '<span class="board-migration-text">You have <strong>' + n + '</strong> pinned Board card(s). Migrate them to your active thesis canvas?</span>' +
        '<button type="button" class="board-migration-btn board-migration-btn--confirm">Migrate to canvas</button>' +
        '<button type="button" class="board-migration-btn board-migration-btn--dismiss">Dismiss</button>';
      var body = host.querySelector('.canvas-body');
      if (body) host.insertBefore(banner, body);
      else host.appendChild(banner);
      var self = this;
      banner.querySelector('.board-migration-btn--dismiss').addEventListener('click', function () {
        try {
          localStorage.setItem('boardMigrationDone', 'true');
        } catch (e2) {}
        banner.remove();
      });
      banner.querySelector('.board-migration-btn--confirm').addEventListener('click', function () {
        var thesis = typeof ThesisManager !== 'undefined' && ThesisManager.getActive ? ThesisManager.getActive() : null;
        if (!thesis) {
          self.showAddToCanvasNotice('Open a thesis first, then come back to migrate');
          return;
        }
        var canvasCt = document.getElementById('thesis-canvas-container');
        var instance = canvasCt && canvasCt._canvasInstance;
        if (!instance) {
          self.showAddToCanvasNotice('Switch to Canvas mode on your thesis first');
          return;
        }
        var layout = instance.getLayout();
        var maxY = 0;
        (layout.panels || []).forEach(function (p) {
          var bottom = p.y + p.h;
          if (bottom > maxY) maxY = bottom;
        });
        var migrated = 0;
        cards.forEach(function (card) {
          var t = card.type;
          var outputType =
            t === 'overlaid' || t === 'impact' || t === 'factors' || t === 'forecast' || t === 'correlation'
              ? t
              : 'overlaid';
          var cfg = { output_type: outputType, data: card.data, label: card.label || outputType };
          if (outputType === 'impact' && card.data && card.data.shock_pct != null) {
            cfg.shock_pct = card.data.shock_pct;
          }
          instance.addPanel({ type: 'analysis_output', x: 0, y: maxY, w: 8, h: 4, config: cfg });
          maxY += 4;
          migrated++;
        });
        if (typeof ThesisManager !== 'undefined' && ThesisManager.setCanvasLayout) {
          ThesisManager.setCanvasLayout(instance.getLayout());
        }
        try {
          localStorage.setItem('boardMigrationDone', 'true');
        } catch (e3) {}
        banner.remove();
        self.showAddToCanvasNotice('Migrated ' + migrated + ' card(s) to canvas \u2713');
      });
    },

    _thesisSaveDebounce: null,
    _thesisSaveDebounceMs: 1000,

    initThesisEditor: async function () {
      var self = this;
      var thesis = ThesisManager.getActive();
      if (!thesis) {
        thesis = await ThesisManager.createNew();
      }
      var titleEl = document.getElementById('thesis-title-input');
      var editorEl = document.getElementById('thesis-editor');
      if (titleEl) titleEl.value = thesis.title || '';
      if (editorEl) {
        editorEl.innerHTML = thesis.content_html || '';
        editorEl.dataset.thesisId = thesis.id;
      }

      var debouncedSave = function () {
        if (self._thesisSaveDebounce) clearTimeout(self._thesisSaveDebounce);
        self._thesisSaveDebounce = setTimeout(function () { if (typeof ThesisManager !== 'undefined' && ThesisManager.markDirty) ThesisManager.markDirty(); }, self._thesisSaveDebounceMs);
      };

      var saveBtn = document.getElementById('thesis-btn-save');
      if (saveBtn) {
        var savePressTimer = null;
        var saveLongPressTriggered = false;
        saveBtn.addEventListener('mousedown', function (e) {
          saveLongPressTriggered = false;
          savePressTimer = setTimeout(function () {
            saveLongPressTriggered = true;
            ResearchV2.openSaveVersionInput();
          }, 300);
        });
        saveBtn.addEventListener('mouseup', function (e) {
          clearTimeout(savePressTimer);
        });
        saveBtn.addEventListener('click', function (e) {
          if (saveLongPressTriggered) {
            e.preventDefault();
            e.stopPropagation();
            return;
          }
          self.saveThesis();
        });
        saveBtn.addEventListener('mouseleave', function () {
          clearTimeout(savePressTimer);
        });
      }
      var exportBtn = document.getElementById('thesis-btn-export');
      if (exportBtn) exportBtn.addEventListener('click', function () { self.exportThesis(); });
      var pdfBtn = document.getElementById('thesis-btn-pdf');
      if (pdfBtn) pdfBtn.addEventListener('click', function () { self.exportThesisPDF(); });
      var newBtn = document.getElementById('thesis-btn-new');
      if (newBtn) newBtn.addEventListener('click', function () {
        if (!confirm('Create a new thesis? Your current thesis is saved.')) return;
        (async function () {
          await self.saveThesis();
          await ThesisManager.createNew();
          ResearchV2.navigate('thesis');
          ResearchV2.populateSidebarTheses();
        })();
      });
      if (titleEl) titleEl.addEventListener('input', function () { debouncedSave(); if (typeof ThesisManager !== 'undefined' && ThesisManager.markDirty) ThesisManager.markDirty(); });
      if (editorEl) {
        editorEl.addEventListener('keydown', function (e) { self.handleThesisKeydown(e); });
        editorEl.addEventListener('keyup', function (e) {
          var ignored = ['Escape', 'Enter', 'Tab', 'ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Shift', 'Control', 'Alt', 'Meta'];
          if (ignored.indexOf(e.key) !== -1) return;
          if (AtPicker.isOpen && !AtPickerFlow.active) {
            var q = ResearchV2.currentAtQuery ? ResearchV2.currentAtQuery() : '';
            AtPicker.query = q;
            AtPicker.renderStep0();
            AtPicker._ignoreNextOutsideClick = true;
          }
        });
        editorEl.addEventListener('input', function () {
          if (typeof ThesisManager !== 'undefined' && ThesisManager.markDirty) ThesisManager.markDirty();
          debouncedSave();
        });
      }

      await ResearchV2.rehydrateChartEmbeds();
      await ResearchV2.refreshThesisChartEmbeds();
    },

    openSaveVersionInput: function () {
      if (document.getElementById('save-version-input-wrap')) return;
      var saveBtn = document.getElementById('thesis-btn-save');
      if (!saveBtn) return;

      var wrap = document.createElement('div');
      wrap.id = 'save-version-input-wrap';
      wrap.style.cssText = 'position:absolute; background:var(--surface-3); ' +
        'border:1px solid var(--border-subtle); border-radius:4px; ' +
        'padding:6px 8px; display:flex; gap:6px; align-items:center; ' +
        'z-index:200; box-shadow:0 4px 12px rgba(0,0,0,0.15); ' +
        'top:calc(100% + 4px); left:0;';

      var input = document.createElement('input');
      input.type = 'text';
      input.placeholder = 'Version label (optional)';
      input.style.cssText = 'background:var(--surface-2); border:1px solid var(--border-subtle); ' +
        'border-radius:3px; padding:3px 8px; font-size:12px; ' +
        'color:var(--text-primary); width:180px; outline:none;';

      var confirmBtn = document.createElement('button');
      confirmBtn.textContent = 'Save';
      confirmBtn.style.cssText = 'background:var(--accent); border:none; border-radius:3px; ' +
        'padding:3px 10px; font-size:12px; color:var(--bg-primary); cursor:pointer;';

      var cancelBtn = document.createElement('button');
      cancelBtn.textContent = 'Cancel';
      cancelBtn.style.cssText = 'background:none; border:1px solid var(--border-subtle); ' +
        'border-radius:3px; padding:3px 8px; font-size:12px; ' +
        'color:var(--text-secondary); cursor:pointer;';

      function doSave() {
        var label = input.value.trim() || null;
        wrap.remove();
        ThesisManager.save(label);
        if (typeof ResearchV2 !== 'undefined' && ResearchV2.populateSidebarTheses) ResearchV2.populateSidebarTheses();
      }

      function doCancel() {
        wrap.remove();
      }

      confirmBtn.addEventListener('click', doSave);
      cancelBtn.addEventListener('click', doCancel);
      input.addEventListener('keydown', function (e) {
        if (e.key === 'Enter') doSave();
        if (e.key === 'Escape') doCancel();
      });

      wrap.appendChild(input);
      wrap.appendChild(confirmBtn);
      wrap.appendChild(cancelBtn);

      var toolbar = saveBtn.closest('.thesis-toolbar') || saveBtn.parentElement;
      if (toolbar) {
        toolbar.style.position = 'relative';
        toolbar.appendChild(wrap);
      } else {
        document.body.appendChild(wrap);
      }

      setTimeout(function () { input.focus(); }, 50);

      function outsideClick(e) {
        if (!wrap.contains(e.target) && e.target !== saveBtn) {
          doCancel();
          document.removeEventListener('click', outsideClick);
        }
      }
      setTimeout(function () {
        document.addEventListener('click', outsideClick);
      }, 100);
    },

    renderThesisToolbarMeta: function () {
      var thesis = ThesisManager.getActive();
      var host = document.getElementById('thesis-toolbar-meta');
      if (!host) return;
      host.innerHTML = '';
      if (!thesis) return;

      function currentTags() {
        return Array.isArray(thesis.tags) ? thesis.tags.slice() : [];
      }

      // Tags bar
      var tagsBar = document.createElement('div');
      tagsBar.className = 'thesis-tags-bar';
      var tags = currentTags();
      tags.forEach(function (tag) {
        var chip = document.createElement('span');
        chip.className = 'thesis-tag-chip--editor';
        chip.innerHTML = escapeHtml(tag) + ' <button type="button" class="thesis-tag-remove" aria-label="Remove tag">\u00D7</button>';
        chip.querySelector('.thesis-tag-remove').addEventListener('click', function (e) {
          e.stopPropagation();
          (async function () {
            await ThesisManager.updateMeta({ tags: currentTags().filter(function (t) { return t !== tag; }) });
            ResearchV2.renderThesisToolbarMeta();
            await ThesisManager.loadAll();
            ResearchV2.populateSidebarTheses();
            if (ResearchV2.render && ResearchV2.render.thesislist) ResearchV2.render.thesislist();
          })();
        });
        tagsBar.appendChild(chip);
      });
      var addBtn = document.createElement('button');
      addBtn.type = 'button';
      addBtn.className = 'thesis-tag-add-btn';
      addBtn.textContent = '+ tag';
      addBtn.addEventListener('click', function (e) {
        e.stopPropagation();
        if (tagsBar.querySelector('.thesis-tag-input')) return;
        var input = document.createElement('input');
        input.className = 'thesis-tag-input';
        input.placeholder = 'tag';
        tagsBar.appendChild(input);
        input.focus();
        function close() { if (input && input.parentNode) input.parentNode.removeChild(input); }
        function commit() {
          var v = (input.value || '').trim();
          close();
          if (!v) return;
          var curr = currentTags();
          if (curr.indexOf(v) !== -1) return;
          (async function () {
            await ThesisManager.updateMeta({ tags: curr.concat([v]) });
            ResearchV2.renderThesisToolbarMeta();
            await ThesisManager.loadAll();
            ResearchV2.populateSidebarTheses();
            if (ResearchV2.render && ResearchV2.render.thesislist) ResearchV2.render.thesislist();
          })();
        }
        input.addEventListener('blur', commit);
        input.addEventListener('keydown', function (ke) {
          if (ke.key === 'Enter') { ke.preventDefault(); commit(); }
          if (ke.key === 'Escape') { ke.preventDefault(); close(); }
        });
      });
      tagsBar.appendChild(addBtn);
      host.appendChild(tagsBar);

      // Status selector
      var statusSel = document.createElement('select');
      statusSel.className = 'thesis-status-select';
      statusSel.innerHTML =
        '<option value=\"draft\">Draft</option>' +
        '<option value=\"active\">Active</option>' +
        '<option value=\"archived\">Archived</option>';
      statusSel.value = (thesis.status || 'draft');
      statusSel.addEventListener('change', function () {
        (async function () {
          await ThesisManager.updateMeta({ status: statusSel.value });
          ResearchV2._applyArchivedState();
          await ThesisManager.loadAll();
          ResearchV2.populateSidebarTheses();
          if (ResearchV2.render && ResearchV2.render.thesislist) ResearchV2.render.thesislist();
        })();
      });
      host.appendChild(statusSel);

      // History button
      var histBtn = document.createElement('button');
      histBtn.type = 'button';
      histBtn.className = 'thesis-btn';
      histBtn.id = 'thesis-btn-history';
      histBtn.textContent = 'History';
      histBtn.addEventListener('click', function () {
        ResearchV2.toggleHistoryPanel();
      });
      host.appendChild(histBtn);

      ResearchV2._applyArchivedState();
    },

    _applyArchivedState: function () {
      var thesis = ThesisManager.getActive();
      var editor = document.getElementById('thesis-editor');
      var banner = document.getElementById('thesis-archived-banner');
      if (!editor) return;
      var isArchived = thesis && thesis.status === 'archived';
      editor.setAttribute('contenteditable', isArchived ? 'false' : 'true');
      if (banner) banner.style.display = isArchived ? '' : 'none';
    },

    toggleHistoryPanel: function () {
      var panel = document.getElementById('thesis-history-panel');
      if (!panel) return;
      var open = panel.classList.contains('thesis-history-panel--open');
      if (open) {
        panel.classList.remove('thesis-history-panel--open');
        var cont = document.getElementById('thesis-editor-container');
        if (cont) cont.style.paddingRight = '';
        return;
      }
      ResearchV2.openHistoryPanel(false);
    },

    openHistoryPanel: function (includeAuto) {
      var thesis = ThesisManager.getActive();
      var panel = document.getElementById('thesis-history-panel');
      var cont = document.getElementById('thesis-editor-container');
      if (!panel || !thesis) return;
      if (cont) cont.style.paddingRight = '280px';
      panel.classList.add('thesis-history-panel--open');
      panel.innerHTML =
        '<div class=\"thesis-history-header\">' +
        '<div class=\"thesis-history-title\">Version History</div>' +
        '<button type=\"button\" class=\"thesis-history-close\" aria-label=\"Close\">\u00D7</button>' +
        '</div>' +
        '<div class=\"thesis-autosaves-toggle\"><label><input type=\"checkbox\" class=\"thesis-history-autosaves-toggle\"> Show auto-saves</label></div>' +
        '<div class=\"thesis-history-list\" id=\"thesis-history-list\"><div style=\"padding:10px 14px;color:var(--text-tertiary);font-size:12px;\">Loading\u2026</div></div>';
      var closeBtn = panel.querySelector('.thesis-history-close');
      if (closeBtn) closeBtn.addEventListener('click', function () { ResearchV2.toggleHistoryPanel(); });
      var cb = panel.querySelector('.thesis-history-autosaves-toggle');
      if (cb) {
        cb.checked = !!includeAuto;
        cb.addEventListener('change', function () {
          ResearchV2.openHistoryPanel(cb.checked);
        });
      }
      var qs = includeAuto ? '?include_auto_saves=true' : '';
      fetch(CONFIG.API_BASE + '/api/research-theses/' + thesis.id + '/versions' + qs)
        .then(function (r) { return r.json(); })
        .then(function (versions) { ResearchV2.renderVersionList(Array.isArray(versions) ? versions : []); })
        .catch(function () { ResearchV2.renderVersionList([]); });
    },

    renderVersionList: function (versions) {
      function rel(iso) {
        if (!iso) return '';
        var d = new Date(iso);
        var diff = Date.now() - d.getTime();
        if (diff < 0) diff = 0;
        var s = Math.floor(diff / 1000);
        if (s < 60) return 'just now';
        var m = Math.floor(s / 60);
        if (m < 60) return m + 'm ago';
        var h = Math.floor(m / 60);
        if (h < 24) return h + 'h ago';
        var months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return months[d.getMonth()] + ' ' + d.getDate();
      }

      var list = document.getElementById('thesis-history-list');
      if (!list) return;
      if (!versions.length) {
        list.innerHTML = '<div style=\"padding:10px 14px;color:var(--text-tertiary);font-size:12px;\">No versions yet.</div>';
        return;
      }
      var html = '';
      versions.forEach(function (v) {
        html += '<div class=\"thesis-history-row\" data-version-id=\"' + escapeHtml(v.id) + '\" data-version-number=\"' + escapeHtml(String(v.version_number || '')) + '\">' +
          '<div class=\"thesis-history-row-meta\">' +
          '<span class=\"thesis-history-version-num\">v' + escapeHtml(String(v.version_number || '')) + '</span>' +
          '<span class=\"thesis-history-label\">' + escapeHtml(v.version_label || 'Auto-save') + '</span>' +
          '<span class=\"thesis-history-date\">' + escapeHtml(rel(v.created_at)) + '</span>' +
          '</div>' +
          '<button type=\"button\" class=\"thesis-history-restore-btn\" data-version-id=\"' + escapeHtml(v.id) + '\">Restore</button>' +
          '</div>';
      });
      list.innerHTML = html;
      list.querySelectorAll('.thesis-history-restore-btn').forEach(function (btn) {
        btn.addEventListener('click', function (e) {
          e.stopPropagation();
          var row = btn.closest('.thesis-history-row');
          if (!row) return;
          var vid = btn.getAttribute('data-version-id');
          var vn = row.getAttribute('data-version-number') || '';
          btn.style.display = 'none';
          var confirmEl = document.createElement('div');
          confirmEl.style.fontSize = '11px';
          confirmEl.style.color = 'var(--text-tertiary)';
          confirmEl.innerHTML = 'Restore to v' + escapeHtml(vn) + '? <button class=\"confirm-yes\">Yes</button> <button class=\"confirm-no\">Cancel</button>';
          row.appendChild(confirmEl);
          confirmEl.querySelector('.confirm-no').addEventListener('click', function () {
            confirmEl.remove();
            btn.style.display = '';
          });
          confirmEl.querySelector('.confirm-yes').addEventListener('click', function () {
            var thesis = ThesisManager.getActive();
            if (!thesis) return;
            fetch(CONFIG.API_BASE + '/api/research-theses/' + thesis.id + '/versions/' + vid + '/restore', { method: 'POST' })
              .then(function (r) { return r.json(); })
              .then(function (updated) {
                ThesisManager._activeThesis = updated;
                var titleEl = document.getElementById('thesis-title-input');
                if (titleEl) titleEl.value = updated.title || '';
                var editorEl = document.getElementById('thesis-editor');
                if (editorEl) {
                  editorEl.innerHTML = updated.content_html || '';
                  editorEl.dataset.thesisId = updated.id;
                }
                ResearchV2.rehydrateChartEmbeds().then(function () { ResearchV2.refreshThesisChartEmbeds(); });
                ResearchV2.renderThesisToolbarMeta();
                var banner = document.getElementById('thesis-restore-banner');
                if (banner) {
                  banner.textContent = 'Restored to v' + vn;
                  banner.style.display = '';
                  setTimeout(function () { banner.style.display = 'none'; }, 3000);
                }
                ResearchV2.toggleHistoryPanel();
              });
          });
        });
      });
    },

    rehydrateChartEmbeds: async function () {
      var embeds = Array.from(document.querySelectorAll('#thesis-editor .thesis-chart-embed'));
      if (embeds.length === 0) return;
      if (!STATE.universe || STATE.universe.length === 0) {
        setTimeout(function () { ResearchV2.rehydrateChartEmbeds(); }, 500);
        return;
      }
      embeds.forEach(function (el) {
        var wrapper = wrapThesisChartEmbedIfNeeded(el);
        if (wrapper) wireThesisChartEmbedResize(wrapper);
      });
      embeds.forEach(function (el) { wireEmbedButtons(el); });
      await Promise.all(embeds.map(function (el) {
        return renderChartIntoEmbed(el, readParamsFromEmbed(el));
      }));
      embeds.forEach(function (el) {
        var shocks = [];
        try { shocks = JSON.parse(el.dataset.shocks || '[]'); } catch (e) { }
        var impactMode = (el.dataset.impactMode || '').trim() || null;
        if (shocks.length && impactMode) {
          el.shocks = shocks;
          el.impactMode = impactMode;
          var ctx = getEmbedChartImpactContext(el);
          rehydrateImpactOverlay(ctx.getChartContainer(), ctx.getSeries(), shocks, impactMode, ctx.getSeriesData, ctx.getDecomposition);
        }
      });
    },

    /** Re-render chart content only for all thesis embeds. Does not wrap or re-wire handles. Call when thesis tab becomes visible. */
    refreshThesisChartEmbeds: async function () {
      var editor = document.getElementById('thesis-editor');
      if (!editor) return;
      var embeds = Array.from(editor.querySelectorAll('.thesis-chart-embed'));
      if (embeds.length === 0) return;
      if (!STATE.universe || STATE.universe.length === 0) {
        setTimeout(function () { ResearchV2.refreshThesisChartEmbeds(); }, 500);
        return;
      }
      await Promise.all(embeds.map(function (el) {
        return renderChartIntoEmbed(el, readParamsFromEmbed(el));
      }));
      embeds.forEach(function (el) {
        var shocks = [];
        try { shocks = JSON.parse(el.dataset.shocks || '[]'); } catch (e) { }
        var impactMode = (el.dataset.impactMode || '').trim() || null;
        if (shocks.length && impactMode) {
          el.shocks = shocks;
          el.impactMode = impactMode;
          var ctx = getEmbedChartImpactContext(el);
          rehydrateImpactOverlay(ctx.getChartContainer(), ctx.getSeries(), shocks, impactMode, ctx.getSeriesData, ctx.getDecomposition);
        }
      });
    },

    _updateThesisSaveStatus: function (msg) {
      var el = document.getElementById('thesis-save-status');
      if (!el) return;
      el.textContent = msg;
      var self = this;
      if (self._thesisStatusClear) clearTimeout(self._thesisStatusClear);
      if (msg.indexOf('Saved') === 0) self._thesisStatusClear = setTimeout(function () { el.textContent = ''; }, 3000);
    },

    saveThesis: async function () {
      var editorEl = document.getElementById('thesis-editor');
      var id = editorEl && editorEl.dataset && editorEl.dataset.thesisId;
      if (!id) {
        console.warn('[saveThesis] no thesis id on editor — skipping');
        return;
      }
      var titleEl = document.getElementById('thesis-title-input');
      var title = titleEl ? titleEl.value : '';
      var content_html = getThesisHtmlForSave();
      await ThesisManager.save(id, title, content_html);
      await ThesisManager.loadAll();
      ResearchV2.populateSidebarTheses();
      var now = new Date();
      var hh = String(now.getHours()).padStart(2, '0');
      var mm = String(now.getMinutes()).padStart(2, '0');
      this._updateThesisSaveStatus('Saved ' + hh + ':' + mm);
    },

    populateSidebarTheses: function () {
      var container = document.getElementById('panel-theses-list');
      if (!container) return;
      var theses = ThesisManager.getThesisList();
      var active = ThesisManager.getActive();
      var html = '';
      theses.forEach(function (t) {
        var isActive = active && t.id === active.id;
        html += '<button class="panel-item panel-thesis-item' + (isActive ? ' active' : '') + '" data-thesis-id="' + t.id + '">'
          + '<span class="panel-thesis-dot' + (isActive ? ' panel-thesis-dot--active' : '') + '"></span>'
          + escapeHtml(t.title || 'Untitled thesis')
          + '</button>';
      });
      container.innerHTML = html;
      container.querySelectorAll('.panel-thesis-item').forEach(function (btn) {
        btn.addEventListener('click', function () {
          (async function () {
            await ThesisManager.setActive(btn.dataset.thesisId);
            ResearchV2.navigate('thesis');
            Shell.closePanel();
          })();
        });
      });
    },

    exportThesis: function () {
      var titleEl = document.getElementById('thesis-title-input');
      var editorEl = document.getElementById('thesis-editor');
      var title = (titleEl && titleEl.value) ? titleEl.value.trim() : 'thesis';
      if (!editorEl) return;
      var clone = editorEl.cloneNode(true);
      var chartEmbeds = clone.querySelectorAll('.thesis-chart-embed');
      chartEmbeds.forEach(function (emb) {
        var labelEl = emb.querySelector('.chart-embed-label');
        var text = labelEl ? labelEl.textContent.trim() : 'Chart';
        emb.replaceWith(document.createTextNode('[Chart: ' + text + ']\n'));
      });
      var embeds = clone.querySelectorAll('.thesis-embed');
      embeds.forEach(function (emb) {
        var label = emb.querySelector('.thesis-embed-label');
        var text = label ? label.textContent.trim() : 'Board';
        emb.replaceWith(document.createTextNode('[Board: ' + text + ']\n'));
      });
      var chips = clone.querySelectorAll('.at-chip');
      chips.forEach(function (chip) {
        var name = chip.textContent.replace(/\s+/g, ' ').trim();
        var val = chip.querySelector('.at-chip-value');
        var txt = val ? '@' + name + ' ' + val.textContent : '@' + name;
        chip.replaceWith(document.createTextNode(txt));
      });
      var div = document.createElement('div');
      div.appendChild(clone);
      var html = div.innerHTML;
      var plain = html.replace(/<br\s*\/?>/gi, '\n').replace(/<\/p>/gi, '\n').replace(/<[^>]+>/g, '');
      plain = plain.replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&').replace(/&lt;/g, '<').replace(/&gt;/g, '>').replace(/&quot;/g, '"');
      var lines = (title.toUpperCase() + '\n\n' + plain).trim().split('\n').map(function (l) { return l.trimRight(); });
      var out = lines.join('\n');
      var blob = new Blob([out], { type: 'text/plain;charset=utf-8' });
      var a = document.createElement('a');
      a.href = URL.createObjectURL(blob);
      a.download = (title || 'thesis').replace(/[^\w\s-]/g, '') + '.txt';
      a.click();
      URL.revokeObjectURL(a.href);
    },

    exportThesisPDF: function () {
      var loading = document.querySelectorAll('#thesis-editor .chart-embed-loading');
      if (loading && loading.length > 0) {
        alert('Some charts are still loading. Please wait before exporting.');
        return;
      }
      var titleEl = document.getElementById('thesis-title-input');
      var title = (titleEl && titleEl.value) ? titleEl.value.trim() : 'thesis';
      var prevTitle = document.title;
      document.title = title;
      window.print();
      setTimeout(function () {
        document.title = prevTitle;
      }, 1000);
    },

    currentAtQuery: function () {
      var sel = window.getSelection();
      if (!sel || !sel.rangeCount) return '';
      var range = sel.getRangeAt(0);
      var node = range.startContainer;
      var offset = range.startOffset;
      if (node.nodeType !== Node.TEXT_NODE) return '';
      var text = node.textContent ? node.textContent.substring(0, offset) : '';
      var atIdx = text.lastIndexOf('@');
      if (atIdx === -1) return '';
      return text.substring(atIdx + 1);
    },

    handleThesisKeydown: function (e) {
      if (e.key === '@') {
        setTimeout(function () {
          var editor = document.getElementById('thesis-editor');
          if (editor) {
            AtPicker.anchorEl = editor;
            AtPicker.onSelect = function (item) { ResearchV2.insertAtChip(item); };
            AtPicker.query = '';
            AtPickerFlow.active = false;
            AtPickerFlow.step = 0;
            AtPicker.renderStep0();
            AtPicker._ignoreNextOutsideClick = true;
          }
        }, 0);
        return;
      }
      if (e.key === 'Escape') {
        if (AtPicker.isOpen) {
          AtPickerFlow.handleEscape();
        }
        return;
      }
      if (e.key === 'Tab' && AtPicker.isOpen) {
        e.preventDefault();
        var firstRow = document.querySelector('#at-picker-dropdown .at-result-row');
        if (firstRow) {
          if (firstRow.dataset.type === 'chart') {
            AtPicker.select({
              type: 'chart',
              chartType: firstRow.dataset.chartType || '',
              x: firstRow.dataset.chartX || '',
              y: firstRow.dataset.chartY || '',
              period: parseInt(firstRow.dataset.chartPeriod, 10) || 90,
              shockPct: parseFloat(firstRow.dataset.chartShock) || 10,
              instruments: firstRow.dataset.chartInstruments || '',
              label: firstRow.dataset.chartLabel || ''
            });
          } else {
            AtPicker.select({ type: firstRow.dataset.type, id: firstRow.dataset.id, name: firstRow.dataset.name });
          }
        }
        return;
      }
    },

    insertChartEmbedFromPicker: function (item) {
      if (typeof window.insertChartEmbed !== 'function') {
        console.error('[insertChartEmbedFromPicker] insertChartEmbed not available');
        return;
      }
      window.insertChartEmbed({
        embedId: generateEmbedId(),
        type: item.chartType,
        x: item.x || '',
        y: item.y || '',
        period: item.period != null ? item.period : 90,
        shockPct: item.shockPct != null ? item.shockPct : 10,
        instruments: item.instruments || '',
        label: item.label || ''
      });
    },

    insertAtChip: function (item) {
      var editor = document.getElementById('thesis-editor');
      if (!editor) return;
      editor.focus();
      var sel = window.getSelection();
      if (!sel || sel.rangeCount === 0) return;
      var range = sel.getRangeAt(0);
      var node = range.startContainer;
      var offset = range.startOffset;
      var atOffset = -1;
      if (node.nodeType === Node.TEXT_NODE) {
        var text = node.textContent.substring(0, offset);
        atOffset = text.lastIndexOf('@');
      }
      if (atOffset >= 0) {
        var deleteRange = document.createRange();
        deleteRange.setStart(node, atOffset);
        deleteRange.setEnd(node, offset);
        deleteRange.deleteContents();
      }
      var chip = document.createElement('span');
      chip.className = 'at-chip';
      chip.setAttribute('contenteditable', 'false');
      chip.dataset.type = item.type;
      chip.dataset.id = item.id;
      var nameSpan = document.createElement('span');
      nameSpan.textContent = '@' + item.name;
      chip.appendChild(nameSpan);
      var valueSpan = document.createElement('span');
      valueSpan.className = 'at-chip-value';
      if (item.type === 'instrument' && item.value != null) {
        valueSpan.textContent = ' ' + Number(item.value).toFixed(2);
      } else if (item.type === 'topic' && item.count != null) {
        valueSpan.textContent = ' ' + item.count + ' articles';
      }
      chip.appendChild(valueSpan);
      var space = document.createTextNode('\u00A0');
      var insertRange = sel.rangeCount ? sel.getRangeAt(0) : null;
      if (!insertRange) return;
      insertRange.collapse(true);
      insertRange.insertNode(space);
      insertRange.setStartBefore(space);
      insertRange.collapse(true);
      insertRange.insertNode(chip);
      var newRange = document.createRange();
      newRange.setStartAfter(space);
      newRange.collapse(true);
      sel.removeAllRanges();
      sel.addRange(newRange);
      this.saveThesis();
    },

    updateAtChips: function () {
      var editor = document.getElementById('thesis-editor');
      if (!editor) return;
      var chips = editor.querySelectorAll('.at-chip[data-type="instrument"]');
      var prices = STATE.latestPrices || {};
      chips.forEach(function (chip) {
        var id = chip.getAttribute('data-id');
        var price = prices[id];
        if (price && price.value != null) {
          var valueEl = chip.querySelector('.at-chip-value');
          if (valueEl) valueEl.textContent = Number(price.value).toFixed(2);
        }
      });
    },

    _renderOverlaidPreview: function (seriesData, w, h, zoomRange, seriesList) {
      w = w || 280; h = h || 130;
      var dataToRender = (zoomRange && zoomRange.startDate && zoomRange.endDate) ? filterOverlaidDataByDateRange(seriesData, zoomRange.startDate, zoomRange.endDate) : seriesData;
      var seriesById = (dataToRender && dataToRender.series) || {};
      if (seriesList && seriesList.length > 2) {
        var listHasData = seriesList.filter(function (s) { return seriesById[s.id]; });
        if (listHasData.length > 2) return renderOverlaidSVGMulti(dataToRender, listHasData, w, h);
      }
      var keys = Object.keys(seriesById);
      var xId = keys[0]; var yId = keys[1];
      if (!xId || !yId) return '<p style="font-size:11px;color:#94a3b8">No series data</p>';
      return renderOverlaidSVG(dataToRender, xId, yId, w, h, xId, yId, 'Correlation');
    },

    _renderForecastPreview: function (forecastData, w, h, zoomRange) {
      w = w || 280; h = h || 130;
      var dataToRender = (zoomRange && zoomRange.startDate && zoomRange.endDate) ? filterForecastByDateRange(forecastData, zoomRange.startDate, zoomRange.endDate) : forecastData;
      return renderForecastSVG(dataToRender, w, h);
    },

    renderCardPreview: function (card, previewEl, w, h) {
      if (!previewEl) return;
      var type = card.type; var data = card.data;
      var pw = (w != null && w > 0) ? w : 280; var ph = (h != null && h > 0) ? h : 130;
      var self = this;
      if (type === 'overlaid') {
        var baseDataOverlaid = data;
        if (card.timeRange && card.timeRange.from && card.timeRange.to) baseDataOverlaid = filterOverlaidDataByDateRange(data, card.timeRange.from, card.timeRange.to);
        var zoomRangeOverlaid = (card._zoomRange && card._zoomRange.startDate && card._zoomRange.endDate) ? card._zoomRange : null;
        var currentData = zoomRangeOverlaid ? filterOverlaidDataByDateRange(baseDataOverlaid, zoomRangeOverlaid.startDate, zoomRangeOverlaid.endDate) : baseDataOverlaid;
        previewEl.innerHTML = this._renderOverlaidPreview(baseDataOverlaid, pw, ph, zoomRangeOverlaid, card.customSeries && card.customSeries.length > 2 ? card.customSeries : null);
        var keys = Object.keys((baseDataOverlaid && baseDataOverlaid.series) || {});
        var xId = keys[0];
        var dates = datesFromOverlaidData(currentData, xId);
        if (dates.length >= 2) {
          var overlaidZoomed = !!zoomRangeOverlaid;
          var cardIdOverlaid = card.id || null;
          addBrushOverlay(previewEl, {
            margins: { top: 20, right: 80, bottom: 28, left: 44 },
            width: pw,
            height: ph,
            nPoints: dates.length,
            isZoomed: overlaidZoomed,
            getDateAtIndex: function (i) { return datesFromOverlaidData(currentData, xId)[i]; },
            onZoom: function (r) {
              card._zoomRange = r;
              if (typeof ThesisManager !== 'undefined' && cardIdOverlaid) ThesisManager.setLastBrushedRange({ chartId: cardIdOverlaid, start: toIsoDateString(r.startDate), end: toIsoDateString(r.endDate) });
              self.renderCardPreview(card, previewEl, w, h);
            },
            onReset: overlaidZoomed ? function () {
              if (typeof ThesisManager !== 'undefined' && cardIdOverlaid) ThesisManager.setLastBrushedRange({ chartId: cardIdOverlaid, start: null, end: null });
              card._zoomRange = null;
              self.renderCardPreview(card, previewEl, w, h);
            } : undefined
          });
        }
      } else if (type === 'impact') {
        var impacts = (data && data.impacts) || [];
        var rows = impacts.slice(0, 3).map(function (imp) { return '<tr><td style="font-size:11px">' + escapeHtml(imp.name || imp.series_id || '') + '</td><td style="font-size:11px">' + (imp.beta != null ? Number(imp.beta).toFixed(3) : '—') + '</td><td style="font-size:11px">' + (imp.r_squared != null ? Number(imp.r_squared).toFixed(2) : '—') + '</td></tr>'; }).join('');
        previewEl.innerHTML = '<table style="width:100%;font-size:11px;border-collapse:collapse"><thead><tr><th style="text-align:left">Instrument</th><th>β</th><th>R²</th></tr></thead><tbody>' + rows + '</tbody></table>';
      } else if (type === 'factors') {
        var factors = (data && data.factors) || [];
        var maxAbsBeta = Math.max(0.001, Math.max.apply(null, factors.map(function (f) { return Math.abs(Number(f.beta) || 0); })));
        var top3 = factors.slice(0, 3);
        var barW = 120;
        var html = top3.map(function (f) {
          var beta = Number(f.beta) || 0;
          var pct = Math.min((Math.abs(beta) / maxAbsBeta) * 50, 100);
          var barStyle = 'width:' + pct + '%;background:' + (beta >= 0 ? '#16a34a' : '#dc2626') + ';' + (beta >= 0 ? 'left:50%;' : 'right:50%;left:auto;');
          return '<div style="display:flex;align-items:center;gap:6px;margin-bottom:4px;font-size:11px"><span style="flex:0 0 70px;overflow:hidden;text-overflow:ellipsis">' + escapeHtml(f.factor || f.name || '') + '</span><div style="width:' + barW + 'px;height:10px;background:#f1f5f9;border-radius:2px;position:relative;overflow:hidden"><div style="position:absolute;top:0;height:100%;border-radius:2px;' + barStyle + '"></div></div><span style="color:' + (beta >= 0 ? '#16a34a' : '#dc2626') + '">' + beta.toFixed(3) + '</span></div>';
        }).join('');
        previewEl.innerHTML = html || '<p style="font-size:11px;color:#94a3b8">No factors</p>';
      } else if (type === 'forecast') {
        var baseFc = data;
        if (card.timeRange && card.timeRange.from && card.timeRange.to) baseFc = filterForecastByDateRange(data, card.timeRange.from, card.timeRange.to);
        var zoomRangeFc = (card._zoomRange && card._zoomRange.startDate && card._zoomRange.endDate) ? card._zoomRange : null;
        var currentFc = zoomRangeFc ? filterForecastByDateRange(baseFc, zoomRangeFc.startDate, zoomRangeFc.endDate) : baseFc;
        previewEl.innerHTML = this._renderForecastPreview(baseFc, pw, ph, zoomRangeFc);
        var h2 = (currentFc.history && currentFc.history.slice()) || [];
        var a2 = Array.isArray(currentFc.arima_forecast) ? currentFc.arima_forecast : [];
        var allDates = h2.map(function (d) { return d.date; }).concat(a2.map(function (d) { return d.date; }));
        var nPoints = h2.length + a2.length;
        if (nPoints >= 2 && allDates.filter(Boolean).length >= 2) {
          var forecastZoomed = !!zoomRangeFc;
          var cardIdForecast = card.id || null;
          addBrushOverlay(previewEl, {
            margins: { top: 24, right: 80, bottom: 36, left: 52 },
            width: pw,
            height: ph,
            nPoints: nPoints,
            isZoomed: forecastZoomed,
            getDateAtIndex: function (i) { return allDates[i]; },
            onZoom: function (r) {
              card._zoomRange = r;
              if (typeof ThesisManager !== 'undefined' && cardIdForecast) ThesisManager.setLastBrushedRange({ chartId: cardIdForecast, start: toIsoDateString(r.startDate), end: toIsoDateString(r.endDate) });
              self.renderCardPreview(card, previewEl, w, h);
            },
            onReset: forecastZoomed ? function () {
              if (typeof ThesisManager !== 'undefined' && cardIdForecast) ThesisManager.setLastBrushedRange({ chartId: cardIdForecast, start: null, end: null });
              card._zoomRange = null;
              self.renderCardPreview(card, previewEl, w, h);
            } : undefined
          });
        }
      } else previewEl.textContent = '—';
    },

    _renderOverlaidFull: function (seriesData) {
      var seriesById = (seriesData && seriesData.series) || {};
      var keys = Object.keys(seriesById);
      var xId = keys[0]; var yId = keys[1];
      if (!xId || !yId) return '<p>No series data</p>';
      return renderOverlaidSVG(seriesData, xId, yId, 500, 220, xId, yId, xId + ' vs ' + yId);
    },

    _renderImpactFull: function (impactData) {
      var shockVal = (impactData && impactData.shock_pct != null) ? impactData.shock_pct : 10;
      return '<p style="margin-bottom:8px">Shock: ' + shockVal + '%</p>' + renderImpactEmbedHTML(impactData, shockVal);
    },

    _renderFactorsFull: function (factorData) {
      return renderFactorsEmbedHTML(factorData);
    },

    _renderForecastFull: function (forecastData) {
      return renderForecastSVG(forecastData, 500, 380);
    },

    navigate(viewId, params, noPush) {
      params = params || {};
      if (viewId === 'board') {
        return this.navigate('analysis', params, noPush);
      }
      document.querySelectorAll('.canvas-view').forEach(function (v) { v.classList.remove('active'); });
      document.querySelectorAll('.sidebar-item, .sidebar-instrument-row').forEach(function (i) { i.classList.remove('active'); });
      var viewEl = document.getElementById('canvas-' + viewId);
      if (viewEl) viewEl.classList.add('active');
      var sidebarMatch = document.querySelector('[data-view="' + viewId + '"]');
      if (viewId === 'instrument' && params.id) {
        document.querySelectorAll('.sidebar-instrument-row[data-id]').forEach(function (row) {
          if (row.getAttribute('data-id') === params.id) sidebarMatch = row;
        });
      }
      if (sidebarMatch) sidebarMatch.classList.add('active');
      var TAB_MAP = {
        thesislist: 'thesislist',
        thesis: 'thesislist',
        analysis: 'analysis',
        overview: 'overview'
      };
      var activeTab = TAB_MAP[viewId] || 'analysis';
      document.querySelectorAll('.research-tab[data-view]').forEach(function (t) {
        t.classList.toggle('active', t.dataset.view === activeTab);
      });
      var PRIMARY = ['analysis', 'overview', 'thesis', 'thesislist'];
      var breadcrumb = document.getElementById('research-breadcrumb');
      if (breadcrumb) {
        if (!PRIMARY.includes(viewId)) {
          var label = viewId.charAt(0).toUpperCase() + viewId.slice(1);
          breadcrumb.textContent = '/ ' + label;
          breadcrumb.style.display = 'inline';
        } else {
          breadcrumb.textContent = '';
          breadcrumb.style.display = 'none';
        }
      }
      this.state.activeView = viewId;
      if (viewId === 'overview') {
        ResearchV2._renderView('canvas-overview', 'Market', '');
        var bodyEl = document.querySelector('#canvas-overview .canvas-body');
        if (bodyEl && typeof ResearchOverview !== 'undefined' && ResearchOverview.render) {
          ResearchOverview.render(bodyEl);
        }
      } else if (viewId === 'thesislist' && this.render.thesislist) {
        this.render.thesislist(params);
      } else if (this.render[viewId]) {
        this.render[viewId](params);
      }
      if (!noPush) this.state.history.push({ viewId: viewId, params: params });
    },

    back() {
      if (this.state.history.length <= 1) return;
      this.state.history.pop();
      var prev = this.state.history[this.state.history.length - 1];
      if (prev) this.navigate(prev.viewId, prev.params, true);
    },

    initSidebar() {
      var self = this;
      document.addEventListener('click', function (e) {
        if (!e.target.closest('#panel-instruments') && !e.target.closest('.research-sidebar')) return;

        var navItem = e.target.closest('.sidebar-nav-item');
        if (navItem && navItem.dataset.view) {
          self.navigate(navItem.dataset.view);
          return;
        }

        var computedItem = e.target.closest('.sidebar-computed-item');
        if (computedItem && computedItem.dataset.view) {
          self.navigate(computedItem.dataset.view);
          return;
        }

        var instrRow = e.target.closest('.sidebar-instrument-row');
        if (instrRow && instrRow.dataset.id) {
          self.navigate('instrument', { id: instrRow.dataset.id });
          return;
        }

        var topicRow = e.target.closest('.sidebar-topic-row');
        if (topicRow && topicRow.dataset.topic) {
          self.navigate('signals', { topic: topicRow.dataset.topic });
          return;
        }

        var groupHeader = e.target.closest('.sidebar-group-header');
        if (groupHeader) {
          var body = groupHeader.nextElementSibling;
          if (body && body.classList.contains('sidebar-group-body')) body.classList.toggle('collapsed');
        }
      });
      document.addEventListener('click', function (e) {
        if (e.target.closest('.canvas-back-btn')) {
          e.preventDefault();
          ResearchV2.back();
        }
      });
    },

    _searchDebounceTimer: null,
    _searchSelectedIndex: -1,
    _searchInputDelegateBound: false,

    initSearchBar: function () {
      // Removed in Spec 3a.
      // The X/Y search bar HTML has been commented out.
      // Replaced by @ picker three-step flow in Spec 3b.
    },

    getSearchResults(query) {
      var q = query.toLowerCase().trim();
      var instruments = (STATE.universe || []).filter(function (inst) {
        var name = (inst.name || '').toLowerCase();
        var id = (inst.id || '').toLowerCase();
        return name.indexOf(q) >= 0 || id.indexOf(q) >= 0;
      }).slice(0, 6);
      var prices = STATE.latestPrices || {};
      instruments = instruments.map(function (inst) {
        var lp = prices[inst.id];
        var value = lp && lp.value != null ? Number(lp.value).toFixed(2) : '—';
        var pctChg = lp && lp.pct_chg != null && Math.abs(lp.pct_chg) <= 50 ? (lp.pct_chg >= 0 ? '+' : '') + Number(lp.pct_chg).toFixed(2) + '%' : '—';
        var chgCls = lp && lp.pct_chg != null && Math.abs(lp.pct_chg) <= 50 ? (lp.pct_chg >= 0 ? 'positive' : 'negative') : '';
        return { id: inst.id, name: inst.name || inst.id, value: value, pctChg: pctChg, chgCls: chgCls };
      });
      var signals = STATE.signals || [];
      var latestDate = signals.length ? signals.reduce(function (max, r) { return r.date > max ? r.date : max; }, '') : '';
      var forDate = latestDate ? signals.filter(function (r) { return r.date === latestDate; }) : [];
      var topics = forDate.filter(function (r) { return (r.topic || '').toLowerCase().indexOf(q) >= 0; })
        .sort(function (a, b) { return (b.article_count || 0) - (a.article_count || 0); })
        .slice(0, 4)
        .map(function (r) { return { topic: r.topic || '', count: r.article_count != null ? r.article_count : '—' }; });
      return { instruments: instruments, topics: topics };
    },

    renderSearchDropdown(results, query) {
      this.closeSearchDropdown();
      var bar = document.querySelector('.research-search-bar');
      if (!bar) return;
      var dd = document.createElement('div');
      dd.id = 'search-dropdown';
      var html = '';
      if (results.instruments && results.instruments.length > 0) {
        html += '<div class="search-group-label">INSTRUMENTS</div>';
        results.instruments.forEach(function (r) {
          html += '<div class="search-result-item" data-id="' + escapeHtml(r.id) + '" data-type="instrument" data-name="' + escapeHtml(r.name) + '"><span class="search-result-name">' + escapeHtml(r.name) + '</span><span class="search-result-id">' + escapeHtml(r.id) + '</span><span class="search-result-value">' + escapeHtml(r.value) + '</span><span class="search-result-chg ' + (r.chgCls || '') + '">' + (r.pctChg || '—') + '</span></div>';
        });
      }
      if (results.topics && results.topics.length > 0) {
        html += '<div class="search-group-label">SIGNALS</div>';
        results.topics.forEach(function (r) {
          html += '<div class="search-result-item" data-id="' + escapeHtml(r.topic) + '" data-type="topic"><span class="search-result-name">' + escapeHtml(r.topic) + '</span><span class="search-result-id">signal topic</span><span class="search-result-value">' + escapeHtml(String(r.count)) + ' articles</span></div>';
        });
      }
      if (!html) html = '<div class="search-no-results">No results for "' + escapeHtml(query) + '"</div>';
      dd.innerHTML = html;
      var self = this;
      dd.querySelectorAll('.search-result-item').forEach(function (item) {
        item.addEventListener('click', function () {
          var id = item.getAttribute('data-id');
          var type = item.getAttribute('data-type');
          if (type === 'topic') {
            self.navigate('signals', { topic: id });
            self.closeSearchDropdown();
            return;
          }
          var name = item.getAttribute('data-name') || id;
          if (self.state.addingY) {
            self.state.addingY = false;
            self.addY({ id: id, name: name });
            self.closeSearchDropdown();
            if (self.state.xSeries && self.state.ySeries.length > 0) self.navigate('analysis');
            return;
          }
          if (!self.state.xSeries) {
            self.setX({ id: id, name: name });
          } else if (self.state.ySeries.length === 0) {
            self.addY({ id: id, name: name });
          } else {
            if (self.state.ySeries.length < 3) self.addY({ id: id, name: name });
          }
          self.closeSearchDropdown();
          if (self.state.xSeries && self.state.ySeries.length > 0) self.navigate('analysis');
        });
      });
      if (bar) bar.appendChild(dd);
      this._searchSelectedIndex = 0;
      var items = dd.querySelectorAll('.search-result-item');
      if (items.length > 0) items[0].classList.add('selected');
    },

    closeSearchDropdown() {
      var dd = document.getElementById('search-dropdown');
      if (dd && dd.parentNode) dd.parentNode.removeChild(dd);
      this._searchSelectedIndex = -1;
    },

    setX(obj) {
      this.state.xSeries = obj;
      var pill = document.getElementById('search-x-pill');
      if (!pill) return;
      pill.textContent = (obj.name || '').split(' ').slice(0, 2).join(' ') || obj.id;
      pill.classList.add('active');
      pill.dataset.id = obj.id;
      var self = this;
      pill.onclick = function () { self.clearX(); };
    },

    addY(obj) {
      if (this.state.ySeries.some(function (y) { return y.id === obj.id; })) return;
      this.state.ySeries.push(obj);
      this.renderYPills();
    },

    renderYPills() {
      var container = document.getElementById('search-y-pills');
      if (!container) return;
      if (this.state.ySeries.length === 0) {
        container.innerHTML = '<span class="search-y-empty">—</span>';
        return;
      }
      var self = this;
      container.innerHTML = this.state.ySeries.map(function (y) {
        var label = (y.name || '').split(' ').slice(0, 2).join(' ') || y.id;
        return '<span class="search-pill active" data-id="' + escapeHtml(y.id) + '">' + escapeHtml(label) + '<span class="search-pill-remove" data-id="' + escapeHtml(y.id) + '">x</span></span>';
      }).join('');
      container.querySelectorAll('.search-pill-remove').forEach(function (btn) {
        btn.addEventListener('click', function (e) {
          e.stopPropagation();
          self.removeY(btn.getAttribute('data-id'));
        });
      });
    },

    clearX() {
      this.state.xSeries = null;
      var pill = document.getElementById('search-x-pill');
      if (pill) {
        pill.textContent = '—';
        pill.classList.remove('active');
        pill.onclick = null;
      }
    },

    removeY(id) {
      this.state.ySeries = this.state.ySeries.filter(function (y) { return y.id !== id; });
      this.renderYPills();
    },

    _getAnalysisResultsRoot: function () {
      return document.getElementById('analysis-results-root');
    },

    _buildAnalysisUniverseDatalist: function () {
      var opts = (STATE.universe || []).filter(function (u) { return u && u.id; }).map(function (u) {
        var label = (u.name || u.id || '').toString().slice(0, 80);
        return '<option value="' + escapeHtml(u.id) + '">' + escapeHtml(label) + '</option>';
      }).join('');
      return '<datalist id="analysis-universe-datalist">' + opts + '</datalist>';
    },

    _analysisControlBarHtml: function () {
      var p = this.state.period || 90;
      return '<div class="analysis-control-bar" id="analysis-control-bar">'
        + '<div class="analysis-control-row">'
        + '<span class="analysis-bar-label">X</span>'
        + '<input type="search" class="analysis-bar-input analysis-control-bar-x" id="analysis-bar-x" list="analysis-universe-datalist" placeholder="Search or pick instrument…" autocomplete="off" />'
        + '<span class="analysis-bar-label">Y</span>'
        + '<input type="search" class="analysis-bar-input" id="analysis-bar-y" list="analysis-universe-datalist" placeholder="Search or pick instrument…" autocomplete="off" />'
        + '<div class="analysis-period-group" role="group" aria-label="History window">'
        + '<button type="button" class="analysis-period-btn' + (p === 30 ? ' active' : '') + '" data-days="30">30D</button>'
        + '<button type="button" class="analysis-period-btn' + (p === 90 ? ' active' : '') + '" data-days="90">90D</button>'
        + '<button type="button" class="analysis-period-btn' + (p === 180 ? ' active' : '') + '" data-days="180">180D</button>'
        + '<button type="button" class="analysis-period-btn' + (p === 365 ? ' active' : '') + '" data-days="365">1Y</button>'
        + '</div>'
        + '<button type="button" class="analysis-run-btn analysis-bar-analyse" id="analysis-bar-run">Analyse</button>'
        + '</div>'
        + this._buildAnalysisUniverseDatalist()
        + '</div>';
    },

    _findUniverseByInput: function (raw) {
      var q = (raw || '').trim();
      if (!q) return null;
      var u = STATE.universe || [];
      var byId = u.find(function (i) { return i.id === q; });
      if (byId) return byId;
      var lower = q.toLowerCase();
      return u.find(function (i) {
        var nm = (i.name || '').toLowerCase();
        var id = (i.id || '').toLowerCase();
        return nm.indexOf(lower) >= 0 || id.indexOf(lower) >= 0;
      }) || null;
    },

    _runAnalysisFromBar: function () {
      var xIn = document.getElementById('analysis-bar-x');
      var yIn = document.getElementById('analysis-bar-y');
      var xi = this._findUniverseByInput(xIn && xIn.value);
      var yi = this._findUniverseByInput(yIn && yIn.value);
      var root = this._getAnalysisResultsRoot();
      if (!xi || !yi) {
        if (root) root.innerHTML = '<div class="canvas-loading">Select valid X and Y instruments (use suggestions or exact ID).</div>';
        return;
      }
      this.state.xSeries = { id: xi.id, name: xi.name || xi.id };
      this.state.ySeries = [{ id: yi.id, name: yi.name || yi.id }];
      this.runAnalysis();
    },

    _wireAnalysisControlBar: function () {
      var self = this;
      var xIn = document.getElementById('analysis-bar-x');
      var yIn = document.getElementById('analysis-bar-y');
      if (xIn && this.state.xSeries) xIn.value = this.state.xSeries.id;
      if (yIn && this.state.ySeries && this.state.ySeries[0]) yIn.value = this.state.ySeries[0].id;
      document.querySelectorAll('#analysis-control-bar .analysis-period-btn').forEach(function (b) {
        b.onclick = function () {
          document.querySelectorAll('#analysis-control-bar .analysis-period-btn').forEach(function (x) { x.classList.remove('active'); });
          b.classList.add('active');
          self.state.period = parseInt(b.getAttribute('data-days'), 10) || 90;
        };
      });
      var run = document.getElementById('analysis-bar-run');
      if (run) run.onclick = function () { self._runAnalysisFromBar(); };
    },

    async runAnalysis() {
      if (!this.state.xSeries) {
        this.navigate('analysis');
        var root = this._getAnalysisResultsRoot();
        if (root) root.innerHTML = '<div class="canvas-loading">Select an X instrument first</div>';
        return;
      }
      if (!this.state.ySeries || this.state.ySeries.length === 0) {
        this.navigate('analysis');
        var root0 = this._getAnalysisResultsRoot();
        if (root0) root0.innerHTML = '<div class="canvas-loading">Select at least one Y instrument</div>';
        return;
      }
      this.navigate('analysis');
      var bodyEl = this._getAnalysisResultsRoot() || document.querySelector('#canvas-analysis .canvas-body');
      if (bodyEl) bodyEl.innerHTML = '<div class="canvas-loading">Computing analysis...</div>';
      var x = this.state.xSeries.id;
      var y = this.state.ySeries[0].id;
      var days = this.state.period || 90;
      var base = typeof CONFIG !== 'undefined' && CONFIG.API_BASE ? CONFIG.API_BASE : '';
      try {
        var seriesP = fetch(base + '/api/research/series?series_ids=' + encodeURIComponent(x + ',' + y) + '&days=' + days).then(function (r) { return r.json(); });
        var impactP = fetch(base + '/api/research/impact?base_series=' + encodeURIComponent(x) + '&target_series=' + encodeURIComponent(y) + '&shock_pct=10&days=' + days).then(function (r) { return r.json(); });
        var factorP = fetch(base + '/api/research/factor_decomposition?target_series=' + encodeURIComponent(y) + '&days=' + days).then(function (r) { return r.json(); });
        var forecastP = fetch(base + '/api/research/forecast?series_id=' + encodeURIComponent(y) + '&days_forward=30&days_history=' + days + '&model=both').then(function (r) { return r.json(); });
        var results = await Promise.all([seriesP, impactP, factorP, forecastP]);
        this.state.analysisData = { seriesData: results[0], impactData: results[1], factorData: results[2], forecastData: results[3], x: x, y: y, days: days };
        this.renderAnalysis();
      } catch (e) {
        console.error('runAnalysis', e);
        if (bodyEl) bodyEl.innerHTML = '<div class="canvas-loading">Error: ' + escapeHtml(String(e.message || e)) + '</div>';
      }
    },

    _prefillAnalysis: function (instrumentId) {
      var inst = (window.STATE && STATE.universe || []).find(function (u) {
        return u.id === instrumentId;
      });
      if (!inst) {
        // Try creating a stub from the ID
        inst = { id: instrumentId, name: instrumentId };
      }
      // Set X series
      this.state.xSeries = inst;
      // Navigate to analysis
      this.navigate('analysis');
      // Update control bar X input if visible
      setTimeout(function () {
        var xInput = document.querySelector('.analysis-control-bar-x, #analysis-x-input');
        if (xInput) {
          xInput.value = inst.id;
          // Trigger input event to update state
          xInput.dispatchEvent(new Event('input', { bubbles: true }));
        }
      }, 100);
    },

    _spearman: function (arrX, arrY) {
      var n = Math.min(arrX.length, arrY.length);
      if (n < 2) return null;
      var rank = function (arr) {
        var sorted = arr.slice().sort(function (a, b) { return a - b; });
        return arr.map(function (v) { return sorted.indexOf(v) + 1; });
      };
      var rx = rank(arrX.slice(0, n));
      var ry = rank(arrY.slice(0, n));
      var sumD2 = 0;
      for (var i = 0; i < n; i++) sumD2 += (rx[i] - ry[i]) * (rx[i] - ry[i]);
      return 1 - (6 * sumD2) / (n * (n * n - 1));
    },

    renderAnalysis() {
      var data = this.state.analysisData;
      if (!data) return;
      var body = this._getAnalysisResultsRoot() || document.querySelector('#canvas-analysis .canvas-body');
      if (!body) return;
      var xName = (this.state.xSeries && this.state.xSeries.name) || data.x;
      var yName = (this.state.ySeries && this.state.ySeries[0] && this.state.ySeries[0].name) || data.y;
      var days = data.days || 90;
      var seriesData = data.seriesData || {};
      var impactData = data.impactData || {};
      var factorData = data.factorData || {};
      var forecastData = data.forecastData || {};
      var html = '';

      var panel1Title = escapeHtml(xName) + ' vs ' + escapeHtml(yName) + ' — ' + days + 'D';
      html += '<div class="analysis-panel"><div class="analysis-panel-header"><span class="analysis-panel-title">' + panel1Title + '</span><button type="button" class="add-to-canvas-btn" data-panel="series">+ Add to canvas</button></div><div class="analysis-panel-body" id="panel-overlaid"></div></div>';
      var panel2Title = 'If ' + escapeHtml(xName) + ' moves...';
      html += '<div class="analysis-panel"><div class="analysis-panel-header"><span class="analysis-panel-title">' + panel2Title + '</span><button type="button" class="add-to-canvas-btn" data-panel="impact">+ Add to canvas</button></div><div class="analysis-panel-body" id="panel-impact"></div></div>';
      html += '<div class="analysis-panel"><div class="analysis-panel-header"><span class="analysis-panel-title">What drives ' + escapeHtml(yName) + '</span><button type="button" class="add-to-canvas-btn" data-panel="factors">+ Add to canvas</button></div><div class="analysis-panel-body" id="panel-factors"></div></div>';
      html += '<div class="analysis-panel analysis-panel-forecast"><div class="analysis-panel-header"><span class="analysis-panel-title">' + escapeHtml(yName) + ' — 30D projection</span><button type="button" class="add-to-canvas-btn" data-panel="forecast">+ Add to canvas</button></div><div class="analysis-panel-body" id="panel-forecast"></div></div>';
      body.innerHTML = html;

      var self = this;
      var seriesById = seriesData.series || {};
      var xId = (this.state.xSeries && this.state.xSeries.id) || data.x;
      var yId = (this.state.ySeries && this.state.ySeries[0] && this.state.ySeries[0].id) || data.y;
      var rawX = seriesById[xId];
      var rawY = seriesById[yId];
      if (!rawX && Array.isArray(seriesData.series)) {
        rawX = seriesData.series.find(function (s) { return (s.series_id || s.id) === xId; });
        rawX = rawX && (rawX.data || rawX.points || rawX.values) ? (rawX.data || rawX.points || rawX.values) : rawX;
      }
      if (!rawY && Array.isArray(seriesData.series)) {
        rawY = seriesData.series.find(function (s) { return (s.series_id || s.id) === yId; });
        rawY = rawY && (rawY.data || rawY.points || rawY.values) ? (rawY.data || rawY.points || rawY.values) : rawY;
      }
      var corrText = '';
      var corrFromState = STATE.correlations && Array.isArray(STATE.correlations) ? STATE.correlations.find(function (c) { return (c.series_a === data.x && c.series_b === data.y) || (c.series_a === data.y && c.series_b === data.x); }) : null;
      if (corrFromState && corrFromState.rho != null) corrText = 'Correlation: ' + Number(corrFromState.rho).toFixed(2) + (corrFromState.lag != null ? ' | Lag: ' + corrFromState.lag + 'd' : '') + (corrFromState.n != null ? ' | ' + corrFromState.n + ' obs' : '');
      else {
        var rawXArr = Array.isArray(rawX) ? rawX : [];
        var rawYArr = Array.isArray(rawY) ? rawY : [];
        var xRet = [];
        var yRet = [];
        for (var j = 1; j < Math.min(rawXArr.length, rawYArr.length); j++) {
          var p0 = rawXArr[j - 1].value; var p1 = rawXArr[j].value;
          if (p0 && p1) xRet.push((p1 - p0) / p0 * 100);
          var q0 = rawYArr[j - 1].value; var q1 = rawYArr[j].value;
          if (q0 && q1) yRet.push((q1 - q0) / q0 * 100);
        }
        var rho = this._spearman(xRet, yRet);
        corrText = rho != null ? 'Correlation: ' + rho.toFixed(2) : 'Correlation: —';
      }
      var panelOverlaidEl = document.getElementById('panel-overlaid');
      if (panelOverlaidEl) panelOverlaidEl.innerHTML = renderOverlaidSVG(seriesData, xId, yId, 500, 220, xName, yName, corrText);

      var impactImpacts = Array.isArray(impactData.impacts) ? impactData.impacts : [];
      var shockVal = (impactData.shock_pct != null ? impactData.shock_pct : 10);
      var impactHtml = '<div class="impact-input-row"><input type="number" id="impact-shock-input" value="' + escapeHtml(String(shockVal)) + '" step="1" min="-100" max="100"/><span>%</span><button type="button" id="impact-calculate-btn">Calculate</button></div>';
      impactHtml += '<table class="analysis-impact-table"><thead><tr><th>Instrument</th><th>β</th><th>Predicted</th><th>95% CI</th><th>R²</th><th>Conf</th></tr></thead><tbody id="impact-tbody">';
      impactImpacts.forEach(function (imp) {
        var pred = imp.predicted_move_pct != null ? Number(imp.predicted_move_pct) : null;
        var predStr = pred != null ? (pred >= 0 ? '+' : '') + pred.toFixed(2) + '%' : '—';
        var predCls = pred != null ? (pred >= 0 ? 'positive' : 'negative') : '';
        var ciStr = (imp.ci_95_low != null && imp.ci_95_high != null) ? Number(imp.ci_95_low).toFixed(2) + '% to ' + Number(imp.ci_95_high).toFixed(2) + '%' : '—';
        var r2 = imp.r_squared != null ? Number(imp.r_squared) : 0;
        var conf = imp.p_value != null ? (imp.p_value < 0.01 ? 'HIGH' : imp.p_value < 0.05 ? 'MEDIUM' : 'LOW') : '—';
        var confCls = conf === 'HIGH' ? 'conf-high' : conf === 'MEDIUM' ? 'conf-medium' : conf === 'LOW' ? 'conf-low' : '';
        impactHtml += '<tr><td>' + escapeHtml(imp.name || imp.series_id || '') + '</td><td>' + (imp.beta != null ? Number(imp.beta).toFixed(3) : '—') + '</td><td><span class="' + predCls + '">' + predStr + '</span></td><td>' + escapeHtml(ciStr) + '</td><td><div class="r2-bar-wrap" style="display:inline-block;width:40px;height:6px;background:#e2e8f0;border-radius:2px"><div style="width:' + Math.min(100, r2 * 100) + '%;height:100%;background:#0d9488;border-radius:2px"></div></div> ' + (imp.r_squared != null ? Number(imp.r_squared).toFixed(2) : '—') + '</td><td><span class="conf-badge ' + confCls + '">' + escapeHtml(conf) + '</span></td></tr>';
      });
      if (impactImpacts.length === 0) impactHtml += '<tr><td colspan="6" class="impact-empty">' + (impactData.error ? escapeHtml(impactData.error) : 'No impact data for this pair. Try different instruments or period.') + '</td></tr>';
      impactHtml += '</tbody></table>';
      var panelImpactEl = document.getElementById('panel-impact');
      if (panelImpactEl) panelImpactEl.innerHTML = impactHtml;
      document.getElementById('impact-calculate-btn').addEventListener('click', function () {
        var shock = parseFloat(document.getElementById('impact-shock-input').value) || 10;
        API.getImpact(data.x, data.y, shock, data.days).then(function (newImpact) {
          if (newImpact.error) return;
          self.state.analysisData.impactData = newImpact;
          var tbody = document.getElementById('impact-tbody');
          if (!tbody) return;
          var rows = (newImpact.impacts || []).map(function (imp) {
            var pred = imp.predicted_move_pct != null ? Number(imp.predicted_move_pct) : null;
            var predStr = pred != null ? (pred >= 0 ? '+' : '') + pred.toFixed(2) + '%' : '—';
            var predCls = pred != null ? (pred >= 0 ? 'positive' : 'negative') : '';
            var ciStr = (imp.ci_95_low != null && imp.ci_95_high != null) ? Number(imp.ci_95_low).toFixed(2) + '% to ' + Number(imp.ci_95_high).toFixed(2) + '%' : '—';
            var r2 = imp.r_squared != null ? Number(imp.r_squared) : 0;
            var conf = imp.p_value != null ? (imp.p_value < 0.01 ? 'HIGH' : imp.p_value < 0.05 ? 'MEDIUM' : 'LOW') : '—';
            var confCls2 = conf === 'HIGH' ? 'conf-high' : conf === 'MEDIUM' ? 'conf-medium' : conf === 'LOW' ? 'conf-low' : '';
            return '<tr><td>' + escapeHtml(imp.name || imp.series_id || '') + '</td><td>' + (imp.beta != null ? Number(imp.beta).toFixed(3) : '—') + '</td><td><span class="' + predCls + '">' + predStr + '</span></td><td>' + escapeHtml(ciStr) + '</td><td><div class="r2-bar-wrap" style="display:inline-block;width:40px;height:6px;background:#e2e8f0;border-radius:2px"><div style="width:' + Math.min(100, r2 * 100) + '%;height:100%;background:#0d9488;border-radius:2px"></div></div> ' + (imp.r_squared != null ? Number(imp.r_squared).toFixed(2) : '—') + '</td><td><span class="conf-badge ' + confCls2 + '">' + escapeHtml(conf) + '</span></td></tr>';
          }).join('');
          tbody.innerHTML = rows;
        });
      });

      document.getElementById('panel-factors').innerHTML = renderFactorsEmbedHTML(factorData);

      var fcEl = document.getElementById('panel-forecast');
      if (!forecastData || forecastData.error || !forecastData.history || !forecastData.history.length) {
        if (fcEl) fcEl.innerHTML = '<p class="canvas-loading">No forecast data available.</p>';
      } else if (fcEl) {
        fcEl.innerHTML = renderForecastSVG(forecastData, 500, 380);
      }

      var headerRight = document.querySelector('#canvas-analysis .canvas-header-right');
      if (headerRight) {
        headerRight.innerHTML = '<button type="button" class="btn-pin-all">+ Add all to canvas</button>';
        headerRight.querySelector('.btn-pin-all').addEventListener('click', function () {
          var s = self.state;
          var ad = s.analysisData;
          if (!ad || !s.xSeries || !s.ySeries || !s.ySeries[0]) return;
          var xId = s.xSeries.id; var yId = s.ySeries[0].id;
          var xNm = (s.xSeries && s.xSeries.name) || xId;
          var yNm = (s.ySeries[0] && s.ySeries[0].name) || yId;
          self.addAnalysisOutputToCanvas('overlaid', ad.seriesData, xNm + ' vs ' + yNm + ' \u2014 Overlaid');
          var shockInpAll = document.getElementById('impact-shock-input');
          var spAll = shockInpAll ? parseFloat(shockInpAll.value) : NaN;
          if (isNaN(spAll)) spAll = (ad.impactData && ad.impactData.shock_pct != null) ? Number(ad.impactData.shock_pct) : 10;
          self.addAnalysisOutputToCanvas('impact', ad.impactData, 'Impact: ' + xId + ' \u2192 ' + yId, { shockPct: spAll });
          self.addAnalysisOutputToCanvas('factors', ad.factorData, 'What drives ' + yNm);
          self.addAnalysisOutputToCanvas('forecast', ad.forecastData, yNm + ' \u2014 30D Forecast');
        });
      }
      document.querySelectorAll('.add-to-canvas-btn').forEach(function (btn) {
        btn.addEventListener('click', function () {
          var panel = btn.getAttribute('data-panel');
          var s = self.state;
          var ad = s.analysisData;
          if (!ad || !s.xSeries || !s.ySeries || !s.ySeries[0]) return;
          var xId = s.xSeries.id;
          var yId = s.ySeries[0].id;
          var xNm = (s.xSeries && s.xSeries.name) || xId;
          var yNm = (s.ySeries[0] && s.ySeries[0].name) || yId;
          if (panel === 'series') {
            self.addAnalysisOutputToCanvas('overlaid', ad.seriesData, xNm + ' vs ' + yNm + ' \u2014 Overlaid');
          } else if (panel === 'impact') {
            var shockInp = document.getElementById('impact-shock-input');
            var sp = shockInp ? parseFloat(shockInp.value) : NaN;
            if (isNaN(sp)) sp = (ad.impactData && ad.impactData.shock_pct != null) ? Number(ad.impactData.shock_pct) : 10;
            self.addAnalysisOutputToCanvas('impact', ad.impactData, 'Impact: ' + xId + ' \u2192 ' + yId, { shockPct: sp });
          } else if (panel === 'factors') {
            self.addAnalysisOutputToCanvas('factors', ad.factorData, 'What drives ' + yNm);
          } else if (panel === 'forecast') {
            self.addAnalysisOutputToCanvas('forecast', ad.forecastData, yNm + ' \u2014 30D Forecast');
          }
        });
      });
    },

    _assetOrder: ['equity', 'fixed_income', 'commodity', 'fx', 'rates', 'macro'],
    _assetLabels: { equity: 'Equities', fixed_income: 'Fixed Income', commodity: 'Commodities', fx: 'FX', rates: 'Rates', macro: 'Macro' },

    _truncateName: function (name, maxLen) {
      maxLen = maxLen || 18;
      if (!name || name.length <= maxLen) return name;
      var truncated = name.substring(0, maxLen);
      var lastSpace = truncated.lastIndexOf(' ');
      return (lastSpace > 8 ? truncated.substring(0, lastSpace) : truncated) + '...';
    },

    populateSidebar() {
      console.log('[ResearchV2] universe:', STATE.universe?.length);
      console.log('[ResearchV2] latestPrices:', STATE.latestPrices ? Object.keys(STATE.latestPrices).length : 0);
      console.log('[ResearchV2] signals:', STATE.signals?.length);
      var container = document.getElementById('panel-instruments') || document.getElementById('sidebar-instruments');
      if (!container) return;
      if (!STATE.universe || STATE.universe.length === 0) {
        console.log('[ResearchV2] universe not ready, retrying in 2s...');
        setTimeout(function () { if (typeof ResearchV2 !== 'undefined' && ResearchV2.populateSidebar) ResearchV2.populateSidebar(); }, 2000);
        return;
      }
      var universe = STATE.universe || [];
      var prices = STATE.latestPrices || {};
      var order = this._assetOrder;
      var labels = this._assetLabels;
      var self = this;
      var byClass = {};
      universe.forEach(function (i) {
        var ac = (i.asset_class || '').toLowerCase().replace(/\s/g, '_');
        if (ac === 'equities') ac = 'equity';
        if (ac.indexOf('fixed') >= 0) ac = 'fixed_income';
        if (ac === 'commodities') ac = 'commodity';
        if (order.indexOf(ac) < 0) ac = 'macro';
        if (!byClass[ac]) byClass[ac] = [];
        byClass[ac].push(i);
      });
      var fullHtml = '';
      order.forEach(function (ac) {
        var list = byClass[ac] || [];
        list.sort(function (a, b) { return (b.liquidity || 0) - (a.liquidity || 0); });
        var label = (labels[ac] || ac).toUpperCase();
        var groupKey = ac.replace(/_/g, '-');
        fullHtml += '<div class="sidebar-section"><div class="sidebar-group-header" data-group="' + groupKey + '">' + label + '</div><div class="sidebar-group-body">';
        if (list.length === 0) fullHtml += '<div class="sidebar-loading">Loading...</div>';
        else list.forEach(function (i) {
          var name = self._truncateName((i.name || i.id || '').toString(), 18);
          var lp = prices[i.id];
          var price = lp && lp.value != null ? Number(lp.value).toFixed(2) : '—';
          var chg = '—';
          var chgCls = '';
          if (lp && lp.pct_chg != null && Math.abs(lp.pct_chg) <= 50) {
            chg = (lp.pct_chg >= 0 ? '+' : '') + Number(lp.pct_chg).toFixed(2) + '%';
            chgCls = lp.pct_chg >= 0 ? 'positive' : 'negative';
          }
          fullHtml += '<div class="sidebar-instrument-row" data-id="' + escapeHtml(i.id) + '"><span class="sidebar-inst-name">' + escapeHtml(name) + '</span><span class="sidebar-inst-price">' + price + '</span><span class="sidebar-inst-chg ' + chgCls + '">' + chg + '</span></div>';
        });
        fullHtml += '</div></div>';
      });
      // Only update these two containers; VIEWS and COMPUTED DATA stay in index.html
      container.innerHTML = fullHtml;
      var topicsContainer = document.getElementById('sidebar-signal-topics');
      if (topicsContainer) {
        var signals = STATE.signals || [];
        var latestDate = signals.length ? signals.reduce(function (max, r) { return r.date > max ? r.date : max; }, '') : '';
        var forDate = latestDate ? signals.filter(function (r) { return r.date === latestDate; }) : [];
        forDate.sort(function (a, b) { return (b.article_count || 0) - (a.article_count || 0); });
        var top5 = forDate.slice(0, 5);
        if (top5.length === 0) topicsContainer.innerHTML = '<div class="sidebar-loading">Loading...</div>';
        else topicsContainer.innerHTML = top5.map(function (r) {
          var topic = (r.topic || '').toString();
          return '<div class="sidebar-item sidebar-topic-row" data-view="signals" data-topic="' + escapeHtml(topic) + '"><span class="sidebar-item-name">' + escapeHtml(topic) + '</span><span class="sidebar-item-badge">' + (r.article_count != null ? r.article_count : '—') + '</span></div>';
        }).join('');
      }
      var sidebarEl = document.getElementById('panel-instruments') || document.getElementById('research-sidebar');
      if (sidebarEl) sidebarEl.scrollTop = 0;
    },

    updateSidebarPrices() {
      var prices = STATE.latestPrices || {};
      document.querySelectorAll('.sidebar-instrument-row[data-id]').forEach(function (row) {
        var id = row.getAttribute('data-id');
        var lp = prices[id];
        var priceEl = row.querySelector('.sidebar-inst-price');
        var chgEl = row.querySelector('.sidebar-inst-chg');
        if (priceEl) priceEl.textContent = lp && lp.value != null ? Number(lp.value).toFixed(2) : '—';
        if (chgEl) {
          var chg = '—';
          var chgCls = '';
          if (lp && lp.pct_chg != null && Math.abs(lp.pct_chg) <= 50) {
            chg = (lp.pct_chg >= 0 ? '+' : '') + Number(lp.pct_chg).toFixed(2) + '%';
            chgCls = lp.pct_chg >= 0 ? 'positive' : 'negative';
          }
          chgEl.textContent = chg;
          chgEl.className = 'sidebar-inst-chg ' + chgCls;
        }
      });
    },

    render: {
      analysis: function () {
        var bar = ResearchV2._analysisControlBarHtml();
        var hint = ResearchV2.state.analysisData
          ? ''
          : '<div class="canvas-empty-state analysis-results-hint">Select X and Y, choose a period, then click Analyse.</div>';
        ResearchV2._renderView('canvas-analysis', 'Analysis', bar + '<div id="analysis-results-root">' + hint + '</div>');
        ResearchV2._wireAnalysisControlBar();
        if (ResearchV2.state.analysisData) ResearchV2.renderAnalysis();
        ResearchV2._maybeInsertBoardMigrationBanner();
      },
      thesis: async function () {
        var thesisEl = document.getElementById('canvas-thesis');
        if (!thesisEl || thesisEl.id !== 'canvas-thesis') return;
        var thesis = ThesisManager.getActive();
        if (!thesis) thesis = await ThesisManager.createNew();
        var editorEl = document.getElementById('thesis-editor');
        var alreadyShowingSameThesis = editorEl && editorEl.dataset && editorEl.dataset.thesisId === thesis.id;
        if (alreadyShowingSameThesis) {
          try {
            await ResearchV2.refreshThesisChartEmbeds();
          } catch (err) {
            console.warn('[ResearchV2] refreshThesisChartEmbeds error (non-fatal):', err);
          }
          // Still re-wire mode toggle in case canvas container was cleared
          var existingModeBar = document.getElementById('thesis-mode-bar');
          if (!existingModeBar) {
            // Mode bar lost (e.g. after navigate away/back) — fall through to full re-render
          } else {
            return;
          }
        }
        var thesisBody =
          '<div class="thesis-toolbar" id="thesis-toolbar">'
          + '<button type="button" class="thesis-btn" id="thesis-btn-new">+ New</button>'
          + '<button type="button" class="thesis-btn" id="thesis-btn-save">\uD83D\uDCDE Save</button>'
          + '<button type="button" class="thesis-btn" id="thesis-btn-export">\u2193 Export .txt</button>'
          + '<button type="button" class="thesis-btn" id="thesis-btn-pdf">Export PDF</button>'
          + '<span class="thesis-save-status" id="thesis-save-status"></span>'
          + '</div>'
          + '<div class="thesis-toolbar-meta" id="thesis-toolbar-meta"></div>'
          + '<input type="text" class="thesis-title-input" id="thesis-title-input" placeholder="Thesis title..." />'
          + '<div class="thesis-mode-bar" id="thesis-mode-bar">'
          + '<button type="button" class="thesis-mode-btn" id="thesis-mode-canvas" data-mode="canvas">Canvas</button>'
          + '<button type="button" class="thesis-mode-btn" id="thesis-mode-focus" data-mode="focus">Focus</button>'
          + '<button type="button" class="thesis-add-panel-btn" id="thesis-add-panel-btn" style="display:none;">+ Add panel</button>'
          + '</div>'
          + '<div class="thesis-canvas-container" id="thesis-canvas-container"></div>'
          + '<div class="thesis-editor-container" id="thesis-editor-container" style="position:relative;">'
          + '<div class="thesis-archived-banner" id="thesis-archived-banner" style="display:none;">This thesis is archived. Change status to edit.</div>'
          + '<div class="thesis-restore-banner" id="thesis-restore-banner" style="display:none;"></div>'
          + '<div class="thesis-editor" id="thesis-editor" contenteditable="true" spellcheck="true" data-placeholder="Start writing your thesis. Type @ to reference an instrument or signal..."></div>'
          + '<div class="thesis-history-panel" id="thesis-history-panel"></div>'
          + '</div>';
        ResearchV2._renderView('canvas-thesis', 'Thesis', thesisBody);
        try {
          await ResearchV2.initThesisEditor();
        } catch (err) {
          console.warn('[ResearchV2] initThesisEditor error (non-fatal):', err);
        }
        try {
          if (typeof ResearchV2 !== 'undefined' && ResearchV2.renderThesisToolbarMeta) ResearchV2.renderThesisToolbarMeta();
        } catch (err) {
          console.warn('[ResearchV2] renderThesisToolbarMeta error (non-fatal):', err);
        }
        // Wire Canvas/Focus mode toggle
        (function () {
          var canvasBtn = document.getElementById('thesis-mode-canvas');
          var focusBtn  = document.getElementById('thesis-mode-focus');
          var canvasCt  = document.getElementById('thesis-canvas-container');
          var editorCt  = document.getElementById('thesis-editor-container');
          if (!canvasBtn || !focusBtn || !canvasCt || !editorCt) return;

          // Determine starting mode: Canvas if thesis has a canvas_layout, else Focus
          var hasLayout = !!(ThesisManager.getCanvasLayout());
          var currentMode = hasLayout ? 'canvas' : 'focus';

          function mountCanvas(canvasCt, layout) {
            if (typeof CanvasEngine === 'undefined') return;
            var instance = CanvasEngine.mount(canvasCt, layout, {
              onLayoutChange: function (newLayout) {
                ThesisManager.setCanvasLayout(newLayout);
              },
              onPanelClose: function (panelId) {
                instance.removePanel(panelId);
              },
              renderPanel: function (contentEl, panel) {
                if (typeof PanelRegistry !== 'undefined') {
                  PanelRegistry.render(contentEl, panel);
                }
              }
            });
            canvasCt._canvasInstance = instance;
          }

          function applyMode(mode) {
            currentMode = mode;
            var isCanvas = (mode === 'canvas');
            canvasBtn.classList.toggle('thesis-mode-btn--active', isCanvas);
            focusBtn.classList.toggle('thesis-mode-btn--active', !isCanvas);
            canvasCt.style.display = isCanvas ? 'block' : 'none';
            editorCt.style.display = isCanvas ? 'none'  : 'block';
            var addPanelBtn = document.getElementById('thesis-add-panel-btn');
            if (addPanelBtn) addPanelBtn.style.display = isCanvas ? 'inline-flex' : 'none';

            if (isCanvas) {
              canvasCt.innerHTML = '';
              var layout = ThesisManager.getCanvasLayout();

              // If no layout yet but thesis exists, try fetching it
              if (!layout && ThesisManager._activeThesis && ThesisManager._activeThesis.id) {
                // Layout may not be loaded yet — fetch from API
                fetch(CONFIG.API_BASE + '/api/research-theses/' + ThesisManager._activeThesis.id)
                  .then(function (r) { return r.json(); })
                  .then(function (data) {
                    if (data && data.canvas_layout) {
                      ThesisManager._activeThesis.canvas_layout = data.canvas_layout;
                      // Re-apply canvas mode with the loaded layout
                      canvasCt.innerHTML = '';
                      mountCanvas(canvasCt, data.canvas_layout);
                    }
                  })
                  .catch(function () {});
              }

              var effectiveLayout = layout || {
                version: 1,
                panels: [],
                grid: { cols: 12, row_height_px: 80, gap_px: 8 }
              };
              mountCanvas(canvasCt, effectiveLayout);
            }
          }

          canvasBtn.addEventListener('click', function () { applyMode('canvas'); });
          focusBtn.addEventListener('click',  function () { applyMode('focus');  });
          applyMode(currentMode);
        })();
        // Panel picker — Spec 12b
        (function () {
          // All planned panel types — shown regardless of registration state
          var PANEL_TYPES = [
            {
              type: 'macro_context',
              label: 'Macro context',
              desc: 'Live regime, rates, and signals',
              icon: '◎',
              defaultW: 4,
              defaultH: 5,
            },
            {
              type: 'chart',
              label: 'Chart',
              desc: 'Price chart — overlaid, forecast, or impact',
              icon: '📈',
              defaultW: 6,
              defaultH: 4,
            },
            {
              type: 'factor_view',
              label: 'Factor view',
              desc: 'Macro factor decomposition for any instrument',
              icon: '⬡',
              defaultW: 5,
              defaultH: 5,
            },
            {
              type: 'text_block',
              label: 'Text block',
              desc: 'Written notes and analysis',
              icon: '✎',
              defaultW: 6,
              defaultH: 3,
            },
            {
              type: 'analysis_output',
              label: 'Analysis output',
              desc: 'Pinned analysis result',
              icon: '▤',
              defaultW: 8,
              defaultH: 4,
            },
            {
              type: 'screener',
              label: 'Screener',
              desc: 'Market overview snapshot',
              icon: '◫',
              defaultW: 12,
              defaultH: 4,
            },
          ];

          var addPanelBtn = document.getElementById('thesis-add-panel-btn');
          if (!addPanelBtn) return;

          // Build and show picker overlay
          function openPicker() {
            var existing = document.getElementById('panel-picker-overlay');
            if (existing) existing.remove();

            var overlay = document.createElement('div');
            overlay.id = 'panel-picker-overlay';
            overlay.className = 'panel-picker-overlay';

            var modal = document.createElement('div');
            modal.className = 'panel-picker-modal';

            var header = document.createElement('div');
            header.className = 'panel-picker-header';
            header.innerHTML =
              '<span class="panel-picker-title">Add panel</span>' +
              '<button type="button" class="panel-picker-close" id="panel-picker-close">×</button>';
            modal.appendChild(header);

            var grid = document.createElement('div');
            grid.className = 'panel-picker-grid';

            PANEL_TYPES.forEach(function (pt) {
              var card = document.createElement('button');
              card.type = 'button';
              card.className = 'panel-picker-card';
              card.dataset.panelType = pt.type;
              card.innerHTML =
                '<span class="panel-picker-card-icon">' + pt.icon + '</span>' +
                '<span class="panel-picker-card-label">' + pt.label + '</span>' +
                '<span class="panel-picker-card-desc">' + pt.desc + '</span>' +
                '<span class="panel-picker-card-size">' +
                  pt.defaultW + '×' + pt.defaultH + ' grid units' +
                '</span>';
              card.addEventListener('click', function () {
                closePicker();
                addPanel(pt);
              });
              grid.appendChild(card);
            });

            modal.appendChild(grid);
            overlay.appendChild(modal);
            document.body.appendChild(overlay);

            // Close on outside click
            overlay.addEventListener('click', function (e) {
              if (e.target === overlay) closePicker();
            });

            // Close on Escape
            function onKeydown(e) {
              if (e.key === 'Escape') {
                closePicker();
                document.removeEventListener('keydown', onKeydown);
              }
            }
            document.addEventListener('keydown', onKeydown);

            document.getElementById('panel-picker-close')
              .addEventListener('click', closePicker);

            // Animate in
            requestAnimationFrame(function () {
              overlay.classList.add('panel-picker-overlay--visible');
            });
          }

          function closePicker() {
            var overlay = document.getElementById('panel-picker-overlay');
            if (overlay) overlay.remove();
          }

          // Add panel to the canvas
          function addPanel(pt) {
            var canvasCt = document.getElementById('thesis-canvas-container');
            if (!canvasCt || !canvasCt._canvasInstance) {
              console.warn('[12b] No canvas instance found');
              return;
            }
            var instance = canvasCt._canvasInstance;

            // Find a free position: scan existing panels to find bottom of stack
            var layout = instance.getLayout();
            var maxY = 0;
            (layout.panels || []).forEach(function (p) {
              var bottom = p.y + p.h;
              if (bottom > maxY) maxY = bottom;
            });

            var newPanelId = instance.addPanel({
              type: pt.type,
              x: 0,
              y: maxY,
              w: pt.defaultW,
              h: pt.defaultH,
              config: {},
            });

            console.log('[12b] Added panel:', pt.type, 'id:', newPanelId);
          }

          addPanelBtn.addEventListener('click', openPicker);
        })();
      },
      thesislist: async function () {
        function relativeTime(iso) {
          if (!iso) return '';
          var d = new Date(iso);
          var diff = Date.now() - d.getTime();
          if (diff < 0) diff = 0;
          var s = Math.floor(diff / 1000);
          if (s < 60) return 'just now';
          var m = Math.floor(s / 60);
          if (m < 60) return m + 'm ago';
          var h = Math.floor(m / 60);
          if (h < 24) return h + 'h ago';
          var months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
          return months[d.getMonth()] + ' ' + d.getDate();
        }

        function statusLabel(status) {
          return status === 'active' ? 'Active' : status === 'archived' ? 'Archived' : 'Draft';
        }

        function renderRows(theses, active) {
          if (!theses || theses.length === 0) {
            return '<div class="thesislist-empty">No theses yet. Create your first thesis to get started.</div>';
          }
          var html = '<div class="thesislist-list" id="thesislist-rows">';
          theses.forEach(function (t) {
            var isActive = active && t.id === active.id;
            var status = (t.status || 'draft');
            var tags = Array.isArray(t.tags) ? t.tags : [];
            var tagsHtml = tags.map(function (tag) { return '<span class="thesis-tag-chip">' + escapeHtml(tag) + '</span>'; }).join('');
            html += '<div class="thesislist-item' + (isActive ? ' thesislist-item--active' : '') + '" data-thesis-id="' + escapeHtml(t.id) + '" data-status="' + escapeHtml(status) + '" data-title="' + escapeHtml((t.title || '').toLowerCase()) + '" style="position:relative;">'
              + '<span class="thesislist-item-dot"></span>'
              + '<span class="thesislist-item-title" data-role="title">' + escapeHtml(t.title || 'Untitled thesis') + '</span>'
              + '<span class="thesis-status-badge" data-status="' + escapeHtml(status) + '">' + escapeHtml(statusLabel(status)) + '</span>'
              + tagsHtml
              + '<span class="thesis-list-timestamp">' + escapeHtml(relativeTime(t.updated_at)) + '</span>'
              + '<button type="button" class="thesis-list-menu-btn" title="Menu" aria-label="Menu">\u22EF</button>'
              + '<div class="thesislist-item-actions">'
              + '<button class="thesislist-delete-btn" data-thesis-id="' + escapeHtml(t.id) + '">Delete</button>'
              + '</div>'
              + '</div>';
          });
          html += '</div>';
          return html;
        }

        function applyFilters() {
          var statusActive = document.querySelector('.thesis-filter-pill--active');
          var status = statusActive ? (statusActive.getAttribute('data-filter-status') || 'all') : 'all';
          var qEl = document.querySelector('.thesis-list-search');
          var q = qEl ? (qEl.value || '').trim().toLowerCase() : '';
          document.querySelectorAll('.thesislist-item[data-thesis-id]').forEach(function (row) {
            var s = row.getAttribute('data-status') || 'draft';
            var title = row.getAttribute('data-title') || '';
            var okStatus = (status === 'all') ? true : (s === status);
            var okQuery = q ? (title.indexOf(q) !== -1) : true;
            row.style.display = (okStatus && okQuery) ? '' : 'none';
          });
        }

        await ThesisManager.loadAll();
        var theses = ThesisManager.getThesisList();
        var active = ThesisManager.getActive();

        var existing = document.querySelector('#canvas-thesislist .thesislist-container');
        if (!existing) {
          var bodyHtml = '<div class="thesislist-container">'
            + '<div class="thesislist-header">'
            + '<div class="thesislist-title">Theses</div>'
            + '<button class="thesislist-new-btn" id="thesislist-new-btn">+ New thesis</button>'
            + '</div>'
            + '<div class="thesis-filter-bar" id="thesislist-filter-bar">'
            + '<button class="thesis-filter-pill thesis-filter-pill--active" data-filter-status="all">All</button>'
            + '<button class="thesis-filter-pill" data-filter-status="draft">Draft</button>'
            + '<button class="thesis-filter-pill" data-filter-status="active">Active</button>'
            + '<button class="thesis-filter-pill" data-filter-status="archived">Archived</button>'
            + '<input class="thesis-list-search" placeholder="Search theses...">'
            + '</div>'
            + '<div id="thesislist-body">' + renderRows(theses, active) + '</div>'
            + '</div>';
          ResearchV2._renderView('canvas-thesislist', 'Theses', bodyHtml);
        } else {
          var body = document.getElementById('thesislist-body');
          if (body) body.innerHTML = renderRows(theses, active);
        }

        var newBtn = document.getElementById('thesislist-new-btn');
        if (newBtn) {
          newBtn.onclick = function () {
            (async function () {
              await ThesisManager.createNew();
              ResearchV2.navigate('thesis');
              ResearchV2.populateSidebarTheses();
            })();
          };
        }

        // Filter bar wiring (inject once)
        var bar = document.getElementById('thesislist-filter-bar');
        if (bar && !bar._wired) {
          bar._wired = true;
          var debounceT = null;
          bar.querySelectorAll('.thesis-filter-pill').forEach(function (pill) {
            pill.addEventListener('click', function () {
              bar.querySelectorAll('.thesis-filter-pill').forEach(function (p) { p.classList.remove('thesis-filter-pill--active'); });
              pill.classList.add('thesis-filter-pill--active');
              applyFilters();
            });
          });
          var qEl = bar.querySelector('.thesis-list-search');
          if (qEl) {
            qEl.addEventListener('input', function () {
              if (debounceT) clearTimeout(debounceT);
              debounceT = setTimeout(applyFilters, 150);
            });
          }
        }

        // List row click to open thesis
        document.querySelectorAll('.thesislist-item[data-thesis-id]').forEach(function (item) {
          item.addEventListener('click', function (e) {
            if (e.target.classList.contains('thesislist-delete-btn')) return;
            if (e.target.classList.contains('thesis-list-menu-btn')) return;
            if (e.target.closest && e.target.closest('.thesis-list-menu-dropdown')) return;
            (async function () {
              await ThesisManager.setActive(item.getAttribute('data-thesis-id'));
              ResearchV2.navigate('thesis');
              ResearchV2.populateSidebarTheses();
            })();
          });
        });

        // Menu dropdown (Rename / Archive / Delete)
        document.querySelectorAll('.thesislist-item[data-thesis-id] .thesis-list-menu-btn').forEach(function (btn) {
          btn.addEventListener('click', function (e) {
            e.stopPropagation();
            var row = btn.closest('.thesislist-item');
            if (!row) return;
            var existing = row.querySelector('.thesis-list-menu-dropdown');
            document.querySelectorAll('.thesis-list-menu-dropdown').forEach(function (d) { if (d !== existing) d.remove(); });
            if (existing) { existing.remove(); return; }
            var dd = document.createElement('div');
            dd.className = 'thesis-list-menu-dropdown';
            dd.innerHTML =
              '<button type="button" class="thesis-list-menu-item" data-action="rename">Rename</button>' +
              '<button type="button" class="thesis-list-menu-item" data-action="archive">Archive</button>' +
              '<button type="button" class="thesis-list-menu-item" data-action="delete">Delete</button>';
            row.appendChild(dd);
            function close() { dd.remove(); document.removeEventListener('mousedown', outside); }
            function outside(ev) { if (!dd.contains(ev.target) && ev.target !== btn) close(); }
            setTimeout(function () { document.addEventListener('mousedown', outside); }, 0);
            dd.addEventListener('click', function (ev) {
              ev.stopPropagation();
              var action = ev.target && ev.target.getAttribute('data-action');
              var id = row.getAttribute('data-thesis-id');
              var titleEl = row.querySelector('[data-role="title"]');
              if (!action || !id) return;
              if (action === 'rename') {
                if (!titleEl) return;
                titleEl.setAttribute('contenteditable', 'true');
                titleEl.focus();
                try { document.execCommand('selectAll', false, null); } catch (err) {}
                var commit = function () {
                  titleEl.removeEventListener('blur', commit);
                  titleEl.removeEventListener('keydown', onKey);
                  titleEl.setAttribute('contenteditable', 'false');
                  var newTitle = (titleEl.textContent || '').trim();
                  (async function () {
                    await ThesisManager.setActive(id);
                    await ThesisManager.updateMeta({ title: newTitle || 'Untitled Thesis' });
                    await ThesisManager.loadAll();
                    ResearchV2.render.thesislist();
                    ResearchV2.populateSidebarTheses();
                  })();
                };
                var onKey = function (ke) { if (ke.key === 'Enter') { ke.preventDefault(); titleEl.blur(); } };
                titleEl.addEventListener('blur', commit);
                titleEl.addEventListener('keydown', onKey);
                close();
              } else if (action === 'archive') {
                (async function () {
                  await ThesisManager.setActive(id);
                  await ThesisManager.updateMeta({ status: 'archived' });
                  await ThesisManager.loadAll();
                  ResearchV2.render.thesislist();
                  ResearchV2.populateSidebarTheses();
                })();
                close();
              } else if (action === 'delete') {
                var t = theses.find(function (x) { return x.id === id; });
                var title = (t && t.title) ? t.title : 'Untitled thesis';
                if (confirm('Delete "' + title + '"? This cannot be undone.')) {
                  (async function () {
                    await ThesisManager.delete(id);
                    await ThesisManager.loadAll();
                    ResearchV2.render.thesislist();
                    ResearchV2.populateSidebarTheses();
                  })();
                }
                close();
              }
            });
          });
        });

        // Keep existing delete button behavior
        document.querySelectorAll('.thesislist-delete-btn').forEach(function (btn) {
          btn.addEventListener('click', function (e) {
            e.stopPropagation();
            var id = btn.dataset.thesisId;
            var t = theses.find(function (x) { return x.id === id; });
            var title = (t && t.title) ? t.title : 'Untitled thesis';
            if (confirm('Delete "' + title + '"? This cannot be undone.')) {
              (async function () {
                await ThesisManager.delete(id);
                await ThesisManager.loadAll();
                ResearchV2.render.thesislist();
                ResearchV2.populateSidebarTheses();
              })();
            }
          });
        });

        applyFilters();
      },
      instrument: function (params) {
        var id = (params && params.id) ? params.id : null;
        var inst = (STATE.universe || []).find(function (i) { return i.id === id; });
        if (!id || !inst) {
          ResearchV2._renderView('canvas-instrument', 'Instrument', '<div class="inst-not-found">Instrument not found.</div>');
          return;
        }
        var name = inst.name || inst.id || id;
        var price = (STATE.latestPrices && STATE.latestPrices[id]) || {};
        var priceVal = price.value != null ? Number(price.value).toFixed(2) : '—';
        var chg1d = price.pct_chg != null ? (price.pct_chg >= 0 ? '+' : '') + Number(price.pct_chg).toFixed(2) + '%' : '—';
        var chg1dClass = price.pct_chg != null ? (price.pct_chg >= 0 ? 'pos' : 'neg') : '';
        var body = '<div class="inst-header"><div class="inst-header-left"><div class="inst-name">' + escapeHtml(name) + '</div><div class="inst-id">' + escapeHtml(id) + '</div></div><div class="inst-header-actions"><button type="button" class="inst-btn" id="inst-btn-x">Set as X</button><button type="button" class="inst-btn" id="inst-btn-y">+ Set as Y</button><button type="button" class="inst-btn inst-btn-primary" id="inst-btn-analyse">\u2192 Analysis</button></div></div><div class="inst-price-row"><span class="inst-price">' + escapeHtml(priceVal) + '</span><span class="inst-chg ' + chg1dClass + '">' + escapeHtml(chg1d) + '</span><span class="inst-period-chg" id="inst-5d">5D: —</span><span class="inst-period-chg" id="inst-20d">20D: —</span></div><div class="inst-chart-area" id="inst-chart-area"><div class="inst-chart-loading" id="inst-chart-loading">Loading chart...</div></div><div class="inst-stats-row"><div class="inst-stat-card"><div class="inst-stat-label">52W High</div><div class="inst-stat-value" id="inst-52w-high">—</div></div><div class="inst-stat-card"><div class="inst-stat-label">52W Low</div><div class="inst-stat-value" id="inst-52w-low">—</div></div><div class="inst-stat-card"><div class="inst-stat-label">Avg Volume</div><div class="inst-stat-value">—</div></div><div class="inst-stat-card"><div class="inst-stat-label">Volatility</div><div class="inst-stat-value" id="inst-vol">—</div></div></div><div class="inst-factors"><div class="inst-section-title">Factor Exposures</div><div id="inst-factors-content" class="inst-factors-content">Loading...</div></div><div class="inst-signals"><div class="inst-section-title" id="inst-signals-title">Recent Signals</div><div id="inst-signals-content"></div></div>';
        ResearchV2._renderView('canvas-instrument', name, body);
        var self = ResearchV2;
        var base = typeof CONFIG !== 'undefined' && CONFIG.API_BASE ? CONFIG.API_BASE : '';
        var btnX = document.getElementById('inst-btn-x');
        var btnY = document.getElementById('inst-btn-y');
        var btnAnalyse = document.getElementById('inst-btn-analyse');
        if (btnX) btnX.addEventListener('click', function () {
          self.setX({ id: id, name: name });
          var t = btnX.textContent; btnX.textContent = '\u2713 Set as X'; setTimeout(function () { btnX.textContent = t; }, 1500);
        });
        if (btnY) btnY.addEventListener('click', function () {
          self.addY({ id: id, name: name });
          var t = btnY.textContent; btnY.textContent = '\u2713 Added as Y'; setTimeout(function () { btnY.textContent = t; }, 1500);
        });
        if (btnAnalyse) btnAnalyse.addEventListener('click', function () {
          self.setX({ id: id, name: name });
          self.navigate('analysis');
        });
        (function fetchSeries() {
          var url = base + '/api/research/series?series_ids=' + encodeURIComponent(id) + '&days=90';
          fetch(url).then(function (r) { return r.json(); }).then(function (data) {
            var area = document.getElementById('inst-chart-area');
            var loading = document.getElementById('inst-chart-loading');
            if (!area) return;
            var seriesArr = (data.series && data.series[id]) || [];
            if (loading) loading.style.display = 'none';
            if (seriesArr.length) {
              var w = (area.offsetWidth || 800) - 48;
              var h = 260;
              var margins = { top: 16, right: 40, bottom: 28, left: 52 };
              var innerW = w - margins.left - margins.right;
              var innerH = h - margins.top - margins.bottom;
              var vals = seriesArr.map(function (d) { return Number(d.value); }).filter(function (v) { return v != null && !isNaN(v); });
              var minV = vals.length ? Math.min.apply(null, vals) : 0;
              var maxV = vals.length ? Math.max.apply(null, vals) : 1;
              var pad = (maxV - minV) * 0.02 || 0.01;
              minV -= pad; maxV += pad;
              var yScale = function (v) { return margins.top + innerH - (v - minV) / (maxV - minV) * innerH; };
              var xScale = function (i) { return margins.left + (i / (seriesArr.length - 1 || 1)) * innerW; };
              var pathD = seriesArr.length ? 'M ' + xScale(0) + ' ' + yScale(Number(seriesArr[0].value)) : '';
              for (var i = 1; i < seriesArr.length; i++) pathD += ' L ' + xScale(i) + ' ' + yScale(Number(seriesArr[i].value));
              var refLines = '';
              for (var g = 0; g <= 4; g++) {
                var y = margins.top + (g / 4) * innerH;
                refLines += '<line x1="' + margins.left + '" y1="' + y + '" x2="' + (w - margins.right) + '" y2="' + y + '" stroke="#f1f5f9" stroke-width="1"/>';
              }
              var step = Math.max(1, Math.floor(seriesArr.length / 6));
              var axisLabels = '';
              for (var s = 0; s < seriesArr.length; s += step) {
                if (seriesArr[s] && seriesArr[s].date) axisLabels += '<text x="' + xScale(s) + '" y="' + (h - 6) + '" text-anchor="middle" font-size="10" fill="#94a3b8">' + escapeHtml(String(seriesArr[s].date).slice(0, 10)) + '</text>';
              }
              var yStep = (maxV - minV) / 4;
              for (var ys = 0; ys <= 4; ys++) {
                var v = minV + ys * yStep;
                axisLabels += '<text x="' + (margins.left - 6) + '" y="' + (yScale(v) + 4) + '" text-anchor="end" font-size="10" fill="#94a3b8">' + (v.toFixed(1)) + '</text>';
              }
              var lastVal = Number(seriesArr[seriesArr.length - 1].value);
              var val5 = seriesArr.length > 5 ? Number(seriesArr[seriesArr.length - 1 - 5].value) : null;
              var val20 = seriesArr.length > 20 ? Number(seriesArr[seriesArr.length - 1 - 20].value) : null;
              var el5d = document.getElementById('inst-5d');
              var el20d = document.getElementById('inst-20d');
              if (el5d) el5d.textContent = val5 != null && val5 !== 0 ? '5D: ' + ((lastVal - val5) / val5 * 100).toFixed(2) + '%' : '5D: —';
              if (el20d) el20d.textContent = val20 != null && val20 !== 0 ? '20D: ' + ((lastVal - val20) / val20 * 100).toFixed(2) + '%' : '20D: —';
              var high52 = vals.length ? Math.max.apply(null, vals) : null;
              var low52 = vals.length ? Math.min.apply(null, vals) : null;
              var elHigh = document.getElementById('inst-52w-high');
              var elLow = document.getElementById('inst-52w-low');
              if (elHigh) elHigh.textContent = high52 != null ? Number(high52).toFixed(2) : '—';
              if (elLow) elLow.textContent = low52 != null ? Number(low52).toFixed(2) : '—';
              var returns = [];
              for (var j = 1; j < seriesArr.length; j++) {
                var p0 = Number(seriesArr[j - 1].value);
                var p1 = Number(seriesArr[j].value);
                if (p0 && p1) returns.push((p1 - p0) / p0 * 100);
              }
              var vol = null;
              if (returns.length > 1) {
                var mean = returns.reduce(function (a, b) { return a + b; }, 0) / returns.length;
                var variance = returns.reduce(function (sum, r) { return sum + (r - mean) * (r - mean); }, 0) / (returns.length - 1);
                vol = Math.sqrt(variance) * Math.sqrt(252);
              }
              var elVol = document.getElementById('inst-vol');
              if (elVol) elVol.textContent = vol != null ? vol.toFixed(2) + '%' : '—';
              var tooltip = document.createElement('div');
              tooltip.className = 'inst-chart-tooltip';
              tooltip.style.cssText = 'position:absolute;display:none;background:#1e293b;color:#fff;padding:6px 10px;border-radius:4px;font-size:11px;pointer-events:none;z-index:5';
              area.innerHTML = '<svg class="inst-chart-svg" width="' + w + '" height="' + h + '" viewBox="0 0 ' + w + ' ' + h + '"><rect width="' + w + '" height="' + h + '" fill="#fff"/>' + refLines + '<path d="' + pathD + '" fill="none" stroke="#0d9488" stroke-width="2"/>' + axisLabels + '</svg>';
              area.appendChild(tooltip);
              area.style.position = 'relative';
              var svg = area.querySelector('svg');
              if (svg) svg.addEventListener('mousemove', function (e) {
                var rect = svg.getBoundingClientRect();
                var x = e.clientX - rect.left;
                var idx = Math.round((x - margins.left) / innerW * (seriesArr.length - 1));
                idx = Math.max(0, Math.min(idx, seriesArr.length - 1));
                var pt = seriesArr[idx];
                if (pt) { tooltip.textContent = (pt.date || '').slice(0, 10) + ' \u2022 ' + (pt.value != null ? Number(pt.value).toFixed(2) : ''); tooltip.style.display = 'block'; tooltip.style.left = (x + 10) + 'px'; tooltip.style.top = '10px'; }
              });
              if (svg) svg.addEventListener('mouseleave', function () { tooltip.style.display = 'none'; });
            } else if (loading) loading.textContent = 'No series data';
          }).catch(function () {
            var loading = document.getElementById('inst-chart-loading');
            if (loading) loading.textContent = 'Data unavailable';
          });
        })();
        (function fetchFactors() {
          var url = base + '/api/research/factor_decomposition?target_series=' + encodeURIComponent(id) + '&days=90';
          fetch(url).then(function (r) { return r.json(); }).then(function (data) {
            var container = document.getElementById('inst-factors-content');
            if (!container) return;
            if (data.error || !data.factors || !data.factors.length) {
              container.innerHTML = '<div class="inst-muted">Factor data unavailable</div>';
              return;
            }
            var factors = (data.factors || []).slice().sort(function (a, b) { return Math.abs(Number(b.beta) || 0) - Math.abs(Number(a.beta) || 0); }).slice(0, 3);
            if (factors.length === 0) { container.innerHTML = '<div class="inst-muted">Factor data unavailable</div>'; return; }
            var maxAbs = Math.max(0.001, Math.max.apply(null, factors.map(function (f) { return Math.abs(Number(f.beta) || 0); })));
            var html = factors.map(function (f) {
              var beta = Number(f.beta) || 0;
              var pct = Math.min((Math.abs(beta) / maxAbs) * 50, 100);
              var barStyle = 'width:' + pct + '%;background:' + (beta >= 0 ? '#16a34a' : '#dc2626') + ';' + (beta >= 0 ? 'left:50%;' : 'right:50%;left:auto;');
              return '<div class="inst-factor-row"><span class="inst-factor-label">' + escapeHtml(f.factor || f.name || '') + '</span><div class="inst-factor-bar-wrap"><div class="inst-factor-bar" style="' + barStyle + '"></div></div><span class="inst-factor-beta ' + (beta >= 0 ? 'pos' : 'neg') + '">' + beta.toFixed(3) + '</span></div>';
            }).join('');
            container.innerHTML = html;
          }).catch(function () {
            var container = document.getElementById('inst-factors-content');
            if (container) container.innerHTML = '<div class="inst-muted">Factor data unavailable</div>';
          });
        })();
        (function fillSignals() {
          var container = document.getElementById('inst-signals-content');
          var titleEl = document.getElementById('inst-signals-title');
          if (!container) return;
          var signals = (STATE.signals || []).slice();
          var nameWords = (name || '').toLowerCase().split(/\s+/).filter(Boolean);
          var matched = signals.filter(function (s) {
            var topic = (s.topic || '').toLowerCase();
            return nameWords.some(function (w) { return w.length > 2 && topic.indexOf(w) !== -1; }) || (inst.asset_class && topic.indexOf((inst.asset_class || '').toLowerCase()) !== -1);
          });
          if (matched.length === 0) { matched = signals; if (titleEl) titleEl.textContent = 'Latest market signals'; }
          matched.sort(function (a, b) { return (b.date || '').localeCompare(a.date || ''); });
          var rows = matched.slice(0, 3);
          if (rows.length === 0) { container.innerHTML = '<div class="inst-muted">No signals</div>'; return; }
          container.innerHTML = rows.map(function (r) {
            var sent = (r.sentiment_avg != null) ? Number(r.sentiment_avg) : null;
            var sentClass = sent == null ? 'neu' : sent > 0 ? 'pos' : 'neg';
            var sentStr = sent != null ? (sent > 0 ? '+' : '') + sent.toFixed(1) : '—';
            return '<div class="inst-signal-row"><span class="inst-signal-topic">' + escapeHtml(r.topic || '') + '</span><span class="inst-signal-count">' + (r.article_count != null ? r.article_count : '—') + ' articles</span><span class="inst-signal-sentiment ' + sentClass + '">' + escapeHtml(sentStr) + '</span><span class="inst-signal-date">' + escapeHtml(String(r.date || '').slice(0, 10)) + '</span></div>';
          }).join('');
        })();
      },
      signals: function (params) {
        ResearchV2._renderView('canvas-signals', 'Signals', '<div id="rv2-signals-container"></div>');
        var container = document.getElementById('rv2-signals-container');
        var body = ResearchV2._getCanvasBody('canvas-signals');
        if (!container || !body) return;
        try {
          if (typeof renderSignalsSurface === 'function') {
            container.innerHTML = renderSignalsSurface(STATE.signals || []);
            if (params && params.topic) {
              var target = Array.prototype.find.call(container.querySelectorAll('td.topic-cell'), function (td) { return (td.textContent || '').trim().toLowerCase().indexOf((params.topic || '').toLowerCase()) >= 0; });
              if (target) target.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
            }
          } else {
            body.innerHTML = ResearchV2._placeholderHtml('Signals data coming soon');
          }
        } catch (e) {
          body.innerHTML = ResearchV2._placeholderHtml('Signals data coming soon');
        }
      },
      correlations: function () {
        ResearchV2._renderView('canvas-correlations', 'Correlations', '<div id="rv2-correlations-container"></div>');
        var body = ResearchV2._getCanvasBody('canvas-correlations');
        var container = document.getElementById('rv2-correlations-container');
        if (!container) return;
        try {
          if (typeof Research !== 'undefined' && Research.fetchAndRender) {
            var univ = STATE.universe || [];
            if (!Research.state) Research.state = {};
            if (!Research.state.primarySeries && univ[0]) Research.state.primarySeries = univ[0].id;
            if (!Research.state.compareSeries || Research.state.compareSeries.length === 0) Research.state.compareSeries = univ.length > 1 ? [univ[1].id] : [];
            if (ResearchV2.state.xSeries) Research.state.primarySeries = ResearchV2.state.xSeries.id;
            if (ResearchV2.state.ySeries && ResearchV2.state.ySeries.length) Research.state.compareSeries = ResearchV2.state.ySeries.map(function (y) { return y.id; });
            Research.state.days = Research.state.days || ResearchV2.state.period || 90;
            var sel = Research.getSelections();
            if (sel.allSeries.length >= 2) {
              Research.fetchAndRender('correlation', 'rv2-correlations-container');
            } else {
              container.innerHTML = ResearchV2._placeholderHtml('Select at least two instruments (X and Y) above to compute correlations.');
            }
          } else {
            container.innerHTML = ResearchV2._placeholderHtml('Correlations view coming soon');
          }
        } catch (e) {
          container.innerHTML = ResearchV2._placeholderHtml('Correlations view coming soon');
        }
      },
      impact: function () {
        ResearchV2._renderView('canvas-impact', 'Market Impact', '<div id="rv2-impact-container"></div>');
        var body = ResearchV2._getCanvasBody('canvas-impact');
        var container = document.getElementById('rv2-impact-container');
        if (!container) return;
        try {
          var x = ResearchV2.state.xSeries && ResearchV2.state.xSeries.id;
          var yList = ResearchV2.state.ySeries && ResearchV2.state.ySeries.length ? ResearchV2.state.ySeries : [];
          var y = yList[0] && yList[0].id;
          if (typeof Research !== 'undefined' && Research.charts && typeof Research.charts.renderImpactTable === 'function' && x && y) {
            container.innerHTML = ResearchV2._placeholderHtml('Loading impact...');
            var days = ResearchV2.state.period || 90;
            API.getImpact(x, yList.map(function (r) { return r.id; }), 10, days).then(function (data) {
              var c = document.getElementById('rv2-impact-container');
              if (!c) return;
              if (data && !data.error && data.impacts) {
                Research.charts.renderImpactTable(data, 'rv2-impact-container');
              } else {
                c.innerHTML = ResearchV2._placeholderHtml('Impact data unavailable. Set X and Y above.');
              }
            }).catch(function () {
              var c = document.getElementById('rv2-impact-container');
              if (c) c.innerHTML = ResearchV2._placeholderHtml('Impact data unavailable.');
            });
          } else {
            container.innerHTML = ResearchV2._placeholderHtml('Set X and Y above to run impact analysis.');
          }
        } catch (e) {
          container.innerHTML = ResearchV2._placeholderHtml('Market Impact coming soon');
        }
      },
      regime: function () {
        var regimeHtml = '<div id="rv2-regime-container"><div id="rv2-regime-indicators"></div><div id="rv2-regime-fingerprint" style="margin-top:8px;font-size:11px;color:#64748b"></div><div id="rv2-regime-computed" style="font-size:11px;color:#94a3b8;margin-top:4px"></div><div id="rv2-regime-interpretation" style="margin-top:12px"></div><div id="rv2-regime-implications" style="margin-top:12px"></div></div>';
        ResearchV2._renderView('canvas-regime', 'Regime', regimeHtml);
        var wrap = document.getElementById('rv2-regime-container');
        if (!wrap) return;
        try {
          if (typeof renderRegimeIndicators === 'function') {
            var ind = document.getElementById('rv2-regime-indicators');
            if (ind) ind.innerHTML = renderRegimeIndicators(STATE.regime);
          }
          var fp = document.getElementById('rv2-regime-fingerprint');
          if (fp) fp.textContent = STATE.regime && STATE.regime.fingerprint ? 'Fingerprint: ' + STATE.regime.fingerprint : '';
          var comp = document.getElementById('rv2-regime-computed');
          if (comp) comp.textContent = STATE.regime && STATE.regime.computed_at ? 'Last computed: ' + STATE.regime.computed_at.slice(0, 19).replace('T', ' ') : '';
          if (typeof getRegimeInterpretationBlocks === 'function') {
            var interp = document.getElementById('rv2-regime-interpretation');
            if (interp) {
              var blocks = getRegimeInterpretationBlocks(STATE.regime);
              var count = blocks.filter(function (b) { return b.indicators && b.indicators.length > 0; }).length;
              interp.innerHTML = '<p class="regime-pattern-count">' + count + ' pattern' + (count !== 1 ? 's' : '') + ' active</p>' + blocks.map(function (b) {
                var tag = (b.indicators || []).map(function (k) { return k.replace(/_/g, ' '); }).join(', ');
                return '<div class="regime-interp-block"><span class="regime-interp-tag">' + escapeHtml(tag) + '</span><p>' + escapeHtml(b.text) + '</p></div>';
              }).join('');
            }
            var impl = document.getElementById('rv2-regime-implications');
            if (impl) {
              var rows = [];
              blocks.forEach(function (b) { (b.implications || []).forEach(function (r) { rows.push(r); }); });
              if (rows.length === 0) rows = [['Long-duration bonds', 'Headwind (real yields elevated)', 'High'], ['Growth equities', 'Headwind (real yields elevated)', 'High'], ['Gold', 'Tailwind (dollar strength)', 'Medium'], ['EM FX', 'Headwind (dollar strength)', 'Medium']];
              impl.innerHTML = '<table class="regime-implications-table"><thead><tr><th>Asset Class</th><th>Implication</th><th>Confidence</th></tr></thead><tbody>' + rows.map(function (row) { return '<tr><td>' + escapeHtml(row[0]) + '</td><td>' + escapeHtml(row[1]) + '</td><td>' + escapeHtml(row[2]) + '</td></tr>'; }).join('') + '</tbody></table>';
            }
          }
          if (!STATE.regime && wrap.querySelector('#rv2-regime-indicators')) wrap.querySelector('#rv2-regime-indicators').innerHTML = wrap.querySelector('#rv2-regime-indicators').innerHTML || '<p class="text-muted">No regime data</p>';
        } catch (e) {
          if (wrap) wrap.innerHTML = ResearchV2._placeholderHtml('Regime data coming soon');
        }
      },
      forecasts: function (params) {
        var instId = (params && params.id) || (ResearchV2.state.xSeries && ResearchV2.state.xSeries.id);
        if (instId && typeof Research !== 'undefined' && Research.renderForecast && Research.fetchAndRender) {
          Research.state.primarySeries = instId;
          Research.state.forecastHorizon = Research.state.forecastHorizon || 30;
          Research.state.forecastHistory = Research.state.forecastHistory || 90;
          Research.state.forecastModel = Research.state.forecastModel || 'both';
          ResearchV2._renderView('canvas-forecasts', 'Forecasts', '<div id="rv2-forecasts-container">' + ResearchV2._placeholderHtml('Loading forecast...') + '</div>');
          var container = document.getElementById('rv2-forecasts-container');
          if (container) {
            try {
              API.getForecast(instId, Research.state.forecastHorizon, Research.state.forecastHistory, Research.state.forecastModel).then(function (data) {
                var c = document.getElementById('rv2-forecasts-container');
                if (c && data && !data.error && typeof Research.renderForecast === 'function') Research.renderForecast(data, 'rv2-forecasts-container');
                else if (c) c.innerHTML = ResearchV2._placeholderHtml('Forecast data unavailable.');
              }).catch(function () {
                var c = document.getElementById('rv2-forecasts-container');
                if (c) c.innerHTML = ResearchV2._placeholderHtml('Forecast data unavailable.');
              });
            } catch (e) {
              if (container) container.innerHTML = ResearchV2._placeholderHtml('Forecasts coming soon');
            }
          }
        } else {
          var univ = (STATE.universe || []).slice(0, 30);
          var listHtml = univ.length ? '<p style="font-size:12px;color:#64748b;margin-bottom:8px">Select an instrument to view forecasts:</p><div class="rv2-instrument-list">' + univ.map(function (i) { return '<button type="button" class="inst-selector-btn" data-inst-id="' + escapeHtml(i.id) + '">' + escapeHtml(i.name || i.id) + '</button>'; }).join('') + '</div>' : ResearchV2._placeholderHtml('No instruments loaded. Select an instrument from the sidebar.');
          ResearchV2._renderView('canvas-forecasts', 'Forecasts', '<div id="rv2-forecasts-container">' + listHtml + '</div>');
          var container = document.getElementById('rv2-forecasts-container');
          if (container) {
            container.addEventListener('click', function (e) {
              var btn = e.target.closest('[data-inst-id]');
              if (!btn) return;
              var id = btn.dataset.instId;
              if (id) ResearchV2.navigate('forecasts', { id: id });
            });
          }
        }
      },
      volatility: function (params) {
        var instId = (params && params.id) || (ResearchV2.state.xSeries && ResearchV2.state.xSeries.id);
        if (instId && typeof Research !== 'undefined' && Research.renderVolatility) {
          ResearchV2._renderView('canvas-volatility', 'Volatility', '<div id="rv2-volatility-container">' + ResearchV2._placeholderHtml('Loading volatility...') + '</div>');
          var container = document.getElementById('rv2-volatility-container');
          if (container) {
            try {
              API.getVolatility(instId, 90).then(function (data) {
                var c = document.getElementById('rv2-volatility-container');
                if (c && data && !data.error && typeof Research.renderVolatility === 'function') Research.renderVolatility(data, 'rv2-volatility-container');
                else if (c) c.innerHTML = ResearchV2._placeholderHtml('Volatility data unavailable.');
              }).catch(function () {
                var c = document.getElementById('rv2-volatility-container');
                if (c) c.innerHTML = ResearchV2._placeholderHtml('Volatility data unavailable.');
              });
            } catch (e) {
              container.innerHTML = ResearchV2._placeholderHtml('Volatility coming soon');
            }
          }
        } else {
          var univ = (STATE.universe || []).slice(0, 30);
          var listHtml = univ.length ? '<p style="font-size:12px;color:#64748b;margin-bottom:8px">Select an instrument to view volatility:</p><div class="rv2-instrument-list">' + univ.map(function (i) { return '<button type="button" class="inst-selector-btn" data-inst-id="' + escapeHtml(i.id) + '">' + escapeHtml(i.name || i.id) + '</button>'; }).join('') + '</div>' : ResearchV2._placeholderHtml('No instruments loaded.');
          ResearchV2._renderView('canvas-volatility', 'Volatility', '<div id="rv2-volatility-container">' + listHtml + '</div>');
          var volContainer = document.getElementById('rv2-volatility-container');
          if (volContainer) {
            volContainer.addEventListener('click', function (e) {
              var btn = e.target.closest('[data-inst-id]');
              if (!btn) return;
              var id = btn.dataset.instId;
              if (id) ResearchV2.navigate('volatility', { id: id });
            });
          }
        }
      },
      scenarios: function () {
        ResearchV2._renderView('canvas-scenarios', 'Scenarios', '<div id="rv2-scenarios-container"></div>');
        var container = document.getElementById('rv2-scenarios-container');
        if (!container) return;
        try {
          if (typeof Research !== 'undefined' && typeof Research.renderScenario === 'function') {
            var presets = (typeof Research.state !== 'undefined' && Research.state.scenarioPresets) ? Research.state.scenarioPresets : (STATE.scenarios && (STATE.scenarios.presets || (Array.isArray(STATE.scenarios) ? STATE.scenarios : []))) || null;
            if (!presets || (!presets.presets && !Array.isArray(presets))) {
              container.innerHTML = ResearchV2._placeholderHtml('Loading scenarios...');
              API.getScenarios().then(function (data) {
                var payload = data && (data.presets || Array.isArray(data) ? data : null) ? data : (Array.isArray(data) ? { presets: data } : { presets: [] });
                if (typeof Research.state !== 'undefined') Research.state.scenarioPresets = payload;
                var c = document.getElementById('rv2-scenarios-container');
                if (c) Research.renderScenario(payload, null, 'rv2-scenarios-container');
              }).catch(function () {
                var c = document.getElementById('rv2-scenarios-container');
                if (c) c.innerHTML = ResearchV2._placeholderHtml('Scenarios data unavailable.');
              });
            } else {
              Research.renderScenario(presets, (Research.state && Research.state.data && Research.state.data.scenarioResult) || null, 'rv2-scenarios-container');
            }
          } else {
            container.innerHTML = ResearchV2._placeholderHtml('Scenarios coming soon');
          }
        } catch (e) {
          container.innerHTML = ResearchV2._placeholderHtml('Scenarios coming soon');
        }
      },
      news: function () {
        ResearchV2._renderView('canvas-news', 'News & Articles', '<div id="rv2-news-container"></div>');
        var container = document.getElementById('rv2-news-container');
        var body = ResearchV2._getCanvasBody('canvas-news');
        if (!container) return;
        try {
          var articles = STATE.articles || [];
          if (articles.length) {
            container.innerHTML = '<div class="inst-section-title">Articles</div>' + articles.slice(0, 20).map(function (a) {
              return '<div class="inst-signal-row"><span class="inst-signal-topic">' + escapeHtml(a.title || a.headline || a.topic || '') + '</span><span class="inst-signal-count">' + escapeHtml(a.source || '') + '</span><span class="inst-signal-date">' + escapeHtml(String(a.date || a.published_at || '').slice(0, 10)) + '</span></div>';
            }).join('');
          } else {
            var base = typeof CONFIG !== 'undefined' && CONFIG.API_BASE ? CONFIG.API_BASE : '';
            fetch(base + '/api/research/articles').then(function (r) { return r.json(); }).then(function (data) {
              var c = document.getElementById('rv2-news-container');
              if (!c) return;
              var list = (data && (data.articles || data.items || Array.isArray(data) ? data : [])) || [];
              if (list.length) {
                c.innerHTML = '<div class="inst-section-title">Articles</div>' + list.slice(0, 20).map(function (a) {
                  return '<div class="inst-signal-row"><span class="inst-signal-topic">' + escapeHtml(a.title || a.headline || a.topic || '') + '</span><span class="inst-signal-count">' + escapeHtml(a.source || '') + '</span><span class="inst-signal-date">' + escapeHtml(String(a.date || a.published_at || '').slice(0, 10)) + '</span></div>';
                }).join('');
              } else {
                c.innerHTML = ResearchV2._placeholderHtml('News &amp; articles coming soon');
              }
            }).catch(function () {
              var c = document.getElementById('rv2-news-container');
              if (c) c.innerHTML = ResearchV2._placeholderHtml('News &amp; articles coming soon');
            });
          }
        } catch (e) {
          if (body) body.innerHTML = ResearchV2._placeholderHtml('News &amp; articles coming soon');
        }
      }
    },

    _getCanvasBody: function (viewId) {
      var canvas = document.getElementById(viewId);
      return canvas ? canvas.querySelector('.canvas-body') : null;
    },
    _placeholderHtml: function (message) {
      return '<div style="display:flex;align-items:center;justify-content:center;height:200px;color:#94a3b8;font-size:13px;">' + (message || 'Coming soon') + '</div>';
    },
    _renderView: function (canvasId, title, bodyHtml) {
      var el = document.getElementById(canvasId);
      if (!el || el.id !== canvasId) return;
      var withHeader = (canvasId === 'canvas-instrument');
      if (withHeader) {
        el.innerHTML = '<div class="canvas-header"><div class="canvas-header-left"><button type="button" class="canvas-back-btn">Back</button><h2 class="canvas-title">' + escapeHtml(title) + '</h2></div><div class="canvas-header-right"></div></div><div class="canvas-body">' + (bodyHtml || '') + '</div>';
      } else {
        el.innerHTML = '<div class="canvas-body">' + (bodyHtml || '') + '</div>';
      }
    }
  };
  window.ResearchV2 = ResearchV2;

  var ResearchWorkspace = {};


  function sendToThesisBuilder(subview, data, selections) {
    var primaryName = (STATE.universe || []).find(function (i) { return i.id === selections.primary; });
    var primary_name = primaryName ? (primaryName.name || primaryName.id) : (selections.primary || '—');
    var evidence = '';
    switch (subview) {
      case 'overview':
        if (data.overview && data.overview.instruments) {
          var top3 = data.overview.instruments.slice().sort(function (a, b) { return Math.abs(b.zscore_90d || 0) - Math.abs(a.zscore_90d || 0); }).slice(0, 3);
          evidence = top3.map(function (i, n) {
            return (n + 1) + '. ' + (i.name || i.id) + ': z-score=' + (i.zscore_90d != null ? Number(i.zscore_90d).toFixed(2) : '') + 'σ, momentum=' + (i.momentum_score != null ? Number(i.momentum_score).toFixed(2) : '') + ', trend=' + (i.trend_direction || '');
          }).join('\n') + '\nDominant theme: ' + ((data.overview.cross_asset_summary && data.overview.cross_asset_summary.dominant_theme) || '');
        }
        break;
      case 'correlation':
        if (data.impact && data.impact.impacts) {
          var imp = data.impact.impacts;
          var shock_pct = Research.state.impactShockPct || 10;
          evidence = 'Correlation & Impact Analysis:\n' + imp.map(function (i, n) {
            return (n + 1) + '. ' + (i.instrument_id || i.instrument || i.name) + ': β=' + (i.beta != null ? Number(i.beta).toFixed(3) : '') + ', predicted ' + shock_pct + '% shock → ' + (i.predicted != null ? Number(i.predicted).toFixed(2) : '') + '% (R²=' + (i.r2 != null ? Number(i.r2).toFixed(2) : '') + ', p=' + (i.p_value != null ? Number(i.p_value).toFixed(3) : '') + ')';
          }).join('\n');
        }
        break;
      case 'factors':
        if (data.factorDecomp) {
          var fd = data.factorDecomp;
          var sigFactors = (fd.factors || []).filter(function (f) { return f.significant; });
          evidence = 'Factor Decomposition — ' + primary_name + ':\nModel R²=' + (fd.model && fd.model.r_squared != null ? Number(fd.model.r_squared).toFixed(2) : '') + '\n' + sigFactors.map(function (f, n) {
            return (n + 1) + '. ' + (f.name || f.factor) + ': β=' + (f.beta != null ? Number(f.beta).toFixed(3) : '') + (f.t_stat >= 0 ? '+' : '-') + '(t=' + (f.t_stat != null ? Math.abs(f.t_stat).toFixed(1) : '') + ', p=' + (f.p_value != null ? Number(f.p_value).toFixed(3) : '') + ') — ' + (f.contribution_pct != null ? f.contribution_pct.toFixed(1) : '') + '% variance';
          }).join('\n') + '\nResidual (unexplained): ' + (fd.residual_pct != null ? fd.residual_pct.toFixed(1) : '') + '%';
        }
        break;
      case 'forecast':
        if (data.forecast) {
          var fc = data.forecast;
          var lastFc = fc.arima_forecast && fc.arima_forecast.length ? fc.arima_forecast[fc.arima_forecast.length - 1] : null;
          evidence = 'ARIMA Forecast — ' + primary_name + ':\n1. Current: ' + (fc.summary && fc.summary.current) + '\n2. ARIMA 30D forecast: ' + (fc.summary && fc.summary.arima_30d) + ' (' + (fc.summary && fc.summary.arima_pct_change) + ')\n3. 95% CI: [' + (lastFc && lastFc.ci_95_low != null ? Number(lastFc.ci_95_low).toFixed(2) : '') + ' to ' + (lastFc && lastFc.ci_95_high != null ? Number(lastFc.ci_95_high).toFixed(2) : '') + ']\n4. Linear trend: ' + (fc.summary && fc.summary.linear_30d) + ' (' + (fc.summary && fc.summary.linear_pct_change) + ')\n5. Model: ARIMA(' + (fc.arima_model && fc.arima_model.order ? fc.arima_model.order.join(',') : '') + ') AIC=' + (fc.arima_model && fc.arima_model.aic != null ? Number(fc.arima_model.aic).toFixed(1) : '') + ' Ljung-Box p=' + (fc.arima_model && fc.arima_model.ljung_box_p != null ? Number(fc.arima_model.ljung_box_p).toFixed(2) : '') + ')';
        }
        break;
      case 'volatility':
        if (data.volatility) {
          var vd = data.volatility;
          var vp = vd.garch_params;
          evidence = 'Volatility Analysis — ' + primary_name + ':\n1. Current realised vol (21D): ' + (vd.summary && vd.summary.current_realised_21d != null ? Number(vd.summary.current_realised_21d).toFixed(1) : '') + '% ann.\n2. Vol regime: ' + (vd.summary && vd.summary.vol_regime) + ' (' + (vd.summary && vd.summary.vol_percentile_90d) + 'th percentile vs 90D)\n' + (vp ? '3. GARCH persistence: α+β=' + (vp.persistence != null ? vp.persistence.toFixed(3) : '') + ', half-life=' + (vp.half_life_days != null ? vp.half_life_days.toFixed(0) : '') + 'd\n4. Long-run vol: ' + (vp.long_run_vol != null ? vp.long_run_vol.toFixed(1) : '') + '%\n' : '') + '5. VIX: ' + (vd.summary && vd.summary.vix_current != null ? vd.summary.vix_current.toFixed(1) : '') + '%, vol premium: ' + (vd.summary && vd.summary.vol_risk_premium != null ? vd.summary.vol_risk_premium.toFixed(1) : '') + 'pp';
        }
        break;
      case 'scenario':
        if (data.scenarioResult) {
          var sc = data.scenarioResult;
          var shks = (sc.shocks_applied || []).map(function (s) { return s.name + ' ' + (s.change_pct > 0 ? '+' : '') + (s.change_pct != null ? s.change_pct : s.change_bps) + (s.change_pct != null ? '%' : 'bps'); }).join(', ');
          evidence = 'Scenario: ' + (sc.scenario || '') + '\nShocks: ' + shks + '\n' + (sc.impacts || []).slice(0, 5).map(function (i, n) {
            return (n + 1) + '. ' + (i.name || i.series_id) + ': ' + (i.predicted_move_pct != null ? i.predicted_move_pct.toFixed(2) : '') + '% [CI: ' + (i.ci_95_low != null ? i.ci_95_low.toFixed(1) : '') + ' to ' + (i.ci_95_high != null ? i.ci_95_high.toFixed(1) : '') + '%] (' + (i.confidence || '') + ')';
          }).join('\n');
        }
        break;
      case 'rates':
        if (data.yieldCurve && data.ratesDecomp) {
          var yc = data.yieldCurve;
          var rc = data.ratesDecomp;
          evidence = 'Rates & Yield Curve Analysis:\n1. Curve shape: ' + (yc.spreads && yc.spreads.curve_shape) + ', 2s10s=' + (yc.spreads && yc.spreads['2s10s'] != null ? (yc.spreads['2s10s'] * 100).toFixed(0) : '') + 'bps\n2. 10Y nominal: ' + (rc.nominal_10y != null ? rc.nominal_10y.toFixed(2) : '') + '% = ' + (rc.real_yield_10y != null ? rc.real_yield_10y.toFixed(2) : '') + '% real + ' + (rc.breakeven_inflation != null ? rc.breakeven_inflation.toFixed(2) : '') + '% breakeven\n3. ' + (yc.interpretation || '') + '\n4. ' + (rc.interpretation || '');
        }
        break;
      case 'momentum':
        if (data.momentumDeep && data.momentumDeep.instruments && data.momentumDeep.instruments[0]) {
          var mo = data.momentumDeep.instruments[0];
          evidence = 'Momentum Analysis — ' + primary_name + ':\n1. Trend: ' + (mo.trend || '') + ', Score: ' + (mo.momentum_score != null ? mo.momentum_score.toFixed(2) : '') + '\n2. 1M: ' + (mo.momentum_1m != null ? mo.momentum_1m.toFixed(1) : '') + '%, 3M: ' + (mo.momentum_3m != null ? mo.momentum_3m.toFixed(1) : '') + '%, 6M: ' + (mo.momentum_6m != null ? mo.momentum_6m.toFixed(1) : '') + '%\n3. RSI(14): ' + (mo.rsi_14 != null ? mo.rsi_14.toFixed(1) : '') + '\n4. MACD: ' + (mo.macd && mo.macd.value != null ? mo.macd.value.toFixed(2) : '') + ' (' + (mo.macd && (mo.macd.crossover || mo.macd.last_crossover)) || 'no recent crossover' + ')\n5. Signal: ' + (mo.signal || '');
        }
        break;
      default:
        break;
    }
    STATE.research.lastExport = { subview: subview, primary: primary_name, evidence: evidence, timestamp: new Date().toISOString() };
    switchSection('theses');
    switchSubview('theses', 'builder');
  }

  // ——— 4. RENDER MODULE ———
  function formatDateShort(isoStr) {
    if (!isoStr) return '';
    const d = new Date(isoStr);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[d.getMonth()] + ' ' + d.getDate();
  }

  function renderSparkline(dates, values, width, height, color) {
    if (!dates || !values || dates.length === 0) return '';
    var w = width || 120;
    var h = height || 30;
    var pad = 2;
    var minV = Math.min.apply(null, values);
    var maxV = Math.max.apply(null, values);
    var range = maxV - minV || 1;
    var xScale = function (i) { return pad + (i / (dates.length - 1 || 1)) * (w - 2 * pad); };
    var yScale = function (v) { return h - pad - ((v - minV) / range) * (h - 2 * pad); };
    var path = 'M ';
    values.forEach(function (v, i) {
      path += (i ? 'L ' : '') + xScale(i) + ' ' + yScale(v) + ' ';
    });
    return '<svg class="sparkline-svg" width="' + w + '" height="' + h + '" viewBox="0 0 ' + w + ' ' + h + '"><path d="' + path + '" fill="none" stroke="' + (color || '#0d9488') + '" stroke-width="1.5"/></svg>';
  }

  function renderBriefing(data) {
    if (!data) return;
    var highlights = data.highlights || [];
    var html1 = '';
    if (highlights.length === 0) {
      html1 = '<p class="highlight-row"><span class="highlight-desc">No significant changes since last run — markets and signals within normal ranges.</span></p>';
    } else {
      highlights.forEach(function (h) {
        var dotClass = 'highlight-dot ';
        if (h.type === 'regime') dotClass += 'regime';
        else if (h.type === 'signal') dotClass += 'signal';
        else if (h.type === 'market') dotClass += (h.direction === 'positive' ? 'market-pos' : 'market-neg');
        else dotClass += 'signal';
        html1 += '<div class="highlight-row"><span class="' + dotClass + '"></span><span class="highlight-label">' + escapeHtml(h.label) + '</span><span class="highlight-desc">' + escapeHtml(h.description) + '</span><span class="highlight-ts">' + (h.timestamp ? h.timestamp.slice(0, 10) : '') + '</span></div>';
      });
    }
    var el1 = document.getElementById('briefing-highlights');
    if (el1) el1.innerHTML = html1;

    var watch = data.signal_watch || [];
    var html2 = watch.map(function (w) {
      var velBar = w.velocity_7d != null && !Number.isNaN(parseFloat(w.velocity_7d))
        ? '<div class="velocity-bar-wrap"><div class="velocity-bar-fill" style="width:' + Math.min(100, (parseFloat(w.velocity_7d) / 3) * 100) + '%"></div></div>'
        : '<span style="color:var(--text-muted)">—</span>';
      var sent = parseFloat(w.sentiment_avg);
      var arrowClass = sent > 0.1 ? 'up' : sent < -0.1 ? 'down' : 'flat';
      var arrow = sent > 0.1 ? '↑' : sent < -0.1 ? '↓' : '→';
      var pills = (w.linked_instruments || []).slice(0, 3).map(function (id) { return '<span class="tag-pill">' + escapeHtml(id) + '</span>'; }).join('');
      return '<div class="signal-watch-row"><span class="topic-name">' + escapeHtml(w.topic) + '</span>' + velBar + '<span class="sentiment-arrow ' + arrowClass + '">' + arrow + '</span><span>' + (w.article_count ?? '—') + '</span><span>' + escapeHtml((w.latest_article_title || '—').slice(0, 60)) + '</span>' + pills + '</div>';
    }).join('');
    var el2 = document.getElementById('briefing-signal-watch');
    if (el2) el2.innerHTML = html2 || '<p class="text-muted">No signal data</p>';

    var snap = data.market_snapshot || [];
    var html3 = '<div class="briefing-market-strip">' + snap.map(function (m) {
      if (m.value == null) return '<div class="briefing-market-card"><div class="mkt-name">' + escapeHtml(m.name) + '</div><div class="mkt-nodata">No data</div></div>';
      var pct = m.pct_chg_1d != null ? parseFloat(m.pct_chg_1d) : null;
      var pctClass = pct != null && pct >= 0 ? 'positive' : pct != null ? 'negative' : '';
      var pctStr = pct != null ? (pct >= 0 ? '+' : '') + pct.toFixed(2) + '%' : '—';
      return '<div class="briefing-market-card"><div class="mkt-name">' + escapeHtml(m.name) + '</div><div class="mkt-value">' + Number(m.value).toFixed(2) + '</div><div class="' + pctClass + '">' + pctStr + '</div></div>';
    }).join('') + '</div>';
    var el3 = document.getElementById('briefing-market-snapshot');
    if (el3) el3.innerHTML = html3;
  }

  function sentimentColor(sentiment) {
    if (sentiment === null || sentiment === undefined || sentiment === '') return '#f8fafc';
    const s = parseFloat(sentiment);
    if (Number.isNaN(s)) return '#f8fafc';
    const t = Math.max(-1, Math.min(1, s));
    var r, g, b;
    if (t <= 0) {
      var u = (t + 1);
      r = Math.round(220 + (255 - 220) * u);
      g = Math.round(38 + (255 - 38) * u);
      b = Math.round(38 + (255 - 38) * u);
    } else {
      var u = t;
      r = Math.round(255 + (22 - 255) * u);
      g = Math.round(255 + (163 - 255) * u);
      b = Math.round(255 + (74 - 255) * u);
    }
    return 'rgb(' + r + ',' + g + ',' + b + ')';
  }

  function isNotable(cell) {
    if (!cell) return false;
    if (cell.anomaly_flag || cell.divergence_flag) return true;
    var s = cell.sentiment_avg != null ? parseFloat(cell.sentiment_avg) : null;
    if (s != null && !Number.isNaN(s) && Math.abs(s) > 0.3) return true;
    return false;
  }

  function renderSignalsSurface(data) {
    var filter = (STATE.topicFilter || '').toLowerCase();
    var mode = STATE.signalsSurfaceMode || 'notable';
    var allRows = (data || []).filter(function (r) {
      return !filter || (r.topic || '').toLowerCase().indexOf(filter) >= 0;
    });
    var notableTopics = new Set();
    (data || []).forEach(function (r) {
      if (isNotable(r)) notableTopics.add(r.topic);
    });
    var rows = mode === 'notable' ? allRows.filter(function (r) { return notableTopics.has(r.topic); }) : allRows;
    var topics = [...new Set(rows.map(function (r) { return r.topic; }))].sort();
    var dates = [...new Set(rows.map(function (r) { return r.date; }))].sort().reverse().slice(0, 14);
    var byKey = {};
    rows.forEach(function (r) {
      byKey[r.date + '|' + r.topic] = r;
    });
    var html = '<table class="heatmap-table"><thead><tr><th>Topic</th>';
    dates.forEach(function (d) {
      html += '<th>' + escapeHtml(formatDateShort(d)) + '</th>';
    });
    html += '</tr></thead><tbody>';
    topics.forEach(function (topic) {
      html += '<tr><td class="topic-cell">' + escapeHtml(topic) + '</td>';
      dates.forEach(function (date) {
        var cell = byKey[date + '|' + topic];
        var rawSent = cell && (cell.sentiment_avg !== null && cell.sentiment_avg !== undefined && cell.sentiment_avg !== '') ? cell.sentiment_avg : null;
        var sent = rawSent !== null ? parseFloat(rawSent) : null;
        var hasData = sent !== null && !Number.isNaN(sent);
        var anomaly = cell && cell.anomaly_flag;
        var divergence = cell && cell.divergence_flag;
        var coldStart = cell && (cell.data_quality === 'velocity_cold_start');
        var neutralMuted = hasData && Math.abs(sent) < 0.01 && !anomaly && !divergence;
        var bg = hasData ? sentimentColor(sent) : '#f8fafc';
        var val = hasData ? (sent === 0 ? '0.00' : Number(sent).toFixed(2)) : '—';
        var cls = (anomaly ? ' cell-anomaly' : '') + (divergence ? ' cell-divergence' : '') + (coldStart ? ' cell-cold-start' : '') + (neutralMuted ? ' cell-neutral-muted' : '');
        html += '<td class="' + cls.trim() + '" style="background:' + bg + '">' + val + '</td>';
      });
      html += '</tr>';
    });
    html += '</tbody></table>';
    return html;
  }

  function renderAnomaliesTable(data) {
    const rows = data || [];
    let html = '<table class="data-table"><thead><tr><th>Type</th><th>Topic / Series</th><th>Severity</th><th>Detected</th><th>Description</th></tr></thead><tbody>';
    rows.forEach(function (r) {
      const type = (r.anomaly_type || '').replace(/_/g, '_');
      const badgeClass = type === 'velocity' ? 'badge-velocity' : type === 'sentiment_divergence' ? 'badge-sentiment_divergence' : type === 'cross_asset_dislocation' ? 'badge-cross_asset_dislocation' : 'badge-default';
      const topicOrSeries = r.series_id || r.topic || '—';
      const detected = r.detected_at ? r.detected_at.slice(0, 19).replace('T', ' ') : '—';
      html += '<tr><td><span class="badge ' + badgeClass + '">' + escapeHtml(type) + '</span></td><td>' + escapeHtml(topicOrSeries) + '</td><td>' + (r.severity != null ? Number(r.severity).toFixed(2) : '—') + '</td><td>' + detected + '</td><td>' + escapeHtml((r.description || '').slice(0, 80)) + '</td></tr>';
    });
    html += '</tbody></table>';
    return html;
  }

  function liquidityDots(level) {
    const l = (level || '').toLowerCase();
    const n = l === 'very_high' ? 4 : l === 'high' ? 3 : l === 'medium' ? 2 : 1;
    let html = '<span class="liquidity-dots">';
    for (let i = 0; i < 4; i++) html += '<span class="' + (i < n ? 'filled' : '') + '"></span>';
    html += '</span>';
    return html;
  }

  function hasActiveSignal(instrument) {
    var topics = instrument.themes || [];
    var latestDate = (STATE.signals || []).reduce(function (max, r) { return r.date > max ? r.date : max; }, '');
    var anomalyTopics = new Set((STATE.signals || []).filter(function (r) { return r.date === latestDate && r.anomaly_flag; }).map(function (r) { return r.topic; }));
    return topics.some(function (t) { return anomalyTopics.has(t); });
  }

  function renderUniverseGrid(data) {
    var af = (STATE.assetFilter || 'ALL').toUpperCase().replace(/\s/g, '_');
    var list = (data || []).filter(function (i) {
      if (af === 'ALL') return true;
      var ac = (i.asset_class || '').toLowerCase().replace(/\s/g, '_');
      if (af === 'EQUITY') return ac === 'equity';
      if (af === 'FIXED_INCOME') return ac.indexOf('fixed') >= 0;
      if (af === 'COMMODITY') return ac === 'commodity';
      if (af === 'FX') return ac === 'fx';
      if (af === 'RATES') return ac === 'rates';
      return true;
    });
    var sortBy = STATE.universeSort || 'signal';
    if (sortBy === 'signal') list.sort(function (a, b) { return (hasActiveSignal(b) ? 1 : 0) - (hasActiveSignal(a) ? 1 : 0); });
    if (sortBy === 'name') list.sort(function (a, b) { return (a.name || a.id).localeCompare(b.name || b.id); });
    if (sortBy === 'risk') list.sort(function (a, b) { return (a.risk_profile || '').localeCompare(b.risk_profile || ''); });
    var byClass = {};
    list.forEach(function (i) {
      var c = i.asset_class || 'Other';
      if (!byClass[c]) byClass[c] = [];
      byClass[c].push(i);
    });
    var order = ['equity', 'fixed_income', 'commodity', 'fx', 'rates'];
    var html = '<div class="universe-grid">';
    order.forEach(function (ac) {
      var items = byClass[ac] || byClass[ac.replace('_', ' ')] || [];
      if (items.length === 0) return;
      html += '<div class="section-divider">' + escapeHtml(ac) + '</div>';
      items.forEach(function (i) {
        var themes = (i.themes || []).slice(0, 3);
        var lp = STATE.latestPrices[i.id];
        var price = '—';
        var pctChg = '—';
        if (lp && lp.value != null) {
          price = Number(lp.value).toFixed(2);
          if (lp.pct_chg != null) pctChg = (lp.pct_chg >= 0 ? '+' : '') + Number(lp.pct_chg).toFixed(2) + '%';
        }
        var spark = '';
        var sparkData = STATE.sparklines7d[i.id];
        if (sparkData && sparkData.length >= 2) {
          var d = sparkData.map(function (x) { return x.date; }).reverse();
          var v = sparkData.map(function (x) { return parseFloat(x.value); }).reverse();
          spark = renderSparkline(d, v, 60, 30, '#0d9488');
        }
        var sigCls = hasActiveSignal(i) ? 'active' : 'inactive';
        html += '<div class="universe-card"><div class="card-name">' + escapeHtml(i.name || i.id) + '</div><div class="card-id">' + escapeHtml(i.id) + '</div><div class="card-meta"><span class="tag-pill">' + escapeHtml(i.asset_class || '') + '</span>' + liquidityDots(i.liquidity) + '<span class="tag-pill">' + escapeHtml(i.risk_profile || '') + '</span><span class="signal-dot ' + sigCls + '" title="' + (sigCls === 'active' ? 'Active signal' : 'No signal') + '"></span></div><div class="card-price">' + price + '</div><div class="' + (pctChg.indexOf('+') === 0 ? 'positive' : pctChg.indexOf('-') === 0 ? 'negative' : '') + '">' + pctChg + '</div><div class="card-sparkline">' + spark + '</div><div class="card-themes">';
        themes.forEach(function (t) {
          html += '<span class="tag-pill">' + escapeHtml(t) + '</span>';
        });
        html += '</div></div>';
      });
    });
    var rest = list.filter(function (i) {
      var ac = (i.asset_class || '').toLowerCase();
      return order.indexOf(ac) < 0 && order.indexOf(ac.replace(' ', '_')) < 0;
    });
    if (rest.length) {
      html += '<div class="section-divider">Other</div>';
      rest.forEach(function (i) {
        html += '<div class="universe-card"><div class="card-name">' + escapeHtml(i.name || i.id) + '</div><div class="card-id">' + escapeHtml(i.id) + '</div></div>';
      });
    }
    html += '</div>';
    return html;
  }

  function renderUniverseTable(data) {
    var af = (STATE.assetFilter || 'ALL').toUpperCase().replace(/\s/g, '_');
    var list = (data || []).filter(function (i) {
      if (af === 'ALL') return true;
      var ac = (i.asset_class || '').toLowerCase();
      if (af === 'EQUITY') return ac === 'equity';
      if (af === 'FIXED_INCOME') return ac.indexOf('fixed') >= 0;
      if (af === 'COMMODITY') return ac === 'commodity';
      if (af === 'FX') return ac === 'fx';
      if (af === 'RATES') return ac === 'rates';
      return true;
    });
    if (STATE.universeSort === 'signal') list.sort(function (a, b) { return (hasActiveSignal(b) ? 1 : 0) - (hasActiveSignal(a) ? 1 : 0); });
    if (STATE.universeSort === 'name') list.sort(function (a, b) { return (a.name || a.id).localeCompare(b.name || b.id); });
    var html = '<table class="data-table"><thead><tr><th>ID</th><th>Name</th><th>Class</th><th>Liquidity</th><th>Themes</th><th>Risk</th><th>Price</th><th>1d Chg</th><th>Signal</th></tr></thead><tbody>';
    list.forEach(function (i) {
      var themes = (i.themes || []).join(', ');
      var lp = STATE.latestPrices[i.id];
      var price = lp && lp.value != null ? Number(lp.value).toFixed(2) : '—';
      var pctChg = lp && lp.pct_chg != null ? (lp.pct_chg >= 0 ? '+' : '') + Number(lp.pct_chg).toFixed(2) + '%' : '—';
      var sig = hasActiveSignal(i) ? '<span style="color:var(--accent)">●</span>' : '<span style="color:var(--text-muted)">○</span>';
      html += '<tr><td>' + escapeHtml(i.id) + '</td><td>' + escapeHtml(i.name || '') + '</td><td>' + escapeHtml(i.asset_class || '') + '</td><td>' + liquidityDots(i.liquidity) + '</td><td>' + escapeHtml(themes) + '</td><td>' + escapeHtml(i.risk_profile || '') + '</td><td>' + price + '</td><td class="' + (pctChg.indexOf('+') === 0 ? 'positive' : 'negative') + '">' + pctChg + '</td><td>' + sig + '</td></tr>';
    });
    html += '</tbody></table>';
    return html;
  }

  function renderRegimeIndicators(regime) {
    if (!regime) return '<p class="text-muted">No regime data</p>';
    const names = [
      { key: 'growth_pulse', label: 'Growth pulse' },
      { key: 'credit_stress', label: 'Credit stress' },
      { key: 'real_yield', label: 'Real yield' },
      { key: 'dollar_strength', label: 'Dollar strength' },
      { key: 'rates_vol', label: 'Rates vol' },
      { key: 'equity_vol', label: 'Equity vol' },
      { key: 'curve_shape', label: 'Curve shape' },
    ];
    let html = '<div class="regime-indicators">';
    names.forEach(function (n) {
      const state = (regime[n.key] || 'INSUFFICIENT_DATA').toUpperCase().replace(/\s/g, '_');
      const cls = state === 'ELEVATED' ? 'state-elevated' : state === 'NORMAL' ? 'state-normal' : state === 'SUPPRESSED' ? 'state-suppressed' : 'state-insufficient_data';
      html += '<div class="regime-card"><div class="name">' + escapeHtml(n.label) + '</div><div class="state ' + cls + '">' + escapeHtml(regime[n.key] || '—') + '</div></div>';
    });
    html += '</div>';
    return html;
  }

  function regimeDescription(regime) {
    if (!regime) return '';
    const names = { growth_pulse: 'Growth pulse', credit_stress: 'Credit stress', real_yield: 'Real yields', dollar_strength: 'Dollar strength', rates_vol: 'Rates volatility', equity_vol: 'Equity volatility', curve_shape: 'Curve shape' };
    const parts = [];
    ['equity_vol', 'real_yield', 'growth_pulse', 'credit_stress', 'dollar_strength', 'rates_vol', 'curve_shape'].forEach(function (k) {
      const v = regime[k];
      if (v) parts.push(names[k] + ' is ' + v + '.');
    });
    return parts.join(' ');
  }

  function confidenceLabel(score) {
    if (score == null) return 'LOW';
    const s = parseFloat(score);
    if (s < 0.4) return 'LOW';
    if (s < 0.65) return 'MEDIUM';
    if (s <= 0.8) return 'MEDIUM-HIGH';
    return 'HIGH';
  }

  function renderThesesCards(theses, activeOnly) {
    let list = theses || [];
    if (activeOnly) list = list.filter(function (t) { return (t.status || '').toLowerCase() === 'active'; });
    let html = '<div class="theses-list">';
    list.forEach(function (t) {
      const confLabel = confidenceLabel(t.confidence);
      const primary = (t.instruments && t.instruments.primary) || {};
      const dir = (primary.direction || '').toLowerCase();
      const dirClass = dir === 'long' ? 'long' : dir === 'short' ? 'short' : '';
      const invList = (t.full_doc || '').match(/INVALIDATION:?\s*([\s\S]*?)(?=MONITORING|$)/i);
      const invText = invList ? invList[1].trim() : '';
      const invLines = invText.split(/\n/).filter(Boolean).slice(0, 3);
      html += '<div class="thesis-card"><div class="card-header"><span class="thesis-id">' + escapeHtml(t.thesis_id || '') + '</span><span>' + escapeHtml(t.theme || '') + '</span><span class="confidence-badge confidence-' + confLabel + '">' + confLabel + '</span><span class="tag-pill">' + escapeHtml(t.status || '') + '</span><span class="text-muted">' + (t.generated_at ? t.generated_at.slice(0, 10) : '') + '</span></div>';
      html += '<div class="hypothesis">' + escapeHtml(t.hypothesis || '') + '</div>';
      html += '<div class="evidence-toggle">▼ Signal evidence</div><div class="evidence-block">' + escapeHtml((t.full_doc || '').replace(/\r/g, '').split('SIGNAL_EVIDENCE:')[1] || '').split('PRIMARY_INSTRUMENT')[0].trim().slice(0, 500) + '</div>';
      if (primary.id) html += '<div class="primary-pill ' + dirClass + '">' + escapeHtml(primary.direction || '') + ' ' + escapeHtml(primary.id) + '</div>';
      html += '<ul class="invalid-list">';
      invLines.forEach(function (line) { html += '<li>' + escapeHtml(line.replace(/^\d+\.\s*/, '')) + '</li>'; });
      html += '</ul><div class="full-doc-toggle">View full thesis</div><div class="full-doc-block">' + escapeHtml(t.full_doc || '') + '</div></div>';
    });
    html += '</div>';
    return html;
  }

  function renderCorrelationsTable(data) {
    var lagFilter = STATE.correlationsLagFilter || 'all';
    var rows = (data || []).filter(function (r) {
      var lag = parseInt(r.lag_days, 10);
      if (lagFilter === '0') return lag === 0;
      if (lagFilter === '1') return lag === 1;
      if (lagFilter === '3') return lag >= 3;
      return true;
    }).slice().sort(function (a, b) {
      return Math.abs(parseFloat(b.correlation) || 0) - Math.abs(parseFloat(a.correlation) || 0);
    });
    var html = '<table class="data-table"><thead><tr><th>Topic</th><th>Series</th><th>Lag</th><th>Correlation</th><th>P-value</th></tr></thead><tbody>';
    rows.forEach(function (r) {
      var rho = parseFloat(r.correlation);
      var cls = rho > 0.3 ? 'corr-positive' : rho < -0.3 ? 'corr-negative' : 'corr-neutral';
      var barW = Math.min(100, (rho != null ? Math.abs(rho) : 0) * 100);
      var barCls = (rho != null && rho >= 0) ? 'pos' : 'neg';
      html += '<tr><td>' + escapeHtml(r.topic) + '</td><td>' + escapeHtml(r.series_id) + '</td><td>' + (r.lag_days ?? '') + '</td><td class="' + cls + '"><span class="corr-bar-wrap"><span class="corr-bar-fill ' + barCls + '" style="width:' + barW + '%"></span></span>' + (rho != null ? rho.toFixed(3) : '') + '</td><td>' + (r.p_value != null ? Number(r.p_value).toFixed(4) : '') + '</td></tr>';
    });
    html += '</tbody></table>';
    return html;
  }

  function getRegimeInterpretationBlocks(regime) {
    if (!regime) return [{ text: 'Current regime shows no strong directional signal — mixed conditions.', indicators: [] }];
    var r = regime;
    var blocks = [];
    if ((r.equity_vol === 'ELEVATED') && (r.rates_vol === 'ELEVATED') && (r.curve_shape === 'SUPPRESSED')) {
      blocks.push({
        indicators: ['equity_vol', 'rates_vol', 'curve_shape'],
        text: 'Triple stress signal: elevated equity volatility, elevated rates volatility, and a flat/inverted curve simultaneously active. This combination historically precedes credit spread widening and risk-off rotation. Key watch: investment grade vs high yield spread divergence.',
        implications: [
          ['Short-duration govts', 'Tailwind', 'High'],
          ['High yield credit', 'Headwind', 'High'],
          ['Defensive equities', 'Tailwind', 'Medium'],
          ['Long vol (VIX calls)', 'Tailwind', 'Medium'],
        ],
      });
    }
    if (r.dollar_strength === 'ELEVATED' && r.equity_vol === 'ELEVATED') {
      blocks.push({
        indicators: ['dollar_strength', 'equity_vol'],
        text: 'Strong dollar combined with elevated equity vol creates a particularly difficult environment for EM assets, which face both currency and risk-off headwinds simultaneously.',
        implications: [
          ['EM equities', 'Headwind', 'High'],
          ['EM FX', 'Headwind', 'High'],
          ['USD cash', 'Tailwind', 'High'],
        ],
      });
    }
    if (r.credit_stress === 'SUPPRESSED' && r.curve_shape === 'SUPPRESSED') {
      blocks.push({
        indicators: ['credit_stress', 'curve_shape'],
        text: 'Credit spreads suppressed despite flat curve — potential complacency signal. Watch for spread normalization if growth data disappoints.',
        implications: [
          ['IG credit', 'Neutral/watch', 'Medium'],
          ['HY credit', 'Headwind risk', 'Medium'],
        ],
      });
    }
    if ((r.real_yield === 'ELEVATED') && (r.rates_vol === 'ELEVATED')) {
      blocks.push({ indicators: ['real_yield', 'rates_vol'], text: 'Elevated real yields combined with high rates volatility suggests markets are repricing the terminal rate. Historically this environment pressures: growth equities, long-duration bonds, EM assets.', implications: [] });
    }
    if ((r.equity_vol === 'ELEVATED') && (r.credit_stress === 'ELEVATED')) {
      blocks.push({ indicators: ['equity_vol', 'credit_stress'], text: 'Simultaneous equity and credit stress signals a risk-off environment. Watch for: spread widening, flight to quality (short-end govts, gold, CHF/JPY).', implications: [] });
    }
    if ((r.growth_pulse === 'SUPPRESSED') && (r.curve_shape === 'SUPPRESSED')) {
      blocks.push({ indicators: ['growth_pulse', 'curve_shape'], text: 'Weak growth pulse and inverted/flat curve suggest late-cycle slowdown concerns. Historically precedes: credit underperformance, defensive equity outperformance.', implications: [] });
    }
    if (r.dollar_strength === 'ELEVATED') {
      blocks.push({ indicators: ['dollar_strength'], text: 'Strong dollar creates headwinds for: EM assets, commodity exporters, US multinationals.', implications: [] });
    }
    if (r.real_yield === 'ELEVATED') {
      blocks.push({ indicators: ['real_yield'], text: 'Elevated real yields are a headwind for long-duration bonds and growth equities.', implications: [] });
    }
    if (r.credit_stress === 'ELEVATED') {
      blocks.push({ indicators: ['credit_stress'], text: 'Credit stress suggests favouring quality and reducing cyclical exposure.', implications: [] });
    }
    if (r.equity_vol === 'ELEVATED') {
      blocks.push({ indicators: ['equity_vol'], text: 'Elevated equity volatility supports defensive positioning and optionality.', implications: [] });
    }
    if (r.curve_shape === 'SUPPRESSED') {
      blocks.push({ indicators: ['curve_shape'], text: 'Flat or inverted curve historically signals recession risk and favours short duration.', implications: [] });
    }
    if (blocks.length === 0) blocks.push({ text: 'Current regime shows no strong directional signal — mixed conditions.', indicators: [], implications: [] });
    return blocks;
  }

  function getRegimeInterpretation(regime) {
    var blocks = getRegimeInterpretationBlocks(regime);
    return blocks.map(function (b) { return b.text; }).join(' ');
  }

  function renderRegimeHistory(data) {
    var el = document.getElementById('regime-history-charts');
    if (!el) return;
    var names = ['growth_pulse', 'credit_stress', 'real_yield', 'dollar_strength', 'rates_vol', 'equity_vol', 'curve_shape'];
    var labels = { growth_pulse: 'Growth pulse', credit_stress: 'Credit stress', real_yield: 'Real yield', dollar_strength: 'Dollar strength', rates_vol: 'Rates vol', equity_vol: 'Equity vol', curve_shape: 'Curve shape' };
    var html = '';
    names.forEach(function (key) {
      var series = (data && data[key]) || [];
      var dates = series.map(function (x) { return x.date; });
      var values = series.map(function (x) { return parseFloat(x.value); });
      var currentState = STATE.regime && STATE.regime[key] ? STATE.regime[key] : '—';
      var svg = series.length >= 2 ? renderSparkline(dates, values, 280, 80, '#0d9488') : '<span class="text-muted">No data</span>';
      html += '<div class="regime-history-chart-row"><span class="indicator-label">' + (labels[key] || key) + '</span><div class="chart-inner">' + svg + '</div><span class="state state-normal">' + escapeHtml(currentState) + '</span></div>';
    });
    el.innerHTML = html;
  }

  function renderThesesActive(theses) {
    var list = (theses || []).filter(function (t) { return (t.status || '').toLowerCase() === 'active'; });
    var html = '<div class="theses-list">' + list.map(function (t) {
      var confLabel = confidenceLabel(t.confidence);
      var primary = (t.instruments && t.instruments.primary) || {};
      return '<div class="thesis-card"><div class="card-header"><span class="thesis-id">' + escapeHtml(t.thesis_id || '') + '</span><span>' + escapeHtml(t.theme || '') + '</span><span class="confidence-badge confidence-' + confLabel + '">' + confLabel + '</span><span class="tag-pill">' + escapeHtml(t.status || '') + '</span><span class="text-muted">' + (t.generated_at ? t.generated_at.slice(0, 10) : '') + '</span></div><div class="hypothesis">' + escapeHtml(t.hypothesis || '') + '</div><div class="signal-chain"><span class="signal-chain-box signal">Signal</span><span class="signal-chain-arrow">→</span><span class="signal-chain-box regime">Regime</span><span class="signal-chain-arrow">→</span><span class="signal-chain-box instrument">' + escapeHtml(primary.id || '—') + '</span><span class="signal-chain-arrow">→</span><span class="signal-chain-box hypothesis">' + escapeHtml((t.hypothesis || '').slice(0, 60)) + '</span></div><div class="evidence-toggle">▼ Evidence</div><div class="evidence-block">' + escapeHtml((t.full_doc || '').slice(0, 400)) + '</div></div>';
    }).join('') + '</div>';
    var wrap = document.getElementById('theses-active-wrap');
    if (wrap) wrap.innerHTML = html;
  }

  function buildBuilderSignalEvidence(data, topic) {
    if (!data || !topic) return '';
    var stats = (data.stats || [])[0] || {};
    var vel = stats.velocity_7d != null && !Number.isNaN(parseFloat(stats.velocity_7d)) ? parseFloat(stats.velocity_7d).toFixed(2) + 'σ' : 'cold start';
    var sent = parseFloat(stats.sentiment_avg);
    var dir = sent > 0.1 ? 'positive' : sent < -0.1 ? 'negative' : 'neutral';
    var sentVal = stats.sentiment_avg != null ? Number(stats.sentiment_avg).toFixed(2) : '—';
    var reg = STATE.regime || {};
    var artCount = stats.article_count != null ? stats.article_count : '—';
    var lines = [
      '1. ' + topic + ' velocity: ' + vel + ' above baseline',
      '2. Sentiment: ' + sentVal + ' (' + dir + ') over 7 days',
      '3. Regime: ' + (reg.dollar_strength || '—') + ' dollar, ' + (reg.equity_vol || '—') + ' equity vol, ' + (reg.rates_vol || '—') + ' rates vol',
      '4. Article count: ' + artCount + ' (last available date)',
    ];
    return lines.join('\n');
  }

  function renderThesesBuilder() {
    var topics = [...new Set((STATE.signals || []).map(function (r) { return r.topic; }))].sort();
    var topicOpts = '<option value="">Select topic…</option>' + topics.map(function (t) { return '<option value="' + escapeHtml(t) + '">' + escapeHtml(t) + '</option>'; }).join('');
    var html = '<div class="builder-layout"><div class="builder-left"><section class="panel"><h3 class="panel-header">SIGNAL PICKER</h3><div class="panel-body"><select id="builder-topic">' + topicOpts + '</select></div></section><section class="panel"><h3 class="panel-header">REGIME CONTEXT</h3><div class="panel-body" id="builder-regime">' + escapeHtml(getRegimeInterpretation(STATE.regime)) + '</div></section><section class="panel"><h3 class="panel-header">INSTRUMENT PICKER</h3><div class="panel-body" id="builder-instruments"><p class="text-muted">Select a topic first</p></div></section></div><div class="builder-right"><section class="panel"><h3 class="panel-header">THESIS WRITER</h3><div class="panel-body builder-form"><div class="form-group"><label>Title</label><input type="text" id="builder-title" placeholder="Title"></div><div class="form-group"><label>Hypothesis</label><textarea id="builder-hypothesis" placeholder="If X happens by Y date, Z will move"></textarea></div><div class="form-group"><label>Theme cluster</label><input type="text" id="builder-theme" placeholder="Theme"></div><div class="form-group"><label>Signal evidence</label><textarea id="builder-signal-evidence"></textarea></div><div class="form-group"><label>Primary instrument</label><input type="text" id="builder-primary-inst"></div><div class="form-group"><label>Conviction</label><div class="conviction-btns"><button type="button" data-c="H">H</button><button type="button" data-c="M">M</button><button type="button" data-c="L">L</button></div></div><div class="form-group"><label>Invalidation 1</label><input type="text" id="builder-inv1"></div><div class="form-group"><label>Invalidation 2</label><input type="text" id="builder-inv2"></div><div class="form-group"><label>Invalidation 3</label><input type="text" id="builder-inv3"></div><div class="builder-actions"><button type="button" class="primary" id="builder-save">Save as Draft</button><button type="button" id="builder-export">Export TXT</button><button type="button" id="builder-clear">Clear</button></div></div></section></div></div>';
    var wrap = document.getElementById('theses-builder-wrap');
    if (!wrap) return;
    wrap.innerHTML = html;
    var topicSel = document.getElementById('builder-topic');
    if (topicSel) {
      topicSel.addEventListener('change', function () {
        var topic = topicSel.value;
        var themeIn = document.getElementById('builder-theme');
        var evIn = document.getElementById('builder-signal-evidence');
        var instWrap = document.getElementById('builder-instruments');
        if (!topic) {
          STATE.builderTopicData = null;
          if (themeIn) themeIn.value = '';
          if (evIn) evIn.value = '';
          if (instWrap) instWrap.innerHTML = '<p class="text-muted">Select a topic first</p>';
          return;
        }
        if (themeIn) themeIn.value = topic;
        API.getSignalsTopic(topic).then(function (data) {
          STATE.builderTopicData = data;
          var linked = (data && data.linked_instruments) || [];
          if (instWrap) {
            instWrap.innerHTML = linked.length ? linked.map(function (i) {
              return '<div class="picker-item" data-id="' + escapeHtml(i.id) + '" data-name="' + escapeHtml(i.name || i.id) + '">' + escapeHtml(i.name || i.id) + ' <span class="text-muted">' + escapeHtml(i.id) + '</span></div>';
            }).join('') : '<p class="text-muted">No linked instruments</p>';
            instWrap.querySelectorAll('.picker-item').forEach(function (item) {
              item.addEventListener('click', function () {
                instWrap.querySelectorAll('.picker-item').forEach(function (x) { x.classList.remove('selected'); });
                item.classList.add('selected');
                var primIn = document.getElementById('builder-primary-inst');
                if (primIn) primIn.value = item.getAttribute('data-name') || item.getAttribute('data-id');
                var evIn = document.getElementById('builder-signal-evidence');
                if (evIn) {
                  var currentTopic = document.getElementById('builder-topic') && document.getElementById('builder-topic').value;
                  var corr = (STATE.correlations || []).find(function (c) {
                    return c.topic === currentTopic && c.series_id === item.getAttribute('data-id');
                  });
                  if (corr) {
                    var line = '5. Correlation with ' + item.getAttribute('data-id') + ': rho=' + (corr.correlation != null ? Number(corr.correlation).toFixed(3) : '') + ' at lag ' + (corr.lag_days != null ? corr.lag_days : 0) + ' days';
                    if (evIn.value.indexOf('5. Correlation') < 0) evIn.value = (evIn.value || '').trim() + (evIn.value ? '\n' : '') + line;
                  }
                }
              });
            });
          }
          if (evIn && (!evIn.value || !evIn.value.trim())) {
            evIn.value = buildBuilderSignalEvidence(data, topic);
          }
        });
      });
    }
    wrap.querySelectorAll('.conviction-btns button').forEach(function (btn) {
      btn.addEventListener('click', function () {
        wrap.querySelectorAll('.conviction-btns button').forEach(function (b) { b.classList.remove('active'); });
        btn.classList.add('active');
      });
    });
    var saveBtn = document.getElementById('builder-save');
    if (saveBtn) saveBtn.addEventListener('click', function () {
      var body = { theme: (document.getElementById('builder-theme') && document.getElementById('builder-theme').value) || '', hypothesis: (document.getElementById('builder-hypothesis') && document.getElementById('builder-hypothesis').value) || '', full_doc: (document.getElementById('builder-signal-evidence') && document.getElementById('builder-signal-evidence').value) || '', status: 'draft' };
      API.createThesis(body).then(function (res) {
        if (res && res.thesis_id) { STATE.theses = STATE.theses || []; STATE.theses.unshift({ thesis_id: res.thesis_id, status: 'draft' }); alert('Saved as ' + res.thesis_id); }
      });
    });
    var clearBtn = document.getElementById('builder-clear');
    if (clearBtn) clearBtn.addEventListener('click', function () {
      ['builder-title', 'builder-hypothesis', 'builder-theme', 'builder-signal-evidence', 'builder-primary-inst', 'builder-inv1', 'builder-inv2', 'builder-inv3'].forEach(function (id) {
        var el = document.getElementById(id);
        if (el) el.value = '';
      });
      var iw = document.getElementById('builder-instruments');
      if (iw) iw.querySelectorAll('.picker-item').forEach(function (x) { x.classList.remove('selected'); });
    });
    if (STATE.research && STATE.research.lastExport) {
      var exp = STATE.research.lastExport;
      var evEl = document.getElementById('builder-signal-evidence');
      if (evEl) evEl.value = exp.evidence || '';
      var primEl = document.getElementById('builder-primary-inst');
      if (primEl) primEl.value = exp.primary || '';
      var banner = document.createElement('div');
      banner.className = 'research-builder-flash success';
      banner.textContent = 'Research findings from ' + (exp.subview || '') + ' pre-loaded — edit as needed';
      wrap.insertBefore(banner, wrap.firstChild);
      setTimeout(function () {
        if (banner.parentNode) banner.parentNode.removeChild(banner);
      }, 5000);
      STATE.research.lastExport = null;
    }
  }

  function renderThesesArchive(theses) {
    var list = theses || [];
    var html = '<table class="theses-archive-table"><thead><tr><th>ID</th><th>Type</th><th>Theme</th><th>Hypothesis</th><th>Confidence</th><th>Status</th><th>Created</th></tr></thead><tbody>';
    list.forEach(function (t) {
      var typeBadge = (t.thesis_id || '').indexOf('MAN-') === 0 ? 'MANUAL' : 'AUTO';
      html += '<tr class="expandable"><td>' + escapeHtml(t.thesis_id || '') + '</td><td><span class="type-badge ' + typeBadge + '">' + typeBadge + '</span></td><td>' + escapeHtml(t.theme || '') + '</td><td>' + escapeHtml((t.hypothesis || '').slice(0, 50)) + '</td><td>' + (t.confidence != null ? Number(t.confidence).toFixed(2) : '—') + '</td><td>' + escapeHtml(t.status || '') + '</td><td>' + (t.generated_at ? t.generated_at.slice(0, 10) : '') + '</td></tr><tr><td colspan="7" class="expand-detail">' + escapeHtml(t.full_doc || '') + '</td></tr>';
    });
    html += '</tbody></table>';
    var wrap = document.getElementById('theses-archive-wrap');
    if (wrap) { wrap.innerHTML = html; wrap.querySelectorAll('.expandable').forEach(function (row) { row.addEventListener('click', function () { var next = row.nextElementSibling; if (next && next.classList) next.classList.toggle('open'); }); }); }
  }

  function renderThesesTrackRecord(theses) {
    var closed = (theses || []).filter(function (t) { return (t.outcome || t.status || '').toLowerCase() === 'closed' || (t.closed_at != null); });
    var wrap = document.getElementById('theses-trackrecord-wrap');
    if (!wrap) return;
    if (closed.length === 0) {
      wrap.innerHTML = '<div class="track-record-empty"><p>Track record will appear here once theses have been closed with outcomes.</p><p>Close theses and record outcomes to see win rate, performance by confidence band, and timeline.</p></div>';
    } else {
      wrap.innerHTML = '<div class="track-record-stats"><span class="stat-box">Total: ' + closed.length + '</span></div>';
    }
  }

  function renderDeepDiveTopicList() {
    var byTopic = {};
    (STATE.signals || []).forEach(function (r) {
      if (!byTopic[r.topic]) byTopic[r.topic] = 0;
      byTopic[r.topic] += r.article_count || 0;
    });
    var topics = Object.keys(byTopic).sort(function (a, b) { return (byTopic[b] || 0) - (byTopic[a] || 0); });
    var html = topics.map(function (t) {
      var cls = t === STATE.selectedTopic ? ' deepdive-topic-row selected' : ' deepdive-topic-row';
      return '<div class="' + cls.trim() + '" data-topic="' + escapeHtml(t) + '"><span>' + escapeHtml(t) + '</span><span class="count-badge">' + (byTopic[t] || 0) + '</span></div>';
    }).join('');
    var el = document.getElementById('deepdive-topic-list');
    if (el) {
      el.innerHTML = html;
      el.querySelectorAll('.deepdive-topic-row').forEach(function (row) {
        row.addEventListener('click', function () {
          STATE.selectedTopic = row.getAttribute('data-topic');
          renderDeepDiveTopicList();
          API.getSignalsTopic(STATE.selectedTopic).then(function (data) {
            STATE.topicDetail = data;
            renderDeepDiveDetail(STATE.selectedTopic);
          });
        });
      });
    }
  }

  function renderDeepDiveDetail(topic) {
    var data = STATE.topicDetail;
    console.log('[deep-dive] API response:', data);
    var wrap = document.getElementById('deepdive-detail-wrap');
    if (!wrap) return;
    if (!data) {
      wrap.innerHTML = '<p class="text-muted">Select a topic</p>';
      return;
    }
    var stats = data.stats || [];
    var dates = stats.map(function (s) { return s.date; }).reverse();
    var artCounts = stats.map(function (s) { return s.article_count || 0; }).reverse();
    var sents = stats.map(function (s) { return parseFloat(s.sentiment_avg) || 0; }).reverse();
    var velSpark = dates.length ? renderSparkline(dates, artCounts, 400, 60, '#0d9488') : '';
    var sentSpark = dates.length ? renderSparkline(dates, sents, 400, 60, '#16a34a') : '';
    var articlesHtml = (data.articles || []).slice(0, 10).map(function (a) {
      return '<li>' + escapeHtml((a.title || '').slice(0, 80)) + ' | ' + escapeHtml(a.source_id || '') + ' | ' + (a.published_at ? a.published_at.slice(0, 10) : '') + ' | ' + (a.sentiment != null ? Number(a.sentiment).toFixed(2) : '—') + '</li>';
    }).join('');
    var instHtml = (data.linked_instruments || []).map(function (i) {
      return '<div class="detail-instrument-card">' + escapeHtml(i.name || i.id) + ' <span class="text-muted">' + escapeHtml(i.id) + '</span></div>';
    }).join('');
    wrap.innerHTML = '<div class="deepdive-section"><h4>Velocity trend (30d)</h4>' + velSpark + '</div><div class="deepdive-section"><h4>Sentiment trend (30d)</h4>' + sentSpark + '</div><div class="deepdive-section"><h4>Recent articles</h4><ul class="detail-articles-list">' + articlesHtml + '</ul></div><div class="deepdive-section"><h4>Linked instruments</h4><div class="detail-instruments-cards">' + instHtml + '</div></div>';
  }

  function escapeHtml(s) {
    if (s == null) return '';
    const div = document.createElement('div');
    div.textContent = s;
    return div.innerHTML;
  }

  // ——— 5. CHART MODULE ———
  function renderChart(dates, values, targetId) {
    const el = document.getElementById(targetId);
    if (!el || !dates || !values || dates.length === 0) return;
    const w = el.clientWidth || 600;
    const h = el.clientHeight || 320;
    const pad = { top: 20, right: 12, bottom: 32, left: 52 };
    const chartW = w - pad.left - pad.right;
    const chartH = h - pad.top - pad.bottom;
    const minV = Math.min.apply(null, values);
    const maxV = Math.max.apply(null, values);
    const range = maxV - minV || 1;
    const xScale = function (i) {
      return pad.left + (i / (dates.length - 1 || 1)) * chartW;
    };
    const yScale = function (v) {
      return pad.top + chartH - ((v - minV) / range) * chartH;
    };
    var path = 'M ';
    values.forEach(function (v, i) {
      path += (i ? 'L ' : '') + xScale(i) + ' ' + yScale(v) + ' ';
    });
    var yTicks = 5;
    var yTickValues = [];
    for (var yi = 0; yi <= yTicks; yi++) {
      yTickValues.push(minV + (range * yi / yTicks));
    }
    var xStep = Math.max(1, Math.floor(dates.length / 6));
    var parts = [];
    parts.push('<svg width="' + w + '" height="' + h + '" viewBox="0 0 ' + w + ' ' + h + '" class="chart-svg">');
    parts.push('<defs><line id="gridline" x1="' + pad.left + '" y1="0" x2="' + w + '" y2="0" stroke="#f1f5f9" stroke-width="1"/></defs>');
    yTickValues.forEach(function (yv, yi) {
      var yy = yScale(yv);
      parts.push('<line x1="' + pad.left + '" y1="' + yy + '" x2="' + (w - pad.right) + '" y2="' + yy + '" stroke="#f1f5f9" stroke-width="1"/>');
      parts.push('<text x="' + (pad.left - 6) + '" y="' + (yy + 4) + '" text-anchor="end" font-size="10" fill="#64748b">' + (yv.toFixed(2)) + '</text>');
    });
    for (var xi = 0; xi < dates.length; xi += xStep) {
      var xx = xScale(xi);
      parts.push('<text x="' + xx + '" y="' + (h - 8) + '" text-anchor="middle" font-size="10" fill="#64748b">' + escapeHtml(formatDateShort(dates[xi])) + '</text>');
    }
    parts.push('<path d="' + path + '" fill="none" stroke="#0d9488" stroke-width="2" class="chart-line"/>');
    values.forEach(function (v, i) {
      var cx = xScale(i);
      var cy = yScale(v);
      parts.push('<circle cx="' + cx + '" cy="' + cy + '" r="4" fill="#0d9488" opacity="0" class="chart-point" data-index="' + i + '" data-date="' + escapeHtml(dates[i] || '') + '" data-value="' + (typeof v === 'number' ? v.toFixed(2) : v) + '"/>');
    });
    parts.push('</svg>');
    el.innerHTML = parts.join('');
    var tip = document.getElementById('chart-tooltip');
    if (!tip) {
      tip = document.createElement('div');
      tip.id = 'chart-tooltip';
      tip.className = 'chart-tooltip';
      el.appendChild(tip);
    }
    el.querySelectorAll('.chart-point').forEach(function (pt) {
      pt.addEventListener('mouseenter', function () {
        var date = pt.getAttribute('data-date');
        var value = pt.getAttribute('data-value');
        tip.textContent = (date ? formatDateShort(date) : '') + ' · ' + value;
        tip.style.display = 'block';
        tip.style.left = (pt.getBoundingClientRect().left - el.getBoundingClientRect().left + 8) + 'px';
        tip.style.top = (pt.getBoundingClientRect().top - el.getBoundingClientRect().top - 28) + 'px';
      });
      pt.addEventListener('mouseleave', function () {
        tip.style.display = 'none';
      });
    });
  }

  function renderChartZScore(dates, values, targetId) {
    var el = document.getElementById(targetId);
    if (!el || !dates || !values || dates.length < 2) return;
    var w = el.clientWidth || 600;
    var h = 120;
    var pad = { top: 12, right: 12, bottom: 20, left: 40 };
    var chartW = w - pad.left - pad.right;
    var chartH = h - pad.top - pad.bottom;
    var mean = values.reduce(function (a, b) { return a + b; }, 0) / values.length;
    var variance = values.reduce(function (sum, v) { return sum + (v - mean) * (v - mean); }, 0) / values.length;
    var std = Math.sqrt(variance) || 1;
    var zValues = values.map(function (v) { return (v - mean) / std; });
    var minZ = Math.min.apply(null, zValues);
    var maxZ = Math.max.apply(null, zValues);
    var rangeZ = Math.max(maxZ - minZ, 1);
    var yScale = function (z) {
      return pad.top + chartH - ((z - minZ) / rangeZ) * chartH;
    };
    var xScale = function (i) {
      return pad.left + (i / (dates.length - 1 || 1)) * chartW;
    };
    var path = 'M ';
    zValues.forEach(function (z, i) {
      path += (i ? 'L ' : '') + xScale(i) + ' ' + yScale(z) + ' ';
    });
    var y2 = yScale(2);
    var yMinus2 = yScale(-2);
    var parts = [];
    parts.push('<svg width="' + w + '" height="' + h + '" viewBox="0 0 ' + w + ' ' + h + '"><line x1="' + pad.left + '" y1="' + y2 + '" x2="' + (w - pad.right) + '" y2="' + y2 + '" stroke="#dc2626" stroke-width="1" stroke-dasharray="4,2"/>');
    parts.push('<line x1="' + pad.left + '" y1="' + yMinus2 + '" x2="' + (w - pad.right) + '" y2="' + yMinus2 + '" stroke="#dc2626" stroke-width="1" stroke-dasharray="4,2"/>');
    parts.push('<path d="' + path + '" fill="none" stroke="#0d9488" stroke-width="2"/>');
    parts.push('<text x="' + (pad.left - 4) + '" y="' + (yScale(2) + 3) + '" text-anchor="end" font-size="9" fill="#64748b">+2</text>');
    parts.push('<text x="' + (pad.left - 4) + '" y="' + (yScale(-2) + 3) + '" text-anchor="end" font-size="9" fill="#64748b">-2</text>');
    parts.push('</svg>');
    el.innerHTML = parts.join('');
  }

  // ——— 6. ROUTER ———
  var Shell = {
    activeSection: null,
    panelOpen: false,

    init: function () {
      document.querySelectorAll('.rail-item[data-section]').forEach(function (btn) {
        btn.addEventListener('click', function () {
          Shell.navigate(btn.dataset.section);
        });
      });
      var overlay = document.getElementById('sidebar-overlay');
      if (overlay) {
        overlay.addEventListener('click', function () {
          Shell.closePanel();
        });
      }
      var railPipelineBtn = document.getElementById('rail-pipeline-btn');
      if (railPipelineBtn) {
        railPipelineBtn.addEventListener('click', function () {
          Shell.runPipeline();
        });
      }
      var themeToggle = document.getElementById('rail-theme-toggle');
      if (themeToggle) {
        themeToggle.addEventListener('click', function () {
          Shell.toggleTheme();
        });
      }
      Shell.applyTheme(localStorage.getItem('signal-theme') || 'light');
      var activeScreen = document.querySelector('.screen.active');
      if (activeScreen) {
        Shell.activeSection = activeScreen.getAttribute('data-section') || 'briefing';
      }
      Shell._updateRailActive(Shell.activeSection);

      // Delegated nav for slide-out panel (TOOLS / views) — survives innerHTML refreshes
      var slidePanel = document.getElementById('sidebar-panel');
      if (slidePanel) {
        slidePanel.addEventListener('click', function (e) {
          var navBtn = e.target.closest('.panel-item[data-view]');
          if (!navBtn || !slidePanel.contains(navBtn)) return;
          var view = navBtn.getAttribute('data-view');
          if (!view) return;
          if (typeof ResearchV2 !== 'undefined' && ResearchV2.navigate) {
            ResearchV2.navigate(view);
          }
          Shell.closePanel();
        });
      }
    },

    navigate: function (section, opts) {
      opts = opts || {};
      var openPanel = opts.openPanel !== false;

      document.querySelectorAll('.screen').forEach(function (s) {
        s.classList.toggle('active', s.getAttribute('data-section') === section);
      });
      Shell._updateRailActive(section);
      Shell.renderPanel(section);

      if (Shell.activeSection === section && Shell.panelOpen) {
        Shell.closePanel();
      } else if (openPanel) {
        Shell.openPanel();
      }

      Shell.activeSection = section;

      if (section === 'research') {
        if (typeof ResearchV2 !== 'undefined' && ResearchV2.init) ResearchV2.init();
        if (typeof ResearchV2 !== 'undefined' && ResearchV2.initSearchBar) ResearchV2.initSearchBar();
        if (STATE.universe && STATE.universe.length > 0 && typeof ResearchV2 !== 'undefined' && ResearchV2.populateSidebar) ResearchV2.populateSidebar();
      }
      if (section === 'intelligence' && typeof Intelligence !== 'undefined' && typeof Intelligence.init === 'function') {
        Intelligence.init();
      }
      if (section === 'briefing' && typeof renderBriefing === 'function') {
        if (STATE.briefing) renderBriefing(STATE.briefing);
        else API.getBriefing().then(function (data) { STATE.briefing = data; renderBriefing(data); });
      }
      if (section === 'market' && typeof renderMarket === 'function') {
        if (!STATE.marketSeriesId && STATE.briefing && STATE.briefing.default_chart_series_id) {
          STATE.marketSeriesId = STATE.briefing.default_chart_series_id;
          var sel = document.getElementById('market-series-select');
          if (sel) sel.value = STATE.marketSeriesId;
        }
        if (STATE.marketSeriesId) {
          Promise.all([
            API.getMarketData(STATE.marketSeriesId, STATE.marketDays),
            API.getMarketData(STATE.marketSeriesId, 90),
          ]).then(function (results) {
            var data = results[0];
            var data90 = results[1];
            STATE.marketData = STATE.marketData || {};
            STATE.marketData[STATE.marketSeriesId] = data;
            var dates = data.map(function (r) { return r.date; }).reverse();
            var values = data.map(function (r) { return parseFloat(r.value); }).reverse();
            renderChart(dates, values, 'chart-svg-wrap');
            if (data90 && data90.length >= 2) {
              var dates90 = data90.map(function (r) { return r.date; }).reverse();
              var values90 = data90.map(function (r) { return parseFloat(r.value); }).reverse();
              renderChartZScore(dates90, values90, 'chart-zscore-wrap');
            } else {
              var zEl = document.getElementById('chart-zscore-wrap');
              if (zEl) zEl.innerHTML = '<p class="text-muted" style="font-size:12px;padding:8px 0;">Relative to 90d avg — need 90 days of data</p>';
            }
            if (data.length) {
              var last = data[0];
              var d1 = data[1];
              var d5 = data[5];
              var d20 = data[20];
              var lastVal = last.value != null ? parseFloat(last.value) : null;
              var v5 = d5 && d5.value != null ? parseFloat(d5.value) : null;
              var v20 = d20 && d20.value != null ? parseFloat(d20.value) : null;
              var stats = 'Current: ' + (lastVal != null ? lastVal.toFixed(2) : '—');
              if (d1 && last.pct_chg != null) stats += ' · 1d: <span class="' + (last.pct_chg >= 0 ? 'positive' : 'negative') + '">' + (last.pct_chg >= 0 ? '+' : '') + Number(last.pct_chg).toFixed(2) + '%</span>';
              if (d5) stats += ' · 5d: ' + (v5 != null && lastVal != null ? '<span class="' + (lastVal >= v5 ? 'positive' : 'negative') + '">' + (lastVal >= v5 ? '+' : '') + ((lastVal - v5) / v5 * 100).toFixed(2) + '%</span>' : '—');
              if (d20) stats += ' · 20d: ' + (v20 != null && lastVal != null ? '<span class="' + (lastVal >= v20 ? 'positive' : 'negative') + '">' + (lastVal >= v20 ? '+' : '') + ((lastVal - v20) / v20 * 100).toFixed(2) + '%</span>' : '—');
              if (data90 && data90.length) {
                var vals90 = data90.map(function (r) { return parseFloat(r.value); });
                var min90 = Math.min.apply(null, vals90);
                var max90 = Math.max.apply(null, vals90);
                var mean90 = vals90.reduce(function (a, b) { return a + b; }, 0) / vals90.length;
                var var90 = vals90.reduce(function (s, v) { return s + (v - mean90) * (v - mean90); }, 0) / vals90.length;
                var std90 = Math.sqrt(var90) || 1;
                var zScore = lastVal != null ? ((lastVal - mean90) / std90).toFixed(2) : '—';
                stats += ' · 90d high: ' + max90.toFixed(2) + ' · 90d low: ' + min90.toFixed(2) + ' · Z-score: ' + zScore;
              }
              var statEl = document.getElementById('chart-stats');
              if (statEl) statEl.innerHTML = '<div class="stat">' + stats + '</div>';
            }
          });
        } else {
          var sel = document.getElementById('market-series-select');
          if (sel && sel.options.length > 1) {
            STATE.marketSeriesId = sel.options[1].value;
            sel.value = STATE.marketSeriesId;
            sel.dispatchEvent(new Event('change'));
          }
        }
      }
      if (section === 'signals' && typeof renderSignals === 'function') renderSignals();
      if (section === 'universe' && typeof renderUniverse === 'function') renderUniverse();
      if (section === 'regime' && typeof renderRegime === 'function') renderRegime();
      if (section === 'theses' && typeof renderTheses === 'function') renderTheses();
      if (section === 'thesis-engine' && typeof ThesisEngineApp !== 'undefined' && ThesisEngineApp.activate) {
        ThesisEngineApp.activate();
      }
    },

    _updateRailActive: function (section) {
      document.querySelectorAll('.rail-item[data-section]').forEach(function (btn) {
        var railSection = btn.dataset.section;
        var active = (railSection === section) || (railSection === 'intelligence' && section !== 'research' && section !== 'thesis-engine');
        btn.classList.toggle('active', !!active);
      });
    },

    openPanel: function () {
      var panel = document.getElementById('sidebar-panel');
      var overlay = document.getElementById('sidebar-overlay');
      if (panel) {
        panel.classList.remove('collapsed');
        panel.classList.add('open');
      }
      if (overlay) overlay.classList.add('active');
      Shell.panelOpen = true;
    },

    closePanel: function () {
      var panel = document.getElementById('sidebar-panel');
      var overlay = document.getElementById('sidebar-overlay');
      if (panel) {
        panel.classList.remove('open');
        panel.classList.add('collapsed');
      }
      if (overlay) overlay.classList.remove('active');
      Shell.panelOpen = false;
    },

    renderPanel: function (section) {
      var panel = document.getElementById('sidebar-panel');
      if (!panel) return;

      var html = '';
      if (section === 'research') {
        html = Shell._researchPanelHtml();
      } else if (section === 'intelligence') {
        html = Shell._intelligencePanelHtml();
      } else {
        html = Shell._defaultPanelHtml(section);
      }
      html += Shell._pipelinePanelHtml();
      panel.innerHTML = html;

      // .panel-item[data-view] navigation is handled by delegated listener on #sidebar-panel (Shell.init)

      panel.querySelectorAll('.panel-item[data-intel-section]').forEach(function (btn) {
        btn.addEventListener('click', function () {
          if (typeof Intelligence !== 'undefined') {
            Intelligence.openSection(btn.dataset.intelSection);
          }
          Shell.closePanel();
        });
      });

      var pipelineBtn = panel.querySelector('#sidebar-pipeline-btn');
      if (pipelineBtn) {
        pipelineBtn.addEventListener('click', function () {
          Shell.runPipeline();
        });
      }

      Shell.updateLastRun();
      if (section === 'research' && typeof ResearchV2 !== 'undefined' && ResearchV2.populateSidebar) {
        setTimeout(function () { ResearchV2.populateSidebar(); }, 0);
      }
      if (section === 'research' && typeof ResearchV2 !== 'undefined' && typeof ResearchV2.populateSidebarTheses === 'function') {
        ResearchV2.populateSidebarTheses();
      }
    },

    _researchPanelHtml: function () {
      return '<div class="panel-section">'
        + '<div class="panel-section-title">THESES</div>'
        + '<button class="panel-item" data-view="thesislist">All theses</button>'
        + '<div id="panel-theses-list"></div>'
        + '</div>'
        + '<div class="panel-section">'
        + '<div class="panel-section-title">TOOLS</div>'
        + '<button class="panel-item" data-view="analysis">Analysis</button>'
        + '</div>'
        + '<div class="panel-section">'
        + '<div class="panel-section-title">COMPUTED DATA</div>'
        + '<button class="panel-item" data-view="signals">Signals</button>'
        + '<button class="panel-item" data-view="correlations">Correlations</button>'
        + '<button class="panel-item" data-view="impact">Market Impact</button>'
        + '<button class="panel-item" data-view="regime">Regime</button>'
        + '<button class="panel-item" data-view="forecasts">Forecasts</button>'
        + '<button class="panel-item" data-view="volatility">Volatility</button>'
        + '<button class="panel-item" data-view="scenarios">Scenarios</button>'
        + '<button class="panel-item" data-view="news">News &amp; Articles</button>'
        + '</div>'
        + '<div class="panel-section" id="panel-instruments">'
        + '</div>';
    },

    _intelligencePanelHtml: function () {
      return '<div class="panel-section">'
        + '<div class="panel-section-title">SECTIONS</div>'
        + '<button class="panel-item" data-intel-section="briefing">Today</button>'
        + '<button class="panel-item" data-intel-section="signals">Signals</button>'
        + '<button class="panel-item" data-intel-section="regime">Regime</button>'
        + '<button class="panel-item" data-intel-section="market">Market</button>'
        + '<button class="panel-item" data-intel-section="correlations">Correlations</button>'
        + '<button class="panel-item" data-intel-section="forecasts">Forecasts</button>'
        + '<button class="panel-item" data-intel-section="volatility">Volatility</button>'
        + '<button class="panel-item" data-intel-section="scenarios">Scenarios</button>'
        + '</div>';
    },

    _defaultPanelHtml: function (section) {
      var label = section.charAt(0).toUpperCase() + section.slice(1);
      return '<div class="panel-section"><div class="panel-section-title">' + label + '</div></div>';
    },

    _pipelinePanelHtml: function () {
      return '<div class="panel-pipeline">'
        + '<button class="panel-pipeline-btn" id="sidebar-pipeline-btn">Run pipeline</button>'
        + '<div class="panel-pipeline-meta" id="sidebar-last-run">Last run: —</div>'
        + '</div>';
    },

    updateLastRun: function () {
      var el = document.getElementById('sidebar-last-run');
      if (!el) return;
      var ts = (window.SIGNAL_LAST_RUN) || (STATE && STATE.status && STATE.status.last_run) || (STATE && STATE.lastRun) || null;
      el.textContent = ts ? 'Last run: ' + (typeof ts === 'string' ? ts.slice(0, 19).replace('T', ' ') : ts) : 'Last run: —';
    },

    runPipeline: function () {
      if (typeof API !== 'undefined' && typeof API.runPipeline === 'function') {
        var btn = document.getElementById('rail-pipeline-btn');
        var sidebarBtn = document.getElementById('sidebar-pipeline-btn');
        if (btn) { btn.disabled = true; btn.textContent = '...'; }
        if (sidebarBtn) { sidebarBtn.disabled = true; sidebarBtn.textContent = 'Running...'; }
        API.runPipeline().then(function () {
          if (STATE && STATE.status) STATE.status.last_run = new Date().toISOString();
          setTimeout(function () {
            if (btn) { btn.disabled = false; btn.textContent = '\u25B6'; }
            if (sidebarBtn) { sidebarBtn.disabled = false; sidebarBtn.textContent = 'Run pipeline'; }
            Shell.updateLastRun();
          }, 3000);
        }).catch(function () {
          if (btn) { btn.disabled = false; btn.textContent = '\u25B6'; }
          if (sidebarBtn) { sidebarBtn.disabled = false; sidebarBtn.textContent = 'Run pipeline'; }
        });
      }
    },

    toggleTheme: function () {
      var current = document.documentElement.getAttribute('data-theme') || 'light';
      Shell.applyTheme(current === 'dark' ? 'light' : 'dark');
    },

    applyTheme: function (theme) {
      document.documentElement.setAttribute('data-theme', theme);
      try { localStorage.setItem('signal-theme', theme); } catch (e) {}
      var icon = document.getElementById('theme-icon') || document.getElementById('rail-theme-toggle');
      if (icon) icon.textContent = theme === 'dark' ? '\u25CB' : '\u25D0';
    }
  };
  window.Shell = Shell;


  function switchSection(sectionId) {
    Shell.navigate(sectionId);
  }

  function switchSubview(sectionId, subviewId) {
    var screen = document.getElementById('screen-' + sectionId);
    if (!screen) return;
    screen.querySelectorAll('.subview').forEach(function (s) {
      s.classList.toggle('active', s.getAttribute('data-subview') === subviewId);
    });
    screen.querySelectorAll('.subnav-btn').forEach(function (b) {
      b.classList.toggle('active', b.getAttribute('data-subview') === subviewId);
    });
    if (sectionId === 'regime' && subviewId === 'history') {
      API.getRegimeHistory(90).then(function (data) {
        STATE.regimeHistory = data;
        renderRegimeHistory(data);
      });
    }
    if (sectionId === 'research') {
      Research.state.activeSubview = subviewId || 'overview';
    }
    if (sectionId === 'theses') {
      if (subviewId === 'active') renderThesesActive(STATE.theses);
      if (subviewId === 'builder') renderThesesBuilder();
      if (subviewId === 'archive') renderThesesArchive(STATE.theses);
      if (subviewId === 'trackrecord') renderThesesTrackRecord(STATE.theses);
    }
    if (sectionId === 'signals' && subviewId === 'deepdive') {
      renderDeepDiveTopicList();
      if (STATE.selectedTopic) renderDeepDiveDetail(STATE.selectedTopic);
    }
  }

  // ——— 7. INIT ———
  function refreshStatus() {
    API.getStatus().then(function (data) {
      STATE.status = data;
      if (data) {
        var el;
        el = document.getElementById('topbar-last-run'); if (el) el.textContent = data.last_run ? 'Last run: ' + data.last_run.slice(0, 19).replace('T', ' ') : '—';
        el = document.getElementById('side-articles'); if (el) el.textContent = data.articles_total ?? '—';
        el = document.getElementById('side-topics'); if (el) el.textContent = data.topics_active ?? data.daily_signals_rows ?? '—';
        el = document.getElementById('side-anomalies'); if (el) el.textContent = data.anomalies_today ?? '—';
        el = document.getElementById('side-theses'); if (el) el.textContent = data.theses_active ?? '—';
        el = document.getElementById('status-text'); if (el) el.innerHTML = (data.topics_active ?? 0) + ' topics · ' + (data.anomalies_today ?? 0) + ' anomalies · ' + (data.theses_active ?? 0) + ' active theses · Last run: ' + (data.last_run ? data.last_run.slice(0, 19).replace('T', ' ') : '—');
      }
    });
  }

  function refreshSidebarRegime() {
    if (!STATE.regime) return;
    const r = STATE.regime;
    const names = ['growth_pulse', 'credit_stress', 'real_yield', 'dollar_strength', 'rates_vol', 'equity_vol', 'curve_shape'];
    let html = '';
    names.forEach(function (k) {
      const v = r[k] || '—';
      const cls = v === 'ELEVATED' ? 'state-elevated' : v === 'NORMAL' ? 'state-normal' : v === 'SUPPRESSED' ? 'state-suppressed' : 'state-insufficient_data';
      html += '<div class="regime-mini-row"><span>' + k.replace(/_/g, ' ') + '</span><span class="state ' + cls + '">' + v + '</span></div>';
    });
    var regimeEl = document.getElementById('sidebar-regime-list');
    if (regimeEl) regimeEl.innerHTML = html || '—';
  }

  function applyRenders() {
    var el = function (id) { return document.getElementById(id); };
    if (el('signals-heatmap-wrap')) el('signals-heatmap-wrap').innerHTML = renderSignalsSurface(STATE.signals);
    if (el('anomalies-table-wrap')) el('anomalies-table-wrap').innerHTML = renderAnomaliesTable(STATE.anomalies);
    if (el('universe-grid-wrap')) el('universe-grid-wrap').innerHTML = renderUniverseGrid(STATE.universe);
    if (el('universe-table-wrap')) el('universe-table-wrap').innerHTML = renderUniverseTable(STATE.universe);
    if (el('regime-indicators-wrap')) el('regime-indicators-wrap').innerHTML = renderRegimeIndicators(STATE.regime);
    if (el('regime-fingerprint')) el('regime-fingerprint').textContent = STATE.regime && STATE.regime.fingerprint ? STATE.regime.fingerprint : '—';
    if (el('regime-computed')) el('regime-computed').textContent = STATE.regime && STATE.regime.computed_at ? 'Last computed: ' + STATE.regime.computed_at.slice(0, 19).replace('T', ' ') : '';
    if (el('regime-interpretation')) {
      var blocks = getRegimeInterpretationBlocks(STATE.regime);
      var count = blocks.filter(function (b) { return b.indicators && b.indicators.length > 0; }).length;
      var html = '<p class="regime-pattern-count">' + count + ' pattern' + (count !== 1 ? 's' : '') + ' active</p>';
      blocks.forEach(function (b) {
        var tag = (b.indicators || []).map(function (k) { return k.replace(/_/g, ' '); }).join(', ');
        html += '<div class="regime-interp-block"><span class="regime-interp-tag">' + escapeHtml(tag) + '</span><p>' + escapeHtml(b.text) + '</p></div>';
      });
      el('regime-interpretation').innerHTML = html;
    }
    if (el('regime-implications-wrap')) {
      var blocks = getRegimeInterpretationBlocks(STATE.regime);
      var rows = [];
      blocks.forEach(function (b) {
        (b.implications || []).forEach(function (row) {
          rows.push(row);
        });
      });
      if (rows.length === 0) rows = [['Long-duration bonds', 'Headwind (real yields elevated)', 'High'], ['Growth equities', 'Headwind (real yields elevated)', 'High'], ['Gold', 'Tailwind (dollar strength)', 'Medium'], ['EM FX', 'Headwind (dollar strength)', 'Medium']];
      var tbody = rows.map(function (row) {
        return '<tr><td>' + escapeHtml(row[0]) + '</td><td>' + escapeHtml(row[1]) + '</td><td>' + escapeHtml(row[2]) + '</td></tr>';
      }).join('');
      el('regime-implications-wrap').innerHTML = '<table class="regime-implications-table"><thead><tr><th>Asset Class</th><th>Implication</th><th>Confidence</th></tr></thead><tbody>' + tbody + '</tbody></table>';
    }
    if (el('regime-reference-content')) el('regime-reference-content').innerHTML = '<h4>Indicator reference</h4><p>Each indicator is computed from market data and classified as ELEVATED (top 25%), NORMAL (middle 50%), or SUPPRESSED (bottom 25%). INSUFFICIENT_DATA appears when history is too short.</p><h4>How to read</h4><p>ELEVATED = current value in top quartile; NORMAL = middle; SUPPRESSED = bottom quartile. The fingerprint concatenates all 7 states (e.g. NORMAL-ELEVATED-SUPPRESSED-...).</p><h4>Common combinations</h4><ul><li>Real yield ELEVATED + Rates vol ELEVATED: repricing terminal rate, pressure on duration.</li><li>Equity vol + Credit stress ELEVATED: risk-off, flight to quality.</li><li>Growth pulse + Curve SUPPRESSED: late-cycle slowdown.</li><li>Dollar ELEVATED: headwinds for EM, commodities, US multinationals.</li></ul>';
    if (el('theses-active-wrap')) { renderThesesActive(STATE.theses); }
    if (el('theses-archive-wrap')) renderThesesArchive(STATE.theses);
    if (el('theses-trackrecord-wrap')) renderThesesTrackRecord(STATE.theses);
    if (el('market-correlations-wrap')) el('market-correlations-wrap').innerHTML = renderCorrelationsTable(STATE.correlations);
    if (STATE.briefing && el('briefing-highlights')) renderBriefing(STATE.briefing);
  }

  function applyDemoChrome(isDemo) {
    if (!isDemo) return;
    CONFIG.DEMO = true;
    window.SIGNAL_DEMO = 1;
    var banner = document.getElementById('demo-banner');
    if (banner) banner.hidden = false;
    var pipe = document.getElementById('rail-pipeline-btn');
    if (pipe) {
      pipe.disabled = true;
      pipe.title = 'Disabled on public demo';
      pipe.setAttribute('aria-disabled', 'true');
    }
  }

  function init() {
    Shell.init();
    if (window.location.protocol === 'file:') {
      var block = document.getElementById('file-protocol-block');
      var appMain = document.getElementById('app-main');
      if (block) {
        block.style.display = 'flex';
        document.body.classList.add('file-protocol-active');
      }
      if (appMain) appMain.style.display = 'none';
      var copyBtn = document.getElementById('file-protocol-copy');
      var cmdEl = document.getElementById('file-protocol-cmd');
      if (copyBtn && cmdEl) {
        copyBtn.addEventListener('click', function () {
          navigator.clipboard.writeText(cmdEl.textContent).then(function () { copyBtn.textContent = 'Copied!'; setTimeout(function () { copyBtn.textContent = 'Copy command'; }, 2000); });
        });
      }
      return;
    }
    if (CONFIG.DEMO) applyDemoChrome(true);
    else {
      fetch(CONFIG.API_BASE + '/api/demo')
        .then(function (r) { return r.ok ? r.json() : null; })
        .then(function (d) { if (d && d.demo) applyDemoChrome(true); })
        .catch(function () {});
    }
    Promise.all([
      API.getStatus(),
      API.getSignalsLatest(),
      API.getUniverse(),
      API.getCorrelations(),
      API.getRegimeLatest(),
      API.getAnomaliesRecent(),
      API.getTheses(),
      API.getBriefing(),
      API.getMarketDataLatestAll(),
      API.getMarketDataSparklines(7),
    ]).then(function (results) {
      STATE.status = results[0];
      STATE.signals = results[1];
      STATE.universe = results[2];
      STATE.correlations = results[3];
      STATE.regime = results[4];
      STATE.anomalies = results[5];
      STATE.theses = results[6];
      STATE.briefing = results[7];
      STATE.latestPrices = results[8] || {};
      STATE.sparklines7d = results[9] || {};
      refreshStatus();
      refreshSidebarRegime();
      applyRenders();
      if (STATE.briefing && document.getElementById('briefing-highlights')) renderBriefing(STATE.briefing);
      if (typeof ResearchWorkspace !== 'undefined' && ResearchWorkspace.renderMacroContext) ResearchWorkspace.renderMacroContext();
      // Always refresh Research sidebar when data loads
      if (typeof ResearchV2 !== 'undefined' && ResearchV2.populateSidebar) ResearchV2.populateSidebar();

      var withTicker = (STATE.universe || []).filter(function (i) { return i.yfinance_ticker; });
      var snap = (STATE.briefing && STATE.briefing.market_snapshot) || [];
      var seen = new Set(withTicker.map(function (i) { return i.id; }));
      var options = withTicker.map(function (i) { return { value: i.id, label: i.name || i.id }; });
      snap.forEach(function (m) {
        if (m.series_id && !seen.has(m.series_id)) {
          seen.add(m.series_id);
          options.push({ value: m.series_id, label: m.name || m.series_id });
        }
      });
      var sel = document.getElementById('market-series-select');
      if (sel) {
        sel.innerHTML = '<option value="">Select instrument</option>' + options.map(function (o) {
          return '<option value="' + escapeHtml(o.value) + '">' + escapeHtml(o.label) + '</option>';
        }).join('');
        if (STATE.briefing && STATE.briefing.default_chart_series_id && seen.has(STATE.briefing.default_chart_series_id)) {
          STATE.marketSeriesId = STATE.briefing.default_chart_series_id;
          sel.value = STATE.marketSeriesId;
        }
        sel.addEventListener('change', function () {
          STATE.marketSeriesId = sel.value || null;
          if (STATE.marketSeriesId) {
            API.getMarketData(STATE.marketSeriesId, STATE.marketDays).then(function (data) {
              STATE.marketData[STATE.marketSeriesId] = data;
              const dates = data.map(function (r) { return r.date; }).reverse();
              const values = data.map(function (r) { return parseFloat(r.value); }).reverse();
              renderChart(dates, values, 'chart-svg-wrap');
              if (data.length) {
                const last = data[0];
                const d5 = data[5]; const d20 = data[20];
                let stats = 'Current: ' + (last.value != null ? Number(last.value).toFixed(2) : '—');
                if (last.pct_chg != null) stats += ' · 1d: <span class="' + (last.pct_chg >= 0 ? 'positive' : 'negative') + '">' + (last.pct_chg >= 0 ? '+' : '') + Number(last.pct_chg).toFixed(2) + '%</span>';
                if (d5 && d5.pct_chg != null) stats += ' · 5d: ' + Number(d5.pct_chg).toFixed(2) + '%';
                if (d20 && d20.pct_chg != null) stats += ' · 20d: ' + Number(d20.pct_chg).toFixed(2) + '%';
                document.getElementById('chart-stats').innerHTML = '<div class="stat">' + stats + '</div>';
              }
            });
          } else {
            document.getElementById('chart-svg-wrap').innerHTML = '';
            document.getElementById('chart-stats').innerHTML = '';
          }
        });
      }
      document.querySelectorAll('.chart-range .range-btn').forEach(function (btn) {
        btn.addEventListener('click', function () {
          document.querySelectorAll('.chart-range .range-btn').forEach(function (b) { b.classList.remove('active'); });
          btn.classList.add('active');
          STATE.marketDays = parseInt(btn.getAttribute('data-days'), 10);
          if (STATE.marketSeriesId) {
            API.getMarketData(STATE.marketSeriesId, STATE.marketDays).then(function (data) {
              const dates = data.map(function (r) { return r.date; }).reverse();
              const values = data.map(function (r) { return parseFloat(r.value); }).reverse();
              renderChart(dates, values, 'chart-svg-wrap');
            });
          }
        });
      });

    }).catch(function (e) {
      console.error('Init fetch error', e);
      var statusEl = document.getElementById('status-text');
      if (statusEl) statusEl.textContent = 'Failed to load data. Is the API running on port 8000?';
    });

    var tabs = document.querySelectorAll('.section-tabs .tab');
    if (tabs.length) {
      tabs.forEach(function (tab) {
        tab.addEventListener('click', function () {
          switchSection(tab.getAttribute('data-section'));
        });
      });
    }
    document.querySelectorAll('.subnav-btn').forEach(function (btn) {
      btn.addEventListener('click', function () {
        const section = btn.closest('.screen').getAttribute('data-section');
        switchSubview(section, btn.getAttribute('data-subview'));
      });
    });
    document.querySelectorAll('.filter-btn[data-asset]').forEach(function (btn) {
      btn.addEventListener('click', function () {
        document.querySelectorAll('.filter-asset .filter-btn').forEach(function (b) { b.classList.remove('active'); });
        btn.classList.add('active');
        STATE.assetFilter = btn.getAttribute('data-asset');
        document.getElementById('universe-grid-wrap').innerHTML = renderUniverseGrid(STATE.universe);
        document.getElementById('universe-table-wrap').innerHTML = renderUniverseTable(STATE.universe);
      });
    });
    var topicInput = document.getElementById('filter-topic');
    if (topicInput) {
      topicInput.addEventListener('input', function () {
        STATE.topicFilter = topicInput.value;
        var wrap = document.getElementById('signals-heatmap-wrap');
        if (wrap) wrap.innerHTML = renderSignalsSurface(STATE.signals);
      });
    }
    document.querySelectorAll('.surface-toggle .toggle-btn').forEach(function (btn) {
      btn.addEventListener('click', function () {
        document.querySelectorAll('.surface-toggle .toggle-btn').forEach(function (b) { b.classList.remove('active'); });
        btn.classList.add('active');
        STATE.signalsSurfaceMode = btn.getAttribute('data-surface') || 'notable';
        var wrap = document.getElementById('signals-heatmap-wrap');
        if (wrap) wrap.innerHTML = renderSignalsSurface(STATE.signals);
      });
    });
    document.querySelectorAll('.universe-sort .sort-btn').forEach(function (btn) {
      btn.addEventListener('click', function () {
        document.querySelectorAll('.universe-sort .sort-btn').forEach(function (b) { b.classList.remove('active'); });
        btn.classList.add('active');
        STATE.universeSort = btn.getAttribute('data-sort') || 'signal';
        var g = document.getElementById('universe-grid-wrap');
        var t = document.getElementById('universe-table-wrap');
        if (g) g.innerHTML = renderUniverseGrid(STATE.universe);
        if (t) t.innerHTML = renderUniverseTable(STATE.universe);
      });
    });
    document.querySelectorAll('.correlations-filter .lag-btn').forEach(function (btn) {
      btn.addEventListener('click', function () {
        document.querySelectorAll('.correlations-filter .lag-btn').forEach(function (b) { b.classList.remove('active'); });
        btn.classList.add('active');
        STATE.correlationsLagFilter = btn.getAttribute('data-lag') || 'all';
        var wrap = document.getElementById('market-correlations-wrap');
        if (wrap) wrap.innerHTML = renderCorrelationsTable(STATE.correlations);
      });
    });

    var runBtn = document.getElementById('topbar-run-pipeline');
    if (runBtn) {
      runBtn.addEventListener('click', function () {
        if (runBtn.disabled) return;
        runBtn.disabled = true;
        runBtn.textContent = 'Running...';
        API.runPipeline().then(function () {
          var statusEl = document.getElementById('status-text');
          if (statusEl) statusEl.textContent = 'Pipeline triggered — data will update shortly';
          setTimeout(function () {
            runBtn.disabled = false;
            runBtn.textContent = '\u25B6 Run pipeline';
          }, 3000);
          setTimeout(function () { refreshStatus(); }, 10000);
        }).catch(function () {
          runBtn.disabled = false;
          runBtn.textContent = '\u25B6 Run pipeline';
        });
      });
    }
    var exportBtn = document.getElementById('theses-export-json');
    if (exportBtn) {
      exportBtn.addEventListener('click', function () {
        var dateStr = new Date().toISOString().slice(0, 10);
        var blob = new Blob([JSON.stringify(STATE.theses || [], null, 2)], { type: 'application/json' });
        var a = document.createElement('a');
        a.href = URL.createObjectURL(blob);
        a.download = 'signal_theses_' + dateStr + '.json';
        a.click();
        URL.revokeObjectURL(a.href);
      });
    }

    var sidebarToggle = document.getElementById('sidebar-toggle');
    if (sidebarToggle) {
      sidebarToggle.addEventListener('click', function () {
        var sidebar = document.getElementById('sidebar');
        if (sidebar) sidebar.classList.toggle('collapsed');
      });
    }
    var contentEl = document.querySelector('.content') || document.getElementById('main-content');
    if (contentEl) contentEl.addEventListener('click', function (e) {
      if (e.target.classList.contains('evidence-toggle')) {
        var block = e.target.nextElementSibling;
        if (block) block.classList.toggle('open');
      }
      if (e.target.classList.contains('full-doc-toggle')) {
        var card = e.target.closest('.thesis-card');
        var block = card && card.querySelector('.full-doc-block');
        if (block) block.classList.toggle('open');
      }
    });

    setInterval(function () {
      refreshStatus();
      if (typeof ResearchV2 !== 'undefined' && ResearchV2.updateSidebarPrices) ResearchV2.updateSidebarPrices();
      if (typeof ResearchV2 !== 'undefined' && ResearchV2.updateAtChips) ResearchV2.updateAtChips();
    }, CONFIG.POLL_INTERVAL_MS);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

  window.addEventListener('beforeunload', function (e) {
    if (typeof ThesisManager !== 'undefined' && ThesisManager._isDirty) {
      e.preventDefault();
      e.returnValue = '';
      if (ThesisManager._autoSave) ThesisManager._autoSave();
    }
  });
})();
