"""
YFinance adapter. Fetches 30 days of daily close for instruments with yfinance_ticker;
writes to market_data with series_id = instrument.id, source = 'yfinance'.
Deduplicates on (date, series_id).
"""
import logging
from datetime import date, timedelta
from typing import List

import yfinance as yf

logger = logging.getLogger("signals.ingestion")


def run_yfinance_backfill(conn, start: date, end: date) -> int:
    """
    Pull yfinance close for all instruments with yfinance_ticker over [start, end].
    Returns number of rows inserted. Use for historical backfill (e.g. 90 days).
    """
    cur = conn.cursor()
    try:
        cur.execute(
            "SELECT id, yfinance_ticker FROM instruments WHERE yfinance_ticker IS NOT NULL AND yfinance_ticker != ''"
        )
        rows = cur.fetchall()
    finally:
        cur.close()

    if not rows:
        return 0

    total_inserted = 0
    for instrument_id, ticker in rows:
        ticker = (ticker or "").strip()
        if not ticker:
            continue
        try:
            obj = yf.Ticker(ticker)
            hist = obj.history(start=start, end=end, auto_adjust=True)
        except Exception as e:
            logger.warning("yfinance fetch failed for %s (%s): %s", ticker, instrument_id, e)
            continue

        if hist is None or hist.empty:
            continue

        hist = hist.sort_index()
        prev_value = None
        cur = conn.cursor()
        try:
            for dt, row in hist.iterrows():
                try:
                    close = float(row.get("Close", row.get("Close", 0)))
                except (TypeError, ValueError):
                    continue
                d = dt.date() if hasattr(dt, "date") else date.fromisoformat(str(dt)[:10])
                if d < start or d > end:
                    continue
                daily_chg = (close - prev_value) if prev_value is not None else None
                pct_chg = (100.0 * (close - prev_value) / prev_value) if prev_value and prev_value != 0 else None
                cur.execute(
                    """
                    INSERT INTO market_data (date, series_id, value, daily_chg, pct_chg, source)
                    SELECT %s, %s, %s, %s, %s, 'yfinance'
                    WHERE NOT EXISTS (SELECT 1 FROM market_data WHERE date = %s AND series_id = %s)
                    """,
                    (d, instrument_id, close, daily_chg, pct_chg, d, instrument_id),
                )
                if cur.rowcount:
                    total_inserted += 1
                prev_value = close
        finally:
            cur.close()

    return total_inserted


def run_yfinance(conn, source_id: str, config: dict) -> int:
    """
    Query instruments where yfinance_ticker is not null; pull 30 days close for each;
    write to market_data. Returns number of rows inserted. Never raises.
    """
    cur = conn.cursor()
    try:
        cur.execute(
            "SELECT id, yfinance_ticker FROM instruments WHERE yfinance_ticker IS NOT NULL AND yfinance_ticker != ''"
        )
        rows = cur.fetchall()
    finally:
        cur.close()

    if not rows:
        return 0

    end = date.today()
    start = end - timedelta(days=30)
    total_inserted = 0

    for instrument_id, ticker in rows:
        ticker = (ticker or "").strip()
        if not ticker:
            continue
        try:
            obj = yf.Ticker(ticker)
            hist = obj.history(start=start, end=end, auto_adjust=True)
        except Exception as e:
            logger.warning("yfinance fetch failed for %s (%s): %s", ticker, instrument_id, e)
            try:
                c = conn.cursor()
                c.execute(
                    "INSERT INTO pipeline_errors (source_id, error_type, error_msg) VALUES (%s, %s, %s)",
                    (source_id, "fetch_error", f"{ticker}: {str(e)[:200]}"),
                )
                c.close()
            except Exception:
                pass
            continue

        if hist is None or hist.empty:
            continue

        hist = hist.sort_index()
        prev_value = None
        cur = conn.cursor()
        try:
            for dt, row in hist.iterrows():
                try:
                    close = float(row.get("Close", row.get("Close", 0)))
                except (TypeError, ValueError):
                    continue
                d = dt.date() if hasattr(dt, "date") else date.fromisoformat(str(dt)[:10])
                daily_chg = (close - prev_value) if prev_value is not None else None
                pct_chg = (100.0 * (close - prev_value) / prev_value) if prev_value and prev_value != 0 else None
                cur.execute(
                    """
                    INSERT INTO market_data (date, series_id, value, daily_chg, pct_chg, source)
                    SELECT %s, %s, %s, %s, %s, 'yfinance'
                    WHERE NOT EXISTS (SELECT 1 FROM market_data WHERE date = %s AND series_id = %s)
                    """,
                    (d, instrument_id, close, daily_chg, pct_chg, d, instrument_id),
                )
                if cur.rowcount:
                    total_inserted += 1
                prev_value = close
        finally:
            cur.close()

    return total_inserted
