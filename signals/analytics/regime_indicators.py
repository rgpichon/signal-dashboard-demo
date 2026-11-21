"""
Compute 7 regime indicators from market_data and store snapshot in regime_snapshots.
States: ELEVATED (top 25%), NORMAL (middle 50%), SUPPRESSED (bottom 25%), or INSUFFICIENT_DATA.
"""
import logging
from datetime import date, timedelta
from typing import Optional, Tuple

logger = logging.getLogger("signals.analytics")

REGIME_SERIES = {
    "growth_pulse": ("ratio", ["CM.COPPER", "CM.GOLD"]),
    "credit_stress": ("vs_90d_mean", ["EQ.HYG"]),
    "real_yield": ("series", ["DFII10"]),
    "dollar_strength": ("series", ["FX.DXY"]),
    "rates_vol": ("series", ["EQ.MOVE"]),
    "equity_vol": ("series", ["EQ.VIX"]),
    "curve_shape": ("series", ["T10Y2Y"]),
}
# Prefer 30 for stable percentiles; use 5 when history is limited so we get a fingerprint
MIN_DAYS_FOR_STATE = 5
ROLLING_DAYS = 90
LONG_LOOKBACK_DAYS = 756 + 30  # 786


def _create_regime_snapshots_table(conn) -> None:
    cur = conn.cursor()
    try:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS regime_snapshots (
                id              SERIAL PRIMARY KEY,
                date            DATE UNIQUE,
                growth_pulse    VARCHAR(20),
                credit_stress   VARCHAR(20),
                real_yield      VARCHAR(20),
                dollar_strength VARCHAR(20),
                rates_vol       VARCHAR(20),
                equity_vol      VARCHAR(20),
                curve_shape     VARCHAR(20),
                fingerprint     TEXT,
                computed_at     TIMESTAMPTZ DEFAULT NOW()
            )
        """)
        conn.commit()
    finally:
        cur.close()


def _get_series_values(conn, series_id: str, as_of: date, lookback_days: int) -> list:
    """Return list of (date, value) for series_id in [as_of - lookback_days, as_of], sorted by date."""
    cur = conn.cursor()
    try:
        start = as_of - timedelta(days=lookback_days)
        cur.execute("""
            SELECT date, value FROM market_data
            WHERE series_id = %s AND value IS NOT NULL AND date >= %s AND date <= %s
            ORDER BY date
        """, (series_id, start, as_of))
        return cur.fetchall()
    finally:
        cur.close()


def _percentile_state(percentile_25: float, percentile_50: float, percentile_75: float, current: float) -> str:
    if current <= percentile_25:
        return "SUPPRESSED"
    if current >= percentile_75:
        return "ELEVATED"
    return "NORMAL"


def _compute_percentile_rank(
    current_value: float,
    historical_values: list,
) -> int:
    """
    Returns 0-100 integer percentile rank of current_value
    within historical_values.
    Lower values = lower percentile.
    """
    if not historical_values or len(historical_values) < 2:
        return 50
    below = sum(1 for v in historical_values if float(v) < float(current_value))
    return int(round(below / len(historical_values) * 100))


def _compute_indicator_state(
    conn, key: str, config: tuple, as_of: date
) -> Tuple[str, int, int]:
    kind, series_list = config
    if kind == "series":
        series_id = series_list[0]
        rows = _get_series_values(conn, series_id, as_of, ROLLING_DAYS + 30)
        if len(rows) < MIN_DAYS_FOR_STATE:
            return ("INSUFFICIENT_DATA", 50, 50)
        vals = [float(r[1]) for r in rows]
        try:
            current = next(r[1] for r in rows if r[0] == as_of)
        except StopIteration:
            current = vals[-1] if vals else None
        if current is None:
            return ("INSUFFICIENT_DATA", 50, 50)
        vals_sorted = sorted(vals)
        n = len(vals_sorted)
        p25 = vals_sorted[int(0.25 * n)] if n else 0
        p50 = vals_sorted[int(0.50 * n)] if n else 0
        p75 = vals_sorted[int(0.75 * n)] if n else 0
        state = _percentile_state(p25, p50, p75, float(current))
        pct_90d = _compute_percentile_rank(float(current), vals)
        rows_756 = _get_series_values(conn, series_id, as_of, LONG_LOOKBACK_DAYS)
        vals_756 = [float(r[1]) for r in rows_756]
        if len(vals_756) >= 5:
            pct_756d = _compute_percentile_rank(float(current), vals_756)
        else:
            pct_756d = pct_90d
        return (state, pct_90d, pct_756d)

    if kind == "vs_90d_mean":
        series_id = series_list[0]
        rows = _get_series_values(conn, series_id, as_of, ROLLING_DAYS + 30)
        if len(rows) < MIN_DAYS_FOR_STATE:
            return ("INSUFFICIENT_DATA", 50, 50)
        vals = [float(r[1]) for r in rows]
        try:
            current = next(r[1] for r in rows if r[0] == as_of)
        except StopIteration:
            current = vals[-1]
        mean_90 = sum(vals[-90:]) / min(90, len(vals))
        diff = float(current) - mean_90
        all_diffs = [
            v - (sum(vals[max(0, i - 89): i + 1]) / min(90, i + 1))
            for i, v in enumerate(vals)
        ]
        all_diffs_sorted = sorted(all_diffs)
        n = len(all_diffs_sorted)
        if n < MIN_DAYS_FOR_STATE:
            return ("INSUFFICIENT_DATA", 50, 50)
        p25 = all_diffs_sorted[int(0.25 * n)]
        p75 = all_diffs_sorted[int(0.75 * n)]
        if diff <= p25:
            state = "SUPPRESSED"
        elif diff >= p75:
            state = "ELEVATED"
        else:
            state = "NORMAL"
        pct_90d = _compute_percentile_rank(diff, all_diffs)
        rows_756 = _get_series_values(conn, series_id, as_of, LONG_LOOKBACK_DAYS)
        vals_756 = [float(r[1]) for r in rows_756]
        if len(vals_756) >= MIN_DAYS_FOR_STATE:
            all_diffs_756 = [
                v
                - (
                    sum(vals_756[max(0, i - 89): i + 1])
                    / min(90, i + 1)
                )
                for i, v in enumerate(vals_756)
            ]
            if len(all_diffs_756) >= 5:
                pct_756d = _compute_percentile_rank(diff, all_diffs_756)
            else:
                pct_756d = pct_90d
        else:
            pct_756d = pct_90d
        return (state, pct_90d, pct_756d)

    if kind == "ratio":
        a_id, b_id = series_list[0], series_list[1]
        rows_a = _get_series_values(conn, a_id, as_of, ROLLING_DAYS + 30)
        rows_b = _get_series_values(conn, b_id, as_of, ROLLING_DAYS + 30)
        if len(rows_a) < MIN_DAYS_FOR_STATE or len(rows_b) < MIN_DAYS_FOR_STATE:
            return ("INSUFFICIENT_DATA", 50, 50)
        by_date_a = {r[0]: float(r[1]) for r in rows_a}
        by_date_b = {r[0]: float(r[1]) for r in rows_b}
        common_dates = sorted(set(by_date_a) & set(by_date_b))
        if len(common_dates) < MIN_DAYS_FOR_STATE:
            return ("INSUFFICIENT_DATA", 50, 50)
        ratios = []
        for d in common_dates:
            b = by_date_b[d]
            if b and b != 0:
                ratios.append(by_date_a[d] / b)
        if len(ratios) < MIN_DAYS_FOR_STATE:
            return ("INSUFFICIENT_DATA", 50, 50)
        try:
            current = by_date_a[as_of] / by_date_b[as_of] if by_date_b.get(as_of) else None
        except Exception:
            current = ratios[-1] if ratios else None
        if current is None:
            return ("INSUFFICIENT_DATA", 50, 50)
        ratios_sorted = sorted(ratios)
        n = len(ratios_sorted)
        p25 = ratios_sorted[int(0.25 * n)]
        p50 = ratios_sorted[int(0.50 * n)]
        p75 = ratios_sorted[int(0.75 * n)]
        state = _percentile_state(p25, p50, p75, float(current))
        pct_90d = _compute_percentile_rank(float(current), ratios)
        rows_a_756 = _get_series_values(conn, a_id, as_of, LONG_LOOKBACK_DAYS)
        rows_b_756 = _get_series_values(conn, b_id, as_of, LONG_LOOKBACK_DAYS)
        by_date_a756 = {r[0]: float(r[1]) for r in rows_a_756}
        by_date_b756 = {r[0]: float(r[1]) for r in rows_b_756}
        common_dates_756 = sorted(set(by_date_a756) & set(by_date_b756))
        ratios_756 = []
        for d in common_dates_756:
            b = by_date_b756[d]
            if b and b != 0:
                ratios_756.append(by_date_a756[d] / b)
        if len(ratios_756) >= 5:
            pct_756d = _compute_percentile_rank(float(current), ratios_756)
        else:
            pct_756d = pct_90d
        return (state, pct_90d, pct_756d)

    return ("INSUFFICIENT_DATA", 50, 50)


def run_regime_indicators(conn, as_of: Optional[date] = None) -> int:
    """
    Compute all 7 regime indicators and upsert one row into regime_snapshots for as_of (default today).
    Returns 1 if row inserted/updated, 0 otherwise.
    """
    as_of = as_of or date.today()
    _create_regime_snapshots_table(conn)

    states = {}
    pct_90d_vals = {}
    pct_756d_vals = {}
    for key, config in REGIME_SERIES.items():
        state, p90, p756 = _compute_indicator_state(conn, key, config, as_of)
        states[key] = state
        pct_90d_vals[key] = p90
        pct_756d_vals[key] = p756

    fingerprint = "-".join(
        states[k]
        for k in [
            "growth_pulse",
            "credit_stress",
            "real_yield",
            "dollar_strength",
            "rates_vol",
            "equity_vol",
            "curve_shape",
        ]
    )
    logger.info("Regime snapshot: [%s]", fingerprint)

    insert_cols = (
        "date, growth_pulse, credit_stress, real_yield, dollar_strength, "
        "rates_vol, equity_vol, curve_shape, fingerprint, "
        "growth_pulse_pct_90d, growth_pulse_pct_756d, "
        "credit_stress_pct_90d, credit_stress_pct_756d, "
        "real_yield_pct_90d, real_yield_pct_756d, "
        "dollar_strength_pct_90d, dollar_strength_pct_756d, "
        "rates_vol_pct_90d, rates_vol_pct_756d, "
        "equity_vol_pct_90d, equity_vol_pct_756d, "
        "curve_shape_pct_90d, curve_shape_pct_756d"
    )
    placeholders = ", ".join(["%s"] * 23)
    update_assignments = ", ".join(
        [
            "growth_pulse = EXCLUDED.growth_pulse",
            "credit_stress = EXCLUDED.credit_stress",
            "real_yield = EXCLUDED.real_yield",
            "dollar_strength = EXCLUDED.dollar_strength",
            "rates_vol = EXCLUDED.rates_vol",
            "equity_vol = EXCLUDED.equity_vol",
            "curve_shape = EXCLUDED.curve_shape",
            "fingerprint = EXCLUDED.fingerprint",
            "growth_pulse_pct_90d = EXCLUDED.growth_pulse_pct_90d",
            "growth_pulse_pct_756d = EXCLUDED.growth_pulse_pct_756d",
            "credit_stress_pct_90d = EXCLUDED.credit_stress_pct_90d",
            "credit_stress_pct_756d = EXCLUDED.credit_stress_pct_756d",
            "real_yield_pct_90d = EXCLUDED.real_yield_pct_90d",
            "real_yield_pct_756d = EXCLUDED.real_yield_pct_756d",
            "dollar_strength_pct_90d = EXCLUDED.dollar_strength_pct_90d",
            "dollar_strength_pct_756d = EXCLUDED.dollar_strength_pct_756d",
            "rates_vol_pct_90d = EXCLUDED.rates_vol_pct_90d",
            "rates_vol_pct_756d = EXCLUDED.rates_vol_pct_756d",
            "equity_vol_pct_90d = EXCLUDED.equity_vol_pct_90d",
            "equity_vol_pct_756d = EXCLUDED.equity_vol_pct_756d",
            "curve_shape_pct_90d = EXCLUDED.curve_shape_pct_90d",
            "curve_shape_pct_756d = EXCLUDED.curve_shape_pct_756d",
            "computed_at = NOW()",
        ]
    )

    values_tuple = (
        as_of,
        states["growth_pulse"],
        states["credit_stress"],
        states["real_yield"],
        states["dollar_strength"],
        states["rates_vol"],
        states["equity_vol"],
        states["curve_shape"],
        fingerprint,
        pct_90d_vals["growth_pulse"],
        pct_756d_vals["growth_pulse"],
        pct_90d_vals["credit_stress"],
        pct_756d_vals["credit_stress"],
        pct_90d_vals["real_yield"],
        pct_756d_vals["real_yield"],
        pct_90d_vals["dollar_strength"],
        pct_756d_vals["dollar_strength"],
        pct_90d_vals["rates_vol"],
        pct_756d_vals["rates_vol"],
        pct_90d_vals["equity_vol"],
        pct_756d_vals["equity_vol"],
        pct_90d_vals["curve_shape"],
        pct_756d_vals["curve_shape"],
    )

    cur = conn.cursor()
    try:
        cur.execute(
            f"""
            INSERT INTO regime_snapshots (
                {insert_cols}
            ) VALUES ({placeholders})
            ON CONFLICT (date) DO UPDATE SET
                {update_assignments}
            """,
            values_tuple,
        )
        conn.commit()
        return 1
    except Exception as e:
        conn.rollback()
        logger.warning("Regime snapshot upsert failed: %s", e)
        return 0
    finally:
        cur.close()
