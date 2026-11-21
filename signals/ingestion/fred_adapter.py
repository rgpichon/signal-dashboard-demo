"""
FRED API adapter. Fetches numeric series and writes to market_data only (not articles).
Uses canonical series_id via series_mapping. Skips gracefully if FRED_API_KEY is missing or empty.
"""
import logging
import os
from datetime import date, timedelta
from typing import List, Optional

import requests

from signals.ingestion.series_mapping import to_canonical

logger = logging.getLogger("signals.ingestion")

FRED_BASE = "https://api.stlouisfed.org/fred/series/observations"


def get_fred_api_key() -> Optional[str]:
    key = os.environ.get("FRED_API_KEY") or ""
    return key.strip() or None


def fetch_series(series_id: str, api_key: str, start: date, end: date) -> List[dict]:
    """Return list of {date, value} dicts."""
    params = {
        "series_id": series_id,
        "api_key": api_key,
        "file_type": "json",
        "observation_start": start.isoformat(),
        "observation_end": end.isoformat(),
    }
    resp = requests.get(FRED_BASE, params=params, timeout=30)
    resp.raise_for_status()
    data = resp.json()
    obs = data.get("observations", [])
    out = []
    for o in obs:
        try:
            v = o.get("value")
            if v in (None, "."):
                continue
            d = o.get("date")
            if not d:
                continue
            out.append({"date": d, "value": float(v)})
        except (TypeError, ValueError):
            continue
    return out


def _insert_fred_rows(conn, raw_series_id: str, rows: List[dict]) -> int:
    """Insert fetched FRED rows into market_data with canonical series_id; return count inserted."""
    if not rows:
        return 0
    series_id = to_canonical(raw_series_id)
    rows.sort(key=lambda x: x["date"])
    prev_value = None
    cur = conn.cursor()
    total_inserted = 0
    try:
        for r in rows:
            dt, val = r["date"], r["value"]
            daily_chg = (val - prev_value) if prev_value is not None else None
            pct_chg = (100.0 * (val - prev_value) / prev_value) if prev_value and prev_value != 0 else None
            cur.execute(
                """
                INSERT INTO market_data (date, series_id, value, daily_chg, pct_chg, source)
                SELECT %s, %s, %s, %s, %s, 'fred'
                WHERE NOT EXISTS (SELECT 1 FROM market_data WHERE date = %s AND series_id = %s)
                """,
                (dt, series_id, val, daily_chg, pct_chg, dt, series_id),
            )
            if cur.rowcount:
                total_inserted += 1
            prev_value = val
    finally:
        cur.close()
    return total_inserted


def run_fred_backfill(conn, series_ids: List[str], start: date, end: date) -> int:
    """
    Fetch each series from FRED for [start, end] and insert into market_data.
    Returns total rows inserted. Use for historical backfill (e.g. 90 days).
    """
    api_key = get_fred_api_key()
    if not api_key:
        logger.warning("FRED_API_KEY missing or empty; skipping FRED backfill")
        return 0
    total = 0
    for series_id in series_ids:
        try:
            rows = fetch_series(series_id, api_key, start, end)
            n = _insert_fred_rows(conn, series_id, rows)
            total += n
            logger.info("FRED backfill %s: %s rows", series_id, n)
        except Exception as e:
            logger.warning("FRED backfill failed for %s: %s", series_id, e)
    return total


def run_fred(conn, source_id: str, config: dict) -> int:
    """
    Fetch each series in config['series'], insert into market_data.
    Returns number of market_data rows inserted. Never raises.
    """
    api_key = get_fred_api_key()
    if not api_key:
        logger.warning("FRED_API_KEY missing or empty; skipping %s", source_id)
        try:
            cur = conn.cursor()
            cur.execute(
                "INSERT INTO pipeline_errors (source_id, error_type, error_msg) VALUES (%s, %s, %s)",
                (source_id, "config_error", "FRED_API_KEY missing or empty"),
            )
            cur.close()
        except Exception:
            pass
        return 0

    series_list = config.get("series") or []
    if not series_list:
        return 0

    end = date.today()
    start = end - timedelta(days=30)
    total_inserted = 0

    for series_id in series_list:
        try:
            rows = fetch_series(series_id, api_key, start, end)
        except Exception as e:
            logger.warning("FRED fetch failed for %s: %s", series_id, e)
            try:
                cur = conn.cursor()
                cur.execute(
                    "INSERT INTO pipeline_errors (source_id, error_type, error_msg) VALUES (%s, %s, %s)",
                    (source_id, "fetch_error", f"series {series_id}: {e}"),
                )
                cur.close()
            except Exception:
                pass
            continue

        if not rows:
            continue

        total_inserted += _insert_fred_rows(conn, series_id, rows)

    return total_inserted
