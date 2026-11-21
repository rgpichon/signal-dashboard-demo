"""
One-time migration: replace raw FRED series_id in market_data with canonical ids.
Run from repo root: PYTHONPATH=. python signals/db/migrate_series_ids.py
Idempotent — safe to run multiple times.
"""
import sys

from signals.db.connection import get_connection
from signals.ingestion.series_mapping import FRED_TO_CANONICAL


def main() -> None:
    with get_connection() as conn:
        cur = conn.cursor()
        total_migrated = 0
        for raw, canonical in FRED_TO_CANONICAL.items():
            cur.execute(
                "UPDATE market_data SET series_id = %s WHERE series_id = %s",
                (canonical, raw),
            )
            n = cur.rowcount
            if n:
                print(f"Migrated {n} rows: {raw} → {canonical}")
                total_migrated += n
        cur.close()
    print(f"Total migrated: {total_migrated} rows.")
    if total_migrated == 0:
        print("(No rows to migrate — already canonical or no matching data.)")


if __name__ == "__main__":
    main()
    sys.exit(0)
