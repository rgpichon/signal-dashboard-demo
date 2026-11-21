-- 008_universe_expansion.sql
-- Extends instruments table and adds factor decomposition cache.
-- Safe to re-run (uses IF NOT EXISTS and IF NOT EXISTS for columns).

ALTER TABLE instruments
    ADD COLUMN IF NOT EXISTS sector        TEXT,
    ADD COLUMN IF NOT EXISTS country       TEXT DEFAULT 'US',
    ADD COLUMN IF NOT EXISTS market_cap    TEXT,
    ADD COLUMN IF NOT EXISTS currency      TEXT DEFAULT 'USD',
    ADD COLUMN IF NOT EXISTS index_member  TEXT[] DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS is_active     BOOLEAN DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS last_synced   TIMESTAMPTZ;

CREATE TABLE IF NOT EXISTS factor_decomposition_cache (
    instrument_id   TEXT PRIMARY KEY,
    decomposition   JSONB NOT NULL,
    computed_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at      TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_factor_decomp_cache_expires
    ON factor_decomposition_cache(expires_at);
