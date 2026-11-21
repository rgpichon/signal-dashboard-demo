"""
Preset scenarios and scenario run: multivariate OLS of targets on shock series.
"""
from typing import Any

import numpy as np
import statsmodels.api as sm

from signals.research.data import get_aligned_returns

MIN_OBS = 30

PRESET_SCENARIOS = [
    {"id": "fed_hike_25bps", "name": "Fed Hike +25bps", "description": "US 2Y yield +25bps, curve flattens, VIX +10%", "shocks": [{"series_id": "RATES.US2Y", "change_bps": 25}, {"series_id": "RATES.2S10S", "change_bps": -10}, {"series_id": "EQ.VIX", "change_pct": 10}]},
    {"id": "oil_spike_20pct", "name": "Oil Spike +20%", "description": "Supply shock — Brent +20%, WTI +18%", "shocks": [{"series_id": "CM.BRENT", "change_pct": 20}, {"series_id": "CM.WTI", "change_pct": 18}]},
    {"id": "risk_off_shock", "name": "Risk-Off Shock", "description": "VIX spikes, equities sell off, safe havens bid", "shocks": [{"series_id": "EQ.VIX", "change_pct": 40}, {"series_id": "EQ.SPX", "change_pct": -8}, {"series_id": "CM.GOLD", "change_pct": 5}, {"series_id": "FX.EURUSD", "change_pct": -2}]},
    {"id": "dollar_surge", "name": "Dollar Surge +5%", "description": "DXY +5% — pressure on EM and commodities", "shocks": [{"series_id": "FX.DXY", "change_pct": 5}]},
    {"id": "eu_credit_stress", "name": "EU Credit Stress", "description": "iTraxx widens, Euro equities sell off", "shocks": [{"series_id": "CREDIT.HY_OAS", "change_bps": 80}, {"series_id": "EQ.SX7E", "change_pct": -5}, {"series_id": "EQ.DAX", "change_pct": -4}]},
    {"id": "china_slowdown", "name": "China Slowdown", "description": "Growth pulse weakens — copper falls, EM stress", "shocks": [{"series_id": "CM.COPPER", "change_pct": -15}, {"series_id": "EQ.EEM", "change_pct": -8}, {"series_id": "CM.IRON_ORE", "change_pct": -12}]},
    {"id": "inflation_surprise", "name": "Inflation Surprise +0.5%", "description": "CPI prints 50bps above consensus", "shocks": [{"series_id": "RATES.BREAKEVEN", "change_bps": 20}, {"series_id": "RATES.US10Y", "change_bps": 15}, {"series_id": "EQ.VIX", "change_pct": 8}]},
]


def get_preset_scenarios() -> list[dict]:
    return PRESET_SCENARIOS


def _get_instrument_name(conn, series_id: str) -> str:
    cur = conn.cursor()
    try:
        cur.execute("SELECT name FROM instruments WHERE id = %s", (series_id,))
        row = cur.fetchone()
        return (row[0] or series_id) if row else series_id
    finally:
        cur.close()


def _shock_to_pct(conn, shock: dict) -> float:
    """Convert shock to percentage move. change_pct used as-is; change_bps converted using latest value."""
    if "change_pct" in shock and shock["change_pct"] is not None:
        return float(shock["change_pct"])
    if "change_bps" in shock and shock["change_bps"] is not None:
        cur = conn.cursor()
        try:
            cur.execute("SELECT value FROM market_data WHERE series_id = %s ORDER BY date DESC LIMIT 1", (shock["series_id"],))
            row = cur.fetchone()
            if row and row[0] and float(row[0]) != 0:
                return float(shock["change_bps"]) / 10000.0 / float(row[0]) * 100.0
            return float(shock["change_bps"]) / 100.0
        finally:
            cur.close()
    return 0.0


def run_scenario(conn, shocks: list[dict], target_series_list: list[str], days: int) -> dict[str, Any]:
    shock_series_ids = [s["series_id"] for s in shocks]
    series_ids = list(dict.fromkeys(shock_series_ids + target_series_list))
    df = get_aligned_returns(conn, series_ids, days)
    if df is None or df.empty or len(df) < MIN_OBS:
        return {"error": "insufficient_data", "available": len(df) if df is not None else 0, "required": MIN_OBS}
    df = df.dropna(how="any")
    if len(df) < MIN_OBS:
        return {"error": "insufficient_data", "available": len(df), "required": MIN_OBS}

    shock_pcts = []
    shocks_applied = []
    for s in shocks:
        sid = s["series_id"]
        pct = _shock_to_pct(conn, s)
        shock_pcts.append(pct)
        name = _get_instrument_name(conn, sid)
        if "change_pct" in s and s["change_pct"] is not None:
            shocks_applied.append({"series_id": sid, "change_pct": float(s["change_pct"]), "name": name})
        else:
            shocks_applied.append({"series_id": sid, "change_bps": s.get("change_bps"), "name": name})

    impacts = []
    for target in target_series_list:
        if target not in df.columns:
            continue
        y = df[target].values
        X_cols = [c for c in shock_series_ids if c in df.columns]
        if not X_cols:
            continue
        X = sm.add_constant(df[X_cols].values)
        model = sm.OLS(y, X).fit(cov_type="HC3")
        betas = model.params[1:]
        predicted_move_pct = sum(b * p for b, p in zip(betas, shock_pcts[: len(betas)]))
        bse = model.bse[1:]
        var_pred = sum(se ** 2 * (p / 100) ** 2 for se, p in zip(bse, shock_pcts[: len(bse)]))
        ci_half = 1.96 * (var_pred ** 0.5) * 100 if var_pred > 0 else 0
        ci_95_low = round(predicted_move_pct - ci_half, 2)
        ci_95_high = round(predicted_move_pct + ci_half, 2)
        individual = [{"shock": shock_series_ids[i], "contribution_pct": round(betas[i] * shock_pcts[i], 2)} for i in range(len(betas))]
        direction = "bullish" if predicted_move_pct > 0.5 else ("bearish" if predicted_move_pct < -0.5 else "neutral")
        p_val = float(model.f_pvalue) if hasattr(model, "f_pvalue") else 0.05
        if model.rsquared > 0.4 and p_val < 0.01:
            confidence = "HIGH"
        elif p_val < 0.05:
            confidence = "MEDIUM"
        else:
            confidence = "LOW"
        name = _get_instrument_name(conn, target)
        impacts.append({
            "series_id": target,
            "name": name,
            "predicted_move_pct": round(predicted_move_pct, 2),
            "ci_95_low": ci_95_low,
            "ci_95_high": ci_95_high,
            "r_squared": round(float(model.rsquared), 4),
            "direction": direction,
            "confidence": confidence,
            "individual_contributions": individual,
        })

    impacts.sort(key=lambda x: abs(x["predicted_move_pct"]), reverse=True)
    n = int(len(df))
    date_range = {"from": str(df.index.min().date()), "to": str(df.index.max().date())}
    return {
        "scenario": "Custom",
        "shocks_applied": shocks_applied,
        "impacts": impacts,
        "methodology": f"Multivariate OLS, {n}d daily returns, HC3 robust errors",
        "observations": n,
        "date_range": date_range,
    }
