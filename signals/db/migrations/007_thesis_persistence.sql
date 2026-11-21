-- 007_thesis_persistence.sql
-- Creates research_theses and research_thesis_versions tables for the
-- Spec 7 thesis editor persistence feature.
-- The existing theses table (Claude-generated thesis tracker) is not touched.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS research_theses (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title           TEXT NOT NULL DEFAULT 'Untitled Thesis',
    content_html    TEXT NOT NULL DEFAULT '',
    tags            TEXT[] NOT NULL DEFAULT '{}',
    status          TEXT NOT NULL DEFAULT 'draft'
                    CHECK (status IN ('draft', 'active', 'archived')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_auto_saved TIMESTAMPTZ,
    metadata        JSONB NOT NULL DEFAULT '{}'
);

CREATE TABLE IF NOT EXISTS research_thesis_versions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thesis_id       UUID NOT NULL REFERENCES research_theses(id) ON DELETE CASCADE,
    version_number  INTEGER NOT NULL,
    version_label   TEXT,
    content_html    TEXT NOT NULL,
    metadata        JSONB NOT NULL DEFAULT '{}',
    tags            TEXT[] NOT NULL DEFAULT '{}',
    status          TEXT NOT NULL DEFAULT 'draft',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_by      TEXT DEFAULT 'user',
    is_auto_save    BOOLEAN NOT NULL DEFAULT FALSE,
    UNIQUE (thesis_id, version_number)
);

CREATE INDEX IF NOT EXISTS idx_research_thesis_versions_thesis_id
    ON research_thesis_versions(thesis_id);

CREATE INDEX IF NOT EXISTS idx_research_theses_status
    ON research_theses(status);

CREATE INDEX IF NOT EXISTS idx_research_theses_updated_at
    ON research_theses(updated_at DESC);
