"""
Correlation matrix, rolling Spearman, lead-lag. Uses get_aligned_returns for aligned pct_chg.
"""
from typing import Any

import numpy as np
import pandas as pd
from scipy.stats import pearsonr, spearmanr

from signals.research.data import get_aligned_returns

MIN_OBS = 30


def compute_correlation_matrix(conn, series_ids: list[str], days: int) -> dict[str, Any]:
    df = get_aligned_returns(conn, series_ids, days)
    if df is None or df.empty:
        return {"error": "insufficient_data", "available": 0, "required": MIN_OBS}
    if len(df) < MIN_OBS:
        return {"error": "insufficient_data", "available": len(df), "required": MIN_OBS}
    df = df.dropna(how="any")
    if len(df) < MIN_OBS:
        return {"error": "insufficient_data", "available": len(df), "required": MIN_OBS}

    series = list(df.columns)
    n = len(df)
    corr = df.corr(method="pearson")
    matrix = corr.values.tolist()
    p_values = []
    for i, a in enumerate(series):
        row = []
        for j, b in enumerate(series):
            if i == j:
                row.append(0.0)
            else:
                _, p = pearsonr(df[a], df[b])
                row.append(round(float(p), 4))
        p_values.append(row)

    significant_pairs = []
    for i in range(len(series)):
        for j in range(i + 1, len(series)):
            r = matrix[i][j]
            p = p_values[i][j]
            if p < 0.05 and abs(r) > 0.3:
                interp = "Strong positive — move together" if r > 0 else "Strong negative — move opposite"
                significant_pairs.append({
                    "series_a": series[i],
                    "series_b": series[j],
                    "correlation": round(float(r), 4),
                    "p_value": round(float(p), 4),
                    "interpretation": f"{series[i]} vs {series[j]}: {interp}",
                })

    date_min = df.index.min()
    date_max = df.index.max()
    return {
        "series": series,
        "matrix": [[round(x, 4) for x in row] for row in matrix],
        "p_values": p_values,
        "observations": n,
        "date_range": {"from": str(date_min), "to": str(date_max)},
        "significant_pairs": significant_pairs,
    }


def compute_rolling_correlation(
    conn, series_a: str, series_b: str, window: int, days: int
) -> dict[str, Any]:
    need = days + window
    df = get_aligned_returns(conn, [series_a, series_b], need)
    if df is None or df.empty or len(df) < window:
        return {"error": "insufficient_data", "available": len(df) if df is not None else 0, "required": window}
    df = df.dropna(how="any")
    if len(df) < window:
        return {"error": "insufficient_data", "available": len(df), "required": window}

    rolling_list = []
    for i in range(window - 1, len(df)):
        slice_a = df[series_a].iloc[i - window + 1 : i + 1].values
        slice_b = df[series_b].iloc[i - window + 1 : i + 1].values
        r, _ = spearmanr(slice_a, slice_b)
        if np.isnan(r):
            r = 0.0
        date_val = df.index[i]
        rolling_list.append({"date": str(date_val), "correlation": round(float(r), 4), "observations": window})

    if not rolling_list:
        return {"error": "insufficient_data", "available": len(df), "required": window}

    current = rolling_list[-1]["correlation"]
    last_90 = rolling_list[-90:] if len(rolling_list) >= 90 else rolling_list
    vals_90 = [x["correlation"] for x in last_90]
    min_90d = round(min(vals_90), 4)
    max_90d = round(max(vals_90), 4)

    regime_changes = []
    for i in range(1, len(rolling_list)):
        prev = rolling_list[i - 1]["correlation"]
        curr = rolling_list[i]["correlation"]
        cross_zero = (prev <= 0 < curr) or (prev >= 0 > curr)
        lookback = max(0, i - 10)
        move_10d = abs(curr - rolling_list[lookback]["correlation"])
        if cross_zero:
            regime_changes.append({
                "date": rolling_list[i]["date"],
                "from": round(prev, 4),
                "to": round(curr, 4),
                "note": "Correlation flipped sign — relationship breakdown",
            })
        elif move_10d > 0.3:
            regime_changes.append({
                "date": rolling_list[i]["date"],
                "from": round(prev, 4),
                "to": round(curr, 4),
                "note": f"Correlation shifted >0.3 in 10 days (from {prev:.2f} to {curr:.2f})",
            })

    return {
        "series_a": series_a,
        "series_b": series_b,
        "window_days": window,
        "rolling": rolling_list,
        "current": round(current, 4),
        "min_90d": min_90d,
        "max_90d": max_90d,
        "regime_changes": regime_changes,
    }


def compute_lead_lag(
    conn, series_a: str, series_b: str, max_lag: int, days: int
) -> dict[str, Any]:
    df = get_aligned_returns(conn, [series_a, series_b], days)
    if df is None or df.empty or len(df) < MIN_OBS:
        return {"error": "insufficient_data", "available": len(df) if df is not None else 0, "required": MIN_OBS}
    df = df.dropna(how="any")
    if len(df) < MIN_OBS:
        return {"error": "insufficient_data", "available": len(df), "required": MIN_OBS}

    a = df[series_a].values
    b = df[series_b].values
    lags_list = []
    best_abs = -1
    best_lag = 0
    for k in range(-max_lag, max_lag + 1):
        if k < 0:
            a_slice = a[:k]
            b_slice = b[-k:]
        elif k > 0:
            a_slice = a[k:]
            b_slice = b[:-k]
        else:
            a_slice = a
            b_slice = b
        if len(a_slice) < MIN_OBS:
            continue
        r, _ = pearsonr(a_slice, b_slice)
        if np.isnan(r):
            r = 0.0
        interp = None
        if k < 0:
            interp = f"{series_a} leads {series_b} by {-k} days"
        elif k > 0:
            interp = f"{series_b} leads {series_a} by {k} days"
        else:
            interp = "No lead-lag (contemporaneous)"
        lags_list.append({"lag": k, "correlation": round(float(r), 4), "interpretation": interp})
        if abs(r) > best_abs:
            best_abs = abs(r)
            best_lag = k

    if best_lag < 0:
        interp = f"{series_a} leads {series_b} by {-best_lag} days (rho={best_abs:.2f})"
    elif best_lag > 0:
        interp = f"{series_b} leads {series_a} by {best_lag} days (rho={best_abs:.2f})"
    else:
        interp = "No lead-lag relationship detected"
    return {
        "series_a": series_a,
        "series_b": series_b,
        "lags": lags_list,
        "optimal_lag": best_lag,
        "optimal_correlation": round(best_abs, 4),
        "interpretation": interp,
    }
