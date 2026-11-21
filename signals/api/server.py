"""
FastAPI server exposing SIGNAL DB data as JSON for the dashboard.
Run: PYTHONPATH=. uvicorn signals.api.server:app --reload --port 8000

SIGNAL_DEMO=1 — portfolio / public packaging:
  - serves signals/dashboard/ from the same origin
  - blocks mutating API routes (pipeline, thesis CRUD, resolve, …)
"""
import json
import math
import os
import subprocess
import sys
from datetime import date, datetime, timezone
from pathlib import Path
from typing import Any, Optional

import numpy as np
from fastapi import Body, FastAPI, Query, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from starlette.middleware.base import BaseHTTPMiddleware

from signals.db.connection import get_connection
from signals.research.factor_model import (
    compute_factor_decomposition,
    _get_cached_decomposition,
    _cache_decomposition,
    _get_instrument_asset_class,
)


def _demo_mode() -> bool:
    return os.environ.get("SIGNAL_DEMO", "").strip().lower() in {
        "1",
        "true",
        "yes",
        "on",
    }


# ---------------------------------------------------------------------------
# Numpy-safe JSON serialization for research endpoints
# ---------------------------------------------------------------------------
class _NumpyEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, (np.integer,)):
            return int(obj)
        if isinstance(obj, (np.floating,)):
            return float(obj)
        if isinstance(obj, np.ndarray):
            return obj.tolist()
        if isinstance(obj, float) and (math.isnan(obj) or math.isinf(obj)):
            return None
        if isinstance(obj, (date, datetime)):
            return obj.strftime("%Y-%m-%d") if hasattr(obj, "strftime") else str(obj)
        return super().default(obj)


def _jsonify(data: Any) -> Any:
    """Recursively convert data to JSON-serializable form (numpy, NaN/Inf, etc.)."""
    return json.loads(json.dumps(data, cls=_NumpyEncoder))

_PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent

app = FastAPI(title="SIGNAL API", version="1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


_DEMO_BLOCK_METHODS = {"POST", "PUT", "PATCH", "DELETE"}


class _DemoReadOnlyMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        if not _demo_mode():
            return await call_next(request)
        path = request.url.path
        method = request.method.upper()
        if path.rstrip("/") == "/api/pipeline/run" or path.startswith(
            "/api/instruments/resolve"
        ):
            return JSONResponse(
                {
                    "error": "demo_read_only",
                    "message": "Pipeline and instrument writes are disabled on the public demo.",
                },
                status_code=403,
            )
        if method in _DEMO_BLOCK_METHODS and (
            path.startswith("/api/research-theses")
            or path.startswith("/api/theses")
            or path.startswith("/api/thesis-engine")
            or path.startswith("/api/research/scenario")
        ):
            return JSONResponse(
                {
                    "error": "demo_read_only",
                    "message": "Write routes are disabled on the public demo.",
                },
                status_code=403,
            )
        return await call_next(request)


if _demo_mode():
    app.add_middleware(_DemoReadOnlyMiddleware)


@app.on_event("startup")
async def on_startup():
    from signals.db.connection import run_sql_file

    for path in [
        "signals/db/migrations/007_thesis_persistence.sql",
        "signals/db/migrations/008_universe_expansion.sql",
        "signals/db/migrations/009_canvas_layout.sql",
    ]:
        try:
            run_sql_file(path)
        except Exception as e:
            print(f"[migration] Error on {path}: {e}")
    if _demo_mode():
        print("[SIGNAL_DEMO] read-only public mode — mutating API routes blocked")


# ---------------------------------------------------------------------------
# Research theses persistence API (Spec 7) — uses research_* tables
# Prefix: /api/research-theses (avoid conflict with existing /api/theses)
# ---------------------------------------------------------------------------


@app.get("/api/research-theses")
def list_research_theses(status: Optional[str] = Query(None), tag: Optional[str] = Query(None)):
    from signals.backend.thesis_store import list_theses
    return list_theses(status=status, tag=tag)


@app.post("/api/research-theses", status_code=201)
def create_research_thesis(body: dict = Body(default=None)):
    from signals.backend.thesis_store import create_thesis
    body = body or {}
    title = body.get("title") if isinstance(body, dict) else None
    thesis = create_thesis(title=title or "Untitled Thesis")
    return JSONResponse(content=_jsonify(thesis), status_code=201)


@app.get("/api/research-theses/{thesis_id}")
def get_research_thesis(thesis_id: str):
    from signals.backend.thesis_store import get_thesis
    thesis = get_thesis(thesis_id)
    if not thesis:
        return JSONResponse(content={"error": "not_found"}, status_code=404)
    return thesis


@app.put("/api/research-theses/{thesis_id}")
def update_research_thesis(thesis_id: str, body: dict = Body(default=None)):
    from signals.backend.thesis_store import update_thesis
    body = body or {}
    kwargs = {}
    for k in ["title", "content_html", "tags", "status", "metadata", "canvas_layout", "is_auto_save"]:
        if isinstance(body, dict) and k in body and body[k] is not None:
            kwargs[k] = body[k]
    thesis = update_thesis(thesis_id, **kwargs)
    if not thesis:
        return JSONResponse(content={"error": "not_found"}, status_code=404)
    return thesis


@app.delete("/api/research-theses/{thesis_id}")
def delete_research_thesis(thesis_id: str):
    from signals.backend.thesis_store import delete_thesis
    deleted = delete_thesis(thesis_id)
    if not deleted:
        return JSONResponse(content={"error": "not_found"}, status_code=404)
    return {"deleted": True}


@app.post("/api/research-theses/{thesis_id}/save")
def save_research_thesis(thesis_id: str, body: dict = Body(default=None)):
    from signals.backend.thesis_store import update_thesis, create_version
    body = body or {}
    if not isinstance(body, dict) or body.get("content_html") is None:
        return JSONResponse(content={"error": "content_html required"}, status_code=400)
    content_html = body.get("content_html")
    metadata = body.get("metadata") if isinstance(body.get("metadata"), dict) else (body.get("metadata") if body.get("metadata") is None else body.get("metadata"))
    version_label = body.get("version_label")
    canvas_layout = body.get("canvas_layout")
    is_auto = version_label is None

    thesis = update_thesis(
        thesis_id,
        content_html=content_html,
        metadata=metadata if metadata is not None else None,
        canvas_layout=canvas_layout if canvas_layout is not None else None,
        is_auto_save=is_auto,
    )
    if not thesis:
        return JSONResponse(content={"error": "not_found"}, status_code=404)

    version = create_version(thesis_id, version_label=version_label, is_auto_save=is_auto)
    if not version:
        return JSONResponse(content={"error": "not_found"}, status_code=404)

    return {"thesis": thesis, "version": version}


@app.get("/api/research-theses/{thesis_id}/versions")
def list_research_thesis_versions(
    thesis_id: str,
    include_auto_saves: bool = Query(False),
):
    from signals.backend.thesis_store import list_versions
    return list_versions(thesis_id, include_auto_saves=include_auto_saves)


@app.post("/api/research-theses/{thesis_id}/versions/{version_id}/restore")
def restore_research_thesis_version(thesis_id: str, version_id: str):
    from signals.backend.thesis_store import restore_version
    thesis = restore_version(thesis_id, version_id)
    if not thesis:
        return JSONResponse(content={"error": "not_found"}, status_code=404)
    return thesis


@app.get("/api/research-theses/{thesis_id}/export")
def export_research_thesis(thesis_id: str):
    from signals.backend.thesis_store import get_thesis, list_versions
    thesis = get_thesis(thesis_id)
    if not thesis:
        return JSONResponse(content={"error": "not_found"}, status_code=404)
    versions = list_versions(thesis_id, include_auto_saves=False)
    from datetime import datetime, timezone
    safe_title = (thesis.get("title") or "thesis")[:30].replace(" ", "-")
    filename = f"thesis-{safe_title}-{datetime.today().strftime('%Y%m%d')}.json"
    body = {
        "export_version": "1",
        "exported_at": datetime.now(timezone.utc).isoformat(),
        "thesis": thesis,
        "versions": versions,
    }
    headers = {"Content-Disposition": f'attachment; filename="{filename}"'}
    return JSONResponse(content=_jsonify(body), headers=headers)


def _serialize_row(cur, row: tuple) -> dict:
    """Convert row tuple to dict with serializable values."""
    if row is None:
        return {}
    cols = [d[0] for d in cur.description]
    out = {}
    for i, c in enumerate(cols):
        v = row[i]
        if isinstance(v, (date, datetime)):
            out[c] = v.isoformat() if v else None
        elif hasattr(v, "__iter__") and not isinstance(v, (str, bytes)):
            try:
                out[c] = list(v)
            except Exception:
                out[c] = str(v)
        else:
            out[c] = v
    return out


def _last_run(conn) -> Optional[str]:
    cur = conn.cursor()
    try:
        for q in [
            "SELECT MAX(generated_at) FROM theses",
            "SELECT MAX(computed_at) FROM regime_snapshots",
            "SELECT MAX(ingested_at) FROM articles",
        ]:
            cur.execute(q)
            r = cur.fetchone()
            if r and r[0]:
                return r[0].isoformat() if hasattr(r[0], "isoformat") else str(r[0])
    finally:
        cur.close()
    return None


@app.post("/api/pipeline/run")
def run_pipeline():
    """Trigger a one-off pipeline run (non-blocking). Returns immediately."""
    env = os.environ.copy()
    env.setdefault("PYTHONPATH", str(_PROJECT_ROOT))
    subprocess.Popen(
        [sys.executable, "-m", "signals.main", "--once"],
        cwd=str(_PROJECT_ROOT),
        env=env,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    return {"status": "started", "message": "Pipeline running"}


@app.get("/api/status")
def get_status():
    """Last run, article count, market_data rows, active theses, daily_signals rows, topics today, anomalies today."""
    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute("SELECT COUNT(*) FROM articles")
        articles_total = cur.fetchone()[0]
        cur.execute("SELECT COUNT(*) FROM market_data")
        market_data_rows = cur.fetchone()[0]
        cur.execute("SELECT COUNT(*) FROM theses WHERE status = 'active'")
        theses_active = cur.fetchone()[0]
        cur.execute("SELECT COUNT(*) FROM daily_signals")
        daily_signals_rows = cur.fetchone()[0]
        cur.execute("""
            SELECT COUNT(DISTINCT topic) FROM daily_signals
            WHERE date = (SELECT MAX(date) FROM daily_signals)
        """)
        topics_active = cur.fetchone()[0] or 0
        cur.execute("""
            SELECT COUNT(*) FROM anomalies
            WHERE detected_at::date = (SELECT MAX(date) FROM daily_signals)
            AND (resolved IS FALSE OR resolved IS NULL)
        """)
        anomalies_today = cur.fetchone()[0] or 0
        last_run = _last_run(conn)
        cur.close()
    return {
        "last_run": last_run,
        "articles_total": articles_total,
        "market_data_rows": market_data_rows,
        "theses_active": theses_active,
        "daily_signals_rows": daily_signals_rows,
        "topics_active": topics_active,
        "anomalies_today": anomalies_today,
    }


@app.get("/api/signals/latest")
def get_signals_latest():
    """Last 30 rows from daily_signals, date desc."""
    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute("""
            SELECT date, topic, article_count, velocity_7d, sentiment_avg,
                   source_count, divergence_flag, anomaly_flag, data_quality
            FROM daily_signals
            ORDER BY date DESC, topic
            LIMIT 30
        """)
        rows = cur.fetchall()
        out = [_serialize_row(cur, r) for r in rows]
        cur.close()
    return out


@app.get("/api/universe")
def get_universe():
    """All instruments with specified fields."""
    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute("""
            SELECT id, name, asset_class, sub_type, geography, sectors,
                   themes, risk_profile, liquidity, yfinance_ticker,
                   sector, country, currency
            FROM instruments
            WHERE is_active = TRUE
            ORDER BY asset_class, id
        """)
        rows = cur.fetchall()
        out = [_serialize_row(cur, r) for r in rows]
        cur.close()
    return out


def _resolve_ticker_lookup(ticker: str) -> dict | None:
    """
    Try to resolve an arbitrary ticker via OpenBB (yfinance provider).
    Falls back to direct yfinance if OpenBB not available.
    Returns a result dict or None if the ticker is invalid.
    """
    # Try OpenBB first
    try:
        from openbb import obb
        r = obb.equity.profile(symbol=ticker, provider="yfinance")
        if r and hasattr(r, 'results') and r.results:
            profile = r.results[0] if hasattr(r.results, '__getitem__') else r.results
            name = getattr(profile, 'name', None) or getattr(profile, 'long_name', None) or ticker
            sector = getattr(profile, 'sector', None)
            return {
                "id": None,
                "name": name,
                "yfinance_ticker": ticker,
                "asset_class": "equity",
                "sector": sector,
                "country": None,
                "currency": None,
                "source": "openbb_lookup"
            }
    except Exception:
        pass

    # Fallback: direct yfinance
    try:
        import yfinance as yf
        info = yf.Ticker(ticker).info
        name = info.get('longName') or info.get('shortName')
        if not name:
            return None
        return {
            "id": None,
            "name": name,
            "yfinance_ticker": ticker,
            "asset_class": "equity",
            "sector": info.get('sector'),
            "country": info.get('country'),
            "currency": info.get('currency'),
            "source": "yfinance_lookup"
        }
    except Exception:
        return None


@app.get("/api/instruments/search")
async def search_instruments(q: str = "", limit: int = 10):
    q = q.strip()
    if len(q) < 2:
        return []

    # Search DB
    try:
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute("""
                    SELECT id, name, yfinance_ticker, asset_class, sector, country, currency
                    FROM instruments
                    WHERE is_active = TRUE
                      AND (
                          name ILIKE %s OR
                          id ILIKE %s OR
                          yfinance_ticker ILIKE %s
                      )
                    ORDER BY
                        CASE WHEN id ILIKE %s THEN 0
                             WHEN yfinance_ticker ILIKE %s THEN 1
                             WHEN name ILIKE %s THEN 2
                             ELSE 3 END,
                        name ASC
                    LIMIT %s
                """, (f'%{q}%', f'%{q}%', f'%{q}%',
                      f'{q}%', f'{q}%', f'{q}%', limit))
                rows = cur.fetchall()
    except Exception as e:
        rows = []

    results = [
        {"id": r[0], "name": r[1], "yfinance_ticker": r[2],
         "asset_class": r[3], "sector": r[4], "country": r[5],
         "currency": r[6], "source": "db"}
        for r in rows
    ]

    # If fewer than limit results and query looks like a ticker (2-6 uppercase letters),
    # try resolving via yfinance
    if len(results) < limit and q == q.upper() and 2 <= len(q) <= 6 and q.isalpha():
        existing_tickers = {r["yfinance_ticker"] for r in results}
        if q not in existing_tickers:
            yf_result = _resolve_ticker_lookup(q)
            if yf_result:
                results.append(yf_result)

    return results


@app.get("/api/instruments")
async def list_instruments(
    asset_class: str = None,
    index_member: str = None,
    limit: int = 500
):
    conditions = ["is_active = TRUE"]
    params = []
    if asset_class:
        conditions.append("asset_class = %s")
        params.append(asset_class)
    if index_member:
        conditions.append("%s = ANY(index_member)")
        params.append(index_member)
    params.append(limit)
    where = " AND ".join(conditions)

    try:
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(f"""
                    SELECT id, name, yfinance_ticker, asset_class,
                           sector, country, currency, index_member
                    FROM instruments
                    WHERE {where}
                    ORDER BY asset_class, name
                    LIMIT %s
                """, params)
                rows = cur.fetchall()
    except Exception as e:
        return []

    return [
        {"id": r[0], "name": r[1], "yfinance_ticker": r[2],
         "asset_class": r[3], "sector": r[4], "country": r[5],
         "currency": r[6], "index_member": list(r[7] or [])}
        for r in rows
    ]


@app.post("/api/instruments/resolve")
async def resolve_instrument(body: dict):
    ticker = (body.get("ticker") or "").strip().upper()
    if not ticker:
        return {"error": "ticker required"}

    # Check if already exists by yfinance_ticker
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT id, name, yfinance_ticker, asset_class, sector, country, currency
                FROM instruments WHERE yfinance_ticker = %s
            """, (ticker,))
            existing = cur.fetchone()

    if existing:
        return {"id": existing[0], "name": existing[1],
                "yfinance_ticker": existing[2], "asset_class": existing[3],
                "sector": existing[4], "country": existing[5],
                "currency": existing[6], "source": "db"}

    # New instrument — assign SIGNAL ID and insert
    signal_id = f"EQ.{ticker.replace('-', '_')}"

    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO instruments
                    (id, name, yfinance_ticker, asset_class, sector,
                     country, currency, is_active)
                VALUES (%s, %s, %s, %s, %s, %s, %s, TRUE)
                ON CONFLICT (id) DO UPDATE SET
                    name = EXCLUDED.name,
                    yfinance_ticker = EXCLUDED.yfinance_ticker,
                    is_active = TRUE
                RETURNING id, name, yfinance_ticker, asset_class, sector, country, currency
            """, (signal_id,
                  body.get("name", ticker),
                  ticker,
                  body.get("asset_class", "equity"),
                  body.get("sector"),
                  body.get("country"),
                  body.get("currency")))
            row = cur.fetchone()
        conn.commit()

    # Also cache in _INSTRUMENTS for this session
    try:
        from signals.backend.price_series_provider import _INSTRUMENTS
        _INSTRUMENTS[signal_id] = {"ticker": ticker, "name": body.get("name", ticker)}
    except Exception:
        pass

    return {"id": row[0], "name": row[1], "yfinance_ticker": row[2],
            "asset_class": row[3], "sector": row[4],
            "country": row[5], "currency": row[6], "source": "inserted"}


@app.get("/api/market_data/latest/all")
def get_market_data_latest_all():
    """Latest value + pct_chg per series_id. Returns dict keyed by series_id (instrument id or FRED id)."""
    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute("""
            WITH latest AS (
                SELECT DISTINCT ON (series_id) series_id, value, pct_chg, daily_chg, date
                FROM market_data
                ORDER BY series_id, date DESC
            )
            SELECT series_id, value, pct_chg, daily_chg, date FROM latest
        """)
        rows = cur.fetchall()
        out = {}
        for r in rows:
            sid = r[0]
            out[sid] = {
                "value": r[1],
                "pct_chg": r[2],
                "daily_chg": r[3],
                "date": r[4].isoformat() if hasattr(r[4], "isoformat") else str(r[4]) if r[4] else None,
            }
        cur.close()
    return out


@app.get("/api/market_data/sparklines")
def get_market_data_sparklines(days: int = Query(7, ge=5, le=90)):
    """Last N days per series_id. Returns { series_id: [{date, value}] }."""
    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute("SELECT DISTINCT series_id FROM market_data")
        series_ids = [row[0] for row in cur.fetchall()]
        out = {}
        for sid in series_ids:
            cur.execute("""
                SELECT date, value FROM market_data
                WHERE series_id = %s
                ORDER BY date DESC
                LIMIT %s
            """, (sid, days))
            out[sid] = [{"date": r[0].isoformat(), "value": r[1]} for r in cur.fetchall()]
        cur.close()
    return out


@app.get("/api/market_data/{series_id}")
def get_market_data(series_id: str, days: int = Query(30, ge=1, le=365)):
    """Last N days of market_data for one series_id."""
    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute("""
            SELECT date, value, daily_chg, pct_chg
            FROM market_data
            WHERE series_id = %s
            ORDER BY date DESC
            LIMIT %s
        """, (series_id, days))
        rows = cur.fetchall()
        out = [_serialize_row(cur, r) for r in rows]
        cur.close()
    return out


@app.get("/api/price-series")
def get_price_series_api(
    ids: str = Query(""),
    from_: Optional[str] = Query(None, alias="from"),
    to: Optional[str] = Query(None),
):
    """
    Daily close price series for SIGNAL instrument IDs.
    Returns an array of per-instrument results (including per-item errors).
    """
    from datetime import timedelta
    from signals.backend.price_series_provider import get_price_series

    ids_param = (ids or "").strip()
    if not ids_param:
        return []
    instrument_ids = [i.strip() for i in ids_param.split(",") if i.strip()]
    if not instrument_ids:
        return []

    from_date = from_ or (datetime.today() - timedelta(days=365)).strftime("%Y-%m-%d")
    to_date = to or datetime.today().strftime("%Y-%m-%d")

    with get_connection() as conn:
        results = [get_price_series(inst_id, from_date, to_date, conn) for inst_id in instrument_ids]
    return results


@app.get("/api/correlations")
def get_correlations():
    """All correlations where quality='ok'."""
    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute("""
            SELECT topic, series_id, lag_days, correlation, p_value
            FROM correlations
            WHERE quality = 'ok'
            ORDER BY ABS(correlation) DESC
        """)
        rows = cur.fetchall()
        out = [_serialize_row(cur, r) for r in rows]
        cur.close()
    return out


@app.get("/api/regime/latest")
def get_regime_latest():
    """Latest regime_snapshots row: 7 indicators + fingerprint + date."""
    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute("""
            SELECT date, growth_pulse, credit_stress, real_yield, dollar_strength,
                   rates_vol, equity_vol, curve_shape, fingerprint, computed_at
            FROM regime_snapshots
            ORDER BY date DESC
            LIMIT 1
        """)
        row = cur.fetchone()
        out = _serialize_row(cur, row) if row else {}
        cur.close()
    return out


@app.get("/api/anomalies/recent")
def get_anomalies_recent():
    """Last 20 anomalies, detected_at desc."""
    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute("""
            SELECT anomaly_type, topic, series_id, severity, description, detected_at
            FROM anomalies
            ORDER BY detected_at DESC
            LIMIT 20
        """)
        rows = cur.fetchall()
        out = [_serialize_row(cur, r) for r in rows]
        cur.close()
    return out


@app.get("/api/theses")
def get_theses():
    """All theses, generated_at desc."""
    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute("""
            SELECT thesis_id, generated_at, theme, hypothesis, confidence, status, full_doc, instruments
            FROM theses
            ORDER BY generated_at DESC
        """)
        rows = cur.fetchall()
        out = [_serialize_row(cur, r) for r in rows]
        cur.close()
    return out


# ——— Briefing, topic detail, regime history, manual theses ———

BRIEFING_MARKET_IDS = [
    "EQ.SPX", "EQ.SX7E", "FI.DE10Y", "DGS10", "FX.EURUSD", "CM.GOLD", "CM.BRENT", "EQ.VIX",
]
SERIES_ID_TO_NAME = {
    "DGS10": "US 10Y",
    "EQ.SPX": "S&P 500",
    "EQ.SX7E": "Euro Stoxx 50",
    "FI.DE10Y": "DE 10Y",
    "FX.EURUSD": "EUR/USD",
    "CM.GOLD": "Gold",
    "CM.BRENT": "Brent",
    "EQ.VIX": "VIX",
}


@app.get("/api/briefing")
def get_briefing():
    """Highlights, signal watch, market snapshot for Briefing screen."""
    from datetime import timedelta
    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute("SELECT MAX(date) FROM daily_signals")
        latest_signal_date = cur.fetchone()[0]
        cur.execute("SELECT MAX(date) FROM regime_snapshots")
        latest_regime_date = cur.fetchone()[0]
        today = date.today()

        highlights = []
        # Regime: compare two most recent snapshots (skip if only one row)
        cur.execute("""
            SELECT date, growth_pulse, credit_stress, real_yield, dollar_strength,
                   rates_vol, equity_vol, curve_shape
            FROM regime_snapshots
            ORDER BY date DESC
            LIMIT 2
        """)
        regime_rows = cur.fetchall()
        if regime_rows and len(regime_rows) >= 2:
            cols = [d[0] for d in cur.description]
            curr = dict(zip(cols, regime_rows[0]))
            prev = dict(zip(cols, regime_rows[1]))
            for k in ["growth_pulse", "credit_stress", "real_yield", "dollar_strength", "rates_vol", "equity_vol", "curve_shape"]:
                if prev.get(k) != curr.get(k) and curr.get(k):
                    label = k.replace("_", " ").title()
                    highlights.append({
                        "type": "regime",
                        "label": label,
                        "description": f"{label} flipped {curr[k]} (was {prev.get(k) or '—'} yesterday)",
                        "timestamp": (curr.get("date") or today).isoformat(),
                        "direction": "neutral",
                    })

        # Signals: divergence or anomaly on latest date (uses MAX(date) already)
        if latest_signal_date:
            cur.execute("""
                SELECT topic, article_count, sentiment_avg, divergence_flag, anomaly_flag
                FROM daily_signals
                WHERE date = %s AND (divergence_flag = TRUE OR anomaly_flag = TRUE)
            """, (latest_signal_date,))
            for r in cur.fetchall():
                topic, article_count, sentiment_avg, div, anom = r[0], r[1], r[2], r[3], r[4]
                direction = "positive" if (sentiment_avg or 0) > 0.1 else ("negative" if (sentiment_avg or 0) < -0.1 else "neutral")
                sent_str = f"{float(sentiment_avg or 0):.2f}"
                highlights.append({
                    "type": "signal",
                    "label": topic,
                    "description": f"{topic} signal heating up — {article_count or 0} articles, sentiment {'up' if direction == 'positive' else 'down' if direction == 'negative' else 'neutral'} ({sent_str})",
                    "timestamp": latest_signal_date.isoformat(),
                    "direction": direction,
                })

        # Market: |pct_chg| > 1.5% today (use latest date in market_data as "today")
        cur.execute("SELECT MAX(date) FROM market_data")
        latest_md_date = cur.fetchone()[0]
        if latest_md_date:
            cur.execute("""
                SELECT md.series_id, md.value, md.pct_chg, i.name
                FROM market_data md
                LEFT JOIN instruments i ON i.id = md.series_id
                WHERE md.date = %s AND ABS(md.pct_chg) > 1.5
            """, (latest_md_date,))
            for r in cur.fetchall():
                series_id, value, pct_chg, name = r[0], r[1], r[2], r[3]
                display_name = (name or series_id)[:20]
                direction = "positive" if (pct_chg or 0) > 0 else "negative"
                highlights.append({
                    "type": "market",
                    "label": display_name,
                    "description": f"{display_name} {float(pct_chg or 0):.2f}% today ({float(value or 0):.2f} current)",
                    "timestamp": latest_md_date.isoformat(),
                    "direction": direction,
                })

        # Signal watch: top 5 topics by article_count for latest date (MAX(date) from daily_signals)
        signal_watch = []
        if latest_signal_date:
            cur.execute("""
                SELECT topic, article_count, velocity_7d, sentiment_avg
                FROM daily_signals
                WHERE date = %s
                ORDER BY article_count DESC NULLS LAST
                LIMIT 5
            """, (latest_signal_date,))
            signal_rows = cur.fetchall()
            for r in signal_rows:
                topic, article_count, velocity_7d, sentiment_avg = r[0], r[1], r[2], r[3]
                cur.execute("""
                    SELECT title FROM articles
                    WHERE processed = TRUE AND topics ? %s
                    ORDER BY published_at DESC NULLS LAST
                    LIMIT 1
                """, (topic,))
                art = cur.fetchone()
                latest_title = (art[0][:60] + "…") if art and art[0] and len(art[0]) > 60 else (art[0] if art else None)
                cur.execute("SELECT id FROM instruments WHERE themes @> ARRAY[%s]::text[] LIMIT 3", (topic,))
                linked = [row[0] for row in cur.fetchall()]
                signal_watch.append({
                    "topic": topic,
                    "article_count": article_count,
                    "velocity_7d": velocity_7d,
                    "sentiment_avg": sentiment_avg,
                    "latest_article_title": latest_title,
                    "linked_instruments": linked,
                })

        # Market snapshot: try priority IDs, then fallback to instrument id or yfinance_ticker
        cur.execute("SELECT DISTINCT series_id FROM market_data")
        available_series = {row[0] for row in cur.fetchall()}
        cur.execute("SELECT id, name, yfinance_ticker, fred_series_id FROM instruments WHERE id = ANY(%s)", (BRIEFING_MARKET_IDS,))
        inst_by_id = {row[0]: {"name": row[1], "yfinance_ticker": row[2], "fred_series_id": row[3]} for row in cur.fetchall()}
        market_snapshot = []
        missing_ids = []
        for series_id in BRIEFING_MARKET_IDS:
            name = SERIES_ID_TO_NAME.get(series_id) or (inst_by_id.get(series_id, {}).get("name") or series_id)
            sid_to_try = series_id
            row = None
            cur.execute("""
                SELECT value, pct_chg FROM market_data
                WHERE series_id = %s
                ORDER BY date DESC
                LIMIT 1
            """, (sid_to_try,))
            row = cur.fetchone()
            if not row and series_id == "DGS10":
                cur.execute("SELECT value, pct_chg FROM market_data WHERE series_id = 'FI.US10Y' ORDER BY date DESC LIMIT 1")
                row = cur.fetchone()
                if row:
                    sid_to_try = "FI.US10Y"
            if not row and inst_by_id.get(series_id):
                yf = (inst_by_id[series_id].get("yfinance_ticker") or "").strip()
                if yf:
                    cur.execute("SELECT value, pct_chg FROM market_data WHERE series_id = %s ORDER BY date DESC LIMIT 1", (yf,))
                    row = cur.fetchone()
                    if row:
                        sid_to_try = yf
            if row:
                market_snapshot.append({
                    "series_id": sid_to_try,
                    "name": name,
                    "value": row[0],
                    "pct_chg_1d": row[1],
                })
            else:
                market_snapshot.append({"series_id": series_id, "name": name, "value": None, "pct_chg_1d": None})
                missing_ids.append(series_id)
        found_ids = [s["series_id"] for s in market_snapshot if s.get("value") is not None]
        # If no priority instruments had data, use any available series
        if not found_ids and available_series:
            market_snapshot = []
            for sid in list(available_series)[:8]:
                cur.execute("SELECT value, pct_chg FROM market_data WHERE series_id = %s ORDER BY date DESC LIMIT 1", (sid,))
                r = cur.fetchone()
                if r:
                    market_snapshot.append({"series_id": sid, "name": sid, "value": r[0], "pct_chg_1d": r[1]})

        default_chart = None
        best_abs = -1
        for m in market_snapshot:
            if m.get("pct_chg_1d") is not None:
                a = abs(float(m["pct_chg_1d"]))
                if a > best_abs:
                    best_abs = a
                    default_chart = m["series_id"]
        cur.close()

    return {
        "highlights": highlights,
        "signal_watch": signal_watch,
        "market_snapshot": market_snapshot,
        "default_chart_series_id": default_chart,
    }


@app.get("/api/signals/topic/{topic}")
def get_signals_topic(topic: str):
    """One topic: 30d stats, last 10 articles, linked instruments."""
    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute("""
            SELECT date, article_count, velocity_7d, sentiment_avg, divergence_flag, anomaly_flag
            FROM daily_signals
            WHERE topic = %s
            ORDER BY date DESC
            LIMIT 30
        """, (topic,))
        stats_rows = cur.fetchall()
        # Articles: topics is JSONB object { "topic_key": score }. Match key and score > 0.35
        cur.execute("""
            SELECT id, title, source_id, published_at, sentiment
            FROM articles
            WHERE processed = TRUE AND topics IS NOT NULL AND topics != 'null'::jsonb
            AND topics ? %s AND COALESCE((topics->>%s)::float, 0) > 0.35
            ORDER BY published_at DESC NULLS LAST
            LIMIT 10
        """, (topic, topic))
        articles_rows = cur.fetchall()
        if not articles_rows:
            cur.execute("""
                SELECT id, title, source_id, published_at, sentiment
                FROM articles
                WHERE processed = TRUE AND topics IS NOT NULL AND topics != 'null'::jsonb AND topics ? %s
                ORDER BY published_at DESC NULLS LAST
                LIMIT 10
            """, (topic,))
            articles_rows = cur.fetchall()
        cur.execute("SELECT id, name FROM instruments WHERE themes @> ARRAY[%s]::text[]", (topic,))
        inst_rows = cur.fetchall()
        cur.close()

    stats = []
    for r in stats_rows:
        stats.append({
            "date": r[0].isoformat() if r[0] else None,
            "article_count": r[1],
            "velocity_7d": r[2],
            "sentiment_avg": r[3],
            "divergence_flag": r[4],
            "anomaly_flag": r[5],
        })
    articles = []
    for r in articles_rows:
        articles.append({
            "id": r[0],
            "title": r[1],
            "source_id": r[2],
            "published_at": r[3].isoformat() if hasattr(r[3], "isoformat") else str(r[3]) if r[3] else None,
            "sentiment": r[4],
        })
    linked_instruments = [{"id": r[0], "name": r[1]} for r in inst_rows]
    return {
        "stats": stats,
        "articles": articles,
        "linked_instruments": linked_instruments,
    }


REGIME_SERIES_IDS = {
    "growth_pulse": ["CM.COPPER", "CM.GOLD"],
    "credit_stress": ["EQ.HYG"],
    "real_yield": ["DFII10"],
    "dollar_strength": ["FX.DXY"],
    "rates_vol": ["EQ.MOVE"],
    "equity_vol": ["EQ.VIX"],
    "curve_shape": ["T10Y2Y"],
}


@app.get("/api/regime/history")
def get_regime_history(days: int = Query(90, ge=7, le=365)):
    """Per-indicator time series from market_data for last N days."""
    from datetime import timedelta
    end = date.today()
    start = end - timedelta(days=days)
    out = {}
    with get_connection() as conn:
        cur = conn.cursor()
        for ind_name, series_list in REGIME_SERIES_IDS.items():
            if ind_name == "growth_pulse" and len(series_list) >= 2:
                cur.execute("""
                    SELECT date, series_id, value FROM market_data
                    WHERE series_id IN (%s, %s) AND date >= %s AND date <= %s
                    ORDER BY date
                """, (series_list[0], series_list[1], start, end))
                rows = cur.fetchall()
                by_date = {}
                for d, sid, v in rows:
                    if d not in by_date:
                        by_date[d] = {}
                    by_date[d][sid] = v
                ratio_series = []
                for d in sorted(by_date.keys()):
                    a, b = by_date[d].get(series_list[0]), by_date[d].get(series_list[1])
                    if a is not None and b is not None and b != 0:
                        ratio_series.append({"date": d.isoformat(), "value": float(a) / float(b)})
                out[ind_name] = ratio_series
            else:
                sid = series_list[0]
                cur.execute("""
                    SELECT date, value FROM market_data
                    WHERE series_id = %s AND date >= %s AND date <= %s
                    ORDER BY date
                """, (sid, start, end))
                out[ind_name] = [{"date": r[0].isoformat(), "value": r[1]} for r in cur.fetchall()]
        cur.close()
    return out


@app.post("/api/theses")
def create_thesis(body: dict = Body(default=None)):
    """Create a manual draft thesis. thesis_id auto-assigned as MAN-NNN if omitted."""
    import json
    body = body or {}
    with get_connection() as conn:
        cur = conn.cursor()
        thesis_id = body.get("thesis_id")
        if not thesis_id or not str(thesis_id).strip():
            cur.execute("SELECT COALESCE(MAX(CAST(SUBSTRING(thesis_id FROM 5) AS INTEGER)), 0) + 1 FROM theses WHERE thesis_id LIKE 'MAN-%'")
            n = cur.fetchone()[0]
            thesis_id = f"MAN-{n:03d}"
        inst = body.get("instruments")
        sig = body.get("signals_used")
        cur.execute("""
            INSERT INTO theses (thesis_id, generated_at, theme, hypothesis, full_doc, instruments, signals_used, confidence, status)
            VALUES (%s, NOW(), %s, %s, %s, %s::jsonb, %s::jsonb, %s, %s)
        """, (
            thesis_id,
            body.get("theme") or "",
            body.get("hypothesis") or "",
            body.get("full_doc") or "",
            json.dumps(inst) if isinstance(inst, (list, dict)) else (inst or "[]"),
            json.dumps(sig) if isinstance(sig, (list, dict)) else (sig or "[]"),
            body.get("confidence"),
            body.get("status") or "draft",
        ))
        conn.commit()
        cur.close()
    return {"status": "ok", "thesis_id": thesis_id}


# ---------------------------------------------------------------------------
# Research API (R2+R3)
# ---------------------------------------------------------------------------

def _research_json(obj: dict, status: int = 200):
    return JSONResponse(content=_jsonify(obj), status_code=status)


@app.get("/api/research/articles")
async def get_research_articles(limit: int = 50):
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT id, title, url, source_id, published_at,
                       sentiment, topics, entities
                FROM articles
                WHERE processed = TRUE
                ORDER BY published_at DESC
                LIMIT %s
            """, (limit,))
            rows = cur.fetchall()
    return [
        {
            "id": r[0],
            "title": r[1],
            "url": r[2],
            "source_id": r[3],
            "published_at": r[4].isoformat() if r[4] else None,
            "sentiment": r[5],
            "topics": r[6] or [],
            "entities": r[7] or []
        }
        for r in rows
    ]


@app.get("/api/research/series")
def get_research_series(series_ids: str = Query(""), days: int = Query(90, ge=1, le=365)):
    ids = [x.strip() for x in series_ids.split(",") if x.strip()]
    if not ids:
        return _research_json({"series": {}, "common_dates": 0, "date_range": {"from": None, "to": None}, "missing_series": []})
    try:
        from signals.research.data import get_series_bulk
        with get_connection() as conn:
            out = get_series_bulk(conn, ids, days)
        return _research_json(out)
    except Exception as e:
        return _research_json({"error": str(e), "detail": str(e)}, 500)


@app.get("/api/research/returns")
def get_research_returns(series_ids: str = Query(""), days: int = Query(90, ge=1, le=365)):
    ids = [x.strip() for x in series_ids.split(",") if x.strip()]
    if not ids:
        return _research_json({"series": {}, "common_dates": 0, "date_range": {"from": None, "to": None}, "missing_series": []})
    try:
        from signals.research.data import get_series_bulk
        with get_connection() as conn:
            raw = get_series_bulk(conn, ids, days)
        for sid in raw.get("series", {}):
            raw["series"][sid] = [{"date": x["date"], "return_pct": x.get("pct_chg")} for x in raw["series"][sid]]
        return _research_json(raw)
    except Exception as e:
        return _research_json({"error": str(e)}, 500)


@app.get("/api/research/overview")
def get_research_overview(days: int = Query(30, ge=1, le=365)):
    try:
        from signals.research.overview import compute_overview
        with get_connection() as conn:
            out = compute_overview(conn, days)
        if out.get("error"):
            return _research_json(out, 400)
        return _research_json(out)
    except Exception as e:
        return _research_json({"error": str(e)}, 500)


@app.get("/api/research/correlation_matrix")
def get_correlation_matrix(series_ids: str = Query(""), days: int = Query(90, ge=1, le=365)):
    ids = [x.strip() for x in series_ids.split(",") if x.strip()]
    if not ids:
        return _research_json({"error": "series_ids required"}, 400)
    try:
        from signals.research.correlation import compute_correlation_matrix
        with get_connection() as conn:
            out = compute_correlation_matrix(conn, ids, days)
        if out.get("error"):
            return _research_json(out, 400)
        return _research_json(out)
    except Exception as e:
        return _research_json({"error": str(e)}, 500)


@app.get("/api/research/rolling_correlation")
def get_rolling_correlation(
    series_a: str = Query(""), series_b: str = Query(""),
    window: int = Query(30, ge=5, le=120), days: int = Query(180, ge=1, le=365),
):
    if not series_a or not series_b:
        return _research_json({"error": "series_a and series_b required"}, 400)
    try:
        from signals.research.correlation import compute_rolling_correlation
        with get_connection() as conn:
            out = compute_rolling_correlation(conn, series_a, series_b, window, days)
        if out.get("error"):
            return _research_json(out, 400)
        return _research_json(out)
    except Exception as e:
        return _research_json({"error": str(e)}, 500)


@app.get("/api/research/impact")
def get_impact(
    base_series: str = Query(""), target_series: str = Query(""),
    shock_pct: float = Query(10), shock_bps: Optional[float] = Query(None),
    days: int = Query(90, ge=1, le=365),
):
    if not base_series or not target_series:
        return _research_json({"error": "base_series and target_series required"}, 400)
    targets = [x.strip() for x in target_series.split(",") if x.strip()]
    try:
        from signals.research.impact import compute_impact
        with get_connection() as conn:
            out = compute_impact(conn, base_series, targets, shock_pct, days, shock_bps)
        if out.get("error"):
            return _research_json(out, 400)
        return _research_json(out)
    except Exception as e:
        return _research_json({"error": str(e)}, 500)


@app.get("/api/research/lead_lag")
def get_lead_lag(
    series_a: str = Query(""), series_b: str = Query(""),
    max_lag: int = Query(10, ge=1, le=30), days: int = Query(180, ge=1, le=365),
):
    if not series_a or not series_b:
        return _research_json({"error": "series_a and series_b required"}, 400)
    try:
        from signals.research.correlation import compute_lead_lag
        with get_connection() as conn:
            out = compute_lead_lag(conn, series_a, series_b, max_lag, days)
        if out.get("error"):
            return _research_json(out, 400)
        return _research_json(out)
    except Exception as e:
        return _research_json({"error": str(e)}, 500)


@app.get("/api/research/factor_decomposition")
def get_factor_decomposition(target_series: str = Query(""), days: int = Query(90, ge=1, le=365)):
    if not target_series:
        return _research_json({"error": "target_series required"}, 400)
    try:
        from signals.research.factor_model import compute_factor_decomposition
        with get_connection() as conn:
            out = compute_factor_decomposition(conn, target_series.strip(), days)
        if out.get("error"):
            return _research_json(out, 400)
        return _research_json(out)
    except Exception as e:
        return _research_json({"error": str(e)}, 500)


@app.get("/api/factors")
def get_factors_e1(instrument: str = Query(""), days: int = Query(90, ge=1, le=365)):
    """
    E1: Factor decomposition for a SIGNAL instrument. Returns instrument, name, factors (with id, name, beta, r2, p_value, residual_std_error, primary_instrument), total_r2.
    Error: HTTP 200 with { "instrument": "...", "error": "no_decomposition" }.
    """
    if not instrument or not instrument.strip():
        return _research_json({"instrument": "", "error": "no_decomposition"}, 200)
    instrument = instrument.strip()
    try:
        from signals.backend.factor_instruments import FACTOR_INSTRUMENTS

        # Check cache first
        cached = _get_cached_decomposition(instrument)
        if cached:
            return cached

        # For equities/ETFs: ensure market_data is populated before decomposition
        asset_class = _get_instrument_asset_class(instrument)
        is_equity_instrument = asset_class in ('equity', 'etf')

        if is_equity_instrument:
            with get_connection() as check_conn:
                with check_conn.cursor() as cur:
                    cur.execute(
                        "SELECT COUNT(*) FROM market_data WHERE series_id = %s",
                        (instrument,),
                    )
                    row_count = cur.fetchone()[0]

            if row_count < 60:
                # Fetch 2 years of price history and write to market_data
                from datetime import datetime, timedelta
                from signals.backend.price_series_provider import get_price_series

                from_date = (datetime.today() - timedelta(days=730)).strftime('%Y-%m-%d')
                to_date = datetime.today().strftime('%Y-%m-%d')
                price_result = get_price_series(instrument, from_date, to_date, db_conn=None)

                if "error" not in price_result and price_result.get("dates"):
                    with get_connection() as insert_conn:
                        with insert_conn.cursor() as cur:
                            cur.execute("""
                                SELECT column_name FROM information_schema.columns
                                WHERE table_name = 'market_data'
                                ORDER BY ordinal_position
                            """)
                            cols = [r[0] for r in cur.fetchall()]
                            has_daily_chg = "daily_chg" in cols
                            has_pct_chg = "pct_chg" in cols
                            has_source = "source" in cols

                            # Pre-build rows: date, value, daily_chg, pct_chg
                            dates = price_result["dates"]
                            values = price_result["values"]

                            rows_to_insert = []
                            prev_v = None
                            for i, (d, v) in enumerate(zip(dates, values)):
                                if v is None:
                                    continue
                                fv = float(v)
                                if fv != fv:  # NaN
                                    continue

                                daily_chg = None
                                pct_chg = None
                                if i > 0 and prev_v is not None and prev_v != 0 and prev_v == prev_v:
                                    daily_chg = fv - prev_v if has_daily_chg else None
                                    pct_chg = (100.0 * (fv - prev_v) / prev_v) if has_pct_chg else None

                                prev_v = fv
                                rows_to_insert.append((d, instrument, round(fv, 4), daily_chg, pct_chg))

                            # For non-US equities (and ETFs), trading calendars differ.
                            # Forward-fill the target close onto the EQ.SPX calendar dates so
                            # the factor join has enough overlapping observations.
                            try:
                                ref_from = (datetime.today() - timedelta(days=252 + 30)).strftime('%Y-%m-%d')
                                ref_to = datetime.today().strftime('%Y-%m-%d')
                                cur.execute("""
                                    SELECT date
                                    FROM market_data
                                    WHERE series_id = 'EQ.SPX'
                                      AND date >= %s AND date <= %s
                                      AND pct_chg IS NOT NULL
                                    ORDER BY date
                                """, (ref_from, ref_to))
                                ref_dates = [r[0] for r in cur.fetchall()]
                                # Build sorted price points for forward-fill lookup.
                                price_points = []
                                for d, v in zip(dates, values):
                                    if v is None:
                                        continue
                                    fv = float(v)
                                    if fv != fv:
                                        continue
                                    price_points.append((datetime.fromisoformat(str(d)).date(), fv))
                                price_points.sort(key=lambda x: x[0])
                                idx = 0
                                last_close = None
                                prev_syn_close = None
                                synthetic_rows = []
                                for rd in ref_dates:
                                    while idx < len(price_points) and price_points[idx][0] <= rd:
                                        last_close = price_points[idx][1]
                                        idx += 1
                                    if last_close is None:
                                        continue
                                    daily_chg = None
                                    pct_chg = None
                                    if prev_syn_close is not None and prev_syn_close != 0 and prev_syn_close == prev_syn_close:
                                        daily_chg = (last_close - prev_syn_close) if has_daily_chg else None
                                        pct_chg = (100.0 * (last_close - prev_syn_close) / prev_syn_close) if has_pct_chg else None
                                    synthetic_rows.append((rd.isoformat(), instrument, round(last_close, 4), daily_chg, pct_chg))
                                    prev_syn_close = last_close
                                if synthetic_rows:
                                    rows_to_insert.extend(synthetic_rows)
                            except Exception:
                                pass

                            # Insert using NOT EXISTS pattern (schema may not have a unique constraint for ON CONFLICT).
                            if has_pct_chg and has_daily_chg and has_source:
                                cur.executemany("""
                                    INSERT INTO market_data (date, series_id, value, daily_chg, pct_chg, source)
                                    SELECT %s, %s, %s, %s, %s, 'yfinance_direct'
                                    WHERE NOT EXISTS (
                                        SELECT 1 FROM market_data WHERE date = %s AND series_id = %s
                                    )
                                """, [(d, s, val, dchg, pchg, d, s) for (d, s, val, dchg, pchg) in rows_to_insert])
                            else:
                                # Minimal fallback: insert date/series/value (+ daily_chg if present, without pct_chg).
                                if has_daily_chg and has_source:
                                    cur.executemany("""
                                        INSERT INTO market_data (date, series_id, value, daily_chg, source)
                                        SELECT %s, %s, %s, %s, 'yfinance_direct'
                                        WHERE NOT EXISTS (
                                            SELECT 1 FROM market_data WHERE date = %s AND series_id = %s
                                        )
                                    """, [(d, s, val, dchg, d, s) for (d, s, val, dchg, _pchg) in rows_to_insert])
                                elif has_source:
                                    cur.executemany("""
                                        INSERT INTO market_data (date, series_id, value, source)
                                        SELECT %s, %s, %s, 'yfinance_direct'
                                        WHERE NOT EXISTS (
                                            SELECT 1 FROM market_data WHERE date = %s AND series_id = %s
                                        )
                                    """, [(d, s, val, d, s) for (d, s, val, _dchg, _pchg) in rows_to_insert])

                        insert_conn.commit()

        # Calendar-alignment forward-fill (idempotent): ensure the target has values
        # on the EQ.SPX factor calendar dates, even if the initial yfinance insert
        # already populated the series.
        try:
            from datetime import timedelta
            with get_connection() as insert_conn:
                with insert_conn.cursor() as cur:
                    cur.execute("""
                        SELECT column_name FROM information_schema.columns
                        WHERE table_name = 'market_data'
                        ORDER BY ordinal_position
                    """)
                    cols = [r[0] for r in cur.fetchall()]
                    has_daily_chg = "daily_chg" in cols
                    has_pct_chg = "pct_chg" in cols
                    has_source = "source" in cols

                    ref_from = (datetime.today() - timedelta(days=252 + 30)).strftime('%Y-%m-%d')
                    ref_to = datetime.today().strftime('%Y-%m-%d')
                    cur.execute("""
                        SELECT date
                        FROM market_data
                        WHERE series_id = 'EQ.SPX'
                          AND date >= %s AND date <= %s
                          AND pct_chg IS NOT NULL
                        ORDER BY date
                    """, (ref_from, ref_to))
                    ref_dates = [r[0] for r in cur.fetchall()]

                    if ref_dates:
                        base_from = (datetime.today() - timedelta(days=730)).strftime('%Y-%m-%d')
                        cur.execute("""
                            SELECT date, value
                            FROM market_data
                            WHERE series_id = %s
                              AND date >= %s AND date <= %s
                            ORDER BY date ASC
                        """, (instrument, base_from, ref_to))
                        value_rows = cur.fetchall()

                        price_points = [(r[0], float(r[1])) for r in value_rows if r[1] is not None]
                        price_points.sort(key=lambda x: x[0])

                        idx = 0
                        last_close = None
                        prev_syn_close = None
                        synthetic_rows = []

                        for rd in ref_dates:
                            while idx < len(price_points) and price_points[idx][0] <= rd:
                                last_close = price_points[idx][1]
                                idx += 1
                            if last_close is None:
                                continue

                            daily_chg = None
                            pct_chg = None
                            if prev_syn_close is not None and prev_syn_close != 0 and prev_syn_close == prev_syn_close:
                                daily_chg = (last_close - prev_syn_close) if has_daily_chg else None
                                pct_chg = (100.0 * (last_close - prev_syn_close) / prev_syn_close) if has_pct_chg else None

                            synthetic_rows.append((rd.isoformat(), instrument, round(last_close, 4), daily_chg, pct_chg))
                            prev_syn_close = last_close

                        if synthetic_rows:
                            if has_pct_chg and has_daily_chg and has_source:
                                cur.executemany("""
                                    INSERT INTO market_data (date, series_id, value, daily_chg, pct_chg, source)
                                    SELECT %s, %s, %s, %s, %s, 'yfinance_direct'
                                    WHERE NOT EXISTS (
                                        SELECT 1 FROM market_data WHERE date = %s AND series_id = %s
                                    )
                                """, [(d, s, val, dchg, pchg, d, s) for (d, s, val, dchg, pchg) in synthetic_rows])
                            else:
                                if has_daily_chg and has_source:
                                    cur.executemany("""
                                        INSERT INTO market_data (date, series_id, value, daily_chg, source)
                                        SELECT %s, %s, %s, %s, 'yfinance_direct'
                                        WHERE NOT EXISTS (
                                            SELECT 1 FROM market_data WHERE date = %s AND series_id = %s
                                        )
                                    """, [(d, s, val, dchg, d, s) for (d, s, val, dchg, _pchg) in synthetic_rows])
                                elif has_source:
                                    cur.executemany("""
                                        INSERT INTO market_data (date, series_id, value, source)
                                        SELECT %s, %s, %s, 'yfinance_direct'
                                        WHERE NOT EXISTS (
                                            SELECT 1 FROM market_data WHERE date = %s AND series_id = %s
                                        )
                                    """, [(d, s, val, d, s) for (d, s, val, _dchg, _pchg) in synthetic_rows])

                    insert_conn.commit()
        except Exception:
            pass

        with get_connection() as conn:
            decomp_days = 252 if is_equity_instrument else days
            out = compute_factor_decomposition(conn, instrument, decomp_days)
            if out.get("error"):
                return _research_json({"instrument": instrument, **out}, 200)
            inst_name = instrument
            try:
                cur = conn.cursor()
                cur.execute("SELECT name FROM instruments WHERE id = %s", (instrument,))
                row = cur.fetchone()
                if row:
                    inst_name = row[0]
                cur.close()
            except Exception:
                pass

        total_r2 = out["model"]["r_squared"]
        res_std = out["model"].get("residual_std_error", 0.0)
        factors_spec = []
        for f in out["factors"]:
            fkey = f["factor"]
            meta = FACTOR_INSTRUMENTS.get(fkey, {})
            primary = meta.get("primary_instrument", "")
            factors_spec.append({
                "id": fkey,
                "name": f["name"],
                "beta": f["beta"],
                "r2": f.get("r2", 0),
                "p_value": f["p_value"],
                "residual_std_error": round(res_std, 6),
                "primary_instrument": primary,
            })
        final_result = {
            "instrument": instrument,
            "name": inst_name,
            "factors": factors_spec,
            "total_r2": total_r2,
        }

        # Cache result
        ttl = 24 if is_equity_instrument else 4
        _cache_decomposition(instrument, final_result, ttl_hours=ttl)

        return _research_json(final_result)
    except Exception as e:
        return _research_json({"instrument": instrument, "error": "no_decomposition"}, 200)


@app.get("/api/factor-map")
def get_factor_map():
    """E1: Full INSTRUMENT_TO_FACTOR mapping for frontend shock routing."""
    from signals.backend.factor_instruments import INSTRUMENT_TO_FACTOR
    return _research_json(INSTRUMENT_TO_FACTOR)


@app.get("/api/research/factor_comparison")
def get_factor_comparison(target_series: str = Query(""), days: int = Query(90, ge=1, le=365)):
    ids = [x.strip() for x in target_series.split(",") if x.strip()]
    if not ids:
        return _research_json({"error": "target_series required"}, 400)
    try:
        from signals.research.factor_model import compute_factor_comparison
        with get_connection() as conn:
            out = compute_factor_comparison(conn, ids, days)
        return _research_json(out)
    except Exception as e:
        return _research_json({"error": str(e)}, 500)


@app.get("/api/research/forecast")
def get_forecast(
    series_id: str = Query(""), days_forward: int = Query(30), days_history: int = Query(90),
    model: str = Query("both"),
):
    if not series_id:
        return _research_json({"error": "series_id required"}, 400)
    if model not in ("arima", "linear", "both"):
        model = "both"
    try:
        from signals.research.forecasting import compute_forecast
        with get_connection() as conn:
            out = compute_forecast(conn, series_id.strip(), days_forward, days_history, model)
        if out.get("error"):
            return _research_json(out, 400)
        return _research_json(out)
    except Exception as e:
        import traceback
        traceback.print_exc()
        return _research_json({"error": str(e)}, 500)


@app.get("/api/research/forecast/decompose")
def get_forecast_decompose(series_id: str = Query(""), days: int = Query(180, ge=1, le=365)):
    if not series_id:
        return _research_json({"error": "series_id required"}, 400)
    try:
        from signals.research.forecasting import compute_stl_decomposition
        with get_connection() as conn:
            out = compute_stl_decomposition(conn, series_id.strip(), days)
        if out.get("error"):
            return _research_json(out, 400)
        return _research_json(out)
    except Exception as e:
        return _research_json({"error": str(e)}, 500)


@app.get("/api/research/volatility")
def get_volatility(series_id: str = Query(""), days: int = Query(90, ge=1, le=365)):
    if not series_id:
        return _research_json({"error": "series_id required"}, 400)
    try:
        from signals.research.volatility import compute_volatility
        with get_connection() as conn:
            out = compute_volatility(conn, series_id.strip(), days)
        if out.get("error"):
            return _research_json(out, 400)
        return _research_json(out)
    except Exception as e:
        return _research_json({"error": str(e)}, 500)


@app.get("/api/research/volatility/surface")
def get_vol_surface(series_ids: str = Query(""), days: int = Query(90, ge=1, le=365)):
    ids = [x.strip() for x in series_ids.split(",") if x.strip()]
    if not ids:
        return _research_json({"instruments": []})
    try:
        from signals.research.volatility import compute_vol_surface
        with get_connection() as conn:
            out = compute_vol_surface(conn, ids, days)
        return _research_json(out)
    except Exception as e:
        return _research_json({"error": str(e)}, 500)


@app.get("/api/research/scenarios")
def get_scenarios():
    try:
        from signals.research.scenario import get_preset_scenarios
        presets = get_preset_scenarios()
        return _research_json({"presets": presets})
    except Exception as e:
        return _research_json({"error": str(e)}, 500)


@app.post("/api/research/scenario/run")
def post_scenario_run(body: dict = Body(...)):
    shocks = body.get("shocks") or []
    target_series = body.get("target_series") or []
    days = int(body.get("days") or 90)
    if not shocks or not target_series:
        return _research_json({"error": "shocks and target_series required"}, 400)
    try:
        from signals.research.scenario import run_scenario
        with get_connection() as conn:
            out = run_scenario(conn, shocks, target_series, days)
        if out.get("error"):
            return _research_json(out, 400)
        return _research_json(out)
    except Exception as e:
        return _research_json({"error": str(e)}, 500)


@app.get("/api/research/yield_curve")
def get_yield_curve(
    date_param: Optional[str] = Query("latest", alias="date"),
    compare_dates: Optional[str] = Query(None),
):
    try:
        from signals.research.rates import compute_yield_curve
        with get_connection() as conn:
            out = compute_yield_curve(conn, date_param or "latest", compare_dates)
        return _research_json(out)
    except Exception as e:
        return _research_json({"error": str(e)}, 500)


@app.get("/api/research/yield_curve/history")
def get_yield_curve_history(days: int = Query(180, ge=1, le=365)):
    try:
        from signals.research.rates import compute_yield_curve_history
        with get_connection() as conn:
            out = compute_yield_curve_history(conn, days)
        return _research_json(out)
    except Exception as e:
        return _research_json({"error": str(e)}, 500)


@app.get("/api/research/rates/decomposition")
def get_rates_decomposition(days: int = Query(90, ge=1, le=365)):
    try:
        from signals.research.rates import compute_rates_decomposition
        with get_connection() as conn:
            out = compute_rates_decomposition(conn, days)
        if out.get("error"):
            return _research_json(out, 400)
        return _research_json(out)
    except Exception as e:
        return _research_json({"error": str(e)}, 500)


@app.get("/api/research/momentum")
def get_momentum(series_ids: str = Query(""), days: int = Query(180, ge=1, le=365)):
    ids = [x.strip() for x in series_ids.split(",") if x.strip()]
    if not ids:
        return _research_json({"instruments": []})
    try:
        from signals.research.momentum import compute_momentum
        with get_connection() as conn:
            out = compute_momentum(conn, ids, days)
        return _research_json(out)
    except Exception as e:
        return _research_json({"error": str(e)}, 500)


@app.get("/api/research/momentum/cross_asset")
def get_momentum_cross_asset(days: int = Query(90, ge=1, le=365)):
    try:
        from signals.research.momentum import compute_momentum_cross_asset
        with get_connection() as conn:
            out = compute_momentum_cross_asset(conn, days)
        return _research_json(out)
    except Exception as e:
        return _research_json({"error": str(e)}, 500)


app.include_router(__import__("signals.thesis_engine.router", fromlist=["router"]).router)

_DASHBOARD_DIR = _PROJECT_ROOT / "signals" / "dashboard"


@app.get("/api/demo")
def demo_flags():
    return {"demo": _demo_mode()}


# Mount last so /api/* keeps precedence. html=True serves index.html for "/".
if _DASHBOARD_DIR.is_dir():
    app.mount(
        "/",
        StaticFiles(directory=str(_DASHBOARD_DIR), html=True),
        name="dashboard",
    )


if __name__ == "__main__":
    import uvicorn

    port = int(os.environ.get("PORT", "8000"))
    uvicorn.run(
        "signals.api.server:app",
        host="0.0.0.0",
        port=port,
        reload=not _demo_mode(),
    )
