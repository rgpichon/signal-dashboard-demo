"""
Detect 3 anomaly types from daily_signals and correlations; write to anomalies table.
Skip all where data_quality != 'ok'.
"""
import logging
from datetime import date, timedelta
from typing import Optional

logger = logging.getLogger("signals.analytics")


def run_anomaly_detector(conn, target_date: Optional[date] = None) -> tuple:
    """
    Detect velocity, sentiment_divergence, cross_asset_dislocation. Insert into anomalies.
    Returns (n_velocity, n_divergence, n_cross_asset). Only considers data_quality = 'ok'.
    """
    target_date = target_date or date.today()
    n_vel = 0
    n_div = 0
    n_cross = 0

    cur = conn.cursor()
    try:
        # TYPE 1 — velocity
        cur.execute("""
            SELECT topic, velocity_7d
            FROM daily_signals
            WHERE date = %s AND data_quality = 'ok' AND velocity_7d > 2.0
        """, (target_date,))
        for (topic, velocity_7d) in cur.fetchall():
            cur.execute("""
                INSERT INTO anomalies (detected_at, anomaly_type, topic, severity, description)
                VALUES (NOW(), 'velocity', %s, %s, %s)
            """, (topic, float(velocity_7d), f"Topic {topic} velocity_7d = {velocity_7d:.2f} (> 2.0)"))
            n_vel += 1

        # TYPE 2 — sentiment_divergence
        cur.execute("""
            SELECT ds.topic, ds.sentiment_avg, ds.sentiment_std
            FROM daily_signals ds
            WHERE ds.date = %s AND ds.data_quality = 'ok' AND ds.divergence_flag = TRUE
        """, (target_date,))
        seven_d_ago = target_date - timedelta(days=7)
        for (topic, sentiment_avg, sentiment_std) in cur.fetchall():
            cur.execute("""
                SELECT sentiment_avg FROM daily_signals
                WHERE date = %s AND topic = %s
            """, (seven_d_ago, topic))
            row_7d = cur.fetchone()
            sent_7d = float(row_7d[0]) if row_7d and row_7d[0] is not None else 0.0
            sent_avg = float(sentiment_avg) if sentiment_avg is not None else 0.0
            sent_std = float(sentiment_std) if sentiment_std and sentiment_std > 0 else 1.0
            severity = min(10.0, max(0.0, abs(sent_avg - sent_7d) / sent_std))
            cur.execute("""
                INSERT INTO anomalies (detected_at, anomaly_type, topic, severity, description)
                VALUES (NOW(), 'sentiment_divergence', %s, %s, %s)
            """, (topic, severity, f"Sentiment divergence for {topic}: |avg - 7d ago|/std = {severity:.2f}"))
            n_div += 1

        # TYPE 3 — cross_asset_dislocation: |rho| > 0.5, lag=0, market moved > 2σ today, sentiment did NOT move > 1σ
        cur.execute("""
            SELECT topic, series_id, correlation
            FROM correlations
            WHERE lag_days = 0 AND window_days = 90 AND ABS(correlation) > 0.5
        """)
        strong_pairs = cur.fetchall()

        for (topic, series_id, rho) in strong_pairs:
            rho = float(rho)
            cur.execute("""
                SELECT date, value FROM market_data
                WHERE series_id = %s AND value IS NOT NULL AND date <= %s
                ORDER BY date DESC LIMIT 91
            """, (series_id, target_date))
            mkt_rows = cur.fetchall()
            if len(mkt_rows) < 30:
                continue
            vals = [float(r[1]) for r in mkt_rows]
            mean_m = sum(vals) / len(vals)
            var_m = sum((v - mean_m) ** 2 for v in vals) / max(len(vals) - 1, 1)
            std_m = var_m ** 0.5 if var_m > 0 else 1.0
            latest_val = vals[0]
            move_mkt = abs(latest_val - mean_m) / std_m if std_m else 0
            if move_mkt <= 2.0:
                continue

            cur.execute("""
                SELECT date, sentiment_avg FROM daily_signals
                WHERE topic = %s AND sentiment_avg IS NOT NULL AND date <= %s
                ORDER BY date DESC LIMIT 91
            """, (topic, target_date))
            sig_rows = cur.fetchall()
            if len(sig_rows) < 2:
                continue
            sents = [float(r[1]) for r in sig_rows]
            mean_s = sum(sents) / len(sents)
            var_s = sum((v - mean_s) ** 2 for v in sents) / max(len(sents) - 1, 1)
            std_s = var_s ** 0.5 if var_s > 0 else 1.0
            latest_sent = sents[0]
            move_sent = abs(latest_sent - mean_s) / std_s if std_s else 0
            if move_sent > 1.0:
                continue

            cur.execute("""
                SELECT id FROM daily_signals WHERE date = %s AND topic = %s AND data_quality = 'ok'
            """, (target_date, topic))
            if cur.fetchone() is None:
                continue

            severity = min(10.0, move_mkt)
            cur.execute("""
                INSERT INTO anomalies (detected_at, anomaly_type, topic, series_id, severity, description)
                VALUES (NOW(), 'cross_asset_dislocation', %s, %s, %s, %s)
            """, (topic, series_id, severity, f"Market {series_id} moved {move_mkt:.1f}σ, topic {topic} sentiment did not move >1σ"))
            n_cross += 1

        conn.commit()
    except Exception as e:
        conn.rollback()
        logger.warning("Anomaly detector failed: %s", e)
    finally:
        cur.close()

    logger.info("Anomalies detected: %s velocity, %s divergence, %s cross_asset", n_vel, n_div, n_cross)
    return n_vel, n_div, n_cross
