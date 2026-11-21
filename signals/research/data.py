"""
Bulk data helpers: aligned series and returns from market_data.
"""
from datetime import date, timedelta
from typing import Any

import pandas as pd


def get_aligned_returns(conn, series_ids: list[str], days: int):
    """
    Pull pct_chg from market_data for each series_id. Inner join on date.
    Return DataFrame with date index, columns = series_ids. Drop rows where ANY column is null.
    """
    if not series_ids:
        return None
    days = min(max(1, days), 365)
    cur = conn.cursor()
    try:
        end = date.today()
        start = end - timedelta(days=days + 30)
        out = None
        for sid in series_ids:
            cur.execute(
                """
                SELECT date, pct_chg FROM market_data
                WHERE series_id = %s AND date >= %s AND date <= %s
                ORDER BY date
                """,
                (sid, start, end),
            )
            rows = cur.fetchall()
            if not rows:
                continue
            df = pd.DataFrame(rows, columns=["date", sid])
            df["date"] = pd.to_datetime(df["date"])
            df = df.set_index("date")
            if out is None:
                out = df
            else:
                out = out.join(df, how="inner")
        if out is None or out.empty:
            return None
        out = out.dropna(how="any")
        out = out.sort_index().tail(days)
        return out
    finally:
        cur.close()


def get_series_bulk(conn, series_ids: list[str], days: int) -> dict[str, Any]:
    """
    Pull value and pct_chg for each series_id. Align on common dates.
    Return dict: series, common_dates, date_range, missing_series.
    """
    days = min(max(1, days), 365)
    cur = conn.cursor()
    try:
        end = date.today()
        start = end - timedelta(days=days + 30)
        by_series = {}
        all_dates = set()
        for sid in series_ids:
            cur.execute(
                """
                SELECT date, value, pct_chg FROM market_data
                WHERE series_id = %s AND date >= %s AND date <= %s
                ORDER BY date
                """,
                (sid, start, end),
            )
            rows = cur.fetchall()
            if not rows:
                continue
            by_series[sid] = [(r[0], float(r[1]) if r[1] is not None else None, float(r[2]) if r[2] is not None else None) for r in rows]
            all_dates.update(r[0] for r in rows)
        if not by_series:
            return {
                "series": {},
                "common_dates": 0,
                "date_range": {"from": None, "to": None},
                "missing_series": list(series_ids),
            }
        common = set.intersection(*(set(d[0] for d in by_series[sid]) for sid in by_series))
        common = sorted(common)
        if not common:
            return {
                "series": {sid: [] for sid in by_series},
                "common_dates": 0,
                "date_range": {"from": None, "to": None},
                "missing_series": [s for s in series_ids if s not in by_series],
            }
        date_set = set(common)
        series_out = {}
        for sid in series_ids:
            if sid not in by_series:
                continue
            by_date = {d[0]: (d[1], d[2]) for d in by_series[sid]}
            list_out = [
                {"date": str(d), "value": round(by_date[d][0], 4) if by_date[d][0] is not None else None, "pct_chg": round(by_date[d][1], 2) if by_date[d][1] is not None else None}
                for d in common if d in by_date
            ]
            series_out[sid] = list_out
        missing = [s for s in series_ids if s not in series_out]
        return {
            "series": series_out,
            "common_dates": len(common),
            "date_range": {"from": str(common[0]), "to": str(common[-1])},
            "missing_series": missing,
        }
    finally:
        cur.close()
