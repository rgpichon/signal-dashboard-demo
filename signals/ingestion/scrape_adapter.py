"""
Generic HTML scraper adapter. Fetches a page and extracts article-like items (links + text).
"""
import logging
import re
from typing import Any, List
from urllib.parse import urljoin, urlparse

import requests
from bs4 import BeautifulSoup

from signals.ingestion.base_adapter import BaseAdapter

logger = logging.getLogger("signals.ingestion")


class ScrapeAdapter(BaseAdapter):
    def fetch(self) -> Any:
        url = self.config.get("url", "").strip()
        if not url:
            return None
        resp = requests.get(url, timeout=30, headers={"User-Agent": "SIGNAL/1.0"})
        resp.raise_for_status()
        return resp.text

    def parse(self, raw: Any) -> List[dict]:
        if raw is None:
            return []
        base_url = self.config.get("url", "").strip()
        soup = BeautifulSoup(raw, "html.parser")
        source_id = self.source_id
        out = []

        # Common patterns: list of links (e.g. ECB press release index)
        for a in soup.find_all("a", href=True):
            href = (a.get("href") or "").strip()
            if not href or href.startswith("#") or href.startswith("mailto:"):
                continue
            full_url = urljoin(base_url, href)
            if not full_url or full_url == base_url:
                continue
            # Prefer same domain for press releases
            if "ecb.europa.eu" in base_url and "ecb.europa.eu" not in full_url:
                continue
            title = (a.get_text(strip=True) or "").strip()[:500]
            if not title and not full_url:
                continue
            # Skip nav/footer links
            if len(title) < 10 and "/press/" not in full_url and "/pr/" not in full_url:
                continue
            parent = a.parent
            body_snippet = ""
            if parent:
                body_snippet = parent.get_text(separator=" ", strip=True)[:2000]
            out.append({
                "title": title or full_url[:200],
                "body_text": body_snippet,
                "url": full_url,
                "published_at": None,
                "source_id": source_id,
            })

        # Dedupe by url within this parse
        seen = set()
        deduped = []
        for item in out:
            if item["url"] not in seen:
                seen.add(item["url"])
                deduped.append(item)

        return deduped[:100]
