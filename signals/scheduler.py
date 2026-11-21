"""
Daily pipeline orchestration. Triggers all layers in order at 06:00 UTC.
Phase 1: placeholder stages only; real work added in later phases.
"""
import logging
from datetime import datetime, timezone

from apscheduler.schedulers.blocking import BlockingScheduler
from apscheduler.triggers.cron import CronTrigger

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("signals.scheduler")

# Placeholder stage names (real implementations in Phases 2–6)
STAGES = [
    "foundation",
    "ingestion",
    "processing",
    "analytics",
    "outcome_tracking",
    "thesis",
    "output",
]


def run_outcome_tracking():
    logger = logging.getLogger("signals.scheduler")
    try:
        from signals.thesis_engine.outcome_tracker import run_path_tracking
        from signals.db.connection import get_connection

        logger.info("Stage: outcome_tracking — starting")
        with get_connection() as conn:
            result = run_path_tracking(conn)
        logger.info("Stage: outcome_tracking — done: %s", result)
    except Exception as e:
        logger.error("Stage: outcome_tracking — failed: %s", e)


def run_daily_pipeline():
    """Run the full pipeline once. Each stage is logged."""
    logger.info("Starting daily pipeline run at %s", datetime.now(timezone.utc).isoformat())
    for stage in STAGES:
        logger.info("Stage: %s", stage)
        if stage == "ingestion":
            try:
                from signals.ingestion.runner import run_ingestion, print_ingestion_summary
                summary = run_ingestion()
                print_ingestion_summary(summary)
            except Exception as e:
                logger.exception("Ingestion stage failed: %s", e)
        elif stage == "processing":
            try:
                from signals.processing.runner import run_processing, print_processing_summary
                result = run_processing()
                print_processing_summary(result)
            except Exception as e:
                logger.exception("Processing stage failed: %s", e)
        elif stage == "analytics":
            try:
                from signals.db.connection import get_connection
                from signals.analytics.correlation_engine import run_correlation_engine
                from signals.analytics.regime_indicators import run_regime_indicators
                from signals.analytics.cftc_signals import run_cftc_signals
                from signals.analytics.anomaly_detector import run_anomaly_detector
                with get_connection() as conn:
                    pairs, sig = run_correlation_engine(conn)
                    run_regime_indicators(conn)
                    cftc_updated, cftc_crowding = run_cftc_signals(conn)
                    nv, nd, nc = run_anomaly_detector(conn)
                logger.info(
                    "Analytics summary: correlations %s pairs %s significant | regime snapshot updated | CFTC %s updated %s crowding | anomalies velocity=%s divergence=%s cross_asset=%s",
                    pairs, sig, cftc_updated, cftc_crowding, nv, nd, nc,
                )
            except Exception as e:
                logger.exception("Analytics stage failed: %s", e)
        elif stage == "outcome_tracking":
            run_outcome_tracking()
        elif stage == "thesis":
            try:
                from signals.thesis.runner import run_thesis_engine
                run_thesis_engine()
            except Exception as e:
                logger.exception("Thesis stage failed: %s", e)
    logger.info("Daily pipeline run completed.")


def main():
    scheduler = BlockingScheduler()
    scheduler.add_job(
        run_daily_pipeline,
        CronTrigger(hour=6, minute=0, timezone="UTC"),
        id="daily_pipeline",
    )
    logger.info("Scheduler started. Next run: 06:00 UTC.")
    scheduler.start()


if __name__ == "__main__":
    main()
