"""
Ollama client for Thesis Engine (Phase T1).
"""
from __future__ import annotations

import json
import logging
import re
from typing import Any

import requests

logger = logging.getLogger(__name__)

OLLAMA_GENERATE_URL = "http://localhost:11434/api/generate"
OLLAMA_MODEL = "llama3:latest"
REQUEST_TIMEOUT_S = 120

_PARSE_SYSTEM = """You are a macro investment research assistant. Extract structured fields from the user's investment thesis description.

Return ONLY valid JSON with these exact keys:
- focal_series_id: the primary market series most relevant (use prefixes: EQ., RATES., CM., FX., CREDIT., MACRO.)
- shock_pct: expected percentage move as a float (positive = up, negative = down)
- direction: one of "long", "short", "relative_value", "macro_hedge"
- asset_class: one of "rates", "fx", "equity", "commodity", "credit", "multi"
- geography: one of "us", "eu", "em", "global", or a specific country name
- time_horizon: one of "short", "medium", "long"
- trigger: brief description of the initiating event (max 15 words)
- claim: one clear sentence of what you believe will happen

Do not include any text outside the JSON object.
"""

_TRANSMISSION_SYSTEM = """You are a macro research assistant. Write one sentence (max 40 words) explaining the transmission mechanism 
between two financial variables in the context of a specific investment thesis.
Be specific. Reference the direction of the relationship. Do not use generic filler phrases.
Return only the sentence, no preamble.
"""

_TENSION_SYSTEM = """You are a macro research assistant reviewing an investment thesis for logical consistency.
Identify pairs of variables that create tension — where both being true simultaneously 
requires the investor to take a position on which dominates.

Common tension patterns:
- "rates rise" AND "equities rally" (rate compression vs earnings resilience)
- "dollar strengthens" AND "commodities rise" (inverse USD relationship)
- "inflation rises" AND "growth accelerates" (stagflation vs overheating distinction)
- "credit spreads widen" AND "equities stable" (decoupling risk)

Return ONLY valid JSON: a list of objects with keys: variable_a, variable_b, description.
If no tensions exist, return an empty list [].
"""

_STATEMENT_SYSTEM = """You are a macro investment research analyst. Write a 3-5 sentence investment thesis statement from the structured data provided.

Rules:
- First sentence: the core claim and trigger event
- Second sentence: the primary transmission mechanism (how the trigger causes the predicted market moves)
- Third sentence: key supporting evidence from the variable list
- Fourth sentence (if risks present): primary risk to the thesis
- Final sentence: the stated asset expression

Write in clear, precise investment research prose.
No bullet points. No headers. No preamble.
Return only the paragraph, nothing else.
Maximum 120 words."""


def _extract_json_object(text: str) -> Any:
    text = (text or "").strip()
    if not text:
        raise ValueError("empty response")
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass
    fence = re.search(r"```(?:json)?\s*([\s\S]*?)```", text)
    if fence:
        return json.loads(fence.group(1).strip())
    start = text.find("{")
    end = text.rfind("}")
    if start >= 0 and end > start:
        return json.loads(text[start : end + 1])
    start = text.find("[")
    end = text.rfind("]")
    if start >= 0 and end > start:
        return json.loads(text[start : end + 1])
    raise json.JSONDecodeError("no JSON found", text, 0)


def _ollama_generate(prompt: str) -> str:
    payload = {"model": OLLAMA_MODEL, "prompt": prompt, "stream": False}
    r = requests.post(
        OLLAMA_GENERATE_URL,
        json=payload,
        timeout=REQUEST_TIMEOUT_S,
    )
    r.raise_for_status()
    data = r.json()
    return (data.get("response") or "").strip()


def _ollama_generate_statement(*, system: str, user: str, timeout_s: float = 30) -> str:
    payload = {
        "model": OLLAMA_MODEL,
        "prompt": user,
        "system": system,
        "stream": False,
    }
    r = requests.post(
        OLLAMA_GENERATE_URL,
        json=payload,
        timeout=timeout_s,
    )
    r.raise_for_status()
    data = r.json()
    return (data.get("response") or "").strip()


def _fallback_thesis_statement(thesis_data: dict[str, Any]) -> str:
    claim = str(thesis_data.get("claim") or "No claim stated")
    trig = str(thesis_data.get("trigger") or "unspecified")
    shock = thesis_data.get("shock_pct", 0)
    focal = str(thesis_data.get("focal_series_id") or "")
    horizon = str(thesis_data.get("time_horizon") or "")
    expr = str(thesis_data.get("asset_expression") or "none stated")
    return (
        f"{claim}. "
        f"The trigger is {trig}. "
        f"A {shock}% move in {focal} is expected "
        f"over a {horizon} horizon. "
        f"Expression: {expr}."
    )


def _supporting_series_ids(thesis_data: dict[str, Any]) -> str:
    raw = thesis_data.get("supporting")
    if not isinstance(raw, list):
        return ""
    parts: list[str] = []
    for v in raw:
        if isinstance(v, dict):
            sid = v.get("series_id")
            if sid is not None:
                parts.append(str(sid))
    return ", ".join(parts)


def _risk_series_ids(thesis_data: dict[str, Any]) -> str:
    raw = thesis_data.get("risks")
    if not isinstance(raw, list):
        return ""
    parts: list[str] = []
    for v in raw:
        if isinstance(v, dict):
            sid = v.get("series_id")
            if sid is not None:
                parts.append(str(sid))
    return ", ".join(parts)


def generate_thesis_statement(thesis_data: dict[str, Any]) -> tuple[str, bool]:
    """
    Calls Llama to generate a 3-5 sentence thesis statement.

    Returns (statement, llama_available). Statement is always a non-empty string.
    Falls back to a templated string if Ollama is unavailable or the response is too short.
    Never raises.
    """
    if not isinstance(thesis_data, dict):
        thesis_data = {}

    fallback = _fallback_thesis_statement(thesis_data)
    if not (fallback and fallback.strip()):
        fallback = "No thesis data provided."

    user_prompt = (
        f"Claim: {thesis_data.get('claim', '')}\n"
        f"Trigger: {thesis_data.get('trigger', '')}\n"
        f"Focal series: {thesis_data.get('focal_series_id', '')} "
        f"expected move: {thesis_data.get('shock_pct', 0)}%\n"
        f"Time horizon: {thesis_data.get('time_horizon', '')}\n"
        f"Asset expression: {thesis_data.get('asset_expression', '')}\n"
        f"Supporting variables: {_supporting_series_ids(thesis_data)}\n"
        f"Risk variables: {_risk_series_ids(thesis_data)}\n"
    )

    try:
        result = _ollama_generate_statement(
            system=_STATEMENT_SYSTEM,
            user=user_prompt,
            timeout_s=30,
        )
        if result and len(result) > 20:
            return result, True
        return fallback, False
    except Exception as e:
        logger.warning("generate_thesis_statement failed: %s", e)
        return fallback, False


def parse_thesis_input(raw_text: str) -> dict:
    try:
        prompt = _PARSE_SYSTEM + "\n\n" + (raw_text or "")
        response_text = _ollama_generate(prompt)
        parsed = _extract_json_object(response_text)
        if not isinstance(parsed, dict):
            logger.error("parse_thesis_input: expected dict from LLM, got %s", type(parsed))
            return {"parsed": {}, "llama_available": False}
        return {"parsed": parsed, "llama_available": True}
    except Exception:
        logger.exception("parse_thesis_input failed")
        return {"parsed": {}, "llama_available": False}


def generate_transmission(
    focal_series: str,
    target_series: str,
    beta: float,
    shock_pct: float,
    thesis_context: dict,
) -> str:
    try:
        claim = ""
        if isinstance(thesis_context, dict):
            claim = str(thesis_context.get("claim") or "")
        user_prompt = (
            f"Thesis: {claim}\n"
            f"Focal variable: {focal_series} moves {shock_pct}%\n"
            f"Target variable: {target_series} (beta={beta:.2f})\n"
            f"Explain why {target_series} matters for this thesis."
        )
        prompt = _TRANSMISSION_SYSTEM + "\n\n" + user_prompt
        return _ollama_generate(prompt).strip()
    except Exception:
        logger.exception("generate_transmission failed")
        return ""


def detect_tensions(addressed_variables: list[dict]) -> list[dict]:
    try:
        user_block = json.dumps(addressed_variables or [], ensure_ascii=False)
        prompt = _TENSION_SYSTEM + "\n\n" + user_block
        response_text = _ollama_generate(prompt)
        data = _extract_json_object(response_text)
        if not isinstance(data, list):
            logger.error("detect_tensions: expected list from LLM, got %s", type(data))
            return []
        out: list[dict] = []
        for item in data:
            if not isinstance(item, dict):
                continue
            va = item.get("variable_a")
            vb = item.get("variable_b")
            desc = item.get("description")
            if va is not None and vb is not None and desc is not None:
                out.append(
                    {
                        "variable_a": va,
                        "variable_b": vb,
                        "description": desc,
                    }
                )
        return out
    except Exception:
        logger.exception("detect_tensions failed")
        return []
