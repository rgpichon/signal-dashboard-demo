"""
Detect logical tensions in the user's addressed variable set.
Two-pass: static lookup first, then Llama for anything not already found.
"""
from __future__ import annotations

import logging
from typing import Any

from signals.thesis_engine.static_graph import KNOWN_TENSIONS

logger = logging.getLogger(__name__)


def _pair_key(variable_a: str, variable_b: str) -> tuple[str, str]:
    x, y = sorted([str(variable_a), str(variable_b)])
    return (x, y)


def _addressed_matches_prefix(addressed: list[dict], prefix: str) -> bool:
    if not prefix:
        return False
    for v in addressed:
        if not isinstance(v, dict):
            continue
        sid = str(v.get("series_id") or "")
        if sid.startswith(prefix):
            return True
    return False


def _static_tensions(addressed: list[dict]) -> list[dict]:
    out: list[dict] = []
    seen_keys: set[tuple[str, str]] = set()
    for a, b, description in KNOWN_TENSIONS:
        if _addressed_matches_prefix(addressed, a) and _addressed_matches_prefix(
            addressed, b
        ):
            rec = {
                "variable_a": a,
                "variable_b": b,
                "description": description,
                "resolved": False,
            }
            k = _pair_key(a, b)
            if k not in seen_keys:
                seen_keys.add(k)
                out.append(rec)
    return out


def detect_tensions(addressed: list[dict], llama_client_module: Any) -> list[dict]:
    """
    Pass 1: KNOWN_TENSIONS static lookup (prefix match on series_id).
    Pass 2: Llama (only if len(addressed) >= 4); merge without duplicate pairs.
    On any exception in Pass 2, return Pass 1 only. Never raises.
    """
    try:
        addressed = addressed or []
        static_results = _static_tensions(addressed)
        seen_keys = {_pair_key(r["variable_a"], r["variable_b"]) for r in static_results}

        if len(addressed) < 4:
            return list(static_results)

        try:
            simplified = [
                {"series_id": v.get("series_id"), "stance": v.get("stance") or ""}
                for v in addressed
                if isinstance(v, dict)
            ]
            llama_list = llama_client_module.detect_tensions(simplified)
        except Exception:
            logger.exception("detect_tensions: Llama pass failed")
            return list(static_results)

        if not isinstance(llama_list, list):
            return list(static_results)

        merged = list(static_results)
        for item in llama_list:
            if not isinstance(item, dict):
                continue
            va = item.get("variable_a")
            vb = item.get("variable_b")
            desc = item.get("description")
            if va is None or vb is None or desc is None:
                continue
            k = _pair_key(str(va), str(vb))
            if k in seen_keys:
                continue
            seen_keys.add(k)
            merged.append(
                {
                    "variable_a": va,
                    "variable_b": vb,
                    "description": desc,
                    "resolved": False,
                }
            )
        return merged
    except Exception:
        logger.exception("detect_tensions: unexpected failure")
        try:
            return _static_tensions(addressed or [])
        except Exception:
            return []
