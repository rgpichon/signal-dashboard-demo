"""
One-time migration: create thesis outcome tracking tables.
Run: python3 signals/thesis_engine/create_outcome_tables.py
"""

from signals.db.connection import get_connection


def run():
    with get_connection() as conn:
        cur = conn.cursor()

        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS
            thesis_outcome_paths (
                id                  SERIAL PRIMARY KEY,
                thesis_id           UUID NOT NULL
                                    REFERENCES research_theses(id)
                                    ON DELETE CASCADE,
                series_id           VARCHAR(50) NOT NULL,
                predicted_move_pct  FLOAT,
                predicted_direction VARCHAR(10),
                horizon_days        INTEGER,
                thesis_created_at   TIMESTAMPTZ,
                current_move_pct    FLOAT,
                max_favourable_pct  FLOAT,
                max_adverse_pct     FLOAT,
                correct_at_30pct    BOOLEAN,
                correct_at_60pct    BOOLEAN,
                correct_at_100pct   BOOLEAN,
                target_reached      BOOLEAN DEFAULT FALSE,
                target_reached_at   TIMESTAMPTZ,
                status              VARCHAR(20)
                                    DEFAULT 'active',
                last_updated        TIMESTAMPTZ
                                    DEFAULT NOW(),
                UNIQUE (thesis_id, series_id)
            )
            """
        )

        cur.execute(
            """
            CREATE INDEX IF NOT EXISTS idx_top_thesis
            ON thesis_outcome_paths(thesis_id)
            """
        )
        cur.execute(
            """
            CREATE INDEX IF NOT EXISTS idx_top_status
            ON thesis_outcome_paths(status)
            """
        )

        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS
            thesis_track_record (
                id                      SERIAL PRIMARY KEY,
                computed_at             TIMESTAMPTZ
                                        DEFAULT NOW(),
                total_theses_tracked    INTEGER DEFAULT 0,
                total_variables_tracked INTEGER DEFAULT 0,
                direction_acc_30pct     FLOAT,
                direction_acc_60pct     FLOAT,
                direction_acc_100pct    FLOAT,
                avg_magnitude_ratio     FLOAT,
                magnitude_ratio_p25     FLOAT,
                magnitude_ratio_p75     FLOAT,
                by_asset_class          JSONB,
                by_focal_series         JSONB
            )
            """
        )

        conn.commit()

        for table in ["thesis_outcome_paths", "thesis_track_record"]:
            cur.execute(
                """
                SELECT EXISTS (
                    SELECT FROM information_schema.tables
                    WHERE table_name = %s
                )
                """,
                (table,),
            )
            print(f"{table}: {cur.fetchone()[0]}")

        cur.close()


if __name__ == "__main__":
    run()
