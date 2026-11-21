"""
ARIMA (pmdarima + fallback) and linear trend forecast. STL decomposition.
"""
import math
import threading
from datetime import date, datetime, timedelta
from typing import Any

import numpy as np
import statsmodels.api as sm
from statsmodels.stats.diagnostic import acorr_ljungbox
from statsmodels.tsa.statespace.sarimax import SARIMAX

MIN_OBS = 30


def _safe_float(v, default=None):
    """Return a JSON-safe float; use default for None, NaN, Inf."""
    if v is None:
        return default
    try:
        f = float(v)
        return default if (math.isnan(f) or math.isinf(f)) else round(f, 4)
    except (TypeError, ValueError):
        return default


def _date_str(d) -> str:
    """Always return Y-m-d string for JSON; never pass datetime to response."""
    if d is None:
        return ""
    if isinstance(d, str) and len(d) >= 10:
        return d[:10]
    if isinstance(d, (date, datetime)):
        return d.strftime("%Y-%m-%d")
    try:
        return date.fromisoformat(str(d).split("T")[0][:10]).strftime("%Y-%m-%d")
    except Exception:
        return date.today().strftime("%Y-%m-%d")


def _run_auto_arima(series, result_holder):
    try:
        from pmdarima import auto_arima
        model = auto_arima(
            series,
            seasonal=False,
            max_p=3,
            max_q=3,
            information_criterion="aic",
            suppress_warnings=True,
            error_action="ignore",
        )
        result_holder["model"] = model
        result_holder["success"] = True
    except Exception as e:
        result_holder["error"] = str(e)


def fit_arima(series):
    result = {"success": False}
    t = threading.Thread(target=_run_auto_arima, args=(series, result))
    t.start()
    t.join(timeout=10)
    if result.get("success") and "model" in result:
        model = result["model"]
        order = getattr(model, "order", (1, 1, 1))
        return model, order, False
    try:
        fallback = SARIMAX(series, order=(1, 1, 1), trend="c").fit(disp=False)
        return fallback, (1, 1, 1), True
    except Exception:
        return None, (1, 1, 1), True


def compute_forecast(
    conn, series_id: str, days_forward: int, days_history: int, model_type: str
) -> dict[str, Any]:
    cur = conn.cursor()
    try:
        end = date.today()
        start = end - timedelta(days=days_history + 50)
        cur.execute(
            "SELECT date, value FROM market_data WHERE series_id = %s AND date >= %s AND date <= %s ORDER BY date",
            (series_id, start, end),
        )
        rows = cur.fetchall()
    finally:
        cur.close()
    if not rows or len(rows) < MIN_OBS:
        return {"error": "insufficient_data", "available": len(rows) if rows else 0, "required": MIN_OBS}

    dates = [r[0] for r in rows]
    try:
        values = np.array([float(r[1]) for r in rows], dtype=float)
    except (TypeError, ValueError):
        return {"error": "invalid_data", "message": "Non-numeric values in series"}
    if np.any(~np.isfinite(values)):
        return {"error": "invalid_data", "message": "Series contains NaN or Inf"}
    history = [{"date": _date_str(d), "value": _safe_float(v, 0.0) or round(float(v), 4)} for d, v in zip(dates, values)]
    current = _safe_float(values[-1]) or round(float(values[-1]), 4)
    history_only = list(history)

    arima_forecast = None
    arima_model = None
    linear_forecast = None
    linear_model = None

    try:
        if model_type in ("arima", "both"):
            try:
                model, order, fallback = fit_arima(values)
            except Exception:
                model, order, fallback = None, (1, 1, 1), True
            if model is not None:
                try:
                    # get_forecast / predict can be ndarray in some libs; avoid calling anything that might be array
                    f, ci, ci_95 = None, None, None
                    try:
                        get_fc = getattr(model, "get_forecast", None)
                        if get_fc is not None and callable(get_fc):
                            fc = get_fc(steps=days_forward)
                            pred = getattr(fc, "predicted_mean", None)
                            if pred is not None:
                                f = np.asarray(pred).flatten()
                            else:
                                f = np.asarray(fc.predicted_mean).flatten()
                            ci = fc.conf_int(alpha=0.2)
                            ci_95 = fc.conf_int(alpha=0.05)
                    except Exception:
                        pass
                    if f is None or len(f) < days_forward:
                        try:
                            pred_m = getattr(model, "predict", None)
                            if callable(pred_m):
                                f = np.asarray(pred_m(n_periods=days_forward)).flatten()
                        except Exception:
                            pass
                    if f is None or len(f) < days_forward:
                        f = np.zeros(days_forward)
                    if ci is None or ci_95 is None:
                        ci = np.column_stack([f - np.std(values), f + np.std(values)])
                        ci_95 = np.column_stack([f - 2 * np.std(values), f + 2 * np.std(values)])
                    if model is not None and (arima_forecast is None or arima_model is None):
                        if ci is None:
                            ci = np.column_stack([f - np.std(values), f + np.std(values)])
                            ci_95 = np.column_stack([f - 2 * np.std(values), f + 2 * np.std(values)])
                        arima_forecast = []
                        try:
                            last_d = dates[-1]
                            if isinstance(last_d, date):
                                base_d = last_d
                            else:
                                base_d = date.fromisoformat(str(last_d).split("T")[0][:10])
                        except Exception:
                            base_d = date.today()
                        for i in range(days_forward):
                            d = base_d + timedelta(days=i + 1)
                            arima_forecast.append({
                                "date": _date_str(d),
                                "value": _safe_float(f[i]) if i < len(f) else None,
                                "ci_80_low": _safe_float(ci[i, 0]) if ci is not None and ci.shape[1] >= 2 else None,
                                "ci_80_high": _safe_float(ci[i, 1]) if ci is not None and ci.shape[1] >= 2 else None,
                                "ci_95_low": _safe_float(ci_95[i, 0]) if ci_95 is not None and ci_95.shape[1] >= 2 else None,
                                "ci_95_high": _safe_float(ci_95[i, 1]) if ci_95 is not None and ci_95.shape[1] >= 2 else None,
                            })
                        # Residuals: use .resid only as property (array); never call .resid() or .predict()
                        try:
                            r = getattr(model, "resid", None)
                            if r is not None and isinstance(r, np.ndarray):
                                resids = np.asarray(r).flatten()
                            elif r is not None and hasattr(r, "__len__") and not callable(r):
                                resids = np.asarray(r).flatten()
                            else:
                                fitted = getattr(model, "fittedvalues", None)
                                if fitted is not None and isinstance(fitted, np.ndarray):
                                    resids = np.asarray(values - fitted).flatten()
                                else:
                                    resids = np.zeros_like(values)
                        except Exception:
                            resids = np.zeros_like(values)
                        if len(resids) == 0:
                            resids = np.zeros_like(values)
                        rmse = _safe_float(np.sqrt(np.mean(resids ** 2)))
                        ljung_p = None
                        n_res = len(resids)
                        lags_val = max(1, min(10, n_res // 5))
                        if n_res > lags_val:
                            try:
                                lb = acorr_ljungbox(resids, lags=[lags_val], return_df=True)
                                ljung_p = _safe_float(lb["lb_pvalue"].iloc[0])
                            except Exception:
                                pass
                        arima_model = {
                            "order": list(order),
                            "aic": _safe_float(getattr(model, "aic", 0)),
                            "bic": _safe_float(getattr(model, "bic", 0)),
                            "ljung_box_p": _safe_float(ljung_p),
                            "residual_std": _safe_float(np.std(resids)),
                            "in_sample_rmse": rmse,
                            "fallback": fallback,
                        }
                except Exception:
                    arima_forecast = []
                    arima_model = {"order": [1, 1, 1], "fallback": True}
            else:
                arima_model = {"order": [1, 1, 1], "fallback": True}
                arima_forecast = []

        if model_type in ("linear", "both"):
            x = np.arange(len(values))
            X = sm.add_constant(x)
            model_lin = sm.OLS(values, X).fit()
            slope = float(model_lin.params[1])
            r2 = float(model_lin.rsquared)
            n = len(values)
            annual_trend = slope * 252 / (values[-1] or 1) * 100
            linear_model = {
                "slope_per_day": round(slope, 4),
                "r_squared": round(r2, 4),
                "annualised_trend_pct": round(annual_trend, 2),
            }
            last_x = len(values) - 1
            linear_forecast = []
            try:
                last_d = dates[-1]
                if isinstance(last_d, date):
                    base_d = last_d
                else:
                    base_d = date.fromisoformat(str(last_d).split("T")[0][:10])
            except Exception:
                base_d = date.today()
            for i in range(1, days_forward + 1):
                d = base_d + timedelta(days=i)
                val = float(model_lin.params[0] + model_lin.params[1] * (last_x + i))
                linear_forecast.append({"date": _date_str(d), "value": _safe_float(val)})

        arima_30d = arima_forecast[-1]["value"] if arima_forecast and len(arima_forecast) >= min(30, days_forward) else (arima_forecast[-1]["value"] if arima_forecast else None)
        linear_30d = linear_forecast[-1]["value"] if linear_forecast and len(linear_forecast) >= min(30, days_forward) else (linear_forecast[-1]["value"] if linear_forecast else None)
        arima_pct = _safe_float((arima_30d / current - 1) * 100) if arima_30d is not None and current else None
        linear_pct = _safe_float((linear_30d / current - 1) * 100) if linear_30d is not None and current else None
        same_dir = True
        if arima_pct is not None and linear_pct is not None:
            same_dir = (arima_pct > 0 and linear_pct > 0) or (arima_pct < 0 and linear_pct < 0)
        model_agreement = "aligned" if same_dir else "divergent"

        return {
            "series_id": series_id,
            "history": history,
            "arima_forecast": arima_forecast or [],
            "linear_forecast": linear_forecast or [],
            "arima_model": arima_model or {},
            "linear_model": linear_model or {},
            "summary": {
                "current": current,
                "arima_30d": arima_30d,
                "arima_pct_change": f"{arima_pct:+.1f}%" if arima_pct is not None else None,
                "linear_30d": linear_30d,
                "linear_pct_change": f"{linear_pct:+.1f}%" if linear_pct is not None else None,
                "model_agreement": model_agreement,
            },
        }
    except BaseException as e:
        return {
            "error": "forecast_failed",
            "detail": str(e),
            "series_id": series_id,
            "history": history_only,
            "arima_forecast": [],
            "linear_forecast": [],
            "arima_model": {"fallback": True, "error": str(e)},
            "linear_model": {},
            "summary": {
                "current": history_only[-1]["value"] if history_only else None,
                "arima_30d": None,
                "arima_pct_change": None,
                "linear_30d": None,
                "linear_pct_change": None,
                "model_agreement": "unknown",
            },
        }


def compute_stl_decomposition(conn, series_id: str, days: int) -> dict[str, Any]:
    from statsmodels.tsa.seasonal import STL
    cur = conn.cursor()
    try:
        end = date.today()
        start = end - timedelta(days=days + 30)
        cur.execute(
            "SELECT date, value FROM market_data WHERE series_id = %s AND date >= %s AND date <= %s ORDER BY date",
            (series_id, start, end),
        )
        rows = cur.fetchall()
    finally:
        cur.close()
    if not rows or len(rows) < MIN_OBS:
        return {"error": "insufficient_data", "available": len(rows) if rows else 0, "required": MIN_OBS}

    values = np.array([float(r[1]) for r in rows], dtype=float)
    dates = [r[0] for r in rows]
    period = min(21, len(values) // 2 - 1)
    if period < 2:
        period = 5
    stl = STL(values, period=period).fit()
    trend = stl.trend
    seasonal = stl.seasonal
    residual = stl.resid
    decomposition = [
        {"date": str(dates[i]), "observed": round(float(values[i]), 4), "trend": round(float(trend[i]), 4), "seasonal": round(float(seasonal[i]), 4), "residual": round(float(residual[i]), 4)}
        for i in range(len(dates))
    ]
    trend_dir = "up" if len(trend) >= 5 and trend[-1] > trend[-5] else "down"
    trend_slope_30d = float(np.polyfit(range(min(30, len(trend))), trend[-30:], 1)[0]) if len(trend) >= 30 else 0
    var_obs = np.var(values)
    seasonality_strength = round(float(np.var(seasonal) / var_obs), 4) if var_obs and var_obs != 0 else 0
    residual_std = round(float(np.std(residual)), 4)
    return {
        "series_id": series_id,
        "decomposition": decomposition,
        "trend_direction": trend_dir,
        "trend_slope_30d": round(trend_slope_30d, 4),
        "seasonality_strength": seasonality_strength,
        "residual_std": residual_std,
    }
