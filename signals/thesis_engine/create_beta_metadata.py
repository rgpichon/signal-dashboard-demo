"""
One-time migration: create beta_metadata table.
Run once: python3 signals/thesis_engine/create_beta_metadata.py
"""
from signals.db.connection import get_connection


def run() -> None:
    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS beta_metadata (
                id               SERIAL PRIMARY KEY,
                base_series_id   VARCHAR(50) NOT NULL,
                target_series_id VARCHAR(50) NOT NULL,
                optimal_decay    FLOAT,
                break_date       DATE,
                break_detected   BOOLEAN DEFAULT FALSE,
                last_computed    TIMESTAMPTZ DEFAULT NOW(),
                UNIQUE (base_series_id, target_series_id)
            )
            """
        )
        cur.execute(
            """
            CREATE INDEX IF NOT EXISTS idx_bm_base
            ON beta_metadata(base_series_id)
            """
        )
        cur.close()

    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute(
            """
            SELECT EXISTS (
                SELECT FROM information_schema.tables
                WHERE table_name = 'beta_metadata'
            )
            """
        )
        print("beta_metadata created:", cur.fetchone()[0])
        cur.close()


if __name__ == "__main__":
    run()
