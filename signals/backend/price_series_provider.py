"""
signals/backend/price_series_provider.py

Fetches daily close price series for one or more SIGNAL instrument IDs.

Data source priority (in order):
  1. market_data DB table — queried first for any dates already stored
  2. yfinance direct — used to fill any date gaps not in DB, or full fetch
     if instrument has no DB rows in the requested range
  3. OpenBB (obb.equity.price.historical) — stubbed try/except for future
     use; currently always falls through because openbb is not installed

Caching:
  In-memory cache keyed by (instrument_id, from_date, to_date).
  Cache entries are invalidated if cached_on != today's date.
  Only successful results (no "error" key) are cached.
"""

from __future__ import annotations

import logging
import math
from datetime import date, datetime, timedelta
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

import yfinance as yf

from signals.db.connection import get_connection

logger = logging.getLogger("signals.price_series")


def _parse_date(s: str) -> date:
    return date.fromisoformat(str(s)[:10])


def _date_str(d: date) -> str:
    return d.isoformat()


def _load_instrument_config() -> dict:
    """
    Reads curated universe YAML files and builds a compact mapping:
    { instrument_id: { "ticker": str|None, "name": str|None } }.

    Precedence: `signals/config/universe.yaml` is loaded first; later universe files
    do not overwrite already-seen instrument IDs.
    """
    try:
        import yaml  # already used elsewhere in the codebase
    except Exception as e:
        logger.warning("universe.yaml load failed (yaml missing): %s", e)
        return {}

    try:
        signals_dir = Path(__file__).resolve().parent.parent
        config_dir = signals_dir / "config"
        paths = [
            config_dir / "universe.yaml",
            config_dir / "universe" / "sp500.yaml",
            config_dir / "universe" / "european_equities.yaml",
            config_dir / "universe" / "etfs.yaml",
        ]

        def _extract_instruments(data: Any) -> list:
            if isinstance(data, dict):
                return data.get("instruments", []) or []
            if isinstance(data, list):
                return data
            return []

        out: dict[str, dict[str, Optional[str]]] = {}
        for path in paths:
            if not path.exists():
                continue
            with open(path, "r") as f:
                data = yaml.safe_load(f) or {}

            instruments = _extract_instruments(data)
            for inv in instruments:
                if not isinstance(inv, dict):
                    continue
                iid = inv.get("id")
                if not iid:
                    continue
                iid = str(iid)
                # Later universe files must not overwrite earlier ones.
                if iid in out:
                    continue
                out[iid] = {
                    "ticker": inv.get("yfinance_ticker") or None,
                    "name": inv.get("name") or None,
                }

        return out
    except Exception as e:
        logger.warning("universe.yaml load failed: %s", e)
        return {}


_INSTRUMENTS: dict = _load_instrument_config()


def _get_instrument_mapping(instrument_id: str) -> Optional[dict]:
    return _INSTRUMENTS.get(instrument_id)


def _get_mapping(instrument_id: str) -> dict | None:
    """
    Returns { "ticker": str, "name": str } or None.
    Checks _INSTRUMENTS dict first (fast), falls back to DB.
    """
    mapping = _INSTRUMENTS.get(instrument_id)
    if mapping:
        return mapping

    # DB fallback for lazily-resolved instruments
    try:
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    SELECT yfinance_ticker, name
                    FROM instruments
                    WHERE id = %s AND is_active = TRUE
                      AND yfinance_ticker IS NOT NULL
                    """,
                    (instrument_id,),
                )
                row = cur.fetchone()
        if row:
            result = {"ticker": row[0], "name": row[1]}
            # Cache in _INSTRUMENTS for this session
            _INSTRUMENTS[instrument_id] = result
            return result
    except Exception:
        pass
    return None


def _fetch_from_db(instrument_id: str, from_date: str, to_date: str, db_conn) -> Optional[dict]:
    """
    Query market_data for rows matching series_id and date range.
    Existing schema uses columns: date, series_id, value (close value).
    """
    if db_conn is None:
        return None
    cur = db_conn.cursor()
    try:
        cur.execute(
            """
            SELECT date, value
            FROM market_data
            WHERE series_id = %s AND date >= %s AND date <= %s
            ORDER BY date ASC
            """,
            (instrument_id, _parse_date(from_date), _parse_date(to_date)),
        )
        rows = cur.fetchall()
        if not rows:
            return None
        dates = []
        values = []
        for d, v in rows:
            if d is None:
                continue
            dates.append(d.isoformat() if hasattr(d, "isoformat") else str(d)[:10])
            try:
                values.append(float(v) if v is not None else float("nan"))
            except Exception:
                values.append(float("nan"))
        if not dates:
            return None
        return {"dates": dates, "values": values}
    finally:
        cur.close()


def _find_missing_date_ranges(db_dates: List[str], from_date: str, to_date: str) -> List[Tuple[str, str]]:
    """
    Identify missing weekday date ranges between from_date and to_date inclusive.
    Weekends are ignored (not treated as gaps).
    """
    if not db_dates:
        return [(from_date, to_date)]
    have = set()
    for d in db_dates:
        try:
            have.add(_parse_date(d))
        except Exception:
            continue
    start = _parse_date(from_date)
    end = _parse_date(to_date)
    gaps: List[Tuple[date, date]] = []
    cur_start: Optional[date] = None
    cur_end: Optional[date] = None

    d = start
    while d <= end:
        is_weekday = d.weekday() < 5
        missing = is_weekday and d not in have
        if missing:
            if cur_start is None:
                cur_start = d
                cur_end = d
            else:
                cur_end = d
        else:
            if cur_start is not None and cur_end is not None:
                gaps.append((cur_start, cur_end))
                cur_start = None
                cur_end = None
        d += timedelta(days=1)
    if cur_start is not None and cur_end is not None:
        gaps.append((cur_start, cur_end))

    return [(_date_str(a), _date_str(b)) for (a, b) in gaps]


def _fetch_from_yfinance(yf_ticker: str, instrument_id: str, name: str, from_date: str, to_date: str) -> dict:
    """
    Direct yfinance fetch (mirrors signals/ingestion/yfinance_adapter.py call signature).
    Returns {dates, values} or {error, detail}.
    """
    yf_ticker = (yf_ticker or "").strip()
    if not yf_ticker:
        return {"error": "no_ticker"}
    try:
        obj = yf.Ticker(yf_ticker)
        hist = obj.history(start=from_date, end=to_date, auto_adjust=True)
    except Exception as e:
        return {"error": "fetch_failed", "detail": str(e)}

    if hist is None or getattr(hist, "empty", False):
        return {"error": "no_data"}

    close_col = "Close" if "Close" in hist.columns else ("Adj Close" if "Adj Close" in hist.columns else None)
    if close_col is None:
        return {"error": "no_close_column"}

    try:
        hist = hist.sort_index()
        dates = [dt.strftime("%Y-%m-%d") for dt in hist.index]
        values = []
        for v in hist[close_col].tolist():
            try:
                values.append(float(v) if v is not None else float("nan"))
            except Exception:
                values.append(float("nan"))
        return {"dates": dates, "values": values}
    except Exception as e:
        return {"error": "parse_failed", "detail": str(e)}


def _merge_series(db_result: Optional[dict], yf_result: Optional[dict]) -> dict:
    """
    Merge two {dates, values} series.
    DB takes precedence for overlapping dates.
    """
    out: Dict[str, float] = {}
    if yf_result and "dates" in yf_result and "values" in yf_result:
        for d, v in zip(yf_result["dates"], yf_result["values"]):
            out[str(d)[:10]] = float(v) if v is not None else float("nan")
    if db_result and "dates" in db_result and "values" in db_result:
        for d, v in zip(db_result["dates"], db_result["values"]):
            out[str(d)[:10]] = float(v) if v is not None else float("nan")
    dates_sorted = sorted(out.keys())
    values_sorted = [out[d] for d in dates_sorted]
    return {"dates": dates_sorted, "values": values_sorted}


def _compute_data_quality(dates: List[str], values: List[float], from_date: str, to_date: str, source: str) -> dict:
    total_points = len(values)
    valid_points = 0
    for v in values:
        try:
            fv = float(v)
            if not math.isnan(fv):
                valid_points += 1
        except Exception:
            continue
    completeness_pct = round((valid_points / total_points) * 100, 1) if total_points else 0.0

    start = _parse_date(from_date)
    end = _parse_date(to_date)
    expected_points = 0
    d = start
    while d <= end:
        if d.weekday() < 5:
            expected_points += 1
        d += timedelta(days=1)
    coverage_pct = round((total_points / expected_points) * 100, 1) if expected_points else 0.0

    return {
        "completeness_pct": completeness_pct,
        "total_points": total_points,
        "valid_points": valid_points,
        "expected_points": expected_points,
        "coverage_pct": coverage_pct,
        "source": source,
    }


_cache: dict = {}


def _cache_key(instrument_id: str, from_date: str, to_date: str) -> str:
    return f"{instrument_id}|{from_date}|{to_date}"


def _is_cache_valid(entry: dict) -> bool:
    return entry.get("cached_on") == date.today()


def get_price_series(instrument_id: str, from_date: str, to_date: str, db_conn) -> dict:
    # 1. Cache
    key = _cache_key(instrument_id, from_date, to_date)
    if key in _cache and _is_cache_valid(_cache[key]):
        return _cache[key]["result"]

    # 2. Mapping
    mapping = _get_mapping(instrument_id)
    if not mapping:
        return {"id": instrument_id, "error": "unknown_instrument"}

    # 3. Ticker
    yf_ticker = (mapping.get("ticker") or "").strip()
    if not yf_ticker:
        return {"id": instrument_id, "error": "no_ticker_mapping"}

    name = mapping.get("name") or instrument_id

    # 4-5. OpenBB stub (future)
    openbb_result = None
    try:
        from openbb import obb  # noqa: F401
        openbb_result = None  # placeholder
    except Exception:
        openbb_result = None

    if openbb_result is not None:
        # Not implemented yet — keep for future parity
        result = openbb_result
        return result

    # 6. DB query (best-effort)
    db_result = _fetch_from_db(instrument_id, from_date, to_date, db_conn)

    # 7-9. Gap fill if DB partial
    if db_result is not None:
        gaps = _find_missing_date_ranges(db_result.get("dates", []), from_date, to_date)
        yf_pieces = []
        for g_from, g_to in gaps:
            yf_piece = _fetch_from_yfinance(yf_ticker, instrument_id, name, g_from, g_to)
            if "error" in yf_piece:
                continue
            yf_pieces.append(yf_piece)
        yf_merged = None
        if yf_pieces:
            yf_merged = {"dates": [], "values": []}
            by_date: Dict[str, float] = {}
            for part in yf_pieces:
                for d, v in zip(part.get("dates", []), part.get("values", [])):
                    by_date[str(d)[:10]] = float(v) if v is not None else float("nan")
            dates_sorted = sorted(by_date.keys())
            yf_merged["dates"] = dates_sorted
            yf_merged["values"] = [by_date[d] for d in dates_sorted]

        merged = _merge_series(db_result, yf_merged)
        source = "db+yfinance" if (yf_merged and yf_merged.get("dates")) else "db"
        dq = _compute_data_quality(merged["dates"], merged["values"], from_date, to_date, source)
        if dq["completeness_pct"] < 50:
            return {"id": instrument_id, "error": "insufficient_data", "detail": f"Only {dq['completeness_pct']}% of points are valid"}
        result = {
            "id": instrument_id,
            "name": name,
            "dates": merged["dates"],
            "values": merged["values"],
            "dataQuality": dq,
        }
        _cache[key] = {"result": result, "cached_on": date.today()}
        return result

    # 10. Full yfinance fetch if no DB rows
    yf_full = _fetch_from_yfinance(yf_ticker, instrument_id, name, from_date, to_date)
    if "error" in yf_full:
        return {"id": instrument_id, "error": yf_full.get("error") or "fetch_failed", "detail": yf_full.get("detail")}

    dq = _compute_data_quality(yf_full["dates"], yf_full["values"], from_date, to_date, "yfinance_direct")
    if dq["completeness_pct"] < 50:
        return {"id": instrument_id, "error": "insufficient_data", "detail": f"Only {dq['completeness_pct']}% of points are valid"}

    result = {
        "id": instrument_id,
        "name": name,
        "dates": yf_full["dates"],
        "values": yf_full["values"],
        "dataQuality": dq,
    }
    _cache[key] = {"result": result, "cached_on": date.today()}
    return result

