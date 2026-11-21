"""
One-time backfill: 90 days of FRED + yfinance, then re-run signal aggregator,
correlation engine, and regime indicators so analytics have enough history.
Run from repo root: PYTHONPATH=. python signals/backfill_history.py
"""
import logging
from datetime import date, timedelta

from signals.db.connection import get_connection
from signals.ingestion.fred_adapter import run_fred_backfill
from signals.ingestion.yfinance_adapter import run_yfinance_backfill
from signals.ingestion.computed_series import run_computed_series
from signals.processing.signal_aggregator import run_signal_aggregator
from signals.analytics.correlation_engine import run_correlation_engine
from signals.analytics.regime_indicators import run_regime_indicators

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger("signals.backfill")

BACKFILL_DAYS = 90
FRED_SERIES = [
    "DGS3MO",
    "DGS2",
    "DGS5",
    "DGS10",
    "DGS30",
    "T10Y2Y",
    "DFII10",
    "DFII5",
    "T10YIE",
    "T5YIE",
    "BAMLC0A0CM",
    "BAMLH0A0HYM2",
    "CPIAUCSL",
    "UNRATE",
    "INDPRO",
    "RSAFS",
    "UMCSENT",
    "MANEMP",
]


def _count(conn, table: str) -> int:
    cur = conn.cursor()
    try:
        cur.execute(f"SELECT COUNT(*) FROM {table}")
        return cur.fetchone()[0] or 0
    finally:
        cur.close()


def main():
    end = date.today()
    start = end - timedelta(days=BACKFILL_DAYS)
    logger.info("Backfill window: %s to %s (%s days)", start, end, BACKFILL_DAYS)

    with get_connection() as conn:
        # 1. FRED 90 days
        logger.info("Step 1/5: Pulling 90 days of FRED series: %s", FRED_SERIES)
        fred_inserted = run_fred_backfill(conn, FRED_SERIES, start, end)
        logger.info("FRED backfill complete: %s market_data rows inserted", fred_inserted)

        # 2. yfinance 90 days
        logger.info("Step 2/5: Pulling 90 days of yfinance for all instruments with yfinance_ticker")
        yf_inserted = run_yfinance_backfill(conn, start, end)
        logger.info("yfinance backfill complete: %s market_data rows inserted", yf_inserted)

        # 2b. Computed series
        computed_inserted = run_computed_series(conn)
        logger.info("Computed series: %s rows inserted", computed_inserted)

        # 3. Signal aggregator for each date in window
        logger.info("Step 3/5: Re-running signal aggregator over %s to %s", start, end)
        daily_signals_upserted = 0
        d = start
        while d <= end:
            daily_signals_upserted += run_signal_aggregator(conn, d)
            d += timedelta(days=1)
        logger.info("Signal aggregator complete: %s daily_signals rows upserted", daily_signals_upserted)

    # 4. Correlation engine (uses its own connection)
    logger.info("Step 4/5: Re-running correlation engine")
    with get_connection() as conn:
        pairs, sig = run_correlation_engine(conn)
        logger.info("Correlation engine complete: %s pairs, %s significant", pairs, sig)

    # 5. Regime indicators for each date in window
    logger.info("Step 5/5: Re-running regime indicators over %s to %s", start, end)
    with get_connection() as conn:
        regime_count = 0
        d = start
        while d <= end:
            regime_count += run_regime_indicators(conn, d)
            d += timedelta(days=1)
        logger.info("Regime indicators complete: %s regime_snapshots rows", regime_count)

    # Summary counts
    with get_connection() as conn:
        market_data_rows = _count(conn, "market_data")
        daily_signals_rows = _count(conn, "daily_signals")
        correlations_rows = _count(conn, "correlations")
        regime_snapshots_rows = _count(conn, "regime_snapshots")

    print("")
    print("Backfill complete:")
    print("  - market_data rows:", market_data_rows)
    print("  - daily_signals rows:", daily_signals_rows)
    print("  - correlations rows:", correlations_rows)
    print("  - regime_snapshots rows:", regime_snapshots_rows)


if __name__ == "__main__":
    main()
