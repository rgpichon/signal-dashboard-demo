"""
Zero-shot topic classifier. Stores topics with score > 0.35 in articles.topics (JSONB).
Uses cross-encoder/nli-MiniLM2-L6-H768 (or ZERO_SHOT_MODEL). Batch size from env (default 32).
"""
import json
import logging
import os
from pathlib import Path

from signals.processing.model_registry import get_zero_shot_classifier

logger = logging.getLogger("signals.processing")

BATCH_SIZE = int(os.environ.get("PROCESSING_BATCH_SIZE", "32"))
TOPICS_PATH = Path(__file__).resolve().parent.parent / "config" / "topics.yaml"
THRESHOLD = 0.35
MAX_SEQ_LENGTH = 1024


def _load_topic_labels() -> list:
    """Flatten topics.yaml into a single list of label strings."""
    import yaml
    with open(TOPICS_PATH, "r") as f:
        data = yaml.safe_load(f)
    labels = []
    for category_labels in (data or {}).values():
        if isinstance(category_labels, list):
            labels.extend(category_labels)
    return list(dict.fromkeys(labels))  # preserve order, dedupe


# Chunk size for zero-shot (many labels at once can OOM on small models)
LABEL_CHUNK_SIZE = 9


def _classify_text(pipe, text: str, candidate_labels: list) -> dict:
    """Return dict of topic -> score for scores above THRESHOLD. Chunks labels to avoid OOM."""
    text = (text or "").strip()[:MAX_SEQ_LENGTH * 4]  # rough char limit
    if not text or not candidate_labels:
        return {}
    merged = {}
    for i in range(0, len(candidate_labels), LABEL_CHUNK_SIZE):
        chunk = candidate_labels[i : i + LABEL_CHUNK_SIZE]
        try:
            out = pipe(text, chunk, multi_label=True)
            labels = out.get("labels", [])
            scores = out.get("scores", [])
            for lbl, s in zip(labels, scores):
                if float(s) >= THRESHOLD:
                    merged[lbl] = round(float(s), 4)
        except Exception:
            continue
    return merged


def run_topic_classifier(conn, batch_ids: list, batch_rows: list, candidate_labels: list) -> int:
    """
    Run topic classification on a batch. batch_rows = [(id, title, body_text), ...].
    Returns count updated.
    """
    pipe = get_zero_shot_classifier()
    if pipe is None:
        logger.warning("Zero-shot classifier not available; skipping topic classification")
        return 0

    updated = 0
    for (article_id, title, body_text) in batch_rows:
        text = ((title or "") + " " + (body_text or "")).strip()
        topics = _classify_text(pipe, text, candidate_labels)
        topics_json = json.dumps(topics) if topics else None
        try:
            cur = conn.cursor()
            cur.execute("UPDATE articles SET topics = %s::jsonb WHERE id = %s", (topics_json, article_id))
            if cur.rowcount:
                updated += 1
            cur.close()
        except Exception as e:
            logger.warning("Topic update failed for article %s: %s", article_id, e)

    return updated


def _run_batch_file(batch_path: str, candidate_labels: list) -> int:
    """Load batch JSON, connect DB, run topic classifier, return count updated. For subprocess use."""
    import json
    from pathlib import Path
    from signals.db.connection import get_connection
    p = Path(batch_path)
    if not p.exists():
        return 0
    with open(p, "r") as f:
        rows = json.load(f)
    batch_ids = [r["id"] for r in rows]
    batch_rows = [(r["id"], r.get("title") or "", r.get("body_text") or "") for r in rows]
    with get_connection() as conn:
        return run_topic_classifier(conn, batch_ids, batch_rows, candidate_labels)


if __name__ == "__main__":
    import sys
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    path = sys.argv[1] if len(sys.argv) > 1 else ""
    labels = _load_topic_labels() if path else []
    if path:
        n = _run_batch_file(path, labels)
        print(n)
    sys.exit(0)
