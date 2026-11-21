"""
Abstract base for article-producing adapters (RSS, scrape).
FRED and ECB SDW write to market_data only; they do not inherit this.
"""
import logging
from abc import ABC, abstractmethod
from typing import Any

logger = logging.getLogger("signals.ingestion")


class BaseAdapter(ABC):
    """Adapter that produces articles: fetch -> parse -> dedupe -> insert."""

    def __init__(self, source_id: str, config: dict):
        self.source_id = source_id
        self.config = config

    @abstractmethod
    def fetch(self) -> Any:
        """Return raw response (bytes, string, or response object)."""
        pass

    @abstractmethod
    def parse(self, raw: Any) -> list[dict]:
        """
        Extract list of article dicts. Each dict: title, body_text, url, published_at, source_id.
        """
        pass

    def run(self, conn, deduplicate_and_insert) -> tuple[int, int]:
        """
        fetch -> parse -> deduplicate_and_insert per item.
        Catches exceptions per item; logs to pipeline_errors. Never raises.
        Returns (inserted_count, skipped_count).
        """
        inserted, skipped = 0, 0
        try:
            raw = self.fetch()
        except Exception as e:
            logger.exception("Fetch failed for %s", self.source_id)
            _log_pipeline_error(conn, self.source_id, "fetch_error", str(e))
            return 0, 0

        try:
            items = self.parse(raw)
        except Exception as e:
            logger.exception("Parse failed for %s", self.source_id)
            _log_pipeline_error(conn, self.source_id, "parse_error", str(e))
            return 0, 0

        if not items:
            _log_pipeline_error(
                conn, self.source_id, "empty_result",
                "Source returned 0 items (e.g. RSS 404 or empty feed)",
            )
            return 0, 0

        for item in items:
            try:
                i, s = deduplicate_and_insert(conn, item)
                inserted += i
                skipped += s
            except Exception as e:
                logger.warning("Item failed for %s: %s", self.source_id, e)
                _log_pipeline_error(conn, self.source_id, "insert_error", str(e))

        return inserted, skipped


def _log_pipeline_error(conn, source_id: str, error_type: str, error_msg: str) -> None:
    """Write one row to pipeline_errors. Does not raise."""
    try:
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO pipeline_errors (source_id, error_type, error_msg) VALUES (%s, %s, %s)",
            (source_id, error_type, error_msg[:10000] if error_msg else None),
        )
        cur.close()
    except Exception:
        logger.exception("Failed to log pipeline_errors")
