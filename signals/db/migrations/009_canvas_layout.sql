-- 009_canvas_layout.sql
-- Adds canvas_layout column to research_theses and research_thesis_versions.
-- Safe to re-run (IF NOT EXISTS). Part of SIGNAL Migration Plan Phase 0.

ALTER TABLE research_theses
    ADD COLUMN IF NOT EXISTS canvas_layout JSONB DEFAULT NULL;

ALTER TABLE research_thesis_versions
    ADD COLUMN IF NOT EXISTS canvas_layout JSONB DEFAULT NULL;
