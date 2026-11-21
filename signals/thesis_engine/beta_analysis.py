"""
Rolling beta analysis: OLS/WLS on aligned returns, structural breaks, decay selection.
Phase B1 — no API wiring yet.
"""
from __future__ import annotations

import logging
from typing import Any

import numpy as np
import statsmodels.api as sm
from scipy import stats

from signals.research.data import get_aligned_returns

logger = logging.getLogger("signals.thesis_engine")


def _empty_betas_payload(
    base_series: str,
    target_series: str,
    windows: list[int],
) -> dict[str, Any]:
    empty_win = {
        "beta": None,
        "ci_low": None,
        "ci_high": None,
        "r_squared": None,
        "n_obs": 0,
        "valid": False,
    }
    return {
        "base": base_series,
        "target": target_series,
        "betas": {int(w): dict(empty_win) for w in windows},
        "beta_trend": "insufficient_data",
        "trend_significant": False,
    }


def compute_rolling_betas(
    conn,
    base_series: str,
    target_series: str,
    windows: list | None = None,
) -> dict[str, Any]:
    """
    Runs OLS at each window size.
    Default windows: [60, 120, 252]

    Returns betas per window, beta_trend, trend_significant.
    Never raises; returns a safe structure on failure.
    """
    windows = [int(w) for w in (windows or [60, 120, 252])]
    MIN_OBS = 30
    try:
        results: dict[int, dict[str, Any]] = {}

        for window in windows:
            try:
                df = get_aligned_returns(
                    conn, [base_series, target_series], window
                )
                if df is None or len(df) < MIN_OBS:
                    results[window] = {
                        "beta": None,
                        "ci_low": None,
                        "ci_high": None,
                        "r_squared": None,
                        "n_obs": len(df) if df is not None else 0,
                        "valid": False,
                    }
                    continue

                df = df.dropna()
                if len(df) < MIN_OBS:
                    results[window] = {
                        "beta": None,
                        "ci_low": None,
                        "ci_high": None,
                        "r_squared": None,
                        "n_obs": int(len(df)),
                        "valid": False,
                    }
                    continue

                y = df[target_series].values.astype(float)
                X = sm.add_constant(df[base_series].values.astype(float))
                model = sm.OLS(y, X).fit(cov_type="HC3")
                beta = float(model.params[1])
                bse = float(model.bse[1])
                ci_low = round(beta - 1.96 * bse, 4)
                ci_high = round(beta + 1.96 * bse, 4)
                results[window] = {
                    "beta": round(beta, 4),
                    "ci_low": ci_low,
                    "ci_high": ci_high,
                    "r_squared": round(float(model.rsquared), 4),
                    "n_obs": int(model.nobs),
                    "valid": True,
                }
            except Exception as e:
                logger.warning(
                    "compute_rolling_betas window=%s %s/%s: %s",
                    window,
                    base_series,
                    target_series,
                    e,
                )
                results[window] = {
                    "beta": None,
                    "ci_low": None,
                    "ci_high": None,
                    "r_squared": None,
                    "n_obs": 0,
                    "valid": False,
                }

        b60 = results.get(60, {}).get("beta")
        b252 = results.get(252, {}).get("beta")
        v60 = results.get(60, {}).get("valid", False)
        v252 = results.get(252, {}).get("valid", False)

        if (
            not v60
            or not v252
            or b252 is None
            or b252 == 0
        ):
            beta_trend = "insufficient_data"
            trend_significant = False
        else:
            pct_change = (abs(b60) - abs(b252)) / abs(b252)
            if pct_change > 0.25:
                beta_trend = "strengthening"
            elif pct_change < -0.25:
                beta_trend = "weakening"
            else:
                beta_trend = "stable"

            ci60_low = results[60].get("ci_low")
            ci60_high = results[60].get("ci_high")
            ci252_low = results[252].get("ci_low")
            ci252_high = results[252].get("ci_high")
            if all(
                v is not None
                for v in [ci60_low, ci60_high, ci252_low, ci252_high]
            ):
                overlap = (
                    ci60_low <= ci252_high and ci252_low <= ci60_high
                )
                trend_significant = not overlap
            else:
                trend_significant = False

        return {
            "base": base_series,
            "target": target_series,
            "betas": results,
            "beta_trend": beta_trend,
            "trend_significant": trend_significant,
        }
    except Exception as e:
        logger.warning(
            "compute_rolling_betas failed %s/%s: %s",
            base_series,
            target_series,
            e,
        )
        return _empty_betas_payload(base_series, target_series, windows)


def detect_structural_break(
    conn,
    base_series: str,
    target_series: str,
    days: int = 252,
    significance: float = 0.05,
) -> dict[str, Any]:
    """
    Chow-style F test for structural break at sample midpoint.
    Never raises; returns SAFE_RETURN on failure.
    """
    MIN_OBS = 30
    SAFE_RETURN: dict[str, Any] = {
        "break_detected": False,
        "break_date": None,
        "f_statistic": None,
        "p_value": None,
        "post_break_n": 0,
        "recommendation": "use_full",
    }
    try:
        df = get_aligned_returns(
            conn, [base_series, target_series], days
        )
        if df is None or len(df) < MIN_OBS * 2:
            return dict(SAFE_RETURN)
        df = df.dropna()
        if len(df) < MIN_OBS * 2:
            return dict(SAFE_RETURN)

        n = len(df)
        mid = n // 2
        break_idx = df.index[mid]

        y = df[target_series].values.astype(float)
        X = sm.add_constant(df[base_series].values.astype(float))
        y1, X1 = y[:mid], X[:mid]
        y2, X2 = y[mid:], X[mid:]

        if len(y1) < MIN_OBS or len(y2) < MIN_OBS:
            return dict(SAFE_RETURN)

        try:
            m_full = sm.OLS(y, X).fit()
            m1 = sm.OLS(y1, X1).fit()
            m2 = sm.OLS(y2, X2).fit()
        except Exception as e:
            logger.warning(
                "detect_structural_break OLS failed %s/%s: %s",
                base_series,
                target_series,
                e,
            )
            return dict(SAFE_RETURN)

        rss_full = float(m_full.ssr)
        rss1 = float(m1.ssr)
        rss2 = float(m2.ssr)
        k = 2

        denom = (rss1 + rss2) / (n - 2 * k)
        if denom == 0 or not np.isfinite(denom):
            return dict(SAFE_RETURN)

        f_stat = ((rss_full - rss1 - rss2) / k) / denom
        if not np.isfinite(f_stat):
            return dict(SAFE_RETURN)

        p_value = float(1 - stats.f.cdf(f_stat, k, n - 2 * k))
        if not np.isfinite(p_value):
            return dict(SAFE_RETURN)

        break_detected = p_value < significance and f_stat > 0
        post_break_n = len(y2)
        recommendation = (
            "use_post_break"
            if break_detected and post_break_n >= MIN_OBS
            else "use_full"
        )

        if hasattr(break_idx, "date"):
            break_date_str = str(break_idx.date())
        else:
            break_date_str = str(break_idx)

        return {
            "break_detected": break_detected,
            "break_date": break_date_str,
            "f_statistic": round(float(f_stat), 4),
            "p_value": round(float(p_value), 4),
            "post_break_n": post_break_n,
            "recommendation": recommendation,
        }
    except Exception as e:
        logger.warning(
            "detect_structural_break failed %s/%s: %s",
            base_series,
            target_series,
            e,
        )
        return dict(SAFE_RETURN)


def estimate_optimal_decay(
    conn,
    base_series: str,
    target_series: str,
    candidate_decays: list | None = None,
    validation_days: int = 60,
    training_days: int = 192,
) -> float:
    """
    WLS with exponential decay weights; pick decay minimizing validation MSE.
    Returns float in [0.85, 1.0] or 1.0 on failure / tie.
    """
    try:
        candidate_decays = list(
            candidate_decays or [0.85, 0.90, 0.94, 0.97, 1.0]
        )
        MIN_REQUIRED = training_days + validation_days

        df = get_aligned_returns(
            conn,
            [base_series, target_series],
            MIN_REQUIRED + 30,
        )
        if df is None or len(df) < MIN_REQUIRED:
            return 1.0
        df = df.dropna()
        if len(df) < MIN_REQUIRED:
            return 1.0

        train = df.iloc[:training_days]
        val = df.iloc[
            training_days : training_days + validation_days
        ]

        if len(train) < 30 or len(val) < 10:
            return 1.0

        best_decay = 1.0
        best_mse = float("inf")
        mse_values: list[float] = []

        for decay in candidate_decays:
            try:
                n = len(train)
                weights = np.array(
                    [decay ** (n - 1 - i) for i in range(n)]
                )
                y_t = train[target_series].values.astype(float)
                X_t = sm.add_constant(
                    train[base_series].values.astype(float)
                )
                model = sm.WLS(y_t, X_t, weights=weights).fit()

                X_v = sm.add_constant(
                    val[base_series].values.astype(float)
                )
                y_pred = model.predict(X_v)
                y_true = val[target_series].values.astype(float)
                mse = float(np.mean((y_true - y_pred) ** 2))
                mse_values.append(mse)

                if mse < best_mse:
                    best_mse = mse
                    best_decay = decay
            except Exception:
                mse_values.append(float("inf"))
                continue

        valid_mses = [m for m in mse_values if m != float("inf")]
        if len(valid_mses) < 2 or (
            max(valid_mses) - min(valid_mses) < 1e-6
        ):
            return 1.0

        return float(best_decay)
    except Exception as e:
        logger.warning(
            "estimate_optimal_decay failed %s/%s: %s",
            base_series,
            target_series,
            e,
        )
        return 1.0


def update_beta_metadata(
    conn,
    base_series: str,
    target_series_list: list,
) -> int:
    """
    Upsert structural break + optimal decay per target into beta_metadata.
    Never raises; returns count of successful upserts.
    """
    count = 0
    n_t = len(target_series_list)
    for i, target in enumerate(target_series_list):
        if i % 10 == 0:
            logger.info(
                "update_beta_metadata: %s/%s (base=%s)",
                i,
                n_t,
                base_series,
            )
        try:
            brk = detect_structural_break(conn, base_series, target)
            decay = estimate_optimal_decay(conn, base_series, target)

            cur = conn.cursor()
            try:
                cur.execute(
                    """
                    INSERT INTO beta_metadata
                      (base_series_id, target_series_id,
                       optimal_decay, break_date,
                       break_detected, last_computed)
                    VALUES (%s, %s, %s, %s, %s, NOW())
                    ON CONFLICT (base_series_id,
                                 target_series_id)
                    DO UPDATE SET
                      optimal_decay  = EXCLUDED.optimal_decay,
                      break_date     = EXCLUDED.break_date,
                      break_detected = EXCLUDED.break_detected,
                      last_computed  = NOW()
                    """,
                    (
                        base_series,
                        target,
                        decay,
                        brk.get("break_date"),
                        brk.get("break_detected", False),
                    ),
                )
            finally:
                cur.close()
            conn.commit()
            count += 1
        except Exception as e:
            logger.warning(
                "update_beta_metadata failed %s->%s: %s",
                base_series,
                target,
                e,
            )
            continue

    return count
