"""
One-time (or idempotent) seed of the asset universe from config/universe.yaml.
Run on first deploy. Do not hardcode instruments elsewhere.
"""
import logging
import os
from pathlib import Path

import yaml

# Allow running from project root or from signals/
SCRIPT_DIR = Path(__file__).resolve().parent
CONFIG_DIR = SCRIPT_DIR.parent / "config"
CONFIG_PATH = CONFIG_DIR / "universe.yaml"
# Additional universe files (Spec 8 U2); same upsert logic as main universe.yaml
UNIVERSE_EXTRA_PATHS = [
    CONFIG_DIR / "universe" / "sp500.yaml",
    CONFIG_DIR / "universe" / "european_equities.yaml",
    CONFIG_DIR / "universe" / "etfs.yaml",
]

logger = logging.getLogger("signals.seed_universe")


def load_universe() -> list[dict]:
    """Load instrument definitions from main universe YAML and extra universe/*.yaml files."""
    path = os.environ.get("SIGNAL_CONFIG_UNIVERSE", str(CONFIG_PATH))
    with open(path, "r") as f:
        data = yaml.safe_load(f)
    instruments = list(data.get("instruments", []) or [])
    for extra_path in UNIVERSE_EXTRA_PATHS:
        if not extra_path.exists():
            continue
        with open(extra_path, "r") as f:
            extra = yaml.safe_load(f)
        instruments.extend(extra.get("instruments", []) or [])
    return instruments


def seed(conn, verbose: bool = False) -> int:
    """
    Upsert all instruments from universe.yaml into the instruments table.
    Returns number of instruments processed.
    """
    instruments = load_universe()
    if verbose:
        logger.info("Loaded %d top-level instrument entries from YAML", len(instruments))
    if not instruments:
        return 0

    cur = conn.cursor()
    processed = 0
    for idx, inv in enumerate(instruments):
        # Map YAML null/None to SQL NULL; empty list to PostgreSQL '{}'
        def pg_array(val):
            if val is None:
                return None
            if isinstance(val, list):
                return val
            return [val] if val else []

        if not isinstance(inv, dict):
            if verbose:
                logger.warning("SKIP index=%d: not a dict (type=%s)", idx, type(inv).__name__)
            continue
        id_ = inv.get("id")
        if not id_:
            if verbose:
                logger.warning("SKIP index=%d id=%r: missing or null/empty id", idx, id_)
            continue
        name = inv.get("name")
        asset_class = inv.get("asset_class")
        sub_type = inv.get("sub_type")
        geography = pg_array(inv.get("geography"))
        sectors = pg_array(inv.get("sectors"))
        themes = pg_array(inv.get("themes"))
        risk_profile = inv.get("risk_profile")
        liquidity = inv.get("liquidity")
        yfinance_ticker = inv.get("yfinance_ticker") or None
        fred_series_id = inv.get("fred_series_id") or None
        correlates_with = pg_array(inv.get("correlates_with"))
        thesis_role = pg_array(inv.get("thesis_role"))
        tradeable_via = pg_array(inv.get("tradeable_via"))
        # Spec 8 U1.2 extended columns (from universe/*.yaml or defaults)
        sector = inv.get("sector")
        country = inv.get("country") if inv.get("country") is not None else "US"
        market_cap = inv.get("market_cap")
        currency = inv.get("currency") if inv.get("currency") is not None else "USD"
        index_member = pg_array(inv.get("index_member"))
        is_active = inv.get("is_active") if "is_active" in inv else True

        try:
            cur.execute(
                """
                INSERT INTO instruments (
                    id, name, asset_class, sub_type, geography, sectors, themes,
                    risk_profile, liquidity, yfinance_ticker, fred_series_id,
                    correlates_with, thesis_role, tradeable_via,
                    sector, country, market_cap, currency, index_member, is_active
                ) VALUES (
                    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,
                    %s, %s, %s, %s, %s, %s
                )
                ON CONFLICT (id) DO UPDATE SET
                    name = EXCLUDED.name,
                    asset_class = EXCLUDED.asset_class,
                    sub_type = EXCLUDED.sub_type,
                    geography = EXCLUDED.geography,
                    sectors = EXCLUDED.sectors,
                    themes = EXCLUDED.themes,
                    risk_profile = EXCLUDED.risk_profile,
                    liquidity = EXCLUDED.liquidity,
                    yfinance_ticker = EXCLUDED.yfinance_ticker,
                    fred_series_id = EXCLUDED.fred_series_id,
                    correlates_with = EXCLUDED.correlates_with,
                    thesis_role = EXCLUDED.thesis_role,
                    tradeable_via = EXCLUDED.tradeable_via,
                    sector = EXCLUDED.sector,
                    country = EXCLUDED.country,
                    market_cap = EXCLUDED.market_cap,
                    currency = EXCLUDED.currency,
                    index_member = EXCLUDED.index_member,
                    is_active = EXCLUDED.is_active
                """,
                (
                    id_,
                    name,
                    asset_class,
                    sub_type,
                    geography,
                    sectors,
                    themes,
                    risk_profile,
                    liquidity,
                    yfinance_ticker,
                    fred_series_id,
                    correlates_with,
                    thesis_role,
                    tradeable_via,
                    sector,
                    country,
                    market_cap,
                    currency,
                    index_member,
                    is_active,
                ),
            )
            processed += 1
        except Exception as e:
            if verbose:
                logger.warning("SKIP index=%d id=%s: DB error: %s", idx, id_, e)
    cur.close()
    return processed


def main():
    import sys
    # Ensure project root (parent of signals/) is on path when run as script
    repo_root = SCRIPT_DIR.parent.parent
    if str(repo_root) not in sys.path:
        sys.path.insert(0, str(repo_root))
    from signals.db.connection import get_connection

    verbose = os.environ.get("SIGNAL_SEED_VERBOSE", "").lower() in ("1", "true", "yes")
    if verbose:
        logging.basicConfig(level=logging.INFO, format="%(levelname)s %(name)s: %(message)s")

    with get_connection() as conn:
        n = seed(conn, verbose=verbose)
    print(f"Seeded {n} instruments.")


if __name__ == "__main__":
    main()
