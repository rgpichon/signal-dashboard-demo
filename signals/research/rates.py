"""
Yield curve, spreads, rates decomposition.
"""
from datetime import date, timedelta
from typing import Any

MIN_OBS = 30

TENORS = [
    ("3M", "RATES.US3M"),
    ("2Y", "RATES.US2Y"),
    ("5Y", "RATES.US5Y"),
    ("10Y", "RATES.US10Y"),
    ("30Y", "RATES.US30Y"),
]


def _curve_for_date(cur, target_date: str) -> list[dict]:
    """Return curve as list of {tenor, series_id, yield} for one date."""
    curve = []
    for tenor, sid in TENORS:
        cur.execute(
            "SELECT value FROM market_data WHERE series_id = %s AND date = %s",
            (sid, target_date),
        )
        row = cur.fetchone()
        y = round(float(row[0]), 4) if row and row[0] is not None else None
        curve.append({"tenor": tenor, "series_id": sid, "yield": y})
    return curve


def _nearest_date_before(cur, before_date: str) -> str | None:
    cur.execute(
        "SELECT date FROM market_data WHERE date <= %s ORDER BY date DESC LIMIT 1",
        (before_date,),
    )
    row = cur.fetchone()
    return str(row[0]) if row and row[0] else None


def compute_yield_curve(
    conn, target_date: str | None = "latest", compare_dates: str | None = None
) -> dict[str, Any]:
    cur = conn.cursor()
    try:
        if target_date == "latest" or not target_date:
            series_ids = [sid for _, sid in TENORS]
            sub = " INTERSECT ".join(["SELECT date FROM market_data WHERE series_id = %s"] * len(series_ids))
            cur.execute(f"SELECT MAX(date) FROM ({sub}) t", tuple(series_ids))
            row = cur.fetchone()
            target_date = str(row[0]) if row and row[0] else date.today().isoformat()
        curve = _curve_for_date(cur, target_date)
        yields_by_tenor = {c["tenor"]: c["yield"] for c in curve if c["yield"] is not None}
        us2y = yields_by_tenor.get("2Y")
        us10y = yields_by_tenor.get("10Y")
        us5y = yields_by_tenor.get("5Y")
        us30y = yields_by_tenor.get("30Y")
        spread_2s10s = round(us10y - us2y, 4) if us10y is not None and us2y is not None else None
        spread_5s30s = round(us30y - us5y, 4) if us30y is not None and us5y is not None else None
        if spread_2s10s is not None:
            if spread_2s10s < -0.10:
                curve_shape = "inverted"
            elif abs(spread_2s10s) <= 0.10:
                curve_shape = "flat"
            else:
                curve_shape = "normal"
        else:
            curve_shape = "unknown"
        spreads = {"2s10s": spread_2s10s, "5s30s": spread_5s30s, "curve_shape": curve_shape}

        approx_1m_ago = (date.fromisoformat(target_date) - timedelta(days=21)).isoformat()
        cur.execute(
            "SELECT date FROM market_data WHERE date <= %s ORDER BY date DESC LIMIT 1",
            (approx_1m_ago,),
        )
        row = cur.fetchone()
        date_1m = str(row[0]) if row and row[0] else None
        vs_1m_ago = []
        if date_1m:
            for tenor, sid in TENORS:
                cur.execute("SELECT value FROM market_data WHERE series_id = %s AND date = %s", (sid, date_1m))
                r1 = cur.fetchone()
                cur.execute("SELECT value FROM market_data WHERE series_id = %s AND date = %s", (sid, target_date))
                r2 = cur.fetchone()
                if r1 and r2 and r1[0] is not None and r2[0] is not None:
                    chg_bps = round((float(r2[0]) - float(r1[0])) * 100, 0)
                    vs_1m_ago.append({"tenor": tenor, "change_bps": int(chg_bps)})

        bps = int(round(spread_2s10s * 100, 0)) if spread_2s10s is not None else None
        interpretation = (
            f"Curve is {curve_shape} (2s10s={bps}bps). "
            if bps is not None
            else "Insufficient data for curve shape."
        )
        out = {
            "date": target_date,
            "curve": curve,
            "spreads": spreads,
            "vs_1m_ago": vs_1m_ago,
            "interpretation": interpretation,
        }
        if compare_dates and "1m" in compare_dates.lower():
            approx_1m = (date.fromisoformat(target_date) - timedelta(days=21)).isoformat()
            date_1m = _nearest_date_before(cur, approx_1m)
            out["one_month_ago"] = _curve_for_date(cur, date_1m) if date_1m else []
        if compare_dates and "3m" in compare_dates.lower():
            approx_3m = (date.fromisoformat(target_date) - timedelta(days=63)).isoformat()
            date_3m = _nearest_date_before(cur, approx_3m)
            out["three_months_ago"] = _curve_for_date(cur, date_3m) if date_3m else []
        return out
    finally:
        cur.close()


def compute_yield_curve_history(conn, days: int) -> dict[str, Any]:
    cur = conn.cursor()
    try:
        end = date.today()
        start = end - timedelta(days=days + 30)
        series_ids = [
            "RATES.2S10S",
            "RATES.5S30S",
            "RATES.REAL10Y",
            "CREDIT.IG_OAS",
            "CREDIT.HY_OAS",
        ]
        out = {}
        for sid in series_ids:
            cur.execute(
                "SELECT date, value FROM market_data WHERE series_id = %s AND date >= %s AND date <= %s ORDER BY date",
                (sid, start, end),
            )
            rows = cur.fetchall()
            out[sid] = [{"date": str(r[0]), "value": round(float(r[1]), 4)} for r in rows]
        return {"series": out}
    finally:
        cur.close()


def compute_rates_decomposition(conn, days: int) -> dict[str, Any]:
    cur = conn.cursor()
    try:
        end = date.today()
        start = end - timedelta(days=days + 30)
        cur.execute(
            "SELECT date, value FROM market_data WHERE series_id = 'RATES.US10Y' AND date >= %s AND date <= %s ORDER BY date",
            (start, end),
        )
        nom = {str(r[0]): float(r[1]) for r in cur.fetchall()}
        cur.execute(
            "SELECT date, value FROM market_data WHERE series_id = 'RATES.REAL10Y' AND date >= %s AND date <= %s ORDER BY date",
            (start, end),
        )
        real = {str(r[0]): float(r[1]) for r in cur.fetchall()}
        cur.execute(
            "SELECT date, value FROM market_data WHERE series_id = 'RATES.BREAKEVEN' AND date >= %s AND date <= %s ORDER BY date",
            (start, end),
        )
        breakeven = {str(r[0]): float(r[1]) for r in cur.fetchall()}
        common = sorted(set(nom.keys()) & set(real.keys()) & set(breakeven.keys()))
        if not common:
            return {"error": "insufficient_data", "available": 0, "required": MIN_OBS}
        history = []
        for d in common:
            n = nom[d]
            r = real[d]
            b = breakeven[d]
            history.append({"date": d, "nominal": round(n, 4), "real": round(r, 4), "breakeven": round(b, 4)})
        latest = history[-1]
        nominal_10y = latest["nominal"]
        real_yield_10y = latest["real"]
        breakeven_inflation = latest["breakeven"]
        real_90 = [history[i]["real"] for i in range(max(0, len(history) - 90), len(history))]
        real_median = (sorted(real_90)[len(real_90) // 2] if real_90 else real_yield_10y)
        if real_yield_10y > real_median * 1.05:
            real_regime = "ELEVATED"
        elif real_yield_10y < real_median * 0.95:
            real_regime = "SUPPRESSED"
        else:
            real_regime = "NORMAL"
        interpretation = (
            f"10Y yield of {nominal_10y}% = {real_yield_10y}% real + {breakeven_inflation}% inflation expectations. "
            f"Real yields are {real_regime} relative to 90d history."
        )
        return {
            "date": common[-1],
            "nominal_10y": nominal_10y,
            "real_yield_10y": real_yield_10y,
            "breakeven_inflation": breakeven_inflation,
            "decomposition": {"real_yield_contribution": real_yield_10y, "inflation_expectations": breakeven_inflation},
            "history": history,
            "interpretation": interpretation,
        }
    finally:
        cur.close()
