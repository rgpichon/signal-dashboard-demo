"""
Macro factor decomposition: OLS of target returns on factor returns, HC3 robust.
Factors: f_rates (RATES.US10Y), f_dollar (FX.DXY), f_risk (EQ.VIX inverted),
f_growth (CM.COPPER), f_credit (CREDIT.HY_OAS daily_chg), f_inflation (RATES.BREAKEVEN daily_chg).
"""
import logging
from datetime import date, timedelta
from typing import Any

import numpy as np
import pandas as pd
import statsmodels.api as sm

from signals.db.connection import get_connection

logger = logging.getLogger("signals.research.factor_model")

MIN_OBS = 30

FACTOR_SERIES = {
    "f_rates": ("RATES.US10Y", "pct_chg", 1),
    "f_dollar": ("FX.DXY", "pct_chg", 1),
    "f_risk": ("EQ.VIX", "pct_chg", -1),
    "f_growth": ("CM.COPPER", "pct_chg", 1),
    "f_credit": ("CREDIT.HY_OAS", "daily_chg", 1),
    "f_inflation": ("RATES.BREAKEVEN", "daily_chg", 1),
}
FACTOR_NAMES = {
    "f_rates": "US 10Y Yield Change",
    "f_dollar": "USD Strength",
    "f_risk": "Risk Sentiment (VIX inv)",
    "f_growth": "Growth (Copper)",
    "f_credit": "Credit (HY OAS)",
    "f_inflation": "Inflation (Breakeven)",
}

def _get_instrument_asset_class(instrument_id: str) -> str | None:
    """Look up asset_class from DB instruments table."""
    try:
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT asset_class FROM instruments WHERE id = %s",
                    (instrument_id,),
                )
                row = cur.fetchone()
        return row[0] if row else None
    except Exception:
        return None


def _compute_market_beta(conn, instrument_id: str, lookback_days: int) -> dict | None:
    """
    Compute beta of instrument against EQ.SPX using OLS on daily pct_chg.
    Returns a factor dict matching the existing factor schema, or None on failure.
    Uses the same conn pattern as the rest of factor_model.py.
    """
    try:
        from_date = (date.today() - timedelta(days=lookback_days + 30)).isoformat()
        to_date = date.today().isoformat()

        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT date, pct_chg FROM market_data
                WHERE series_id = %s
                  AND date >= %s AND date <= %s
                  AND pct_chg IS NOT NULL
                ORDER BY date ASC
                """,
                (instrument_id, from_date, to_date),
            )
            target_rows = cur.fetchall()

            cur.execute(
                """
                SELECT date, pct_chg FROM market_data
                WHERE series_id = 'EQ.SPX'
                  AND date >= %s AND date <= %s
                  AND pct_chg IS NOT NULL
                ORDER BY date ASC
                """,
                (from_date, to_date),
            )
            market_rows = cur.fetchall()

        if len(target_rows) < 30 or len(market_rows) < 30:
            return None

        target_by_date = {r[0]: float(r[1]) for r in target_rows}
        market_by_date = {r[0]: float(r[1]) for r in market_rows}
        common_dates = sorted(set(target_by_date.keys()) & set(market_by_date.keys()))

        if len(common_dates) < 30:
            return None

        y = np.array([target_by_date[d] for d in common_dates])
        x = np.array([market_by_date[d] for d in common_dates])
        X = sm.add_constant(x)
        model = sm.OLS(y, X).fit(cov_type="HC3")

        beta = float(model.params[1])
        p_val = float(model.pvalues[1])
        residual_std_error = float(np.sqrt(model.mse_resid)) if model.df_resid > 0 else 0.0

        var_y = np.var(y)
        r2_i = 0.0
        if p_val < 0.05 and var_y > 0:
            r2_i = float((beta ** 2) * np.var(x) / var_y)
            r2_i = max(0.0, min(1.0, r2_i))

        return {
            "factor": "f_market",
            "name": "Market Beta (EQ.SPX)",
            "beta": round(beta, 4),
            "r2": round(r2_i, 4),
            "t_stat": round(float(model.tvalues[1]), 4),
            "p_value": round(p_val, 4),
            "significant": p_val < 0.05,
            "contribution_pct": round(r2_i * 100, 2) if p_val < 0.05 else None,
            "interpretation": f"β={beta:.2f} — Market Beta (EQ.SPX)",
            "factor_contribution_20d": None,
            "residual_std_error": round(residual_std_error, 6),
        }

    except Exception as e:
        logger.warning("_compute_market_beta failed for %s: %s", instrument_id, e)
        return None


def _get_cached_decomposition(instrument_id: str) -> dict | None:
    """Return cached decomposition if not expired, else None."""
    try:
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    SELECT decomposition FROM factor_decomposition_cache
                    WHERE instrument_id = %s AND expires_at > NOW()
                    """,
                    (instrument_id,),
                )
                row = cur.fetchone()
        if row:
            import json
            return row[0] if isinstance(row[0], dict) else json.loads(row[0])
    except Exception:
        pass
    return None


def _cache_decomposition(instrument_id: str, decomposition: dict, ttl_hours: int = 24) -> None:
    """Write decomposition result to factor_decomposition_cache table."""
    try:
        import json

        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    INSERT INTO factor_decomposition_cache
                        (instrument_id, decomposition, expires_at)
                    VALUES (%s, %s, NOW() + INTERVAL '%s hours')
                    ON CONFLICT (instrument_id) DO UPDATE SET
                        decomposition = EXCLUDED.decomposition,
                        computed_at = NOW(),
                        expires_at = EXCLUDED.expires_at
                    """,
                    (instrument_id, json.dumps(decomposition), ttl_hours),
                )
            conn.commit()
    except Exception as e:
        logger.warning("_cache_decomposition failed for %s: %s", instrument_id, e)


def _get_factor_data(conn, target_series: str, days: int) -> pd.DataFrame | None:
    cur = conn.cursor()
    try:
        end = date.today()
        start = end - timedelta(days=days + 30)
        dfs = []
        for fkey, (sid, col, mult) in FACTOR_SERIES.items():
            cur.execute(
                f"""
                SELECT date, {col} FROM market_data
                WHERE series_id = %s AND date >= %s AND date <= %s
                ORDER BY date
                """,
                (sid, start, end),
            )
            rows = cur.fetchall()
            if not rows:
                continue
            df = pd.DataFrame(rows, columns=["date", fkey])
            df["date"] = pd.to_datetime(df["date"])
            df[fkey] = df[fkey].astype(float) * mult
            df = df.set_index("date")
            dfs.append(df)
        cur.execute(
            """
            SELECT date, pct_chg FROM market_data
            WHERE series_id = %s AND date >= %s AND date <= %s
            ORDER BY date
            """,
            (target_series, start, end),
        )
        rows = cur.fetchall()
        if not rows:
            return None
        target_df = pd.DataFrame(rows, columns=["date", "target"])
        target_df["date"] = pd.to_datetime(target_df["date"])
        target_df = target_df.set_index("date")
        out = target_df
        for df in dfs:
            out = out.join(df, how="inner")
        out = out.dropna(how="any")
        return out.tail(days)
    finally:
        cur.close()


def compute_factor_decomposition(conn, target_series: str, days: int) -> dict[str, Any]:
    # Detect asset class and set appropriate lookback
    asset_class = _get_instrument_asset_class(target_series)
    is_equity = asset_class in ('equity', 'etf')
    equity_min_obs = 60

    # Use longer lookback for equities (252 trading days = 1 year)
    # Macro instruments use the existing shorter lookback (API `days`)
    existing_lookback = days
    lookback_days = 252 if is_equity else existing_lookback

    df = _get_factor_data(conn, target_series, lookback_days)
    if df is None or df.empty or len(df) < MIN_OBS:
        return {"error": "insufficient_data", "available": len(df) if df is not None else 0, "required": MIN_OBS}
    # Equity instruments require more data for stable betas
    if is_equity and len(df) < equity_min_obs:
        return {
            "error": "insufficient_data",
            "available": len(df),
            "required": equity_min_obs,
            "instrument": target_series,
        }
    factor_cols = [c for c in df.columns if c != "target" and c.startswith("f_")]
    if len(factor_cols) < 2:
        return {"error": "insufficient_data", "available": len(df), "required": MIN_OBS}

    y = df["target"].values
    X = sm.add_constant(df[factor_cols].values)
    col_names = ["const"] + factor_cols
    model = sm.OLS(y, X).fit(cov_type="HC3")
    n = int(model.nobs)
    r2 = float(model.rsquared)
    adj_r2 = float(model.rsquared_adj)
    f_stat = float(model.fvalue)
    f_pval = float(model.f_pvalue)
    aic = float(model.aic)
    # Residual standard error: sqrt(MSE) = sqrt(SSR/df_resid), for E2 confidence bands.
    residual_std_error = float(np.sqrt(model.mse_resid)) if model.df_resid > 0 else 0.0

    var_y = np.var(y)
    factors_out = []
    contributions = {}
    for i, fkey in enumerate(factor_cols):
        idx = col_names.index(fkey)
        beta = float(model.params[idx])
        t_stat = float(model.tvalues[idx])
        p_val = float(model.pvalues[idx])
        sig = p_val < 0.05
        contrib_pct = 0.0
        r2_i = 0.0
        if sig and var_y > 0:
            x_col = df[fkey].values
            contrib_pct = float((beta ** 2) * np.var(x_col) / var_y * 100)
            r2_i = contrib_pct / 100.0
            contributions[fkey] = contrib_pct
        interp = f"β={beta:.2f} — " + (FACTOR_NAMES.get(fkey, fkey))
        factors_out.append({
            "factor": fkey,
            "name": FACTOR_NAMES.get(fkey, fkey),
            "beta": round(beta, 4),
            "r2": round(r2_i, 4),
            "t_stat": round(t_stat, 4),
            "p_value": round(p_val, 4),
            "significant": sig,
            "contribution_pct": round(contrib_pct, 2) if sig else None,
            "interpretation": interp,
        })

    total_contrib = sum(contributions.values())
    residual_pct = round(100 - total_contrib, 2)
    dominant = max(contributions, key=contributions.get) if contributions else None
    dom_name = FACTOR_NAMES.get(dominant, dominant) if dominant else "—"
    dom_contrib = round(contributions.get(dominant, 0), 0) if dominant else 0
    interpretation = (
        f"{int(r2*100)}% of {target_series} variance explained by macro factors. "
        f"Primary driver: {dom_name} ({dom_contrib:.0f}%). Unexplained: {residual_pct:.0f}%."
    )

    # 20-day contribution for waterfall (last 20 observations)
    contrib_20d_by_factor = {}
    if len(df) >= 20:
        df_20 = df.tail(20)
        y_20 = df_20["target"].values
        var_y_20 = np.var(y_20)
        if var_y_20 > 0:
            X_20 = sm.add_constant(df_20[factor_cols].values)
            model_20 = sm.OLS(y_20, X_20).fit(cov_type="HC3")
            for i, fkey in enumerate(factor_cols):
                beta_20 = float(model_20.params[i + 1])
                x_col = df_20[fkey].values
                contrib_20d_by_factor[fkey] = round(
                    float((beta_20 ** 2) * np.var(x_col) / var_y_20 * 100), 2
                )
    for f in factors_out:
        f["factor_contribution_20d"] = contrib_20d_by_factor.get(f["factor"])

    # Add market beta factor for equity/ETF instruments
    if is_equity:
        market_factor = _compute_market_beta(conn, target_series, lookback_days)
        if market_factor is not None:
            factors_out.append(market_factor)

    return {
        "target": target_series,
        "model": {
            "r_squared": round(r2, 4),
            "adj_r_squared": round(adj_r2, 4),
            "f_statistic": round(f_stat, 4),
            "f_pvalue": round(f_pval, 6),
            "observations": n,
            "aic": round(aic, 2),
            "residual_std_error": round(residual_std_error, 6),
        },
        "factors": factors_out,
        "residual_pct": residual_pct,
        "dominant_factor": dominant,
        "interpretation": interpretation,
    }


def compute_factor_comparison(conn, target_series_list: list[str], days: int) -> dict[str, Any]:
    factor_keys = list(FACTOR_NAMES.keys())
    targets = {}
    r_squared = {}
    for t in target_series_list:
        out = compute_factor_decomposition(conn, t, days)
        if "error" in out:
            continue
        r_squared[t] = out["model"]["r_squared"]
        targets[t] = {f["factor"]: f["beta"] for f in out["factors"]}
    return {"factors": factor_keys, "targets": targets, "r_squared": r_squared}


def compute_rolling_factor_betas(conn, target_series: str, days: int, window: int = 60) -> dict[str, Any]:
    df = _get_factor_data(conn, target_series, days)
    if df is None or len(df) < window:
        return {"error": "insufficient_data", "available": len(df) if df is not None else 0, "required": window}
    factor_cols = [c for c in df.columns if c != "target" and c.startswith("f_")]
    rolling_betas = {f: [] for f in factor_cols}
    dates = []
    for i in range(window - 1, len(df)):
        slice_df = df.iloc[i - window + 1 : i + 1]
        y = slice_df["target"].values
        X = sm.add_constant(slice_df[factor_cols].values)
        model = sm.OLS(y, X).fit(cov_type="HC3")
        dates.append(str(slice_df.index[-1].date()))
        for j, f in enumerate(factor_cols):
            rolling_betas[f].append(round(float(model.params[j + 1]), 4))
    return {"dates": dates, "rolling_betas": rolling_betas}


def compute_factor_contribution_20d(conn, target_series: str) -> dict[str, Any]:
    df = _get_factor_data(conn, target_series, 90)
    if df is None or len(df) < MIN_OBS:
        return {"error": "insufficient_data", "available": len(df) if df is not None else 0, "required": MIN_OBS}
    last_20 = df.tail(20)
    factor_cols = [c for c in df.columns if c != "target" and c.startswith("f_")]
    y = df["target"].values
    X = sm.add_constant(df[factor_cols].values)
    model = sm.OLS(y, X).fit(cov_type="HC3")
    actual_20d = (df["target"].iloc[-1] - df["target"].iloc[-21]) if len(df) >= 21 else 0
    contributions = {}
    for j, f in enumerate(factor_cols):
        beta = model.params[j + 1]
        factor_move_20d = last_20[f].sum()
        contributions[f] = round(float(beta * factor_move_20d), 4)
    pred_total = sum(contributions.values())
    residual = round(float(actual_20d - pred_total), 4)
    return {
        "target": target_series,
        "actual_20d_move_pct": round(float(actual_20d), 2),
        "factor_contributions": contributions,
        "residual": residual,
    }
