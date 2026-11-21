"""
FinBERT sentiment scorer. Updates articles with sentiment, sentiment_conf, processed=True.
Processes only articles where processed=False. Batch size from env (default 32).
"""
import logging
import os
from typing import List, Tuple

from signals.processing.model_registry import get_finbert

logger = logging.getLogger("signals.processing")

BATCH_SIZE = int(os.environ.get("PROCESSING_BATCH_SIZE", "32"))

# ~512 tokens ≈ 4000 chars; keep input bounded
MAX_INPUT_CHARS = 4000


def _score_text(pipe, title: str, body_text: str) -> Tuple[float, float]:
    """Return (sentiment, sentiment_conf). sentiment in [-1, 1], conf in [0, 1]."""
    text = ((title or "") + " " + (body_text or "")).strip()[:MAX_INPUT_CHARS]
    if not text:
        return 0.0, 0.0
    try:
        out = pipe(text[:5120])[0]  # pipeline may truncate internally
        label = (out.get("label") or "").lower()
        score = float(out.get("score", 0.0))
        if "positive" in label:
            return (1.0 * score, score)
        if "negative" in label:
            return (-1.0 * score, score)
        return (0.0, score)
    except Exception:
        return 0.0, 0.0


def run_finbert(conn, batch_rows: list = None) -> int:
    """
    Process articles: if batch_rows is provided, process those; else fetch all processed=False.
    batch_rows = [(id, title, body_text), ...]. Returns count updated.
    """
    pipe = get_finbert()
    if pipe is None:
        logger.warning("FinBERT not available; skipping sentiment scoring")
        return 0

    if batch_rows is None:
        cur = conn.cursor()
        cur.execute("SELECT id, title, body_text FROM articles WHERE processed = FALSE ORDER BY id")
        batch_rows = cur.fetchall()
        cur.close()

    if not batch_rows:
        return 0

    updated = 0
    for article_id, title, body_text in batch_rows:
        sentiment, sentiment_conf = _score_text(pipe, title or "", body_text or "")
        try:
            c = conn.cursor()
            c.execute(
                "UPDATE articles SET sentiment = %s, sentiment_conf = %s WHERE id = %s",
                (sentiment, sentiment_conf, article_id),
            )
            if c.rowcount:
                updated += 1
            c.close()
        except Exception as e:
            logger.warning("FinBERT update failed for article %s: %s", article_id, e)

    return updated


def _run_batch_file(batch_path: str) -> int:
    """Load batch JSON from file, connect DB, run FinBERT, return count updated. For subprocess use."""
    import json
    from pathlib import Path
    from signals.db.connection import get_connection
    p = Path(batch_path)
    if not p.exists():
        return 0
    with open(p, "r") as f:
        rows = json.load(f)
    batch_rows = [(r["id"], r.get("title") or "", r.get("body_text") or "") for r in rows]
    with get_connection() as conn:
        return run_finbert(conn, batch_rows)


if __name__ == "__main__":
    import sys
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    path = sys.argv[1] if len(sys.argv) > 1 else ""
    if path:
        n = _run_batch_file(path)
        print(n)
    sys.exit(0)
