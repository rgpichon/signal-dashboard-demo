#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
export SIGNAL_DEMO=1
export PYTHONPATH=.
python scripts/bootstrap_demo_db.py || true
exec gunicorn -k uvicorn.workers.UvicornWorker signals.api.server:app \
  --bind "0.0.0.0:${PORT:-8000}" --workers 1 --timeout 120
