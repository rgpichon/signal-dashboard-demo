"""
SHA256(url) deduplication. Skip insert if url already in articles.
Returns (inserted_count, skipped_count) for a single item.
"""
import hashlib
import logging
from typing import Tuple

logger = logging.getLogger("signals.ingestion")


def url_hash(url: str) -> str:
    return hashlib.sha256(url.encode("utf-8", errors="replace")).hexdigest()


def deduplicate_and_insert_article(conn, item: dict) -> Tuple[int, int]:
    """
    If url already in articles, skip (return 0, 1).
    Else insert and return (1, 0). Normalises body_text to first 2000 chars.
    """
    url = (item.get("url") or "").strip()
    if not url:
        return 0, 0

    cur = conn.cursor()
    try:
        cur.execute("SELECT 1 FROM articles WHERE url = %s", (url,))
        if cur.fetchone():
            return 0, 1

        title = item.get("title") or ""
        body_text = (item.get("body_text") or "")[:2000]
        published_at = item.get("published_at")
        source_id = item.get("source_id") or ""

        cur.execute(
            """
            INSERT INTO articles (source_id, url, title, body_text, published_at)
            VALUES (%s, %s, %s, %s, %s)
            """,
            (source_id, url, title, body_text, published_at),
        )
        return 1, 0
    finally:
        cur.close()
