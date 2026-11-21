"""
One-time migration: add dual-horizon percentile columns
to regime_snapshots.
Run once: python3 signals/analytics/migrate_regime_pct.py
"""
from signals.db.connection import get_connection

INDICATORS = [
    "growth_pulse",
    "credit_stress",
    "real_yield",
    "dollar_strength",
    "rates_vol",
    "equity_vol",
    "curve_shape",
]


def run() -> None:
    with get_connection() as conn:
        cur = conn.cursor()
        for ind in INDICATORS:
            for horizon in ("90d", "756d"):
                col = f"{ind}_pct_{horizon}"
                cur.execute(
                    f"""
                    ALTER TABLE regime_snapshots
                    ADD COLUMN IF NOT EXISTS {col} SMALLINT
                    """
                )
        cur.close()
    print(f"Added {len(INDICATORS) * 2} columns (IF NOT EXISTS)")

    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute(
            """
            SELECT column_name FROM information_schema.columns
            WHERE table_name = 'regime_snapshots'
            ORDER BY ordinal_position
            """
        )
        cols = [r[0] for r in cur.fetchall()]
        pct_cols = [c for c in cols if "_pct_" in c]
        print(f"Percentile columns now in table: {len(pct_cols)}")
        for c in pct_cols:
            print(" ", c)
        cur.close()


if __name__ == "__main__":
    run()
