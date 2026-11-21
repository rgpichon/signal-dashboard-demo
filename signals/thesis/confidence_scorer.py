"""
Compute thesis confidence score programmatically (not by Claude).
Weights: signal_strength 0.35, data_coverage 0.25, correlation_support 0.25, regime_alignment 0.15.
"""
import logging
from typing import Any

logger = logging.getLogger("signals.thesis")

WEIGHTS = {
    "signal_strength": 0.35,
    "data_coverage": 0.25,
    "correlation_support": 0.25,
    "regime_alignment": 0.15,
}


def compute_confidence(
    velocity_7d: Any,
    article_count: int,
    correlations: list,
    regime_supports_direction: Any = None,
) -> tuple[float, str]:
    """
    Return (confidence_score, label).
    confidence_score in [0, 1], rounded to 2 decimals.
    label: LOW (<0.4) | MEDIUM (0.4-0.65) | MEDIUM-HIGH (0.65-0.8) | HIGH (>0.8).
    """
    # signal_strength: min(velocity_7d/3, 1) if not null else 0.3 (cold start)
    if velocity_7d is not None:
        try:
            v = float(velocity_7d)
            signal_strength = min(max(v / 3.0, 0.0), 1.0)
        except (TypeError, ValueError):
            signal_strength = 0.3
    else:
        signal_strength = 0.3

    # data_coverage: min(article_count/10, 1)
    data_coverage = min((article_count or 0) / 10.0, 1.0)

    # correlation_support: mean(|rho|) for significant correlations, 0 if none
    if correlations:
        rhos = [abs(float(c.get("correlation", 0) or 0)) for c in correlations]
        correlation_support = sum(rhos) / len(rhos) if rhos else 0.0
    else:
        correlation_support = 0.0

    # regime_alignment: 1 if supports, 0.5 if INSUFFICIENT_DATA/neutral, 0 if opposed. Default 0.5.
    if regime_supports_direction is True:
        regime_alignment = 1.0
    elif regime_supports_direction is False:
        regime_alignment = 0.0
    else:
        regime_alignment = 0.5

    score = (
        WEIGHTS["signal_strength"] * signal_strength
        + WEIGHTS["data_coverage"] * data_coverage
        + WEIGHTS["correlation_support"] * correlation_support
        + WEIGHTS["regime_alignment"] * regime_alignment
    )
    score = round(min(max(score, 0.0), 1.0), 2)

    if score < 0.4:
        label = "LOW"
    elif score < 0.65:
        label = "MEDIUM"
    elif score <= 0.8:
        label = "MEDIUM-HIGH"
    else:
        label = "HIGH"

    return score, label
