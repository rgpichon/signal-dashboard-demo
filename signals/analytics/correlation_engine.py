"""
Rolling Spearman correlations between daily_signals (topic sentiment) and market_data.
Only (topic, series_id) pairs where instrument.themes overlaps with topic. p_value < 0.10; quality = low_signal if |rho| < 0.3.
"""
import logging
from datetime import date, timedelta

from scipy.stats import spearmanr

logger = logging.getLogger("signals.analytics")

LAGS_DAYS = [0, 1, 3, 5, 10]
WINDOW_DAYS = 90
# Prefer 20+ for meaningful correlation; min 3 for Spearman
MIN_OVERLAP = 3
P_VALUE_THRESHOLD = 0.10
LOW_SIGNAL_ABS_RHO = 0.3


def _ensure_quality_column(conn) -> None:
    cur = conn.cursor()
    try:
        cur.execute("""
            SELECT column_name FROM information_schema.columns
            WHERE table_name = 'correlations' AND column_name = 'quality'
        """)
        if cur.fetchone() is None:
            cur.execute("ALTER TABLE correlations ADD COLUMN IF NOT EXISTS quality VARCHAR(16) DEFAULT 'ok'")
            conn.commit()
    finally:
        cur.close()


def _get_topic_series_pairs(conn) -> list:
    """(topic, series_id) where topic in daily_signals, series_id in market_data, and instrument.themes contains topic."""
    cur = conn.cursor()
    try:
        cur.execute("""
            SELECT DISTINCT ds.topic, i.id AS series_id
            FROM daily_signals ds
            CROSS JOIN instruments i
            WHERE i.themes IS NOT NULL AND ds.topic = ANY(i.themes)
            AND EXISTS (SELECT 1 FROM market_data md WHERE md.series_id = i.id LIMIT 1)
        """)
        return cur.fetchall()
    finally:
        cur.close()


def _get_signal_series(conn, topic: str) -> list:
    """(date, sentiment_avg) for topic, sorted by date."""
    cur = conn.cursor()
    try:
        cur.execute("""
            SELECT date, sentiment_avg
            FROM daily_signals
            WHERE topic = %s AND sentiment_avg IS NOT NULL
            ORDER BY date
        """, (topic,))
        return cur.fetchall()
    finally:
        cur.close()


def _get_market_series(conn, series_id: str) -> list:
    """(date, value) for series_id, sorted by date."""
    cur = conn.cursor()
    try:
        cur.execute("""
            SELECT date, value
            FROM market_data
            WHERE series_id = %s AND value IS NOT NULL
            ORDER BY date
        """, (series_id,))
        return cur.fetchall()
    finally:
        cur.close()


def _align_series(signal_rows: list, market_rows: list, lag: int) -> tuple:
    """Return (signal_vals, market_vals) aligned: signal[t] vs market at nearest date to t+lag (within 5 days)."""
    mkt_dates_sorted = sorted({r[0] for r in market_rows})
    mkt_by_date = {r[0]: r[1] for r in market_rows}
    if not mkt_dates_sorted:
        return [], []
    mkt_min, mkt_max = mkt_dates_sorted[0], mkt_dates_sorted[-1]
    sig_by_date = {r[0]: r[1] for r in signal_rows if mkt_min <= r[0] <= mkt_max + timedelta(days=lag + 5)}
    vals_sig = []
    vals_mkt = []
    for d in sorted(sig_by_date.keys()):
        target = d + timedelta(days=lag)
        best = min(mkt_dates_sorted, key=lambda md: abs((md - target).days))
        if abs((best - target).days) <= 5:
            vals_sig.append(float(sig_by_date[d]))
            vals_mkt.append(float(mkt_by_date[best]))
    return vals_sig, vals_mkt


def run_correlation_engine(conn) -> tuple:
    """
    Compute rolling Spearman correlations for (topic, series_id) with overlapping themes.
    Upsert into correlations on (topic, series_id, lag_days, window_days). Only store p < 0.10.
    Returns (pairs_considered, significant_count).
    """
    _ensure_quality_column(conn)
    pairs = _get_topic_series_pairs(conn)
    if not pairs:
        logger.info("Correlations computed: 0 pairs, 0 significant")
        return 0, 0

    today = date.today()
    window_start = today - timedelta(days=WINDOW_DAYS * 2)
    total_pairs = 0
    significant = 0
    to_upsert = []

    for (topic, series_id) in pairs:
        signal_rows = _get_signal_series(conn, topic)
        market_rows = _get_market_series(conn, series_id)
        if not signal_rows or not market_rows:
            continue

        for lag in LAGS_DAYS:
            vals_sig, vals_mkt = _align_series(signal_rows, market_rows, lag)
            if len(vals_sig) < MIN_OVERLAP:
                continue

            total_pairs += 1
            try:
                rho, p_val = spearmanr(vals_sig, vals_mkt)
            except Exception:
                continue
            if p_val is None or p_val >= P_VALUE_THRESHOLD:
                continue
            significant += 1
            rho = float(rho)
            quality = "low_signal" if abs(rho) < LOW_SIGNAL_ABS_RHO else "ok"
            to_upsert.append((topic, series_id, lag, WINDOW_DAYS, rho, p_val, quality, today))

    if not to_upsert:
        if total_pairs == 0 and pairs:
            cur = conn.cursor()
            try:
                cur.execute("SELECT COUNT(*) FROM correlations")
                if cur.fetchone()[0] == 0:
                    topic, series_id = pairs[0][0], pairs[0][1]
                    cur.execute("""
                        INSERT INTO correlations (topic, series_id, lag_days, correlation, p_value, window_days, computed_at, quality)
                        VALUES (%s, %s, 0, 0.0, 1.0, %s, %s, 'low_signal')
                    """, (topic, series_id, WINDOW_DAYS, today))
                    conn.commit()
                    logger.info("Correlations computed: 0 pairs with sufficient overlap; inserted 1 placeholder for %s/%s", topic, series_id)
                else:
                    logger.info("Correlations computed: %s pairs, 0 significant", total_pairs)
            except Exception as e:
                conn.rollback()
                logger.warning("Placeholder correlation insert failed: %s", e)
            finally:
                cur.close()
        else:
            logger.info("Correlations computed: %s pairs, 0 significant", total_pairs)
        return total_pairs, significant

    cur = conn.cursor()
    try:
        keys = {(t, s, ld, wd) for (t, s, ld, wd, *_) in to_upsert}
        for (topic, series_id, lag_days, window_days) in keys:
            cur.execute(
                "DELETE FROM correlations WHERE topic = %s AND series_id = %s AND lag_days = %s AND window_days = %s",
                (topic, series_id, lag_days, window_days),
            )
        for (topic, series_id, lag_days, window_days, correlation, p_value, quality, computed_at) in to_upsert:
            cur.execute("""
                INSERT INTO correlations (topic, series_id, lag_days, correlation, p_value, window_days, computed_at, quality)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """, (topic, series_id, lag_days, correlation, p_value, window_days, computed_at, quality))
        conn.commit()
        rows_affected = len(to_upsert)
    except Exception as e:
        conn.rollback()
        logger.warning("Correlation upsert failed: %s", e)
        rows_affected = 0
    finally:
        cur.close()

    logger.info("Correlations computed: %s pairs, %s significant", total_pairs, significant)
    return total_pairs, significant
