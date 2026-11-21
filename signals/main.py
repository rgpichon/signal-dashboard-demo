"""
SIGNAL — Research & Investment Thesis Engine
Entry point: run the daily pipeline once (--once) or start the scheduler (default).
"""
import argparse
import logging
import os
import sys
from pathlib import Path

# Avoid multiprocessing in tokenizers (can cause exit 138 / semaphore leaks in some envs)
os.environ.setdefault("TOKENIZERS_PARALLELISM", "false")

# Ensure project root is on path when running as script
_ROOT = Path(__file__).resolve().parent
if str(_ROOT.parent) not in sys.path:
    sys.path.insert(0, str(_ROOT.parent))

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger("signals")


def main():
    parser = argparse.ArgumentParser(description="SIGNAL pipeline")
    parser.add_argument(
        "--once",
        action="store_true",
        help="Run the daily pipeline once and exit (default: start scheduler)",
    )
    args = parser.parse_args()

    if args.once:
        from signals.scheduler import run_daily_pipeline
        run_daily_pipeline()
    else:
        from signals.scheduler import main as scheduler_main
        scheduler_main()


if __name__ == "__main__":
    main()
