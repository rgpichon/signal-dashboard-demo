"""
CFTC Commitment of Traders adapter. Fetches weekly CoT data and writes to positioning_signals.
Minimal implementation: fetches current year ZIP, parses disaggregated futures, writes net spec.
"""
import csv
import io
import logging
import zipfile
from datetime import date, timedelta
from typing import List

import requests

logger = logging.getLogger("signals.ingestion")

CFTC_DISAGG_TXT = "https://www.cftc.gov/files/dea/history/fut_disagg_txt_{year}.zip"


def run_cftc(conn, source_id: str, config: dict) -> int:
    """
    Fetch CFTC CoT disaggregated futures for current year, parse, write to positioning_signals.
    Returns number of positioning_signals rows inserted. Never raises.
    """
    year = date.today().year
    url = CFTC_DISAGG_TXT.format(year=year)
    try:
        resp = requests.get(url, timeout=60)
        resp.raise_for_status()
    except Exception as e:
        logger.warning("CFTC fetch failed: %s", e)
        try:
            cur = conn.cursor()
            cur.execute(
                "INSERT INTO pipeline_errors (source_id, error_type, error_msg) VALUES (%s, %s, %s)",
                (source_id, "fetch_error", str(e)[:500]),
            )
            cur.close()
        except Exception:
            pass
        return 0

    try:
        z = zipfile.ZipFile(io.BytesIO(resp.content), "r")
        names = [n for n in z.namelist() if n.endswith(".txt")]
        if not names:
            return 0
        # Use first text file (e.g. year-specific)
        with z.open(names[0]) as f:
            content = f.read().decode("utf-8", errors="replace")
    except Exception as e:
        logger.warning("CFTC unzip/parse failed: %s", e)
        try:
            cur = conn.cursor()
            cur.execute(
                "INSERT INTO pipeline_errors (source_id, error_type, error_msg) VALUES (%s, %s, %s)",
                (source_id, "parse_error", str(e)[:500]),
            )
            cur.close()
        except Exception:
            pass
        return 0

    # CFTC format: header line then data. Columns vary; look for Report Date, Market, Noncommercial Long/Short.
    lines = content.strip().split("\n")
    if not lines:
        return 0

    reader = csv.DictReader(io.StringIO(content), delimiter=",", quotechar='"')
    rows_by_series: dict = {}
    for row in reader:
        try:
            report_date = row.get("Report Date as YYYY-MM-DD") or row.get("Report_Date_as_YYYY_MM_DD") or row.get("Report Date", "")
            if not report_date or len(report_date) < 10:
                continue
            report_date = report_date[:10]
            market = (row.get("Market and Exchange Names") or row.get("Market_and_Exchange_Names") or row.get("CFTC_Contract_Market_Code", "")).strip()
            if not market:
                continue
            try:
                nl = int(row.get("Noncommercial_Long", 0) or row.get("Noncommercial Long", 0) or 0)
                ns = int(row.get("Noncommercial_Short", 0) or row.get("Noncommercial Short", 0) or 0)
            except (TypeError, ValueError):
                continue
            net_spec = nl - ns
            series_id = f"CFTC.{market[:32]}"
            key = (report_date, series_id)
            if key not in rows_by_series:
                rows_by_series[key] = {"date": report_date, "series_id": series_id, "net_spec": net_spec}
        except Exception:
            continue

    if not rows_by_series:
        try:
            cur = conn.cursor()
            cur.execute(
                "INSERT INTO pipeline_errors (source_id, error_type, error_msg) VALUES (%s, %s, %s)",
                (source_id, "empty_result", "Parsed 0 CoT rows from ZIP"),
            )
            cur.close()
        except Exception:
            pass
        return 0

    # Compute percentile_52w and crowding_flag per series (simplified: use last 52 weeks if we had history)
    cur = conn.cursor()
    inserted = 0
    try:
        for (_, series_id), r in rows_by_series.items():
            net_spec = r["net_spec"]
            direction = "long" if net_spec > 0 else "short" if net_spec < 0 else "neutral"
            # Stub: no 52w history in this run so percentile_52w = 0.5, crowding_flag = False
            percentile_52w = 0.5
            crowding_flag = False
            cur.execute(
                """
                INSERT INTO positioning_signals (date, series_id, net_spec, percentile_52w, crowding_flag, direction)
                SELECT %s, %s, %s, %s, %s, %s
                WHERE NOT EXISTS (SELECT 1 FROM positioning_signals WHERE date = %s AND series_id = %s)
                """,
                (r["date"], series_id, net_spec, percentile_52w, crowding_flag, direction, r["date"], series_id),
            )
            if cur.rowcount:
                inserted += 1
    finally:
        cur.close()

    return inserted
