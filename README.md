# SIGNAL — Research & Investment Thesis Engine

**Quick start:** `./start.sh` (starts API + dashboard; open http://localhost:3000)

Standalone financial research and thesis generation engine. Ingests sources, scores signals, runs analytics, and produces instrument-mapped investment theses via Claude API.

## First-time setup

On a Mac with Homebrew (and no Docker), run this once from the repo root to install PostgreSQL 15, create the database, apply the schema, seed the universe, and run a test pipeline:

```bash
./setup_db.sh
```

Then continue with the [Setup](#setup) steps below (Python, dependencies, and any API keys).

## Setup

1. **Python 3.11+** and a virtualenv (recommended).

2. **PostgreSQL 15**  
   Create a database (e.g. `signal`) and run the schema:

   ```bash
   psql -d signal -f signals/db/schema.sql
   ```

3. **Environment**  
   Copy `signals/.env.example` to `signals/.env` (or `.env` in project root) and set:

   - `DATABASE_URL` (or `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD`)
   - `FRED_API_KEY` (for market data / backfill)
   - `ANTHROPIC_API_KEY` (for thesis engine)

4. **Install dependencies**

   ```bash
   pip install -r requirements.txt
   ```

5. **Seed the asset universe** (once)

   From the project root (parent of `signals/`):

   ```bash
   PYTHONPATH=. python -m signals.db.seed_universe
   ```

   Or:

   ```bash
   PYTHONPATH=. python signals/db/seed_universe.py
   ```

   This reads `signals/config/universe.yaml` and upserts into the `instruments` table.

## Running

- **Single pipeline run** (for testing):

  ```bash
  PYTHONPATH=. python -m signals.main --once
  ```

- **Start the daily scheduler** (06:00 UTC):

  ```bash
  PYTHONPATH=. python -m signals.main
  ```

Phase 2 ingestion runs automatically: RSS, scrape, FRED, ECB SDW, and CFTC adapters (see `signals/config/sources.yaml`). Set `FRED_API_KEY` in `signals/.env` to populate `market_data`; without it the FRED source is skipped. Failed sources are logged to `pipeline_errors` and do not stop the run. After each run an ingestion summary is printed (articles inserted/skipped, market_data rows, sources that returned 0).

## First-time backfill (run once after setup)

Populate 90 days of historical data so the analytics layer has enough history for correlations and velocity baselines:

```bash
PYTHONPATH=. python signals/backfill_history.py
```

This pulls 90 days of FRED series and yfinance data, re-runs the signal aggregator over the window, then the correlation engine and regime indicators. At the end it prints a summary of rows in `market_data`, `daily_signals`, `correlations`, and `regime_snapshots`.

## Running the dashboard

The dashboard is a standalone web frontend that talks to a FastAPI server for DB data.

**Terminal 1 — start the API server:**

```bash
cd /path/to/project
PYTHONPATH=. uvicorn signals.api.server:app --reload --port 8000
```

**Terminal 2 — open the dashboard:**

⚠ **Do not open the dashboard via `file://`** (e.g. by double‑clicking `index.html` or using `open signals/dashboard/index.html`). It will break in many browsers or when the API runs on a different port. Always serve the dashboard over HTTP:

```bash
python -m http.server 3000 --directory signals/dashboard
```

Or, if you have a small server script:

```bash
python signals/dashboard/serve.py
```

Then go to **http://localhost:3000** in your browser. The dashboard will request data from `http://localhost:8000`. If you open it via `file://`, a yellow banner will remind you to use the HTTP URL instead.

## Repository layout

See `SIGNAL_spec.md` Section 9. Phase 1 provides: `signals/db/schema.sql`, `signals/db/connection.py`, `signals/db/seed_universe.py`, `signals/config/universe.yaml`, `signals/.env.example`, `signals/scheduler.py`, `signals/main.py`, plus this README and `requirements.txt`.
