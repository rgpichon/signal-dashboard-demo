"""
Realised vol and GARCH(1,1). Vol regime, percentile, surface.
"""
from datetime import date, timedelta
from typing import Any

import numpy as np

MIN_OBS = 30


def compute_realised_vol(returns: np.ndarray, dates: list, window: int = 21) -> list[dict]:
    """Rolling std of returns * sqrt(252) * 100. Also 5d vol."""
    out = []
    for i in range(window - 1, len(returns)):
        r21 = returns[i - window + 1 : i + 1]
        r5 = returns[max(0, i - 4) : i + 1]
        vol_21 = float(np.std(r21) * np.sqrt(252) * 100) if len(r21) > 1 else 0
        vol_5 = float(np.std(r5) * np.sqrt(252) * 100) if len(r5) > 1 else 0
        d = dates[i]
        out.append({"date": str(d), "vol_21d_ann": round(vol_21, 2), "vol_5d_ann": round(vol_5, 2)})
    return out


def fit_garch(returns: np.ndarray):
    try:
        from arch import arch_model
        am = arch_model(returns * 100, vol="Garch", p=1, q=1, mean="Zero", dist="Normal")
        res = am.fit(disp="off", show_warning=False, options={"maxiter": 500})
        if res.convergence_flag != 0:
            return None, "convergence_failed"
        return res, None
    except Exception as e:
        return None, str(e)


def compute_volatility(conn, series_id: str, days: int) -> dict[str, Any]:
    cur = conn.cursor()
    try:
        end = date.today()
        start = end - timedelta(days=max(days, 90) + 30)
        cur.execute(
            "SELECT date, value, pct_chg FROM market_data WHERE series_id = %s AND date >= %s AND date <= %s ORDER BY date",
            (series_id, start, end),
        )
        rows = cur.fetchall()
    finally:
        cur.close()
    if not rows or len(rows) < MIN_OBS:
        return {"error": "insufficient_data", "available": len(rows) if rows else 0, "required": MIN_OBS}

    dates = [r[0] for r in rows]
    values = [float(r[1]) for r in rows]
    pct_chg = [float(r[2]) if r[2] is not None else 0 for r in rows]
    returns = np.array([x / 100.0 for x in pct_chg], dtype=float)

    returns_list = [{"date": str(d), "return_pct": round(pct_chg[i], 2)} for i, d in enumerate(dates)]
    realised = compute_realised_vol(returns, dates, 21)
    current_realised_21d = realised[-1]["vol_21d_ann"] if realised else None

    res, err = fit_garch(returns)
    garch_available = res is not None
    garch_fitted = []
    garch_forecast = []
    garch_params = {}
    if res is not None:
        cond_vol = res.conditional_volatility * np.sqrt(252)
        for i, d in enumerate(dates):
            if i < len(cond_vol):
                garch_fitted.append({"date": str(d), "conditional_vol": round(float(cond_vol[i]), 2)})
        omega = res.params["omega"]
        alpha = res.params["alpha[1]"]
        beta = res.params["beta[1]"]
        persistence = alpha + beta
        half_life = np.log(0.5) / np.log(persistence) if 0 < persistence < 1 else None
        long_run = np.sqrt(omega / (1 - persistence)) * np.sqrt(252) if 0 < persistence < 1 else None
        garch_params = {
            "omega": round(float(omega), 4),
            "alpha": round(float(alpha), 4),
            "beta": round(float(beta), 4),
            "persistence": round(float(persistence), 4),
            "half_life_days": round(float(half_life), 0) if half_life is not None else None,
            "long_run_vol": round(float(long_run), 2) if long_run is not None else None,
        }
        try:
            fc = res.forecast(horizon=30)
            if hasattr(fc, "variance"):
                v = fc.variance.values[-1, :]
                vol_fc = np.sqrt(v) * np.sqrt(252)
            else:
                vol_fc = [current_realised_21d] * 30
            for i in range(30):
                d = end + timedelta(days=i + 1)
                garch_forecast.append({
                    "date": str(d),
                    "forecast_vol": round(float(vol_fc[i]) if i < len(vol_fc) else vol_fc[-1], 2),
                    "ci_95_low": None,
                    "ci_95_high": None,
                })
        except Exception:
            garch_forecast = []
    else:
        garch_params = {"reason": err}

    vol_21_series = [x["vol_21d_ann"] for x in realised]
    vol_percentile = None
    vol_regime = "NORMAL"
    if vol_21_series and current_realised_21d is not None:
        vol_21_arr = np.array(vol_21_series)
        vol_percentile = int(np.sum(vol_21_arr <= current_realised_21d) / len(vol_21_arr) * 100)
        if vol_percentile > 75:
            vol_regime = "ELEVATED"
        elif vol_percentile < 25:
            vol_regime = "SUPPRESSED"

    cur = conn.cursor()
    try:
        cur.execute("SELECT value FROM market_data WHERE series_id IN ('RATES.VIX', 'EQ.VIX') ORDER BY date DESC LIMIT 1")
        row = cur.fetchone()
        vix_current = round(float(row[0]), 2) if row and row[0] else None
    finally:
        cur.close()
    vol_risk_premium = round(current_realised_21d - vix_current, 2) if current_realised_21d and vix_current else None
    forecast_30d = garch_forecast[-1]["forecast_vol"] if garch_forecast else current_realised_21d

    return {
        "series_id": series_id,
        "returns": returns_list,
        "realised_vol": realised,
        "garch_fitted": garch_fitted,
        "garch_forecast": garch_forecast,
        "garch_params": garch_params,
        "garch_available": garch_available,
        "summary": {
            "current_realised_21d": current_realised_21d,
            "current_conditional": round(garch_fitted[-1]["conditional_vol"], 2) if garch_fitted else None,
            "vol_percentile_90d": vol_percentile,
            "vol_regime": vol_regime,
            "vix_current": vix_current,
            "vol_risk_premium": vol_risk_premium,
            "forecast_30d_vol": forecast_30d,
        },
    }


def compute_vol_surface(conn, series_ids: list[str], days: int) -> dict[str, Any]:
    instruments = []
    for sid in series_ids:
        v = compute_volatility(conn, sid, days)
        if "error" in v:
            continue
        s = v["summary"]
        real = v["realised_vol"]
        vol_5_old = real[-6]["vol_5d_ann"] if len(real) >= 6 else s.get("current_realised_21d")
        vol_5_now = real[-1]["vol_5d_ann"] if real else None
        vol_change_5d = round(vol_5_now - vol_5_old, 2) if vol_5_now is not None and vol_5_old is not None else None
        instruments.append({
            "series_id": sid,
            "vol_21d": s.get("current_realised_21d"),
            "vol_5d": vol_5_now,
            "vol_percentile": s.get("vol_percentile_90d"),
            "vol_regime": s.get("vol_regime", "NORMAL"),
            "vol_change_5d": vol_change_5d,
        })
    return {"instruments": instruments}
