"""
ECB Statistical Data Warehouse adapter. Fetches numeric series and writes to market_data only.
"""
import logging
from datetime import date, timedelta
from typing import Any, List

import requests

logger = logging.getLogger("signals.ingestion")

ECB_DATA_BASE = "https://data-api.ecb.europa.eu/service/data"


def fetch_ecb_series(series_key: str, start: date, end: date) -> List[dict]:
    """Fetch series from ECB SDW. Returns list of {date, value}."""
    # Series key format: IRS.M.DE.L.L40.CI.0.EUR.2Y.NX -> dataflow IRS, key M.DE...
    parts = series_key.split(".", 1)
    dataflow = parts[0] if len(parts) > 1 else "IRS"
    key = parts[1] if len(parts) > 1 else series_key
    url = f"{ECB_DATA_BASE}/{dataflow}/{key}"
    params = {
        "startPeriod": start.isoformat(),
        "endPeriod": end.isoformat(),
        "format": "jsondata",
        "detail": "dataonly",
    }
    resp = requests.get(url, params=params, timeout=30)
    resp.raise_for_status()
    data = resp.json()
    out = []
    try:
        for ds in data.get("dataSets", []):
            for s in ds.get("series", {}).values():
                for o in s.get("observations", []):
                    # Observation format varies; often [period, value] or dict
                    if isinstance(o, list) and len(o) >= 2:
                        period = o[0]
                        val = o[1]
                        if isinstance(period, dict):
                            period = period.get("name", "")
                        try:
                            v = float(val) if val is not None else None
                            if v is not None:
                                out.append({"date": str(period)[:10], "value": v})
                        except (TypeError, ValueError):
                            pass
        # Alternative: structure with dimensions and observations
        if not out and "structure" in data and "dataSets" in data:
            for ds in data["dataSets"]:
                series_list = ds.get("series", [])
                if isinstance(series_list, dict):
                    series_list = series_list.values()
                for s in series_list:
                    obs = s.get("observations", [])
                    dims = s.get("dimensions", [])
                    for i, ob in enumerate(obs):
                        if isinstance(ob, list) and len(ob) >= 1:
                            try:
                                v = float(ob[0])
                                # Period from dimensions or index
                                period = dims[0][i] if dims and i < len(dims[0]) else None
                                if period:
                                    out.append({"date": str(period)[:10], "value": v})
                            except (TypeError, ValueError, IndexError):
                                pass
    except Exception as e:
        logger.warning("ECB parse %s: %s", series_key, e)
    return out


def run_ecb_sdw(conn, source_id: str, config: dict) -> int:
    """
    Fetch each series in config['series'], insert into market_data.
    Returns number of market_data rows inserted. Never raises.
    """
    series_list = config.get("series") or []
    if not series_list:
        return 0

    end = date.today()
    start = end - timedelta(days=365)
    total_inserted = 0

    for series_id in series_list:
        try:
            rows = fetch_ecb_series(series_id, start, end)
        except Exception as e:
            logger.warning("ECB SDW fetch failed for %s: %s", series_id, e)
            try:
                cur = conn.cursor()
                cur.execute(
                    "INSERT INTO pipeline_errors (source_id, error_type, error_msg) VALUES (%s, %s, %s)",
                    (source_id, "fetch_error", f"series {series_id}: {str(e)[:500]}"),
                )
                cur.close()
            except Exception:
                pass
            continue

        if not rows:
            continue

        rows.sort(key=lambda x: x["date"])
        prev_value = None
        cur = conn.cursor()
        try:
            for r in rows:
                dt = r["date"]
                val = r["value"]
                daily_chg = (val - prev_value) if prev_value is not None else None
                pct_chg = (100.0 * (val - prev_value) / prev_value) if prev_value and prev_value != 0 else None
                cur.execute(
                    """
                    INSERT INTO market_data (date, series_id, value, daily_chg, pct_chg, source)
                    SELECT %s, %s, %s, %s, %s, 'ecb_sdw'
                    WHERE NOT EXISTS (SELECT 1 FROM market_data WHERE date = %s AND series_id = %s)
                    """,
                    (dt, series_id, val, daily_chg, pct_chg, dt, series_id),
                )
                if cur.rowcount:
                    total_inserted += 1
                prev_value = val
        finally:
            cur.close()

    return total_inserted
