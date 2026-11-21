"""
Call Anthropic API to generate thesis. Read config from thesis_prompt.yaml.
Retry with exponential backoff; parse response into schema; write to theses table.
"""
import json
import logging
import os
import re
import sys
import time
from pathlib import Path
from typing import Any, Optional

import yaml

logger = logging.getLogger("signals.thesis")

CONFIG_PATH = Path(__file__).resolve().parent.parent / "config" / "thesis_prompt.yaml"
MANDATORY_FIELDS = [
    "THESIS_ID", "TITLE", "THEME_CLUSTER", "MACRO_CONTEXT", "HYPOTHESIS",
    "SIGNAL_EVIDENCE", "PRIMARY_INSTRUMENT", "ALTERNATIVE_INSTRUMENTS",
    "INSTRUMENTS_TO_AVOID", "SIZING_FRAMEWORK", "INVALIDATION",
    "MONITORING", "HISTORICAL_ANALOG",
]


def _load_config() -> dict:
    with open(CONFIG_PATH, "r") as f:
        return yaml.safe_load(f)


def _parse_labeled_response(text: str) -> dict:
    """Parse the labeled response (KEY: value or KEY: multi-line) into a dict."""
    out = {}
    current_key = None
    current_lines = []
    for line in text.split("\n"):
        if not line.strip():
            if current_key:
                out[current_key] = "\n".join(current_lines).strip()
                current_key = None
                current_lines = []
            continue
        if ":" in line and re.match(r"^[A-Z_][A-Z0-9_]*:", line):
            if current_key:
                out[current_key] = "\n".join(current_lines).strip()
            key, _, rest = line.partition(":")
            current_key = key.strip()
            current_lines = [rest.strip()] if rest.strip() else []
        elif current_key:
            current_lines.append(line.strip())
    if current_key:
        out[current_key] = "\n".join(current_lines).strip()
    return out


def _extract_primary_instrument(block: str) -> dict:
    """Parse PRIMARY_INSTRUMENT block into dict."""
    d = {}
    for part in (block or "").split("|"):
        part = part.strip()
        if "=" in part:
            k, _, v = part.partition("=")
            d[k.strip().lower()] = v.strip()
    return d


def _extract_alternatives(block: str) -> list:
    """Parse ALTERNATIVE_INSTRUMENTS / INSTRUMENTS_TO_AVOID lines."""
    items = []
    for line in (block or "").strip().split("\n"):
        line = line.strip()
        if line.startswith("-"):
            line = line[1:].strip()
        if not line:
            continue
        d = {}
        for part in line.split("|"):
            part = part.strip()
            if "=" in part:
                k, _, v = part.partition("=")
                d[k.strip().lower()] = v.strip()
        if d:
            items.append(d)
    return items


def generate_thesis(context: dict, thesis_id: str, skip_store: bool = False) -> Optional[dict]:
    """
    Call Claude with context; parse response; validate; write to theses table.
    Returns thesis dict with full_doc, hypothesis, instruments, etc., or None on failure.
    """
    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        logger.error("ANTHROPIC_API_KEY not set")
        return None

    config = _load_config()
    model = config.get("model", "claude-sonnet-4-20250514")
    temperature = config.get("temperature", 0.3)
    max_tokens = config.get("max_tokens", 2000)
    system_prompt = config.get("system_prompt", "")
    user_template = config.get("user_prompt_template", "")

    context_json = json.dumps(context, indent=2)
    user_prompt = user_template.replace("{context_json}", context_json).replace("{thesis_id}", thesis_id)

    last_error = None
    for attempt in range(3):
        try:
            from anthropic import Anthropic
            client = Anthropic(api_key=api_key)
            resp = client.messages.create(
                model=model,
                max_tokens=max_tokens,
                system=system_prompt,
                messages=[{"role": "user", "content": user_prompt}],
                temperature=temperature,
            )
            text = resp.content[0].text if resp.content else ""
            break
        except Exception as e:
            last_error = e
            delay = 2 ** (attempt + 1)
            logger.warning("Claude API attempt %s failed: %s; retry in %ss", attempt + 1, e, delay)
            time.sleep(delay)
    else:
        logger.exception("Claude API failed after 3 retries: %s", last_error)
        return None

    parsed = _parse_labeled_response(text)
    for field in MANDATORY_FIELDS:
        if field not in parsed or not str(parsed.get(field, "")).strip():
            logger.warning("Thesis response missing or empty field: %s", field)

    full_doc = text
    theme = parsed.get("THEME_CLUSTER", "").strip()
    hypothesis = parsed.get("HYPOTHESIS", "").strip()
    primary = _extract_primary_instrument(parsed.get("PRIMARY_INSTRUMENT", ""))
    alternatives = _extract_alternatives(parsed.get("ALTERNATIVE_INSTRUMENTS", ""))
    instruments = {"primary": primary, "alternatives": alternatives}
    signals_used = []  # optional: list of signal IDs we passed

    # Store in DB (unless skip_store e.g. for --mock without DB)
    if not skip_store:
        try:
            from signals.db.connection import get_connection
            from datetime import datetime, timezone
            with get_connection() as conn:
                cur = conn.cursor()
                cur.execute("""
                    INSERT INTO theses (
                        thesis_id, generated_at, theme, hypothesis, full_doc,
                        instruments, signals_used, confidence, status
                    ) VALUES (%s, %s, %s, %s, %s, %s::jsonb, %s::jsonb, %s, 'active')
                """, (
                    thesis_id,
                    datetime.now(timezone.utc),
                    theme,
                    hypothesis,
                    full_doc,
                    json.dumps(instruments),
                    json.dumps(signals_used),
                    context.get("_confidence_score") if context.get("_confidence_score") is not None else 0.0,
                ))
                conn.commit()
                cur.close()
        except Exception as e:
            logger.exception("Failed to store thesis: %s", e)
            return None

    return {
        "thesis_id": thesis_id,
        "theme": theme,
        "hypothesis": hypothesis,
        "full_doc": full_doc,
        "instruments": instruments,
        "confidence": context.get("_confidence_score"),
        "confidence_label": context.get("_confidence_label"),
    }


def run_mock() -> None:
    """Load mock context, call Claude, print result. No DB for context (mock context only); still writes to theses if API key set."""
    from signals.thesis.context_assembler import load_mock_context
    from signals.thesis.confidence_scorer import compute_confidence
    ctx = load_mock_context()
    # Add synthetic candidate fields for confidence
    ctx["_confidence_score"], ctx["_confidence_label"] = compute_confidence(
        velocity_7d=None,
        article_count=5,
        correlations=ctx.get("correlations", []),
        regime_supports_direction=None,
    )
    thesis_id = "TH-MOCK-001"
    result = generate_thesis(ctx, thesis_id, skip_store=True)
    if result:
        print("--- Generated thesis (full_doc) ---")
        print(result.get("full_doc", ""))
        print("--- Confidence: %s (%s) ---" % (result.get("confidence"), result.get("confidence_label")))
    else:
        print("Thesis generation failed.")
        sys.exit(1)


if __name__ == "__main__":
    from pathlib import Path
    try:
        from dotenv import load_dotenv
        _pkg = Path(__file__).resolve().parent.parent
        load_dotenv(_pkg / ".env")
    except Exception:
        pass
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    if "--mock" in sys.argv:
        run_mock()
    else:
        print("Use --mock to run with fixtures/mock_context.json")
        sys.exit(0)
