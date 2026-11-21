"""
SpaCy entity extractor with custom ruler for financial terms.
Output: JSONB {companies:[], countries:[], banks:[], people:[]} in articles.entities.
Processes only articles where processed=False.
"""
import json
import logging
import os
from typing import List

from signals.processing.model_registry import get_spacy

logger = logging.getLogger("signals.processing")

BATCH_SIZE = int(os.environ.get("PROCESSING_BATCH_SIZE", "32"))

# Custom entity ruler patterns: financial terms (label as ORG or PRODUCT as appropriate)
FINANCIAL_TERMS = [
    "BTP", "Bund", "iTraxx", "CDX", "SOFR", "OIS", "EURIBOR", "Gilts",
    "Treasuries", "Fed", "ECB", "BoE", "SNB", "BoJ",
]


def _add_entity_ruler(nlp) -> None:
    """Add a custom entity ruler for financial terms if not already present."""
    if "entity_ruler" in nlp.pipe_names:
        return
    try:
        ruler = nlp.add_pipe("entity_ruler", last=True)
        patterns = [{"label": "ORG", "pattern": term} for term in FINANCIAL_TERMS]
        ruler.add_patterns(patterns)
    except Exception as e:
        logger.warning("Could not add entity ruler: %s", e)


def _extract_entities(nlp, text: str) -> dict:
    """Return {companies: [], countries: [], banks: [], people: []}."""
    text = (text or "").strip()[:10000]
    if not text:
        return {"companies": [], "countries": [], "banks": [], "people": []}

    try:
        doc = nlp(text)
        companies = []
        countries = []
        banks = []
        people = []

        for ent in doc.ents:
            label = ent.label_
            val = ent.text.strip()
            if not val:
                continue
            if label == "ORG":
                if any(b in val.lower() for b in ("bank", "fed", "ecb", "boe", "snb", "boj", "central")):
                    banks.append(val)
                else:
                    companies.append(val)
            elif label == "GPE":
                countries.append(val)
            elif label == "PERSON":
                people.append(val)
            elif label == "PRODUCT":
                companies.append(val)  # treat product (e.g. instruments) as company list for simplicity

        # Dedupe preserving order
        def dedupe(lst):
            seen = set()
            out = []
            for x in lst:
                if x not in seen:
                    seen.add(x)
                    out.append(x)
            return out

        return {
            "companies": dedupe(companies),
            "countries": dedupe(countries),
            "banks": dedupe(banks),
            "people": dedupe(people),
        }
    except Exception as e:
        logger.warning("Entity extraction failed: %s", e)
        return {"companies": [], "countries": [], "banks": [], "people": []}


def run_entity_extractor(conn, batch_rows: list) -> int:
    """batch_rows = [(id, title, body_text), ...]. Returns count updated."""
    nlp = get_spacy()
    if nlp is None:
        logger.warning("SpaCy not available; skipping entity extraction")
        return 0

    _add_entity_ruler(nlp)

    updated = 0
    for (article_id, title, body_text) in batch_rows:
        text = ((title or "") + " " + (body_text or "")).strip()
        entities = _extract_entities(nlp, text)
        entities_json = json.dumps(entities)
        try:
            cur = conn.cursor()
            cur.execute("UPDATE articles SET entities = %s::jsonb WHERE id = %s", (entities_json, article_id))
            if cur.rowcount:
                updated += 1
            cur.close()
        except Exception as e:
            logger.warning("Entity update failed for article %s: %s", article_id, e)

    return updated


def _run_batch_file(batch_path: str) -> int:
    """Load batch JSON, connect DB, run entity extractor, return count updated. For subprocess use."""
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
        return run_entity_extractor(conn, batch_rows)


if __name__ == "__main__":
    import sys
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    path = sys.argv[1] if len(sys.argv) > 1 else ""
    if path:
        n = _run_batch_file(path)
        print(n)
    sys.exit(0)
