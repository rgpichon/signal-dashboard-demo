"""
Canonical series_id mapping for FRED data.
All ingestion (FRED, computed) writes canonical ids into market_data.series_id.
yfinance uses instrument.id as series_id — no mapping needed.
"""
from typing import Dict

FRED_TO_CANONICAL: Dict[str, str] = {
    "DGS2": "RATES.US2Y",
    "DGS3MO": "RATES.US3M",
    "DGS5": "RATES.US5Y",
    "DGS10": "RATES.US10Y",
    "DGS30": "RATES.US30Y",
    "T10Y2Y": "RATES.2S10S",
    "DFII10": "RATES.REAL10Y",
    "DFII5": "RATES.REAL5Y",
    "T10YIE": "RATES.BREAKEVEN",
    "T5YIE": "RATES.BREAKEVEN5Y",
    "BAMLC0A0CM": "CREDIT.IG_OAS",
    "BAMLH0A0HYM2": "CREDIT.HY_OAS",
    "CPIAUCSL": "MACRO.CPI",
    "UNRATE": "MACRO.UNRATE",
    "INDPRO": "MACRO.INDPRO",
    "RSAFS": "MACRO.RETAIL",
    "UMCSENT": "MACRO.UMCSENT",
    "MANEMP": "MACRO.ISM_MFG",
}


def to_canonical(raw_id: str) -> str:
    """Return canonical series_id for a FRED raw id; otherwise return raw_id unchanged."""
    return FRED_TO_CANONICAL.get(raw_id, raw_id)
