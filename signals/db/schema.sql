-- SIGNAL — PostgreSQL schema
-- All timestamps in UTC. Monetary values as float (basis points / index levels).

-- Articles from ingestion (RSS, scrapers). FRED/numeric adapters write to market_data only.
CREATE TABLE articles (
  id             SERIAL PRIMARY KEY,
  source_id      VARCHAR(64) NOT NULL,
  url            TEXT UNIQUE NOT NULL,
  title          TEXT,
  body_text      TEXT,
  published_at   TIMESTAMPTZ,
  ingested_at    TIMESTAMPTZ DEFAULT NOW(),
  entities       JSONB,
  topics         JSONB,
  sentiment      FLOAT,
  sentiment_conf FLOAT,
  processed      BOOLEAN DEFAULT FALSE
);

-- Per-topic per-day signal aggregates. data_quality gates thesis screener.
CREATE TABLE daily_signals (
  id              SERIAL PRIMARY KEY,
  date            DATE NOT NULL,
  topic           VARCHAR(64) NOT NULL,
  article_count   INTEGER,
  velocity_7d     FLOAT,
  sentiment_avg   FLOAT,
  sentiment_std   FLOAT,
  source_count    INTEGER,
  divergence_flag BOOLEAN,
  anomaly_flag    BOOLEAN,
  data_quality    TEXT DEFAULT 'ok' CHECK (data_quality IN ('ok', 'velocity_cold_start', 'insufficient_data'))
);

CREATE INDEX idx_daily_signals_date_topic ON daily_signals (date, topic);
CREATE INDEX idx_daily_signals_data_quality ON daily_signals (data_quality);

-- Market series (yfinance, FRED, ECB SDW).
CREATE TABLE market_data (
  id           SERIAL PRIMARY KEY,
  date         DATE NOT NULL,
  series_id    VARCHAR(64) NOT NULL,
  value        FLOAT,
  daily_chg    FLOAT,
  pct_chg      FLOAT,
  source       VARCHAR(32) NOT NULL
);

CREATE INDEX idx_market_data_date_series ON market_data (date, series_id);

-- Generated theses (Claude API). confidence is computed programmatically.
CREATE TABLE theses (
  id             SERIAL PRIMARY KEY,
  thesis_id      VARCHAR(16) NOT NULL,
  generated_at   TIMESTAMPTZ NOT NULL,
  theme          VARCHAR(128),
  hypothesis     TEXT,
  full_doc       TEXT,
  instruments    JSONB,
  signals_used   JSONB,
  confidence     FLOAT,
  status         VARCHAR(16),
  outcome        VARCHAR(16),
  closed_at      TIMESTAMPTZ,
  notes          TEXT
);

CREATE INDEX idx_theses_status ON theses (status);
CREATE INDEX idx_theses_generated_at ON theses (generated_at);

-- Asset universe registry. Seeded from config/universe.yaml.
CREATE TABLE instruments (
  id               VARCHAR(32) PRIMARY KEY,
  name             TEXT,
  asset_class      VARCHAR(32),
  sub_type         VARCHAR(32),
  geography        TEXT[],
  sectors          TEXT[],
  themes           TEXT[],
  risk_profile     VARCHAR(16),
  liquidity        VARCHAR(16),
  yfinance_ticker  VARCHAR(16),
  fred_series_id   VARCHAR(32),
  correlates_with  TEXT[],
  thesis_role      TEXT[],
  tradeable_via    TEXT[]
);

-- Rolling Spearman correlations: topic × series × lag.
CREATE TABLE correlations (
  id           SERIAL PRIMARY KEY,
  topic        VARCHAR(64) NOT NULL,
  series_id    VARCHAR(64) NOT NULL,
  lag_days     INTEGER NOT NULL,
  correlation  FLOAT,
  p_value      FLOAT,
  window_days  INTEGER,
  computed_at  DATE NOT NULL,
  quality      VARCHAR(16) DEFAULT 'ok'
);

CREATE INDEX idx_correlations_topic_series ON correlations (topic, series_id);

-- Regime indicators snapshot (one row per date).
CREATE TABLE IF NOT EXISTS regime_snapshots (
  id              SERIAL PRIMARY KEY,
  date            DATE UNIQUE,
  growth_pulse    VARCHAR(20),
  credit_stress   VARCHAR(20),
  real_yield      VARCHAR(20),
  dollar_strength VARCHAR(20),
  rates_vol       VARCHAR(20),
  equity_vol      VARCHAR(20),
  curve_shape     VARCHAR(20),
  fingerprint     TEXT,
  computed_at     TIMESTAMPTZ DEFAULT NOW()
);

-- Detected anomalies (velocity, sentiment_divergence, cross_asset_dislocation).
CREATE TABLE anomalies (
  id             SERIAL PRIMARY KEY,
  detected_at    TIMESTAMPTZ NOT NULL,
  anomaly_type   VARCHAR(32) NOT NULL,
  topic          VARCHAR(64),
  series_id      VARCHAR(64),
  severity       FLOAT,
  description    TEXT,
  resolved       BOOLEAN DEFAULT FALSE
);

-- Per-source pipeline errors. One failing source must not abort the run.
CREATE TABLE pipeline_errors (
  id           SERIAL PRIMARY KEY,
  source_id    VARCHAR(64) NOT NULL,
  error_type   VARCHAR(64),
  error_msg    TEXT,
  timestamp    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_pipeline_errors_source_id ON pipeline_errors (source_id);

-- CFTC Commitment of Traders positioning. crowding_flag = >90th or <10th percentile.
CREATE TABLE positioning_signals (
  id             SERIAL PRIMARY KEY,
  date           DATE NOT NULL,
  series_id      VARCHAR(64) NOT NULL,
  net_spec       FLOAT,
  percentile_52w FLOAT,
  crowding_flag  BOOLEAN,
  direction      VARCHAR(8),
  computed_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_positioning_signals_date_series ON positioning_signals (date, series_id);
