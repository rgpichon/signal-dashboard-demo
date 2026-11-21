"""
RSS/Atom feed adapter. Fetches feed URL and parses entries to article dicts.
"""
import logging
from datetime import datetime, timezone
from time import mktime
from typing import Any, List

import feedparser
import requests

from signals.ingestion.base_adapter import BaseAdapter

logger = logging.getLogger("signals.ingestion")


class RSSAdapter(BaseAdapter):
    def fetch(self) -> Any:
        url = self.config.get("url", "").strip()
        if not url:
            return None
        urls = [url]
        fallback = self.config.get("fallback_url", "").strip()
        if fallback:
            urls.append(fallback)
        last_error = None
        for u in urls:
            try:
                resp = requests.get(u, timeout=30)
                resp.raise_for_status()
                return resp.content
            except Exception as e:
                last_error = e
                logger.warning("RSS fetch failed for %s (%s): %s", self.source_id, u, e)
                continue
        if last_error:
            raise last_error
        return None

    def parse(self, raw: Any) -> List[dict]:
        if raw is None:
            return []
        fp = feedparser.parse(raw)
        source_id = self.source_id
        out = []
        for entry in fp.get("entries", []):
            url = (entry.get("link") or "").strip()
            if not url:
                continue
            title = (entry.get("title") or "").strip()
            summary = entry.get("summary") or entry.get("description") or ""
            if hasattr(summary, "value"):
                body_text = summary.value[:2000] if summary else ""
            else:
                body_text = (summary or "")[:2000]
            body_text = (body_text or "").strip()

            published_at = None
            if entry.get("published_parsed"):
                try:
                    ts = mktime(entry.published_parsed)
                    published_at = datetime.fromtimestamp(ts, tz=timezone.utc)
                except Exception:
                    pass
            out.append({
                "title": title,
                "body_text": body_text,
                "url": url,
                "published_at": published_at,
                "source_id": source_id,
            })
        return out
