"""
Thesis Engine API router (Phase T1: parse; Phase T2: expand).
"""
import json
import logging
import uuid
from datetime import date, datetime, timezone
from typing import Any

from fastapi import APIRouter, Body, Query
from fastapi.responses import JSONResponse

from signals.db.connection import get_connection
from signals.thesis_engine import llama_client as llama_client_mod
from signals.thesis_engine.llama_client import (
    generate_thesis_statement,
    parse_thesis_input,
)
from signals.thesis_engine.expander import expand_thesis
from signals.thesis_engine.tension_detector import detect_tensions

router = APIRouter(prefix="/api/thesis-engine", tags=["thesis-engine"])

logger = logging.getLogger(__name__)

HORIZON_MAP = {"short": 90, "medium": 270, "long": 540}

INDICATOR_ORDER = [
    "growth_pulse",
    "credit_stress",
    "real_yield",
    "dollar_strength",
    "rates_vol",
    "equity_vol",
    "curve_shape",
]


def _row_to_regime_snapshot(row: tuple | None, description) -> dict[str, Any]:
    if row is None:
        return {}
    cols = [d[0] for d in description]
    out: dict[str, Any] = {}
    for c, v in zip(cols, row):
        if hasattr(v, "isoformat"):
            out[c] = v.isoformat()
        else:
            out[c] = v
    return out


@router.post("/parse")
def thesis_engine_parse(body: dict[str, Any] = Body(...)) -> dict[str, Any]:
    raw_text = body.get("raw_text")
    if raw_text is None:
        raw_text = ""
    return parse_thesis_input(str(raw_text))


@router.post("/expand")
def thesis_engine_expand(payload: dict[str, Any] = Body(...)) -> dict[str, Any]:
    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute("SELECT * FROM regime_snapshots ORDER BY date DESC LIMIT 1")
        row = cur.fetchone()
        desc = cur.description
        cur.close()
        regime_snapshot = _row_to_regime_snapshot(row, desc)
        return expand_thesis(conn, payload, regime_snapshot)


@router.post("/explain")
def thesis_engine_explain(payload: dict[str, Any] = Body(...)) -> dict[str, Any]:
    try:
        text = llama_client_mod.generate_transmission(
            focal_series=str(payload.get("focal_series_id") or ""),
            target_series=str(payload.get("target_series_id") or ""),
            beta=float(payload.get("beta") or 0.0),
            shock_pct=float(payload.get("shock_pct") or 0.0),
            thesis_context={"claim": str(payload.get("claim") or "")},
        )
        return {"transmission": text or ""}
    except Exception:
        return {"transmission": ""}


@router.post("/generate-statement")
def thesis_engine_generate_statement(
    payload: dict[str, Any] = Body(...),
) -> dict[str, Any]:
    """
    Accepts thesis node fields and returns a generated thesis statement paragraph.
    Always HTTP 200; statement is never empty. llama_available reflects Ollama success.
    """
    body = payload if isinstance(payload, dict) else {}
    statement, llama_available = generate_thesis_statement(body)
    return {"statement": str(statement).strip(), "llama_available": bool(llama_available)}


@router.post("/check")
def thesis_engine_check(payload: dict[str, Any] = Body(...)) -> dict[str, Any]:
    addressed = payload.get("addressed")
    if not isinstance(addressed, list):
        addressed = []
    tensions = detect_tensions(addressed, llama_client_mod)

    conflict = False
    by_series: dict[str, set[str]] = {}
    for v in addressed:
        if not isinstance(v, dict):
            continue
        sid = v.get("series_id")
        stance = (v.get("stance") or "").strip().lower()
        if not sid or not stance:
            continue
        by_series.setdefault(str(sid), set()).add(stance)
    for stances in by_series.values():
        if "supports" in stances and "challenges" in stances:
            conflict = True
            break

    unresolved = any(
        isinstance(t, dict) and not t.get("resolved", False) for t in tensions
    )

    if conflict:
        consistency = "conflict_detected"
    elif unresolved:
        consistency = "tensions_present"
    else:
        consistency = "clean"

    return {"tensions": tensions, "consistency": consistency}


def _parse_metadata(raw: Any) -> dict[str, Any]:
    if raw is None:
        return {}
    if isinstance(raw, dict):
        return raw
    if isinstance(raw, str):
        try:
            out = json.loads(raw)
            return out if isinstance(out, dict) else {}
        except json.JSONDecodeError:
            return {}
    return {}


def _find_addressed(addressed: list[Any], series_id: str | None) -> dict[str, Any] | None:
    if not series_id:
        return None
    sid = str(series_id)
    for v in addressed:
        if isinstance(v, dict) and str(v.get("series_id") or "") == sid:
            return v
    return None


def _signal_thesis_impact(
    addressed: list[Any], relevance_series: str, sentiment_avg: float | None
) -> str:
    s = 0.0 if sentiment_avg is None else float(sentiment_avg)
    av = _find_addressed(addressed, relevance_series)
    stance = (av.get("stance") or "").strip().lower() if av else ""
    if stance == "supports":
        if s > 0.1:
            return "amplifies"
        if s < -0.1:
            return "challenges"
    elif stance == "challenges":
        if s < -0.1:
            return "amplifies"
        if s > 0.1:
            return "challenges"
    return "neutral"


def _anomaly_thesis_impact(addressed: list[Any], series_id: str | None) -> str:
    av = _find_addressed(addressed, series_id)
    stance = (av.get("stance") or "").strip().lower() if av else ""
    if stance == "supports":
        return "amplifies"
    if stance == "challenges":
        return "challenges"
    return "neutral"


@router.get("/monitor/{thesis_id}")
def get_monitor(thesis_id: str) -> dict[str, Any]:
    """
    Aggregate regime, signals, and anomalies relevant to a saved research thesis.
    Always returns HTTP 200 with a JSON body (error dict on failure, never uncaught 500).
    """
    try:
        try:
            uuid.UUID(str(thesis_id))
        except ValueError:
            return {"error": "thesis_not_found"}

        with get_connection() as conn:
            cur = conn.cursor()
            cur.execute(
                """
                SELECT id, title, created_at, metadata
                FROM research_theses
                WHERE id = %s::uuid
                """,
                (thesis_id,),
            )
            row = cur.fetchone()
            if not row:
                cur.close()
                return {"error": "thesis_not_found"}

            _tid, _title, created_at, meta_raw = row
            meta = _parse_metadata(meta_raw)

            focal_series_id = meta.get("focal_series_id")
            time_horizon = str(meta.get("time_horizon") or "medium")
            confidence = str(meta.get("confidence") or "moderate")
            claim = str(meta.get("claim") or "")
            addressed = meta.get("addressed")
            flagged = meta.get("flagged")
            if not isinstance(addressed, list):
                addressed = []
            if not isinstance(flagged, list):
                flagged = []

            creation_fingerprint = meta.get("regime_fingerprint")
            if creation_fingerprint is not None:
                creation_fingerprint = str(creation_fingerprint)

            horizon_days = int(HORIZON_MAP.get(time_horizon, 270))
            if isinstance(created_at, datetime):
                created_date = (
                    created_at.date()
                    if created_at.tzinfo is None
                    else created_at.astimezone(timezone.utc).date()
                )
            else:
                created_date = date.today()
            days_active = max(0, (date.today() - created_date).days)
            horizon_pct = min(
                round(days_active / horizon_days * 100, 1) if horizon_days else 0.0,
                100.0,
            )

            all_series_ids: set[str] = set()
            for item in addressed + flagged:
                if isinstance(item, dict) and item.get("series_id"):
                    all_series_ids.add(str(item["series_id"]))
            if focal_series_id:
                all_series_ids.add(str(focal_series_id))

            instrument_names: dict[str, str] = {}
            if all_series_ids:
                ids_list = list(all_series_ids)
                cur.execute(
                    "SELECT id, name FROM instruments WHERE id = ANY(%s)",
                    (ids_list,),
                )
                for ir in cur.fetchall() or []:
                    if ir[0]:
                        instrument_names[str(ir[0])] = str(ir[1] or "")

            cur.execute(
                "SELECT * FROM regime_snapshots ORDER BY date DESC LIMIT 1"
            )
            reg_row = cur.fetchone()
            reg_desc = cur.description
            reg_dict = _row_to_regime_snapshot(reg_row, reg_desc) if reg_row else {}

            regime_current = {
                "date": str(reg_dict.get("date")) if reg_dict.get("date") is not None else None,
                "fingerprint": reg_dict.get("fingerprint"),
                "indicators": {
                    k: reg_dict.get(k) for k in INDICATOR_ORDER
                },
            }

            if not creation_fingerprint:
                regime_at_creation = None
                regime_changes: list[dict[str, Any]] = []
            else:
                parts = creation_fingerprint.split("-")
                padded = list(parts[: len(INDICATOR_ORDER)])
                while len(padded) < len(INDICATOR_ORDER):
                    padded.append(None)
                creation_states = dict(zip(INDICATOR_ORDER, padded))
                regime_at_creation = {
                    "fingerprint": creation_fingerprint,
                    "indicators": creation_states,
                }
                current_states = regime_current["indicators"]
                regime_changes = [
                    {
                        "indicator": k,
                        "was": creation_states.get(k),
                        "now": current_states.get(k),
                    }
                    for k in INDICATOR_ORDER
                    if creation_states.get(k) != current_states.get(k)
                ]

            cur.execute(
                """
                SELECT date, topic, article_count, velocity_7d,
                       sentiment_avg, divergence_flag, anomaly_flag
                FROM daily_signals
                ORDER BY date DESC
                LIMIT 30
                """
            )
            signal_rows = cur.fetchall() or []

            relevant_signals: list[dict[str, Any]] = []
            seen_topics: set[str] = set()

            for sig in signal_rows:
                if len(relevant_signals) >= 10:
                    break
                topic = str(sig[1] or "")
                topic_l = topic.lower()
                relevant = False
                relevance_series: str | None = None

                for sid in all_series_ids:
                    if sid.lower() in topic_l:
                        relevant = True
                        relevance_series = sid
                        break

                if not relevant:
                    for sid, nm in instrument_names.items():
                        n = (nm or "").strip().lower()
                        if n and n in topic_l:
                            relevant = True
                            relevance_series = sid
                            break

                if not relevant or topic in seen_topics:
                    continue

                seen_topics.add(topic)
                thesis_impact = _signal_thesis_impact(
                    addressed, relevance_series or "", sig[4]
                )
                relevant_signals.append(
                    {
                        "topic": topic,
                        "article_count": sig[2],
                        "velocity_7d": sig[3],
                        "sentiment_avg": sig[4],
                        "divergence_flag": sig[5],
                        "anomaly_flag": sig[6],
                        "relevance_note": f"Related to {relevance_series}",
                        "thesis_impact": thesis_impact,
                    }
                )

            cur.execute(
                """
                SELECT anomaly_type, topic, series_id, severity,
                       description, detected_at
                FROM anomalies
                ORDER BY detected_at DESC
                LIMIT 20
                """
            )
            anom_rows = cur.fetchall() or []
            relevant_anomalies: list[dict[str, Any]] = []

            for ar in anom_rows:
                if len(relevant_anomalies) >= 5:
                    break
                sid = ar[2]
                if not sid or str(sid) not in all_series_ids:
                    continue
                det = ar[5]
                detected_str = (
                    det.isoformat()
                    if hasattr(det, "isoformat")
                    else str(det)
                )
                relevant_anomalies.append(
                    {
                        "anomaly_type": ar[0],
                        "series_id": str(sid),
                        "severity": ar[3],
                        "description": ar[4],
                        "detected_at": detected_str,
                        "thesis_impact": _anomaly_thesis_impact(addressed, str(sid)),
                    }
                )

            cur.close()

        created_at_str = (
            created_at.isoformat()
            if hasattr(created_at, "isoformat")
            else str(created_at)
        )

        return {
            "thesis_id": str(thesis_id),
            "claim": claim,
            "time_horizon": time_horizon,
            "confidence": confidence,
            "created_at": created_at_str,
            "days_active": days_active,
            "horizon_days": horizon_days,
            "horizon_pct": horizon_pct,
            "regime_at_creation": regime_at_creation,
            "regime_current": regime_current,
            "regime_changes": regime_changes,
            "relevant_signals": relevant_signals,
            "relevant_anomalies": relevant_anomalies,
        }
    except Exception:
        logger.exception("get_monitor failed for thesis_id=%s", thesis_id)
        return {"error": "monitor_failed"}


_VALID_STANCES = frozenset({"supports", "challenges", "neutral"})


def _fp_similarity(fp1: str | None, fp2: str | None) -> int:
    if not fp1 or not fp2:
        return 0
    s1 = fp1.split("-")
    s2 = fp2.split("-")
    if len(s1) != 7 or len(s2) != 7:
        return 0
    return sum(1 for a, b in zip(s1, s2) if a == b)


def _tally_stance_rows(rows: list[tuple[Any, ...]]) -> dict[str, Any] | None:
    counts = {"supports": 0, "challenges": 0, "neutral": 0}
    for r in rows:
        st = r[0] if r else None
        if st in counts:
            counts[str(st)] += 1
    total = sum(counts.values())
    if total == 0:
        return None
    dominant = max(counts, key=lambda k: counts[k])
    dom_count = counts[dominant]
    ratio = dom_count / total
    confidence = (
        "high" if ratio >= 0.75 else "medium" if ratio >= 0.60 else "low"
    )
    return {
        "supports": counts["supports"],
        "challenges": counts["challenges"],
        "neutral": counts["neutral"],
        "total": total,
        "dominant_stance": dominant,
        "confidence": confidence,
    }


@router.post("/record-stance")
def record_stance(payload: dict[str, Any] = Body(...)) -> dict[str, Any]:
    """
    Records a stance action into thesis_variable_history.
    Fire-and-forget — always returns 200.
    Never raises.
    """
    try:
        body = payload if isinstance(payload, dict) else {}
        raw_tid = body.get("thesis_id")
        focal = str(body.get("focal_series_id") or "").strip()
        target = str(body.get("target_series_id") or "").strip()
        stance = str(body.get("stance") or "").strip().lower()
        reg_fp = body.get("regime_fingerprint")
        if reg_fp is not None and not isinstance(reg_fp, str):
            reg_fp = str(reg_fp)
        if reg_fp is not None:
            reg_fp = reg_fp.strip() or None

        if stance not in _VALID_STANCES:
            return {"recorded": False}
        if not focal or not target:
            return {"recorded": False}

        thesis_uuid: uuid.UUID | None = None
        if raw_tid is not None and str(raw_tid).strip():
            try:
                thesis_uuid = uuid.UUID(str(raw_tid).strip())
            except ValueError:
                logger.warning("record_stance: invalid thesis_id %r", raw_tid)
                return {"recorded": False}

        with get_connection() as conn:
            cur = conn.cursor()
            cur.execute(
                """
                INSERT INTO thesis_variable_history
                    (thesis_id, focal_series_id, target_series_id,
                     stance, regime_fingerprint)
                VALUES (%s, %s, %s, %s, %s)
                """,
                (thesis_uuid, focal, target, stance, reg_fp),
            )
            cur.close()

        return {"recorded": True}
    except Exception:
        logger.warning("record_stance failed", exc_info=True)
        return {"recorded": False}


@router.get("/history/{focal_series_id}")
def get_history(
    focal_series_id: str,
    regime_fingerprint: str = Query(""),
) -> dict[str, Any]:
    """
    Returns stance frequency history for a focal series.
    Uses conditional (similar-regime) and unconditional frequencies.
    """
    try:
        fp_param = (regime_fingerprint or "").strip()

        with get_connection() as conn:
            cur = conn.cursor()
            cur.execute(
                """
                SELECT thesis_id, target_series_id, stance, regime_fingerprint
                FROM thesis_variable_history
                WHERE focal_series_id = %s
                ORDER BY addressed_at DESC
                """,
                (focal_series_id,),
            )
            all_rows = cur.fetchall()

            if not all_rows:
                cur.close()
                return {
                    "focal_series_id": focal_series_id,
                    "total_theses": 0,
                    "similar_regime_theses": 0,
                    "variables": {},
                }

            cur.execute(
                """
                SELECT COUNT(DISTINCT thesis_id)
                FROM thesis_variable_history
                WHERE focal_series_id = %s
                  AND thesis_id IS NOT NULL
                """,
                (focal_series_id,),
            )
            total_theses_row = cur.fetchone()
            total_theses = int(total_theses_row[0] or 0) if total_theses_row else 0

            cur.close()

        cond_bucket: list[tuple[Any, ...]] = []
        if fp_param:
            for row in all_rows:
                _tid, _tgt, _st, rfp = row
                rfp_s = rfp if isinstance(rfp, str) else (str(rfp) if rfp is not None else "")
                if _fp_similarity(rfp_s, fp_param) >= 5:
                    cond_bucket.append(row)

        similar_ids: set[Any] = set()
        for row in cond_bucket:
            tid = row[0]
            if tid is not None:
                similar_ids.add(tid)
        similar_regime_theses = len(similar_ids)

        targets = {row[1] for row in all_rows if row[1]}
        variables: dict[str, Any] = {}
        for tgt in sorted(targets):
            uncond_rows = [(r[2],) for r in all_rows if r[1] == tgt]
            cond_rows = [(r[2],) for r in cond_bucket if r[1] == tgt]
            uncond = _tally_stance_rows(uncond_rows)
            cond = _tally_stance_rows(cond_rows) if cond_rows else None
            variables[str(tgt)] = {
                "conditional": cond,
                "unconditional": uncond,
            }

        return {
            "focal_series_id": focal_series_id,
            "total_theses": total_theses,
            "similar_regime_theses": similar_regime_theses,
            "variables": variables,
        }
    except Exception:
        logger.warning("get_history failed for focal=%s", focal_series_id, exc_info=True)
        return {
            "focal_series_id": focal_series_id,
            "error": "history_failed",
            "variables": {},
        }


def _tracking_quality(path: dict[str, Any], days_elapsed: int, horizon_days: int) -> str:
    pct = days_elapsed / max(horizon_days, 1)
    if pct < 0.30:
        return "pending"
    c60 = path.get("correct_at_60pct")
    if c60 is None:
        return "pending"
    return "on_track" if bool(c60) else "off_track"


@router.get("/outcomes/{thesis_id}")
def get_outcomes(thesis_id: str) -> dict[str, Any]:
    """
    Returns path tracking data for a specific thesis.
    thesis_id is a UUID string.
    """
    try:
        with get_connection() as conn:
            cur = conn.cursor()
            cur.execute(
                """
                SELECT id, created_at, metadata
                FROM research_theses
                WHERE id = %s::uuid
                """,
                (thesis_id,),
            )
            row = cur.fetchone()
            if not row:
                cur.close()
                return {"error": "thesis_not_found", "thesis_id": thesis_id}

            _tid, created_at, meta_raw = row
            metadata = _parse_metadata(meta_raw)
            time_horizon = str(metadata.get("time_horizon") or "medium")
            horizon_days = int(HORIZON_MAP.get(time_horizon, 270))
            created_date = (
                created_at.date() if hasattr(created_at, "date") else date.today()
            )
            days_elapsed = max(0, (date.today() - created_date).days)
            horizon_pct = min(
                round(days_elapsed / max(horizon_days, 1) * 100, 1),
                100.0,
            )

            cur.execute(
                """
                SELECT
                  series_id,
                  predicted_move_pct,
                  predicted_direction,
                  current_move_pct,
                  max_favourable_pct,
                  max_adverse_pct,
                  correct_at_30pct,
                  correct_at_60pct,
                  correct_at_100pct,
                  target_reached,
                  target_reached_at,
                  status,
                  last_updated
                FROM thesis_outcome_paths
                WHERE thesis_id = %s::uuid
                ORDER BY series_id
                """,
                (thesis_id,),
            )
            rows = cur.fetchall()
            cur.close()

        paths: list[dict[str, Any]] = []
        for r in rows:
            path = {
                "series_id": r[0],
                "predicted_move_pct": r[1],
                "predicted_direction": r[2],
                "current_move_pct": r[3],
                "max_favourable_pct": r[4],
                "max_adverse_pct": r[5],
                "correct_at_30pct": r[6],
                "correct_at_60pct": r[7],
                "correct_at_100pct": r[8],
                "target_reached": bool(r[9]) if r[9] is not None else False,
                "target_reached_at": (
                    r[10].isoformat() if hasattr(r[10], "isoformat") else None
                ),
                "status": r[11],
            }
            path["tracking_quality"] = _tracking_quality(path, days_elapsed, horizon_days)
            paths.append(path)

        return {
            "thesis_id": thesis_id,
            "horizon_days": horizon_days,
            "days_elapsed": days_elapsed,
            "horizon_pct": horizon_pct,
            "paths": paths,
        }
    except Exception:
        logger.exception("get_outcomes failed for thesis_id=%s", thesis_id)
        return {"error": "outcomes_failed", "thesis_id": thesis_id}


@router.get("/track-record")
def get_track_record() -> dict[str, Any]:
    """
    Returns the latest thesis_track_record row.
    Returns has_sufficient_data: false if fewer
    than 10 variables tracked or no rows exist.
    """
    try:
        with get_connection() as conn:
            cur = conn.cursor()
            cur.execute(
                """
                SELECT
                  computed_at,
                  total_theses_tracked,
                  total_variables_tracked,
                  direction_acc_30pct,
                  direction_acc_60pct,
                  direction_acc_100pct,
                  avg_magnitude_ratio,
                  magnitude_ratio_p25,
                  magnitude_ratio_p75,
                  by_asset_class,
                  by_focal_series
                FROM thesis_track_record
                ORDER BY computed_at DESC
                LIMIT 1
                """
            )
            row = cur.fetchone()
            cur.close()

        if not row:
            return {
                "has_sufficient_data": False,
                "total_theses_tracked": 0,
                "total_variables_tracked": 0,
                "computed_at": None,
            }

        by_asset_class = row[9]
        if by_asset_class is None:
            by_asset_class = {}
        elif isinstance(by_asset_class, str):
            try:
                by_asset_class = json.loads(by_asset_class)
            except json.JSONDecodeError:
                by_asset_class = {}

        by_focal_series = row[10]
        if by_focal_series is None:
            by_focal_series = {}
        elif isinstance(by_focal_series, str):
            try:
                by_focal_series = json.loads(by_focal_series)
            except json.JSONDecodeError:
                by_focal_series = {}

        total_variables_tracked = int(row[2] or 0)
        has_sufficient = total_variables_tracked >= 10

        return {
            "computed_at": str(row[0]) if row[0] is not None else None,
            "total_theses_tracked": int(row[1] or 0),
            "total_variables_tracked": total_variables_tracked,
            "direction_acc_30pct": row[3],
            "direction_acc_60pct": row[4],
            "direction_acc_100pct": row[5],
            "avg_magnitude_ratio": row[6],
            "magnitude_ratio_p25": row[7],
            "magnitude_ratio_p75": row[8],
            "by_asset_class": by_asset_class or {},
            "by_focal_series": by_focal_series or {},
            "has_sufficient_data": has_sufficient,
        }
    except Exception:
        logger.exception("get_track_record failed")
        return {
            "has_sufficient_data": False,
            "total_variables_tracked": 0,
            "error": "track_record_failed",
        }
