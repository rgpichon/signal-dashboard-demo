"""
One-time migration: create thesis_variable_history table.
Run: python3 signals/thesis_engine/create_variable_history.py
"""

from signals.db.connection import get_connection


def run():
    with get_connection() as conn:
        cur = conn.cursor()

        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS
            thesis_variable_history (
                id               SERIAL PRIMARY KEY,
                thesis_id        UUID REFERENCES
                                 research_theses(id)
                                 ON DELETE CASCADE,
                focal_series_id  VARCHAR(50) NOT NULL,
                target_series_id VARCHAR(50) NOT NULL,
                stance           VARCHAR(20) NOT NULL,
                regime_fingerprint TEXT,
                addressed_at     TIMESTAMPTZ DEFAULT NOW()
            )
            """
        )

        cur.execute(
            """
            CREATE INDEX IF NOT EXISTS idx_tvh_focal
            ON thesis_variable_history(focal_series_id)
            """
        )
        cur.execute(
            """
            CREATE INDEX IF NOT EXISTS idx_tvh_target
            ON thesis_variable_history(target_series_id)
            """
        )

        cur.execute(
            """
            SELECT EXISTS (
                SELECT FROM information_schema.tables
                WHERE table_name =
                'thesis_variable_history'
            )
            """
        )
        print("thesis_variable_history created:", cur.fetchone()[0])

        cur.close()


if __name__ == "__main__":
    run()
