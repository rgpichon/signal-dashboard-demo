"""
Screen thesis candidates from daily_signals and anomalies.
A candidate is flagged when at least 2 of conditions A–E are true for the same topic.
During cold start (data_quality = 'velocity_cold_start'), only C, D, E apply.
"""
import logging
from datetime import date, timedelta
from typing import Any, Optional

logger = logging.getLogger("signals.thesis")

MAX_CANDIDATES = 5
DEDUPE_DAYS = 5
MARKET_MOVE_SIGMA = 1.5
MARKET_LOOKBACK_DAYS = 5
MARKET_ROLLING_DAYS = 90


def run_screener(conn, target_date: Optional[date] = None) -> list[dict]:
    """
    Return list of candidate dicts: [{topic, conditions_met, sentiment_magnitude, forced}, ...].
    Max 5; if zero qualify naturally, one forced candidate (topic with highest article_count today).
    """
    target_date = target_date or date.today()
    cur = conn.cursor()

    # Today's daily_signals (topic -> row)
    cur.execute("""
        SELECT topic, article_count, velocity_7d, sentiment_avg, divergence_flag, anomaly_flag, data_quality
        FROM daily_signals
        WHERE date = %s
    """, (target_date,))
    rows = cur.fetchall()
    topic_to_signal = {}
    for r in rows:
        topic_to_signal[r[0]] = {
            "article_count": r[1],
            "velocity_7d": r[2],
            "sentiment_avg": r[3],
            "divergence_flag": r[4],
            "anomaly_flag": r[5],
            "data_quality": r[6] or "ok",
        }

    if not topic_to_signal:
        cur.execute("SELECT date FROM daily_signals ORDER BY date DESC LIMIT 1")
        row = cur.fetchone()
        if row:
            fallback_date = row[0]
            cur.execute("""
                SELECT topic, article_count, velocity_7d, sentiment_avg, divergence_flag, anomaly_flag, data_quality
                FROM daily_signals WHERE date = %s
            """, (fallback_date,))
            for r in cur.fetchall():
                topic_to_signal[r[0]] = {
                    "article_count": r[1],
                    "velocity_7d": r[2],
                    "sentiment_avg": r[3],
                    "divergence_flag": r[4],
                    "anomaly_flag": r[5],
                    "data_quality": r[6] or "ok",
                }
            logger.info("Screener: no daily_signals for %s; using fallback date %s", target_date, fallback_date)
        if not topic_to_signal:
            logger.warning("Screener: no daily_signals at all")
            return []

    # Topics with anomalies today
    cur.execute("""
        SELECT topic FROM anomalies
        WHERE detected_at::date = %s AND resolved = FALSE
    """, (target_date,))
    anomaly_topics = {r[0] for r in cur.fetchall() if r[0]}

    # Correlated series for each topic (for condition C)
    cur.execute("SELECT topic, series_id FROM correlations WHERE lag_days = 0")
    topic_series = {}
    for (t, s) in cur.fetchall():
        topic_series.setdefault(t, []).append(s)

    # Market moves: series_id -> pct_chg over last 5 days (sum or last 5d move)
    five_d_ago = target_date - timedelta(days=MARKET_LOOKBACK_DAYS)
    cur.execute("""
        SELECT series_id, date, value, pct_chg
        FROM market_data
        WHERE date >= %s AND date <= %s AND value IS NOT NULL
        ORDER BY series_id, date
    """, (five_d_ago, target_date))
    series_dates = {}
    for (sid, d, val, pct_chg) in cur.fetchall():
        series_dates.setdefault(sid, []).append((d, val, pct_chg))

    # 90d rolling std per series (for sigma move)
    cur.execute("""
        SELECT series_id, date, value FROM market_data
        WHERE date >= %s AND date <= %s AND value IS NOT NULL
    """, (target_date - timedelta(days=MARKET_ROLLING_DAYS), target_date))
    series_vals = {}
    for (sid, d, val) in cur.fetchall():
        series_vals.setdefault(sid, []).append(float(val))

    def series_moved_above_sigma(topic: str) -> bool:
        for sid in topic_series.get(topic, []):
            vals = series_vals.get(sid, [])
            if len(vals) < 10:
                continue
            mean = sum(vals) / len(vals)
            var = sum((x - mean) ** 2 for x in vals) / max(len(vals) - 1, 1)
            std = var ** 0.5 if var > 0 else 1e-9
            points = series_dates.get(sid, [])
            if not points:
                continue
            # Cumulative move over last 5 days (approx: product of (1+pct) or sum pct)
            recent = sorted(points, key=lambda x: x[0])[-MARKET_LOOKBACK_DAYS:]
            cum_pct = 1.0
            for (_, _, pct) in recent:
                if pct is not None:
                    cum_pct *= (1 + pct / 100.0)
            move_pct = (cum_pct - 1.0) * 100
            if std and abs(move_pct) > MARKET_MOVE_SIGMA * (std / mean * 100 if mean else 0):
                return True
            # Simpler: any single day move > 1.5 sigma in pct terms
            for (_, _, pct) in recent:
                if pct is not None and abs(pct) > MARKET_MOVE_SIGMA * 2:
                    return True
        return False

    # Positioning: crowding for instruments related to topic (themes contain topic)
    cur.execute("""
        SELECT i.id, ps.crowding_flag, ps.direction
        FROM instruments i
        JOIN positioning_signals ps ON ps.series_id = i.id
        WHERE ps.date = %s AND i.themes IS NOT NULL
    """, (target_date,))
    pos_rows = cur.fetchall()
    positioning_by_series = {r[0]: (r[1], r[2]) for r in pos_rows}
    cur.execute("SELECT id, themes FROM instruments WHERE themes IS NOT NULL")
    series_to_themes = {r[0]: set(r[1] or []) for r in cur.fetchall()}

    def crowding_for_topic(topic: str) -> bool:
        for sid, themes in series_to_themes.items():
            if topic in themes and sid in positioning_by_series:
                flag, _ = positioning_by_series[sid]
                if flag:
                    return True
        return False

    # Regime: today vs yesterday fingerprint
    cur.execute("SELECT fingerprint FROM regime_snapshots WHERE date = %s", (target_date,))
    row_t = cur.fetchone()
    today_fp = row_t[0] if row_t else None
    yesterday = target_date - timedelta(days=1)
    cur.execute("SELECT fingerprint FROM regime_snapshots WHERE date = %s", (yesterday,))
    row_y = cur.fetchone()
    yesterday_fp = row_y[0] if row_y else None
    regime_changed = (today_fp and yesterday_fp and today_fp != yesterday_fp)

    # Recent theses by theme (for dedupe)
    since = target_date - timedelta(days=DEDUPE_DAYS)
    cur.execute("""
        SELECT theme FROM theses WHERE generated_at::date >= %s
    """, (since,))
    recent_themes = set()
    for r in cur.fetchall():
        if r[0]:
            for t in (r[0] or "").split(","):
                recent_themes.add(t.strip())

    def count_conditions(topic: str, cold_start: bool) -> int:
        sig = topic_to_signal.get(topic, {})
        n = 0
        if not cold_start:
            if sig.get("anomaly_flag"):
                n += 1
            if sig.get("divergence_flag"):
                n += 1
        if series_moved_above_sigma(topic):
            n += 1
        if crowding_for_topic(topic):
            n += 1
        if regime_changed:
            n += 1
        return n

    candidates = []
    for topic, sig in topic_to_signal.items():
        if topic in recent_themes:
            continue
        cold_start = (sig.get("data_quality") == "velocity_cold_start")
        conditions_met = count_conditions(topic, cold_start)
        if conditions_met >= 2:
            sentiment_mag = abs(float(sig.get("sentiment_avg") or 0))
            candidates.append({
                "topic": topic,
                "conditions_met": conditions_met,
                "sentiment_magnitude": sentiment_mag,
                "forced": False,
                "article_count": sig.get("article_count") or 0,
                "velocity_7d": sig.get("velocity_7d"),
                "sentiment_avg": sig.get("sentiment_avg"),
                "data_quality": sig.get("data_quality"),
            })

    # Rank: conditions_met desc, then sentiment_magnitude desc
    candidates.sort(key=lambda c: (c["conditions_met"], c["sentiment_magnitude"]), reverse=True)
    candidates = candidates[:MAX_CANDIDATES]

    if not candidates:
        best_topic = max(topic_to_signal.items(), key=lambda x: (x[1].get("article_count") or 0, abs(float(x[1].get("sentiment_avg") or 0))))
        topic = best_topic[0]
        sig = best_topic[1]
        candidates = [{
            "topic": topic,
            "conditions_met": 0,
            "sentiment_magnitude": abs(float(sig.get("sentiment_avg") or 0)),
            "forced": True,
            "article_count": sig.get("article_count") or 0,
            "velocity_7d": sig.get("velocity_7d"),
            "sentiment_avg": sig.get("sentiment_avg"),
            "data_quality": sig.get("data_quality"),
        }]
        logger.info("Screener: zero candidates; forcing one for topic=%s", topic)

    cur.close()
    return candidates
