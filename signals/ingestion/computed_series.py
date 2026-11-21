"""
Computed series derived after FRED and yfinance pulls.
Inserts into market_data with source='computed'. Deduplicates on (date, series_id).
Run after ingestion in pipeline.
"""
import logging
from datetime import date
from typing import Any

logger = logging.getLogger("signals.ingestion")


def _get_series_by_date(conn, series_id: str) -> dict[date, float]:
    """Return {date: value} for series_id from market_data."""
    cur = conn.cursor()
    try:
        cur.execute(
            "SELECT date, value FROM market_data WHERE series_id = %s ORDER BY date",
            (series_id,),
        )
        return {row[0]: float(row[1]) for row in cur.fetchall()}
    finally:
        cur.close()


def _upsert_computed(conn, series_id: str, rows: list[dict[str, Any]]) -> int:
    """Insert market_data rows for computed series; skip if (date, series_id) exists. Returns count inserted."""
    if not rows:
        return 0
    cur = conn.cursor()
    total = 0
    try:
        for r in rows:
            dt, val = r["date"], r["value"]
            daily_chg = r.get("daily_chg")
            pct_chg = r.get("pct_chg")
            cur.execute(
                """
                INSERT INTO market_data (date, series_id, value, daily_chg, pct_chg, source)
                SELECT %s, %s, %s, %s, %s, 'computed'
                WHERE NOT EXISTS (SELECT 1 FROM market_data WHERE date = %s AND series_id = %s)
                """,
                (dt, series_id, val, daily_chg, pct_chg, dt, series_id),
            )
            if cur.rowcount:
                total += 1
    finally:
        cur.close()
    return total


def _compute_ig_hy_diff(conn) -> int:
    """CREDIT.IG_HY_DIFF = CREDIT.HY_OAS - CREDIT.IG_OAS. Only when both have row for same date."""
    hy = _get_series_by_date(conn, "CREDIT.HY_OAS")
    ig = _get_series_by_date(conn, "CREDIT.IG_OAS")
    common_dates = sorted(set(hy.keys()) & set(ig.keys()))
    rows = [{"date": d, "value": hy[d] - ig[d], "daily_chg": None, "pct_chg": None} for d in common_dates]
    if len(rows) > 1:
        for i in range(1, len(rows)):
            prev_val = rows[i - 1]["value"]
            curr_val = rows[i]["value"]
            rows[i]["daily_chg"] = curr_val - prev_val
            rows[i]["pct_chg"] = (100.0 * (curr_val - prev_val) / prev_val) if prev_val and prev_val != 0 else None
    return _upsert_computed(conn, "CREDIT.IG_HY_DIFF", rows)


def _compute_copper_gold_ratio(conn) -> int:
    """CM.COPPER_GOLD_RATIO = CM.COPPER / CM.GOLD. daily_chg and pct_chg from ratio change."""
    copper = _get_series_by_date(conn, "CM.COPPER")
    gold = _get_series_by_date(conn, "CM.GOLD")
    common_dates = sorted(set(copper.keys()) & set(gold.keys()))
    rows = []
    for i, d in enumerate(common_dates):
        g = gold[d]
        if not g or g == 0:
            continue
        ratio = copper[d] / g
        daily_chg = None
        pct_chg = None
        if i > 0:
            prev_ratio = copper[common_dates[i - 1]] / gold[common_dates[i - 1]] if gold[common_dates[i - 1]] else None
            if prev_ratio and prev_ratio != 0:
                daily_chg = ratio - prev_ratio
                pct_chg = 100.0 * (ratio / prev_ratio - 1)
        rows.append({"date": d, "value": ratio, "daily_chg": daily_chg, "pct_chg": pct_chg})
    return _upsert_computed(conn, "CM.COPPER_GOLD_RATIO", rows)


def _compute_5s30s(conn) -> int:
    """RATES.5S30S = RATES.US30Y - RATES.US5Y. Only when both have row for same date."""
    us30 = _get_series_by_date(conn, "RATES.US30Y")
    us5 = _get_series_by_date(conn, "RATES.US5Y")
    common_dates = sorted(set(us30.keys()) & set(us5.keys()))
    rows = [{"date": d, "value": us30[d] - us5[d], "daily_chg": None, "pct_chg": None} for d in common_dates]
    if len(rows) > 1:
        for i in range(1, len(rows)):
            prev_val = rows[i - 1]["value"]
            curr_val = rows[i]["value"]
            rows[i]["daily_chg"] = curr_val - prev_val
            rows[i]["pct_chg"] = (100.0 * (curr_val - prev_val) / prev_val) if prev_val and prev_val != 0 else None
    return _upsert_computed(conn, "RATES.5S30S", rows)


def _compute_real_term_prem(conn) -> int:
    """RATES.REAL_TERM_PREM = RATES.US10Y - RATES.REAL10Y - RATES.BREAKEVEN. Only when all three available."""
    us10 = _get_series_by_date(conn, "RATES.US10Y")
    real10 = _get_series_by_date(conn, "RATES.REAL10Y")
    breakeven = _get_series_by_date(conn, "RATES.BREAKEVEN")
    common_dates = sorted(set(us10.keys()) & set(real10.keys()) & set(breakeven.keys()))
    rows = [
        {
            "date": d,
            "value": us10[d] - real10[d] - breakeven[d],
            "daily_chg": None,
            "pct_chg": None,
        }
        for d in common_dates
    ]
    if len(rows) > 1:
        for i in range(1, len(rows)):
            prev_val = rows[i - 1]["value"]
            curr_val = rows[i]["value"]
            rows[i]["daily_chg"] = curr_val - prev_val
            rows[i]["pct_chg"] = (100.0 * (curr_val - prev_val) / prev_val) if prev_val and prev_val != 0 else None
    return _upsert_computed(conn, "RATES.REAL_TERM_PREM", rows)


def run_computed_series(conn) -> int:
    """
    Derive CREDIT.IG_HY_DIFF, CM.COPPER_GOLD_RATIO, RATES.5S30S, RATES.REAL_TERM_PREM from market_data.
    Call after FRED and yfinance ingestion. Returns total rows inserted/updated.
    """
    total = 0
    try:
        n = _compute_5s30s(conn)
        total += n
        logger.info("Computed RATES.5S30S: %s rows", n)
    except Exception as e:
        logger.warning("Computed RATES.5S30S failed: %s", e)
    try:
        n = _compute_ig_hy_diff(conn)
        total += n
        logger.info("Computed CREDIT.IG_HY_DIFF: %s rows", n)
    except Exception as e:
        logger.warning("Computed CREDIT.IG_HY_DIFF failed: %s", e)
    try:
        n = _compute_copper_gold_ratio(conn)
        total += n
        logger.info("Computed CM.COPPER_GOLD_RATIO: %s rows", n)
    except Exception as e:
        logger.warning("Computed CM.COPPER_GOLD_RATIO failed: %s", e)
    try:
        n = _compute_real_term_prem(conn)
        total += n
        logger.info("Computed RATES.REAL_TERM_PREM: %s rows", n)
    except Exception as e:
        logger.warning("Computed RATES.REAL_TERM_PREM failed: %s", e)
    return total
