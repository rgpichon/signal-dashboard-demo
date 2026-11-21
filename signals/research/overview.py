"""
Cross-asset overview: current value, changes, z-score, vol, momentum score, trend.
"""
from datetime import date, timedelta
from typing import Any

import numpy as np

MIN_OBS = 30


def compute_overview(conn, days: int) -> dict[str, Any]:
    cur = conn.cursor()
    try:
        cur.execute(
            """
            SELECT DISTINCT i.id, i.name, i.asset_class
            FROM instruments i
            INNER JOIN market_data md ON md.series_id = i.id
            GROUP BY i.id, i.name, i.asset_class
            """
        )
        instruments_meta = cur.fetchall()
    finally:
        cur.close()

    lookback = max(days, 90)
    end = date.today()
    start = end - timedelta(days=lookback + 30)
    instruments_out = []
    missing = []

    for iid, name, asset_class in instruments_meta:
        cur = conn.cursor()
        try:
            cur.execute(
                """
                SELECT date, value, pct_chg FROM market_data
                WHERE series_id = %s AND date >= %s AND date <= %s
                ORDER BY date
                """,
                (iid, start, end),
            )
            rows = cur.fetchall()
        finally:
            cur.close()
        if not rows or len(rows) < MIN_OBS:
            missing.append(iid)
            continue
        dates = [r[0] for r in rows]
        values = [float(r[1]) if r[1] is not None else None for r in rows]
        pct_chgs = [float(r[2]) if r[2] is not None else None for r in rows]
        valid = [i for i, v in enumerate(values) if v is not None]
        if len(valid) < MIN_OBS:
            missing.append(iid)
            continue
        values_clean = [values[i] for i in valid]
        pct_clean = [pct_chgs[i] for i in valid if pct_chgs[i] is not None]
        n = len(values_clean)
        current_value = values_clean[-1]
        first_value = values_clean[0]

        chg_1d_pct = round(pct_chgs[-1], 2) if len(pct_chgs) and pct_chgs[-1] is not None else None
        value_5d = values_clean[-6] if n >= 6 else first_value
        value_20d = values_clean[-21] if n >= 21 else first_value
        chg_5d_pct = round((current_value / value_5d - 1) * 100, 2) if value_5d and abs(value_5d) > 1e-12 else None
        chg_20d_pct = round((current_value / value_20d - 1) * 100, 2) if value_20d and abs(value_20d) > 1e-12 else None
        chg_since_start_pct = round((current_value / first_value - 1) * 100, 2) if first_value and abs(first_value) > 1e-12 else None

        last_90 = values_clean[-90:] if n >= 90 else values_clean
        mean_90 = np.mean(last_90)
        std_90 = np.std(last_90) or 1e-12
        zscore_90d = round((current_value - mean_90) / std_90, 2) if std_90 != 0 else 0.0

        last_21_pct = [pct_chgs[i] for i in range(-21, 0) if i + len(pct_chgs) >= 0 and pct_chgs[i] is not None]
        if len(last_21_pct) >= 10:
            s = np.std(last_21_pct)
            vol_21d_ann = round(float((s or 0) * np.sqrt(252)), 2)
        else:
            vol_21d_ann = None

        chg_1d = (pct_chgs[-1] or 0) / 100 if len(pct_chgs) else 0
        vol_1d = float(np.std(pct_clean[-21:]) / 100) if len(pct_clean) >= 10 else 0.01
        chg_5d = (current_value / value_5d - 1) if value_5d and abs(value_5d) > 1e-12 else 0
        slice5 = values_clean[-5:]
        returns5 = [slice5[j] / slice5[j - 1] - 1 for j in range(1, len(slice5)) if abs(slice5[j - 1]) > 1e-12]
        vol_5d = float(np.std(returns5)) if len(returns5) > 1 else 0.01
        chg_20d = (current_value / value_20d - 1) if value_20d and abs(value_20d) > 1e-12 else 0
        vol_20d = float(np.std(pct_clean[-20:]) / 100) if len(pct_clean) >= 15 else 0.01
        if vol_1d <= 0 or np.isnan(vol_1d):
            vol_1d = 0.01
        if vol_5d <= 0 or np.isnan(vol_5d):
            vol_5d = 0.01
        if vol_20d <= 0 or np.isnan(vol_20d):
            vol_20d = 0.01
        raw_score = 0.33 * (chg_1d / vol_1d) + 0.33 * (chg_5d / vol_5d) + 0.34 * (chg_20d / vol_20d)
        momentum_score = round(float(np.tanh(raw_score)), 2)

        sma_20 = np.mean(values_clean[-20:]) if n >= 20 else current_value
        trend_direction = "up" if current_value > sma_20 else "down"

        max_90 = max(last_90)
        min_90 = min(last_90)
        vs_90d_high_pct = round((current_value / max_90 - 1) * 100, 2) if max_90 and abs(max_90) > 1e-12 else None
        vs_90d_low_pct = round((current_value / min_90 - 1) * 100, 2) if min_90 and abs(min_90) > 1e-12 else None

        instruments_out.append({
            "id": iid,
            "name": name or iid,
            "asset_class": asset_class or "unknown",
            "current_value": round(float(current_value), 4),
            "chg_1d_pct": chg_1d_pct,
            "chg_5d_pct": chg_5d_pct,
            "chg_20d_pct": chg_20d_pct,
            "chg_since_start_pct": chg_since_start_pct,
            "zscore_90d": zscore_90d,
            "vol_21d_ann": vol_21d_ann,
            "momentum_score": momentum_score,
            "trend_direction": trend_direction,
            "vs_90d_high_pct": vs_90d_high_pct,
            "vs_90d_low_pct": vs_90d_low_pct,
        })

    risk_on_count = sum(1 for i in instruments_out if (i.get("momentum_score") or 0) > 0.1)
    risk_off_count = sum(1 for i in instruments_out if (i.get("momentum_score") or 0) < -0.1)
    neutral_count = len(instruments_out) - risk_on_count - risk_off_count
    if risk_on_count > risk_off_count and risk_on_count > neutral_count:
        dominant_theme = "risk_on"
    elif risk_off_count > risk_on_count and risk_off_count > neutral_count:
        dominant_theme = "risk_off"
    else:
        dominant_theme = "mixed"

    return {
        "snapshot_date": str(end),
        "instruments": instruments_out,
        "cross_asset_summary": {
            "risk_on_count": risk_on_count,
            "risk_off_count": risk_off_count,
            "neutral_count": neutral_count,
            "dominant_theme": dominant_theme,
        },
        "missing": missing if missing else None,
        "partial": bool(missing),
    }
