"""
Ingestion runner: load sources from YAML, run each enabled adapter, log to pipeline_errors on failure, print summary.
"""
import logging
from pathlib import Path

import yaml

from signals.db.connection import get_connection
from signals.ingestion.deduplicator import deduplicate_and_insert_article
from signals.ingestion.rss_adapter import RSSAdapter
from signals.ingestion.scrape_adapter import ScrapeAdapter
from signals.ingestion.fred_adapter import run_fred
from signals.ingestion.yfinance_adapter import run_yfinance
from signals.ingestion.ecb_sdw_adapter import run_ecb_sdw
from signals.ingestion.cftc_adapter import run_cftc
from signals.ingestion.computed_series import run_computed_series

logger = logging.getLogger("signals.ingestion")

CONFIG_PATH = Path(__file__).resolve().parent.parent / "config" / "sources.yaml"


def load_sources() -> list[dict]:
    path = CONFIG_PATH
    with open(path, "r") as f:
        data = yaml.safe_load(f)
    return data.get("sources", [])


def run_ingestion() -> dict:
    """
    Run all enabled ingestion sources. Never raises.
    Returns summary: articles_inserted, articles_skipped, market_data_inserted,
    positioning_inserted, sources_zero (list of source_id that returned 0 items).
    """
    sources = load_sources()
    total_articles_inserted = 0
    total_articles_skipped = 0
    total_market_data = 0
    total_positioning = 0
    sources_zero = []

    with get_connection() as conn:
        for src in sources:
            source_id = src.get("id", "")
            if not source_id:
                continue
            if src.get("enabled") is False:
                logger.info("Skipping disabled source: %s", source_id)
                continue

            stype = (src.get("type") or "").strip().lower()
            config = {k: v for k, v in src.items() if k not in ("id", "type", "enabled")}

            try:
                if stype == "rss":
                    adapter = RSSAdapter(source_id, config)
                    inserted, skipped = adapter.run(conn, deduplicate_and_insert_article)
                    total_articles_inserted += inserted
                    total_articles_skipped += skipped
                    if inserted == 0 and skipped == 0:
                        sources_zero.append(source_id)
                elif stype == "scrape":
                    adapter = ScrapeAdapter(source_id, config)
                    inserted, skipped = adapter.run(conn, deduplicate_and_insert_article)
                    total_articles_inserted += inserted
                    total_articles_skipped += skipped
                    if inserted == 0 and skipped == 0:
                        sources_zero.append(source_id)
                elif stype == "fred_api":
                    n = run_fred(conn, source_id, config)
                    total_market_data += n
                    if n == 0:
                        sources_zero.append(source_id)
                elif stype == "yfinance":
                    n = run_yfinance(conn, source_id, config)
                    total_market_data += n
                    if n == 0:
                        sources_zero.append(source_id)
                elif stype == "ecb_sdw":
                    n = run_ecb_sdw(conn, source_id, config)
                    total_market_data += n
                    if n == 0:
                        sources_zero.append(source_id)
                elif stype == "cftc":
                    n = run_cftc(conn, source_id, config)
                    total_positioning += n
                    if n == 0:
                        sources_zero.append(source_id)
                else:
                    logger.warning("Unknown source type '%s' for %s", stype, source_id)
            except Exception as e:
                logger.exception("Ingestion failed for %s: %s", source_id, e)
                try:
                    cur = conn.cursor()
                    cur.execute(
                        "INSERT INTO pipeline_errors (source_id, error_type, error_msg) VALUES (%s, %s, %s)",
                        (source_id, "run_error", str(e)[:500]),
                    )
                    cur.close()
                except Exception:
                    pass
                sources_zero.append(source_id)

        # Computed series (after FRED and yfinance)
        try:
            computed_n = run_computed_series(conn)
            total_market_data += computed_n
            logger.info("Computed series: %s rows inserted/updated", computed_n)
        except Exception as e:
            logger.exception("Computed series failed: %s", e)

    summary = {
        "articles_inserted": total_articles_inserted,
        "articles_skipped": total_articles_skipped,
        "market_data_inserted": total_market_data,
        "positioning_inserted": total_positioning,
        "sources_zero": sources_zero,
    }
    return summary


def print_ingestion_summary(summary: dict) -> None:
    """Print the ingestion summary to stdout."""
    print("--- Ingestion summary ---")
    print(f"  Articles inserted:  {summary['articles_inserted']}")
    print(f"  Articles skipped (duplicates): {summary['articles_skipped']}")
    print(f"  Market data rows inserted: {summary['market_data_inserted']}")
    print(f"  Positioning signals inserted: {summary['positioning_inserted']}")
    if summary["sources_zero"]:
        print(f"  Sources that returned 0 items: {', '.join(summary['sources_zero'])}")
    print("-------------------------")
