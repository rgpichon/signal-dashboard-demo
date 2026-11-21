"""
Update positioning_signals with percentile_52w and crowding_flag from net_spec history.
Crowding: True if percentile > 0.90 or < 0.10. Use available history if < 52 weeks.
"""
import logging
from datetime import date, timedelta

logger = logging.getLogger("signals.analytics")

IDEAL_WEEKS = 52


def run_cftc_signals(conn) -> tuple:
    """
    For each series_id in positioning_signals with sufficient history, compute net_spec
    percentile and set crowding_flag. Update percentile_52w and crowding_flag.
    Returns (rows_updated, crowding_flags_set). Logs warning and returns (0, 0) if table empty.
    """
    cur = conn.cursor()
    try:
        cur.execute("SELECT COUNT(*) FROM positioning_signals")
        if cur.fetchone()[0] == 0:
            logger.warning("positioning_signals is empty (CFTC adapter may return 0); skipping CFTC signals")
            return 0, 0
        cur.execute("SELECT DISTINCT series_id FROM positioning_signals")
        series_ids = [r[0] for r in cur.fetchall()]
    finally:
        cur.close()

    rows_updated = 0
    crowding_set = 0

    for series_id in series_ids:
        cur = conn.cursor()
        try:
            cur.execute("""
                SELECT date, net_spec FROM positioning_signals
                WHERE series_id = %s AND net_spec IS NOT NULL
                ORDER BY date
            """, (series_id,))
            rows = cur.fetchall()
        finally:
            cur.close()

        if len(rows) < 2:
            continue

        net_specs = [float(r[1]) for r in rows]
        dates = [r[0] for r in rows]
        n = len(net_specs)
        sorted_specs = sorted(net_specs)

        for i, (d, net_spec) in enumerate(zip(dates, net_specs)):
            hist = net_specs[: i + 1]
            if len(hist) < 2:
                continue
            sorted_hist = sorted(hist)
            rank = sum(1 for x in sorted_hist if x < net_spec)
            percentile = rank / (len(sorted_hist) - 1) if len(sorted_hist) > 1 else 0.5
            percentile = min(1.0, max(0.0, percentile))
            crowding = percentile > 0.90 or percentile < 0.10

            cur = conn.cursor()
            try:
                cur.execute("""
                    UPDATE positioning_signals
                    SET percentile_52w = %s, crowding_flag = %s
                    WHERE series_id = %s AND date = %s
                """, (percentile, crowding, series_id, d))
                if cur.rowcount:
                    rows_updated += 1
                    if crowding:
                        crowding_set += 1
            finally:
                cur.close()

    logger.info("CFTC signals: %s rows updated, %s crowding flags set", rows_updated, crowding_set)
    return rows_updated, crowding_set
