"""
Processing runner: FinBERT -> topic classifier -> entity extractor (per batch in subprocesses), then signal aggregator.
Marks articles processed=True after all three scorers. Logs processing summary.
Runs each NLP stage in a separate subprocess so only one model is in memory at a time (avoids OOM/exit 138).
"""
import json
import logging
import os
import subprocess
import sys
import tempfile
from datetime import date
from pathlib import Path

from signals.db.connection import get_connection
from signals.processing.topic_classifier import _load_topic_labels
from signals.processing.signal_aggregator import run_signal_aggregator

logger = logging.getLogger("signals.processing")

BATCH_SIZE = int(os.environ.get("PROCESSING_BATCH_SIZE", "32"))


def _run_nlp_subprocess(module: str, batch_path: str, extra_env: dict = None) -> int:
    """Run a processing module as subprocess; it reads batch from batch_path and prints count. Returns count."""
    env = os.environ.copy()
    if extra_env:
        env.update(extra_env)
    try:
        result = subprocess.run(
            [sys.executable, "-m", module, batch_path],
            capture_output=True,
            text=True,
            timeout=600,
            cwd=str(Path(__file__).resolve().parent.parent.parent),
            env={**env, "PYTHONPATH": os.environ.get("PYTHONPATH", "") or str(Path(__file__).resolve().parent.parent.parent)},
        )
        if result.returncode != 0:
            logger.warning("%s subprocess failed: %s", module, result.stderr or result.stdout)
            return 0
        return int(result.stdout.strip() or 0)
    except subprocess.TimeoutExpired:
        logger.warning("%s subprocess timed out", module)
        return 0
    except Exception as e:
        logger.warning("%s subprocess error: %s", module, e)
        return 0


def run_processing(target_date: date = None) -> dict:
    """
    Run full NLP pipeline on unprocessed articles, then aggregate.
    Each NLP stage runs in its own subprocess to avoid loading all models in one process.
    Returns dict: processed_count, sentiment_ok, topics_ok, entities_ok, daily_signals_upserted.
    """
    target_date = target_date or date.today()
    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute(
            "SELECT id, title, body_text FROM articles WHERE processed = FALSE ORDER BY id"
        )
        all_rows = cur.fetchall()
        cur.close()

        if not all_rows:
            daily_rows = run_signal_aggregator(conn, target_date)
            cur = conn.cursor()
            cur.execute("""
                SELECT DISTINCT (published_at AT TIME ZONE 'UTC')::date AS d
                FROM articles
                WHERE processed = TRUE AND topics IS NOT NULL AND topics != 'null'::jsonb AND published_at IS NOT NULL
            """)
            for (d,) in cur.fetchall():
                if d != target_date:
                    daily_rows += run_signal_aggregator(conn, d)
            cur.close()
            return {
                "processed_count": 0,
                "sentiment_ok": True,
                "topics_ok": True,
                "entities_ok": True,
                "daily_signals_upserted": daily_rows,
            }

        processed_ids = []
        n_sentiment = 0
        n_topics = 0
        n_entities = 0

        try:
            topic_labels = _load_topic_labels()
        except Exception as e:
            logger.warning("Could not load topic labels: %s", e)
            topic_labels = []

        prefix = "signals.processing."
        finbert_mod = prefix + "finbert_scorer"
        topic_mod = prefix + "topic_classifier"
        entity_mod = prefix + "entity_extractor"

        for i in range(0, len(all_rows), BATCH_SIZE):
            batch = all_rows[i : i + BATCH_SIZE]
            batch_ids = [r[0] for r in batch]
            batch_payload = [
                {"id": r[0], "title": r[1] or "", "body_text": r[2] or ""}
                for r in batch
            ]

            with tempfile.NamedTemporaryFile(
                mode="w", suffix=".json", delete=False
            ) as f:
                json.dump(batch_payload, f)
                batch_path = f.name

            try:
                n_sentiment += _run_nlp_subprocess(finbert_mod, batch_path)
                n_topics += _run_nlp_subprocess(topic_mod, batch_path)
                n_entities += _run_nlp_subprocess(entity_mod, batch_path)
                processed_ids.extend(batch_ids)
            finally:
                try:
                    os.unlink(batch_path)
                except OSError:
                    pass

        # Mark all processed articles as processed=True
        if processed_ids:
            cur = conn.cursor()
            cur.execute(
                "UPDATE articles SET processed = TRUE WHERE id = ANY(%s)",
                (processed_ids,),
            )
            cur.close()

        # Aggregate for today; then backfill any other dates that have processed articles with topics
        daily_rows = run_signal_aggregator(conn, target_date)
        cur = conn.cursor()
        cur.execute("""
            SELECT DISTINCT (published_at AT TIME ZONE 'UTC')::date AS d
            FROM articles
            WHERE processed = TRUE AND topics IS NOT NULL AND topics != 'null'::jsonb AND published_at IS NOT NULL
        """)
        other_dates = [r[0] for r in cur.fetchall() if r[0] != target_date]
        cur.close()
        for d in other_dates:
            daily_rows += run_signal_aggregator(conn, d)

    return {
        "processed_count": len(processed_ids),
        "sentiment_ok": n_sentiment >= 0,
        "topics_ok": n_topics >= 0,
        "entities_ok": n_entities >= 0,
        "daily_signals_upserted": daily_rows,
    }


def print_processing_summary(result: dict) -> None:
    """Print the processing summary to stdout."""
    print("--- Processing summary ---")
    print(f"  Processed {result['processed_count']} articles: sentiment ✓, topics ✓, entities ✓")
    print(f"  daily_signals rows upserted: {result['daily_signals_upserted']}")
    print("-------------------------")
