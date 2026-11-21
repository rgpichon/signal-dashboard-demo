"""
Thesis expansion engine.
Calls compute_impact for OLS-eligible series, static_graph for the rest.
Applies regime weighting. Returns structured flagged variable list.
"""
from __future__ import annotations

import logging
from datetime import datetime, timezone
from typing import Any

from signals.research.impact import compute_impact
from signals.thesis_engine import static_graph as static_graph_mod

logger = logging.getLogger("signals.thesis_engine")

OLS_MIN_OBS = 30
LAYER1_MAX = 8
LAYER2_MAX = 5
OLS_MIN_R2 = 0.08
OLS_MAX_PVAL = 0.15
# Inner-join alignment over all target columns drops too many dates; batch targets.
IMPACT_BATCH_SIZE = 12

_STRENGTH_SCORE = {"direct": 0.4, "indirect": 0.25, "speculative": 0.1}


def _compute_impact_merge(
    conn,
    base_series: str,
    target_series_list: list[str],
    shock_pct: float,
    days: int,
) -> dict[str, Any]:
    """Run compute_impact in batches; merge impacts (dedupe by series_id, keep higher R²)."""
    all_impacts: list[dict] = []
    any_ok = False
    for i in range(0, len(target_series_list), IMPACT_BATCH_SIZE):
        batch = target_series_list[i : i + IMPACT_BATCH_SIZE]
        if not batch:
            continue
        res = compute_impact(
            conn=conn,
            base_series=base_series,
            target_series_list=batch,
            shock_pct=shock_pct,
            days=days,
        )
        if res.get("error"):
            continue
        any_ok = True
        all_impacts.extend(res.get("impacts") or [])
    if not any_ok and target_series_list:
        return {
            "error": "insufficient_data",
            "impacts": [],
        }
    by_id: dict[str, dict] = {}
    for imp in all_impacts:
        sid = imp.get("series_id")
        if not sid:
            continue
        prev = by_id.get(sid)
        if prev is None or (imp.get("r_squared") or 0) > (prev.get("r_squared") or 0):
            by_id[sid] = imp
    return {
        "base": base_series,
        "shock_pct": shock_pct,
        "impacts": list(by_id.values()),
        "methodology": "batched OLS merge",
    }


def normalize_series_id(raw_id: str, eligible_series: list[str], conn) -> str | None:
    """
    Maps a potentially incomplete series_id (e.g. "CM." or "CM.BRENT")
    to the nearest match in eligible_series.
    Steps:
    1. If raw_id is an exact match in eligible_series, return it.
    2. If raw_id ends with ".", find all eligible series with that prefix,
       return the one with the most market_data rows (most liquid).
    3. If raw_id contains a partial name (e.g. "BRENT"),
       find eligible series containing that substring (case-insensitive).
    4. If no match, return None.
    """
    if not raw_id or not eligible_series:
        return None
    rid = raw_id.strip()
    if rid in eligible_series:
        return rid
    if rid.endswith("."):
        cands = [s for s in eligible_series if s.startswith(rid)]
        if not cands:
            return None
        return _pick_most_liquid(conn, cands)
    upper = rid.upper()
    if not upper:
        return None
    cands = [s for s in eligible_series if upper in s.upper()]
    if not cands:
        return None
    if len(cands) == 1:
        return cands[0]
    return _pick_most_liquid(conn, cands)


def _pick_most_liquid(conn, series_ids: list[str]) -> str:
    cur = conn.cursor()
    try:
        best_sid = series_ids[0]
        best_n = -1
        for sid in series_ids:
            cur.execute(
                "SELECT COUNT(*) FROM market_data WHERE series_id = %s",
                (sid,),
            )
            n = cur.fetchone()[0]
            if n > best_n:
                best_n = n
                best_sid = sid
        return best_sid
    finally:
        cur.close()


def get_ols_eligible_series(conn) -> list[str]:
    """Return all series_ids from market_data with >= OLS_MIN_OBS rows."""
    cur = conn.cursor()
    try:
        cur.execute(
            """
            SELECT series_id FROM market_data
            GROUP BY series_id HAVING COUNT(*) >= %s
            ORDER BY series_id
            """,
            (OLS_MIN_OBS,),
        )
        return [r[0] for r in cur.fetchall()]
    finally:
        cur.close()


def _ensure_regime_snapshot(conn, regime_snapshot: dict | None) -> dict:
    """
    If snapshot lacks *_pct_* keys (e.g. /api/regime/latest omits them),
    load the latest regime_snapshots row so expand uses percentiles.
    """
    snap = dict(regime_snapshot or {})
    if any("_pct_" in k for k in snap):
        return snap
    cur = conn.cursor()
    try:
        cur.execute(
            "SELECT * FROM regime_snapshots ORDER BY date DESC LIMIT 1"
        )
        row = cur.fetchone()
        if not row:
            return snap
        out: dict[str, Any] = {}
        for col, val in zip([d[0] for d in cur.description], row):
            if hasattr(val, "isoformat"):
                out[col] = val.isoformat()
            else:
                out[col] = val
        return out
    finally:
        cur.close()


def get_regime_percentiles(
    series_id: str,
    regime_snapshot: dict,
) -> tuple[int, int]:
    """
    Returns (pct_90d, pct_756d) for the regime indicator
    most relevant to this series_id prefix.
    Falls back to (50, 50) if columns not present in snapshot.
    """
    PREFIX_MAP = {
        "FX.": ("dollar_strength_pct_90d", "dollar_strength_pct_756d"),
        "RATES.": ("rates_vol_pct_90d", "rates_vol_pct_756d"),
        "EQ.": ("equity_vol_pct_90d", "equity_vol_pct_756d"),
        "CREDIT.": ("credit_stress_pct_90d", "credit_stress_pct_756d"),
        "CM.": ("growth_pulse_pct_90d", "growth_pulse_pct_756d"),
        "MACRO.": ("growth_pulse_pct_90d", "growth_pulse_pct_756d"),
    }
    for prefix, (k90, k756) in PREFIX_MAP.items():
        if series_id.startswith(prefix):
            p90 = regime_snapshot.get(k90)
            p756 = regime_snapshot.get(k756)
            return (
                p90 if p90 is not None else 50,
                p756 if p756 is not None else 50,
            )
    return (50, 50)


def regime_amplifies(series_id: str, regime_snapshot: dict) -> bool:
    """
    Returns True if the structural percentile (pct_756d)
    for this series' regime indicator is above 60.
    Uses discrete state as fallback if pct columns absent.
    """
    _, pct_756d = get_regime_percentiles(series_id, regime_snapshot)
    if pct_756d != 50:
        return pct_756d > 60

    PREFIX_STATE_MAP = {
        "FX.": ("dollar_strength", "ELEVATED"),
        "RATES.": ("rates_vol", "ELEVATED"),
        "EQ.": ("equity_vol", "ELEVATED"),
        "CREDIT.": ("credit_stress", "ELEVATED"),
        "CM.": ("growth_pulse", "SUPPRESSED"),
        "MACRO.": ("growth_pulse", "SUPPRESSED"),
    }
    for prefix, (key, target_state) in PREFIX_STATE_MAP.items():
        if series_id.startswith(prefix):
            return regime_snapshot.get(key) == target_state
    return False


def build_regime_note(series_id: str, regime_snapshot: dict) -> str | None:
    """
    Returns a plain-language note when regime context
    is meaningful (structural percentile > 70 or < 30).
    Returns None for neutral / no data.
    """
    pct_90d, pct_756d = get_regime_percentiles(series_id, regime_snapshot)

    PREFIX_LABEL_MAP = {
        "FX.": ("Dollar strength", "FX"),
        "RATES.": ("Rates volatility", "rates"),
        "EQ.": ("Equity volatility", "equity"),
        "CREDIT.": ("Credit stress", "credit"),
        "CM.": ("Growth pulse", "commodity"),
        "MACRO.": ("Growth pulse", "macro"),
    }
    for prefix, (label, asset_label) in PREFIX_LABEL_MAP.items():
        if series_id.startswith(prefix):
            if pct_756d > 70:
                return (
                    f"{label} at {pct_756d}th percentile "
                    f"(3yr) — this {asset_label} "
                    f"relationship is structurally amplified"
                )
            if pct_756d < 30:
                return (
                    f"{label} at {pct_756d}th percentile "
                    f"(3yr) — structurally suppressed "
                    f"environment for this {asset_label} "
                    f"relationship"
                )
            if pct_90d > 80:
                return (
                    f"{label} currently elevated "
                    f"({pct_90d}th percentile, 90d) — "
                    f"this {asset_label} relationship "
                    f"is tactically amplified"
                )
            return None
    return None


def score_variable(impact_row: dict, regime_snapshot: dict, layer: int) -> float:
    """
    Continuous importance score 0.0-1.0.

    base        = min(abs(predicted_move_pct) / 10, 1.0)
    r2_weight   = r_squared (0.0-1.0)
    layer_pen   = 0.7 if layer==2 else 1.0

    Regime boost uses dual-horizon percentiles:
      struct_boost  = 1.0 + (pct_756d / 100) * 0.30
      tactical_mod  = 1.0 + (pct_90d  / 100) * 0.15
      regime_boost  = struct_boost * tactical_mod
      Max ~1.55 at 99th percentile both horizons.

    Falls back to 1.0 regime_boost if both percentiles
    are 50 (neutral / no data).

    score = base * r2_weight * layer_pen * regime_boost
    return min(round(score, 4), 1.0)
    """
    predicted = impact_row.get("predicted_move_pct") or 0.0
    r2 = impact_row.get("r_squared") or 0.0
    layer_pen = 0.7 if layer == 2 else 1.0

    pct_90d, pct_756d = get_regime_percentiles(
        impact_row["series_id"], regime_snapshot
    )

    struct_boost = 1.0 + (pct_756d / 100) * 0.30
    tactical_mod = 1.0 + (pct_90d / 100) * 0.15
    regime_boost = struct_boost * tactical_mod
    if pct_90d == 50 and pct_756d == 50:
        regime_boost = 1.0

    base = min(abs(float(predicted)) / 10.0, 1.0)
    score = base * float(r2) * layer_pen * regime_boost
    return min(round(score, 4), 1.0)


def _completeness_pct(thesis_node: dict, flagged: list) -> int:
    addressed = thesis_node.get("addressed") or []
    if not addressed:
        return 0
    return int(len(addressed) / max(len(flagged) + len(addressed), 1) * 100)


def _static_amplifier(direction: str, shock_pct: float) -> bool:
    if direction == "positive":
        return shock_pct > 0
    if direction == "negative":
        return shock_pct < 0
    return shock_pct != 0


def _collect_static_relationships(focal: str) -> list[dict]:
    rels: list[dict] = []
    sg = static_graph_mod.STATIC_RELATIONSHIPS
    if focal in sg:
        return list(sg[focal])
    parts = focal.split(".", 1)
    prefix = parts[0] + "." if len(parts) >= 1 else focal
    seen_to: set[str] = set()
    for key, edges in sg.items():
        if key == focal or key.startswith(prefix):
            for e in edges:
                t = e.get("to")
                if t and t not in seen_to:
                    seen_to.add(t)
                    rels.append(e)
    return rels


def _flagged_dict_from_ols(
    imp: dict,
    regime_snapshot: dict,
    layer: int,
    thesis_shock_pct: float,
    parent_series_id: str | None = None,
) -> dict:
    sid = imp["series_id"]
    pred = imp["predicted_move_pct"]
    pct_90d, pct_756d = get_regime_percentiles(sid, regime_snapshot)
    amplifier = (pred > 0 and thesis_shock_pct > 0) or (
        pred < 0 and thesis_shock_pct < 0
    )
    if pred == 0 or thesis_shock_pct == 0:
        amplifier = False
    return {
        "series_id": sid,
        "name": imp.get("name"),
        "predicted_move_pct": pred,
        "beta": imp.get("beta"),
        "r_squared": imp.get("r_squared"),
        "ci_95_low": imp.get("ci_95_low"),
        "ci_95_high": imp.get("ci_95_high"),
        "importance_score": score_variable(
            {
                "series_id": sid,
                "predicted_move_pct": pred,
                "r_squared": imp["r_squared"],
            },
            regime_snapshot,
            layer,
        ),
        "layer": layer,
        "source": "ols",
        "transmission": None,
        "regime_note": build_regime_note(sid, regime_snapshot),
        "regime_pct_90d": pct_90d,
        "regime_pct_756d": pct_756d,
        "amplifier": amplifier,
        "p_value": imp.get("p_value"),
        "parent_series_id": parent_series_id,
    }


def _read_beta_metadata(conn, base_series: str) -> dict[str, dict[str, Any]]:
    """
    Reads cached beta metadata for a focal series.
    Returns dict keyed by target_series_id:
      { target: { optimal_decay, break_detected, break_date } }
    Returns empty dict if table missing or error.
    """
    try:
        cur = conn.cursor()
        try:
            cur.execute(
                """
                SELECT target_series_id, optimal_decay,
                       break_detected, break_date
                FROM beta_metadata
                WHERE base_series_id = %s
                """,
                (base_series,),
            )
            rows = cur.fetchall()
        finally:
            cur.close()
        return {
            r[0]: {
                "optimal_decay": float(r[1]) if r[1] is not None else 1.0,
                "break_detected": bool(r[2]) if r[2] is not None else False,
                "break_date": str(r[3]) if r[3] else None,
            }
            for r in rows
        }
    except Exception as e:
        logger.warning(
            "_read_beta_metadata failed for %s: %s",
            base_series,
            e,
        )
        return {}


def compute_impact_ewls(
    conn,
    base_series: str,
    target_series_list: list[str],
    shock_pct: float,
    days: int,
    decay: float,
) -> dict[str, Any]:
    """
    WLS version of compute_impact with exponential decay weights.
    Returns same schema subset as compute_impact impacts list.
    Only called when decay < 1.0.
    """
    from signals.research.data import get_aligned_returns

    import numpy as np
    import statsmodels.api as sm

    MIN_OBS = 30
    series_ids = [base_series] + list(target_series_list)
    df = get_aligned_returns(conn, series_ids, days)
    if df is None or len(df) < MIN_OBS:
        return {"impacts": []}
    df = df.dropna()
    if len(df) < MIN_OBS:
        return {"impacts": []}

    n = len(df)
    weights = np.array([decay ** (n - 1 - i) for i in range(n)])

    impacts: list[dict[str, Any]] = []
    for target in target_series_list:
        if target not in df.columns:
            continue
        try:
            y = df[target].values.astype(float)
            X = sm.add_constant(df[base_series].values.astype(float))
            model = sm.WLS(y, X, weights=weights).fit()
            beta = float(model.params[1])
            predicted = round(beta * shock_pct, 2)
            impacts.append(
                {
                    "series_id": target,
                    "predicted_move_pct": predicted,
                    "beta_ewls": round(beta, 4),
                }
            )
        except Exception as e:
            logger.warning(
                "compute_impact_ewls failed %s->%s: %s",
                base_series,
                target,
                e,
            )
            continue

    return {"impacts": impacts}


def expand_thesis(conn, thesis_node: dict, regime_snapshot: dict) -> dict:
    ts = datetime.now(timezone.utc).isoformat()
    regime_snapshot = _ensure_regime_snapshot(conn, regime_snapshot)
    eligible = get_ols_eligible_series(conn)
    raw_focal = str(thesis_node.get("focal_series_id") or "")
    focal = normalize_series_id(raw_focal, eligible, conn)
    if focal is None:
        return {"error": "focal_series_not_found", "raw_id": raw_focal}

    shock_pct = float(thesis_node.get("shock_pct") or 0.0)
    thesis_effective = {**thesis_node, "focal_series_id": focal}

    targets_l1 = [s for s in eligible if s != focal]
    result = _compute_impact_merge(
        conn,
        focal,
        targets_l1,
        shock_pct,
        252,
    )

    if result.get("error"):
        return {
            "flagged": [],
            "regime_snapshot": regime_snapshot,
            "completeness_pct": _completeness_pct(thesis_effective, []),
            "ols_series_count": len(eligible),
            "expansion_timestamp": ts,
            "error": result["error"],
        }

    impacts = result.get("impacts") or []
    filtered = [
        imp
        for imp in impacts
        if imp.get("r_squared") is not None
        and imp["r_squared"] >= OLS_MIN_R2
        and imp.get("p_value") is not None
        and imp["p_value"] <= OLS_MAX_PVAL
    ]

    layer1_scored: list[dict] = []
    for imp in filtered:
        fd = _flagged_dict_from_ols(
            imp,
            regime_snapshot,
            1,
            thesis_effective["shock_pct"],
            parent_series_id=None,
        )
        layer1_scored.append(fd)

    layer1_scored.sort(key=lambda x: x["importance_score"], reverse=True)
    layer1 = layer1_scored[:LAYER1_MAX]
    layer1_ids = {x["series_id"] for x in layer1}

    meta = _read_beta_metadata(conn, focal)
    from signals.thesis_engine.beta_analysis import compute_rolling_betas

    for var in layer1:
        if var.get("source") != "ols":
            var["beta_60d"] = None
            var["beta_120d"] = None
            var["beta_252d"] = None
            var["beta_60d_ci"] = [None, None]
            var["beta_trend"] = None
            var["beta_trend_significant"] = None
            var["break_detected"] = False
            var["break_date"] = None
            var["beta_note"] = None
            var["predicted_move_ewls"] = var.get("predicted_move_pct")
            continue
        try:
            rolling = compute_rolling_betas(
                conn,
                base_series=focal,
                target_series=var["series_id"],
            )
            betas = rolling.get("betas", {})
            var["beta_60d"] = (betas.get(60) or {}).get("beta")
            var["beta_120d"] = (betas.get(120) or {}).get("beta")
            var["beta_252d"] = (betas.get(252) or {}).get("beta")
            b60 = betas.get(60) or {}
            var["beta_60d_ci"] = [
                b60.get("ci_low"),
                b60.get("ci_high"),
            ]
            var["beta_trend"] = rolling.get("beta_trend")
            var["beta_trend_significant"] = rolling.get(
                "trend_significant"
            )
        except Exception as e:
            logger.warning(
                "Rolling beta failed %s->%s: %s",
                focal,
                var["series_id"],
                e,
            )
            var["beta_60d"] = None
            var["beta_120d"] = None
            var["beta_252d"] = None
            var["beta_60d_ci"] = [None, None]
            var["beta_trend"] = None
            var["beta_trend_significant"] = None

        m = meta.get(var["series_id"], {})
        var["break_detected"] = m.get("break_detected", False)
        var["break_date"] = m.get("break_date")
        if var["break_detected"] and var["break_date"]:
            var["beta_note"] = (
                f"Structural break detected "
                f"{var['break_date']} — "
                f"post-break data used for projection"
            )
        else:
            var["beta_note"] = None

        optimal_decay = float(m.get("optimal_decay", 1.0) or 1.0)
        if (
            optimal_decay < 1.0
            and var.get("predicted_move_pct") is not None
            and var.get("source") == "ols"
        ):
            ewls = compute_impact_ewls(
                conn,
                focal,
                [var["series_id"]],
                float(thesis_effective["shock_pct"]),
                252,
                optimal_decay,
            )
            ewls_impacts = ewls.get("impacts", [])
            if ewls_impacts:
                var["predicted_move_ewls"] = ewls_impacts[0].get(
                    "predicted_move_pct"
                )
            else:
                var["predicted_move_ewls"] = var.get(
                    "predicted_move_pct"
                )
        else:
            var["predicted_move_ewls"] = var.get("predicted_move_pct")

    l2_pool: list[dict] = []
    for l1 in layer1:
        if l1["importance_score"] <= 0.3:
            continue
        base_l2 = l1["series_id"]
        implied_shock = float(l1["predicted_move_pct"])
        remaining = [
            s
            for s in eligible
            if s not in layer1_ids
            and s != focal
            and s != base_l2
        ]
        if not remaining:
            continue
        l2_res = _compute_impact_merge(
            conn,
            base_l2,
            remaining,
            implied_shock,
            252,
        )
        if l2_res.get("error"):
            continue
        for imp in l2_res.get("impacts") or []:
            if (
                imp.get("r_squared") is None
                or imp["r_squared"] < OLS_MIN_R2
                or imp.get("p_value") is None
                or imp["p_value"] > OLS_MAX_PVAL
            ):
                continue
            sid = imp["series_id"]
            if sid in layer1_ids:
                continue
            fd = _flagged_dict_from_ols(
                imp,
                regime_snapshot,
                2,
                thesis_effective["shock_pct"],
                parent_series_id=base_l2,
            )
            l2_pool.append(fd)

    by_id: dict[str, dict] = {}
    for fd in l2_pool:
        sid = fd["series_id"]
        if sid not in by_id or fd["importance_score"] > by_id[sid]["importance_score"]:
            by_id[sid] = fd

    layer2_list = sorted(
        by_id.values(), key=lambda x: x["importance_score"], reverse=True
    )[:LAYER2_MAX]
    layer2_ids = {x["series_id"] for x in layer2_list}

    static_entries: list[dict] = []
    covered = layer1_ids | layer2_ids
    for rel in _collect_static_relationships(focal):
        tgt = rel.get("to")
        if not tgt or tgt in covered or tgt == focal:
            continue
        strength = rel.get("strength") or "speculative"
        imp_score = _STRENGTH_SCORE.get(strength, 0.1)
        direction = rel.get("direction") or "positive"
        static_entries.append(
            {
                "series_id": tgt,
                "name": None,
                "predicted_move_pct": None,
                "beta": None,
                "r_squared": None,
                "ci_95_low": None,
                "ci_95_high": None,
                "importance_score": imp_score,
                "layer": 1,
                "source": "static_graph",
                "transmission": None,
                "regime_note": build_regime_note(tgt, regime_snapshot),
                "regime_pct_90d": None,
                "regime_pct_756d": None,
                "amplifier": _static_amplifier(direction, shock_pct),
                "p_value": None,
                "parent_series_id": None,
                "static_direction": direction,
                "static_condition": rel.get("condition"),
            }
        )

    flagged = list(layer1) + list(layer2_list) + static_entries

    addressed = thesis_node.get("addressed") or []
    addr_ids = {
        a.get("series_id")
        for a in addressed
        if isinstance(a, dict) and a.get("series_id")
    }
    flagged = [f for f in flagged if f["series_id"] not in addr_ids]

    for f in flagged:
        if f.get("source") == "static_graph":
            f["regime_note"] = build_regime_note(f["series_id"], regime_snapshot)
            if "static_direction" in f:
                f["amplifier"] = _static_amplifier(f["static_direction"], shock_pct)

    for f in flagged:
        f.pop("static_direction", None)
        f.pop("static_condition", None)

    flagged.sort(key=lambda x: x.get("importance_score") or 0, reverse=True)

    return {
        "flagged": flagged,
        "regime_snapshot": regime_snapshot,
        "completeness_pct": _completeness_pct(thesis_effective, flagged),
        "ols_series_count": len(eligible),
        "expansion_timestamp": ts,
    }
