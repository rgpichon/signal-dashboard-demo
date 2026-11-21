"""
RSI, MACD, Bollinger, momentum score. Single-instrument and cross-asset.
"""
from datetime import date, timedelta
from typing import Any

import numpy as np

MIN_OBS = 30


def compute_rsi(prices: np.ndarray, period: int = 14) -> np.ndarray:
    deltas = np.diff(prices)
    gains = np.where(deltas > 0, deltas, 0)
    losses = np.where(deltas < 0, -deltas, 0)
    avg_gain = np.zeros_like(prices)
    avg_loss = np.zeros_like(prices)
    avg_gain[period] = np.mean(gains[:period])
    avg_loss[period] = np.mean(losses[:period])
    for i in range(period + 1, len(prices)):
        avg_gain[i] = (avg_gain[i - 1] * (period - 1) + gains[i - 1]) / period
        avg_loss[i] = (avg_loss[i - 1] * (period - 1) + losses[i - 1]) / period
    rs = np.where(np.greater(avg_loss, 1e-12), avg_gain / np.maximum(avg_loss, 1e-12), 100)
    rsi = 100 - (100 / (1 + rs))
    rsi[: period + 1] = np.nan
    return rsi


def _ema(arr: np.ndarray, span: int) -> np.ndarray:
    out = np.full_like(arr, np.nan, dtype=float)
    out[0] = arr[0]
    alpha = 2 / (span + 1)
    for i in range(1, len(arr)):
        out[i] = alpha * arr[i] + (1 - alpha) * out[i - 1]
    return out


def compute_macd(prices: np.ndarray, fast: int = 12, slow: int = 26, signal: int = 9) -> dict:
    ema_f = _ema(prices, fast)
    ema_s = _ema(prices, slow)
    macd_line = ema_f - ema_s
    valid = ~np.isnan(macd_line)
    macd_flat = macd_line[valid]
    sig_full = np.full_like(macd_line, np.nan)
    if len(macd_flat) >= signal:
        signal_line = _ema(macd_flat, signal)
        sig_full[valid] = signal_line
    histogram = macd_line - sig_full
    crossover = None
    for i in range(1, len(histogram)):
        if not np.isnan(histogram[i]) and not np.isnan(histogram[i - 1]):
            if histogram[i - 1] <= 0 < histogram[i]:
                crossover = f"bullish crossover {len(histogram) - i - 1} days ago"
                break
            if histogram[i - 1] >= 0 > histogram[i]:
                crossover = f"bearish crossover {len(histogram) - i - 1} days ago"
                break
    return {
        "value": round(float(macd_line[-1]), 4) if not np.isnan(macd_line[-1]) else None,
        "signal": round(float(sig_full[-1]), 4) if not np.isnan(sig_full[-1]) else None,
        "histogram": round(float(histogram[-1]), 4) if not np.isnan(histogram[-1]) else None,
        "crossover": crossover,
    }


def compute_bollinger(prices: np.ndarray, window: int = 20, num_std: float = 2) -> dict:
    if len(prices) < window:
        return {"upper": None, "middle": None, "lower": None, "pct_b": None, "bandwidth": None}
    mid = np.mean(prices[-window:])
    std = np.std(prices[-window:])
    upper = mid + num_std * std
    lower = mid - num_std * std
    p = prices[-1]
    pct_b = (p - lower) / (upper - lower) if upper != lower else 0.5
    bandwidth = (upper - lower) / mid if mid and mid != 0 else None
    return {
        "upper": round(float(upper), 4),
        "middle": round(float(mid), 4),
        "lower": round(float(lower), 4),
        "pct_b": round(float(pct_b), 4),
        "bandwidth": round(float(bandwidth), 4) if bandwidth is not None else None,
    }


def compute_momentum_score(returns_1m: float, returns_3m: float, returns_6m: float, vol_1m: float, vol_3m: float, vol_6m: float) -> float:
    if vol_1m <= 0:
        vol_1m = 0.01
    if vol_3m <= 0:
        vol_3m = 0.01
    if vol_6m <= 0:
        vol_6m = 0.01
    raw = 0.4 * (returns_1m / vol_1m) + 0.35 * (returns_3m / vol_3m) + 0.25 * (returns_6m / vol_6m)
    return round(float(np.tanh(raw)), 4)


def compute_momentum(conn, series_ids: list[str], days: int = 180) -> dict[str, Any]:
    instruments = []
    for sid in series_ids:
        cur = conn.cursor()
        try:
            end = date.today()
            start = end - timedelta(days=days + 30)
            cur.execute(
                "SELECT date, value, pct_chg FROM market_data WHERE series_id = %s AND date >= %s AND date <= %s ORDER BY date",
                (sid, start, end),
            )
            rows = cur.fetchall()
        finally:
            cur.close()
        if not rows or len(rows) < 50:
            continue
        dates = [r[0] for r in rows]
        values = np.array([float(r[1]) for r in rows])
        pct_chg = [float(r[2]) if r[2] is not None else 0 for r in rows]
        n = len(values)
        current = float(values[-1])
        sma_20 = float(np.mean(values[-20:])) if n >= 20 else current
        sma_50 = float(np.mean(values[-50:])) if n >= 50 else current
        sma_200 = float(np.mean(values[-200:])) if n >= 200 else current
        above_sma_20 = current > sma_20
        above_sma_50 = current > sma_50 if n >= 50 else None
        above_sma_200 = current > sma_200 if n >= 200 else None
        rsi_vals = compute_rsi(values, 14)
        rsi_14 = round(float(rsi_vals[-1]), 2) if not np.isnan(rsi_vals[-1]) else None
        macd = compute_macd(values, 12, 26, 9)
        bollinger = compute_bollinger(values, 20, 2)
        tr_approx = np.abs(np.diff(values)) if len(values) > 1 else np.array([0])
        atr_14 = round(float(np.mean(tr_approx[-14:])), 4) if len(tr_approx) >= 14 else None
        ret_1m = (values[-1] / values[-22] - 1) * 100 if n >= 22 else 0
        ret_3m = (values[-1] / values[-64] - 1) * 100 if n >= 64 else 0
        ret_6m = (values[-1] / values[-127] - 1) * 100 if n >= 127 else 0
        vol_1m = float(np.std(pct_chg[-21:])) * np.sqrt(252) if n >= 21 else 1
        vol_3m = float(np.std(pct_chg[-63:])) * np.sqrt(252) if n >= 63 else 1
        vol_6m = float(np.std(pct_chg[-126:])) * np.sqrt(252) if n >= 126 else 1
        mom_score = compute_momentum_score(ret_1m, ret_3m, ret_6m, vol_1m, vol_3m, vol_6m)
        if above_sma_200 and above_sma_50 and above_sma_20:
            trend = "STRONG_UP"
        elif above_sma_50 and above_sma_20:
            trend = "UP"
        elif not above_sma_20 and (above_sma_50 is False or not above_sma_50) and (above_sma_200 is False or not above_sma_200):
            trend = "STRONG_DOWN"
        elif not above_sma_20 and (above_sma_50 is False or not above_sma_50):
            trend = "DOWN"
        else:
            trend = "NEUTRAL"
        hist = macd.get("histogram") or 0
        if trend in ("STRONG_UP", "UP") and (rsi_14 is None or rsi_14 < 70) and hist > 0:
            signal = "BULLISH"
        elif trend in ("STRONG_DOWN", "DOWN") and (rsi_14 is None or rsi_14 > 30) and hist < 0:
            signal = "BEARISH"
        else:
            signal = "NEUTRAL"
        cur = conn.cursor()
        try:
            cur.execute("SELECT name FROM instruments WHERE id = %s", (sid,))
            row = cur.fetchone()
            name = (row[0] or sid) if row else sid
        finally:
            cur.close()
        instruments.append({
            "series_id": sid,
            "name": name,
            "sma_20": round(sma_20, 4),
            "sma_50": round(sma_50, 4) if n >= 50 else None,
            "sma_200": round(sma_200, 4) if n >= 200 else None,
            "current": round(current, 4),
            "above_sma_20": above_sma_20,
            "above_sma_50": above_sma_50,
            "above_sma_200": above_sma_200,
            "rsi_14": rsi_14,
            "momentum_1m": round(ret_1m, 2),
            "momentum_3m": round(ret_3m, 2),
            "momentum_6m": round(ret_6m, 2),
            "momentum_score": mom_score,
            "trend": trend,
            "macd": macd,
            "bollinger": bollinger,
            "atr_14": atr_14,
            "signal": signal,
        })
    return {"instruments": instruments}


def compute_momentum_cross_asset(conn, days: int = 90) -> dict[str, Any]:
    cur = conn.cursor()
    try:
        cur.execute(
            "SELECT DISTINCT series_id FROM market_data"
        )
        all_ids = [r[0] for r in cur.fetchall()]
    finally:
        cur.close()
    result = compute_momentum(conn, all_ids, days)
    result["instruments"].sort(key=lambda x: x.get("momentum_score") or 0, reverse=True)
    return result
