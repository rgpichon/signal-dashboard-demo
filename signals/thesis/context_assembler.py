"""
Build context dict for each thesis candidate. Supports --mock to load from fixtures/mock_context.json.
"""
import json
import logging
from datetime import date, timedelta
from pathlib import Path
from typing import Any, Optional

logger = logging.getLogger("signals.thesis")

FIXTURES_DIR = Path(__file__).resolve().parent / "fixtures"
MOCK_CONTEXT_PATH = FIXTURES_DIR / "mock_context.json"


def load_mock_context() -> dict:
    """Load context from fixtures/mock_context.json."""
    if not MOCK_CONTEXT_PATH.exists():
        raise FileNotFoundError(f"Mock context not found: {MOCK_CONTEXT_PATH}")
    with open(MOCK_CONTEXT_PATH, "r") as f:
        return json.load(f)


def assemble_context(conn, candidate: dict, target_date: Optional[date] = None) -> dict:
    """
    Build full context dict for a candidate from DB.
    candidate: {topic, conditions_met, sentiment_magnitude, forced, article_count, velocity_7d, sentiment_avg, data_quality}
    """
    target_date = target_date or date.today()
    topic = candidate["topic"]
    cur = conn.cursor()

    # Signal summary (auto-generated 2 sentences)
    vel = candidate.get("velocity_7d")
    sent = candidate.get("sentiment_avg")
    vel_str = f"Article velocity (7d z-score) is {vel:.2f}." if vel is not None else "Article velocity is in cold start (insufficient 30d history)."
    sent_str = f"Topic sentiment average is {sent:.2f}." if sent is not None else "Sentiment not available."
    signal_summary = f"{vel_str} {sent_str}"

    # Sentiment shift: delta over 7 days
    seven_d_ago = target_date - timedelta(days=7)
    cur.execute("""
        SELECT sentiment_avg FROM daily_signals WHERE topic = %s AND date = %s
    """, (topic, seven_d_ago))
    row_7d = cur.fetchone()
    sent_7d = float(row_7d[0]) if row_7d and row_7d[0] is not None else None
    sent_today = float(candidate["sentiment_avg"]) if candidate.get("sentiment_avg") is not None else None
    sentiment_shift = (sent_today - sent_7d) if (sent_today is not None and sent_7d is not None) else None

    # Top 10 articles for this topic (by published_at desc)
    cur.execute("""
        SELECT a.title, a.source_id, a.published_at, a.sentiment
        FROM articles a
        WHERE a.processed = TRUE AND a.topics ? %s
        ORDER BY a.published_at DESC NULLS LAST
        LIMIT 10
    """, (topic,))
    top_articles = []
    for r in cur.fetchall():
        top_articles.append({
            "title": r[0] or "",
            "source_id": r[1] or "",
            "published_at": r[2].isoformat() if r[2] else None,
            "sentiment": float(r[3]) if r[3] is not None else None,
        })

    # Regime snapshot today
    cur.execute("""
        SELECT date, growth_pulse, credit_stress, real_yield, dollar_strength,
               rates_vol, equity_vol, curve_shape, fingerprint
        FROM regime_snapshots WHERE date = %s
    """, (target_date,))
    row_r = cur.fetchone()
    regime_snapshot = {}
    if row_r:
        regime_snapshot = {
            "date": str(row_r[0]),
            "growth_pulse": row_r[1],
            "credit_stress": row_r[2],
            "real_yield": row_r[3],
            "dollar_strength": row_r[4],
            "rates_vol": row_r[5],
            "equity_vol": row_r[6],
            "curve_shape": row_r[7],
            "fingerprint": row_r[8],
        }

    # Correlations for this topic (significant)
    cur.execute("""
        SELECT series_id, lag_days, correlation, quality
        FROM correlations WHERE topic = %s
    """, (topic,))
    correlations = [
        {"series_id": r[0], "lag_days": r[1], "correlation": float(r[2]) if r[2] is not None else 0, "quality": r[3] or "ok"}
        for r in cur.fetchall()
    ]

    # Market moves for correlated instruments (1d, 5d, 20d pct)
    market_moves = {}
    for c in correlations:
        sid = c["series_id"]
        cur.execute("""
            SELECT date, value, pct_chg FROM market_data
            WHERE series_id = %s AND date <= %s AND value IS NOT NULL
            ORDER BY date DESC LIMIT 25
        """, (sid, target_date))
        rows = cur.fetchall()
        if not rows:
            continue
        by_date = {r[0]: (r[1], r[2]) for r in rows}
        dates_sorted = sorted(by_date.keys(), reverse=True)
        v0 = by_date[dates_sorted[0]][0] if dates_sorted else None
        move_1d = move_5d = move_20d = None
        if len(dates_sorted) >= 2 and v0:
            v1 = by_date.get(dates_sorted[1], (None, None))[0]
            if v1:
                move_1d = (v0 - v1) / v1 * 100
        if len(dates_sorted) >= 6 and v0:
            v5 = by_date.get(dates_sorted[5], (None, None))[0]
            if v5:
                move_5d = (v0 - v5) / v5 * 100
        if len(dates_sorted) >= 21 and v0:
            v20 = by_date.get(dates_sorted[20], (None, None))[0]
            if v20:
                move_20d = (v0 - v20) / v20 * 100
        market_moves[sid] = {"move_1d": move_1d, "move_5d": move_5d, "move_20d": move_20d}

    # Positioning: related instruments (themes contain topic) from positioning_signals
    cur.execute("SELECT id, themes FROM instruments WHERE themes IS NOT NULL AND %s = ANY(themes)", (topic,))
    related_ids = [r[0] for r in cur.fetchall()]
    positioning = []
    if related_ids:
        cur.execute("""
            SELECT series_id, crowding_flag, direction
            FROM positioning_signals WHERE date = %s AND series_id = ANY(%s)
        """, (target_date, related_ids))
        for r in cur.fetchall():
            positioning.append({"series_id": r[0], "crowding_flag": r[1], "direction": r[2]})

    # Matched instruments (themes overlap topic), sorted by liquidity
    cur.execute("""
        SELECT id, name, liquidity FROM instruments
        WHERE themes IS NOT NULL AND %s = ANY(themes)
        ORDER BY CASE liquidity WHEN 'very_high' THEN 1 WHEN 'high' THEN 2 WHEN 'medium' THEN 3 ELSE 4 END
    """, (topic,))
    matched_instruments = [{"id": r[0], "name": r[1], "liquidity": r[2] or ""} for r in cur.fetchall()]

    cur.close()
    return {
        "theme": topic,
        "signal_summary": signal_summary,
        "article_velocity": vel,
        "sentiment_shift": sentiment_shift,
        "top_articles": top_articles,
        "regime_snapshot": regime_snapshot,
        "correlations": correlations,
        "market_moves": market_moves,
        "positioning": positioning,
        "matched_instruments": matched_instruments,
        "forced": candidate.get("forced", False),
    }
