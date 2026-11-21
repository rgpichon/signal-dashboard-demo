"""
Impact analysis: OLS of target returns on base returns, HC3 robust errors.
"""
from typing import Any

import numpy as np
import pandas as pd
import statsmodels.api as sm

from signals.research.data import get_aligned_returns

MIN_OBS = 30


def _get_instrument_name(conn, series_id: str) -> str:
    cur = conn.cursor()
    try:
        cur.execute("SELECT name FROM instruments WHERE id = %s", (series_id,))
        row = cur.fetchone()
        return (row[0] or series_id) if row else series_id
    finally:
        cur.close()


def compute_impact(
    conn,
    base_series: str,
    target_series_list: list[str],
    shock_pct: float,
    days: int,
    shock_bps: float | None = None,
) -> dict[str, Any]:
    if shock_bps is not None:
        cur = conn.cursor()
        try:
            cur.execute(
                "SELECT value FROM market_data WHERE series_id = %s ORDER BY date DESC LIMIT 1",
                (base_series,),
            )
            row = cur.fetchone()
            if row and row[0] and float(row[0]) != 0:
                shock_pct = (shock_bps / 10000.0) / float(row[0]) * 100.0
        finally:
            cur.close()

    series_ids = [base_series] + list(target_series_list)
    df = get_aligned_returns(conn, series_ids, days)
    if df is None or df.empty or len(df) < MIN_OBS:
        return {"error": "insufficient_data", "available": len(df) if df is not None else 0, "required": MIN_OBS}
    df = df.dropna(how="any")
    if len(df) < MIN_OBS:
        return {"error": "insufficient_data", "available": len(df), "required": MIN_OBS}

    base_col = base_series
    if base_col not in df.columns:
        return {"error": "insufficient_data", "available": 0, "required": MIN_OBS}

    impacts = []
    for target in target_series_list:
        if target not in df.columns:
            continue
        y = df[target].values
        X = sm.add_constant(df[base_col].values)
        model = sm.OLS(y, X).fit(cov_type="HC3")
        beta = float(model.params[1])
        bse = float(model.bse[1])
        n = int(model.nobs)
        r2 = float(model.rsquared)
        p_val = float(model.pvalues[1])
        t_stat = float(model.tvalues[1])
        predicted_move_pct = round(beta * shock_pct, 2)
        half_width = 1.96 * bse * abs(shock_pct)
        ci_95_low = round(predicted_move_pct - half_width, 2)
        ci_95_high = round(predicted_move_pct + half_width, 2)

        base_pct = df[base_col].values
        big_move_dates = np.where(np.abs(base_pct) > abs(shock_pct) / 2)[0]
        if len(big_move_dates) > 0:
            target_moves = y[big_move_dates]
            historical_median_move = round(float(np.median(target_moves)), 2)
            historical_n_events = len(big_move_dates)
        else:
            historical_median_move = None
            historical_n_events = 0

        interpretation = (
            f"When {base_series} moves {shock_pct}%, {target} historically "
            f"moves {predicted_move_pct}% (R²={r2:.2f}, p={p_val:.3f}, n={n})"
        )
        name = _get_instrument_name(conn, target)
        impacts.append({
            "series_id": target,
            "name": name,
            "beta": round(beta, 4),
            "predicted_move_pct": predicted_move_pct,
            "ci_95_low": ci_95_low,
            "ci_95_high": ci_95_high,
            "r_squared": round(r2, 4),
            "p_value": round(p_val, 4),
            "t_stat": round(t_stat, 4),
            "observations": n,
            "historical_median_move": historical_median_move,
            "historical_n_events": historical_n_events,
            "interpretation": interpretation,
        })

    return {
        "base": base_series,
        "shock_pct": round(shock_pct, 2),
        "impacts": impacts,
        "methodology": "OLS regression of daily pct returns, HC3 robust standard errors",
    }
