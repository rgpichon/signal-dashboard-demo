"""
Thesis engine runner: screener -> context -> confidence -> Claude -> store; then tracker.
"""
import logging
from datetime import date, datetime, timezone

from signals.db.connection import get_connection
from signals.thesis.screener import run_screener
from signals.thesis.context_assembler import assemble_context
from signals.thesis.confidence_scorer import compute_confidence
from signals.thesis.claude_client import generate_thesis
from signals.thesis.tracker import run_tracker

logger = logging.getLogger("signals.thesis")


def _next_thesis_id(conn) -> str:
    """Generate next thesis_id like TH-001."""
    cur = conn.cursor()
    cur.execute("SELECT thesis_id FROM theses ORDER BY id DESC LIMIT 1")
    row = cur.fetchone()
    cur.close()
    if row:
        try:
            num = int(row[0].split("-")[-1])
            return "TH-%03d" % (num + 1)
        except (ValueError, IndexError):
            pass
    return "TH-001"


def run_thesis_engine(target_date: date = None) -> dict:
    """
    Run screener -> for each candidate: assemble context -> score confidence -> Claude -> store.
    Then run tracker. Returns {candidates, generated, stored, checked, expired, invalidated}.
    """
    target_date = target_date or date.today()
    with get_connection() as conn:
        candidates = run_screener(conn, target_date)
    if not candidates:
        with get_connection() as conn:
            checked, expired, inv = run_tracker(conn)
        logger.info("Thesis engine: 0 candidates, 0 theses generated, 0 stored")
        return {"candidates": 0, "generated": 0, "stored": 0, "checked": checked, "expired": expired, "invalidated": inv}

    generated = 0
    stored = 0
    with get_connection() as conn:
        thesis_id = _next_thesis_id(conn)
        for c in candidates:
            ctx = assemble_context(conn, c, target_date)
            score, label = compute_confidence(
                velocity_7d=c.get("velocity_7d"),
                article_count=c.get("article_count") or 0,
                correlations=ctx.get("correlations", []),
                regime_supports_direction=None,
            )
            ctx["_confidence_score"] = score
            ctx["_confidence_label"] = label
            result = generate_thesis(ctx, thesis_id)
            if result:
                generated += 1
                stored += 1
            thesis_id = _next_thesis_id(conn)

        checked, expired, invalidated = run_tracker(conn)

    logger.info(
        "Thesis engine: %s candidates, %s theses generated, %s stored",
        len(candidates), generated, stored,
    )
    return {
        "candidates": len(candidates),
        "generated": generated,
        "stored": stored,
        "checked": checked,
        "expired": expired,
        "invalidated": invalidated,
    }
