"""
Aggregate processed articles into daily_signals per (date, topic).
velocity_7d: z-score vs 30d baseline; NULL and data_quality='velocity_cold_start' if < 30 days.
"""
import json
import logging
from datetime import date, timedelta
from typing import Any, Optional

logger = logging.getLogger("signals.processing")


def run_signal_aggregator(conn, target_date: Optional[date] = None) -> int:
    """
    Compute daily_signals for target_date (default today). Upsert on (date, topic).
    Returns number of rows upserted.
    """
    target_date = target_date or date.today()

    # Fetch all processed articles with topics and sentiment, keyed by (article date, topic)
    cur = conn.cursor()
    cur.execute("""
        SELECT id, source_id, published_at, sentiment, sentiment_conf, topics
        FROM articles
        WHERE processed = TRUE AND topics IS NOT NULL AND topics != 'null'::jsonb
    """)
    rows = cur.fetchall()
    cur.close()

    # Group by (article_date, topic) for articles with this topic score > 0.35
    from collections import defaultdict
    by_date_topic = defaultdict(list)  # (d, topic) -> [(sentiment, conf, source_id), ...]

    for (article_id, source_id, published_at, sentiment, sentiment_conf, topics_json) in rows:
        try:
            d = published_at.date() if published_at else None
            if d is None:
                continue
            topics = json.loads(topics_json) if isinstance(topics_json, str) else (topics_json or {})
        except Exception:
            continue
        sentiment = float(sentiment) if sentiment is not None else 0.0
        sentiment_conf = float(sentiment_conf) if sentiment_conf is not None else 0.0
        for topic, score in (topics or {}).items():
            if float(score) < 0.35:
                continue
            by_date_topic[(d, topic)].append((sentiment, sentiment_conf, source_id))

    # Build 30-day history of article counts per topic for velocity
    topic_daily_counts = defaultdict(list)  # topic -> [(date, count), ...] sorted by date
    for (d, topic), items in by_date_topic.items():
        topic_daily_counts[topic].append((d, len(items)))
    for topic in topic_daily_counts:
        topic_daily_counts[topic].sort(key=lambda x: x[0])

    # Sentiment 7 days ago per topic (for divergence)
    topic_sentiment_7d_ago = {}
    seven_d_ago = target_date - timedelta(days=7)
    for (d, topic), items in by_date_topic.items():
        if d != seven_d_ago:
            continue
        w_sum = sum(s * c for s, c, _ in items)
        w_total = sum(c for _, c, _ in items)
        topic_sentiment_7d_ago[topic] = w_sum / w_total if w_total else 0.0

    # Replace target_date's rows: delete then insert (no UNIQUE on date,topic in schema)
    cur = conn.cursor()
    try:
        cur.execute("DELETE FROM daily_signals WHERE date = %s", (target_date,))
    finally:
        cur.close()

    upserted = 0
    cur = conn.cursor()
    try:
        for (d, topic), items in by_date_topic.items():
            if d != target_date:
                continue

            article_count = len(items)
            source_ids = set(x[2] for x in items)
            source_count = len(source_ids)

            # Weighted mean and std of sentiment
            sents = [x[0] for x in items]
            if not items:
                continue
            w_sum = sum(s * c for s, c, _ in items)
            w_total = sum(c for _, c, _ in items)
            sentiment_avg = w_sum / w_total if w_total else 0.0
            if len(sents) > 1:
                variance = sum((s - sentiment_avg) ** 2 for s in sents) / (len(sents) - 1)
                sentiment_std = variance ** 0.5
            else:
                sentiment_std = 0.0

            # Velocity: 7d rolling count vs 30d baseline
            counts = topic_daily_counts.get(topic, [])
            cutoff_30 = target_date - timedelta(days=30)
            last_30 = [(dt, c) for dt, c in counts if cutoff_30 <= dt <= target_date]
            if len(last_30) < 30:  # need 30 days of history
                velocity_7d = None
                anomaly_flag = False
                data_quality = "velocity_cold_start"
            else:
                last_7_dates = [target_date - timedelta(days=k) for k in range(7)]
                date_to_count = dict(last_30)
                rolling_7 = [date_to_count.get(dt, 0) for dt in last_7_dates]
                avg_7 = sum(rolling_7) / 7.0
                counts_30 = [c for _, c in last_30]
                mean_30 = sum(counts_30) / len(counts_30)
                var_30 = sum((c - mean_30) ** 2 for c in counts_30) / max(len(counts_30) - 1, 1)
                std_30 = var_30 ** 0.5 if var_30 > 0 else 1.0
                velocity_7d = (avg_7 - mean_30) / std_30 if std_30 else 0.0
                anomaly_flag = velocity_7d > 2.0
                data_quality = "ok"

            sent_7d = topic_sentiment_7d_ago.get(topic)
            if sent_7d is not None and sentiment_std > 0:
                divergence_flag = abs(sentiment_avg - sent_7d) > 1.5 * sentiment_std
            else:
                divergence_flag = False

            cur.execute("""
                INSERT INTO daily_signals (
                    date, topic, article_count, velocity_7d, sentiment_avg, sentiment_std,
                    source_count, divergence_flag, anomaly_flag, data_quality
                ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """, (
                d, topic, article_count, velocity_7d, sentiment_avg, sentiment_std,
                source_count, divergence_flag, anomaly_flag, data_quality,
            ))
            upserted += 1
    finally:
        cur.close()

    return upserted
