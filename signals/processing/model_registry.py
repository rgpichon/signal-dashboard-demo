"""
Singleton model registry. Loads FinBERT, zero-shot classifier (MiniLM2 or ZERO_SHOT_MODEL), and SpaCy once at startup.
If a model fails to load, it is set to None; downstream code must skip gracefully.
"""
import logging
import os
import time
from typing import Any, Optional

logger = logging.getLogger("signals.processing")

_finbert = None
_zero_shot_classifier = None
_spacy_nlp = None


def get_finbert() -> Optional[Any]:
    """Return loaded FinBERT pipeline or None if unavailable."""
    global _finbert
    if _finbert is not None:
        return _finbert
    try:
        t0 = time.perf_counter()
        from transformers import pipeline
        _finbert = pipeline(
            "sentiment-analysis",
            model="ProsusAI/finbert",
            tokenizer="ProsusAI/finbert",
        )
        elapsed = time.perf_counter() - t0
        logger.info("Loaded FinBERT in %.1fs", elapsed)
        return _finbert
    except Exception as e:
        logger.exception("FinBERT load failed: %s", e)
        _finbert = None
        return None


def get_zero_shot_classifier() -> Optional[Any]:
    """Return loaded zero-shot classification pipeline (~90MB MiniLM2 by default) or None if unavailable."""
    global _zero_shot_classifier
    if _zero_shot_classifier is not None:
        return _zero_shot_classifier
    model_name = os.environ.get("ZERO_SHOT_MODEL", "cross-encoder/nli-MiniLM2-L6-H768")
    try:
        t0 = time.perf_counter()
        from transformers import pipeline
        _zero_shot_classifier = pipeline(
            "zero-shot-classification",
            model=model_name,
            device=-1,
        )
        elapsed = time.perf_counter() - t0
        logger.info("Loaded zero-shot %s in %.1fs", model_name, elapsed)
        return _zero_shot_classifier
    except Exception as e:
        logger.exception("Zero-shot model %s load failed: %s", model_name, e)
        _zero_shot_classifier = None
        return None


def get_spacy() -> Optional[Any]:
    """Return loaded SpaCy nlp (en_core_web_sm or en_core_web_trf) or None."""
    global _spacy_nlp
    if _spacy_nlp is not None:
        return _spacy_nlp
    # Load in subprocess to avoid multiprocessing/signal issues in some envs
    for model_name in ("en_core_web_sm", "en_core_web_trf"):
        try:
            t0 = time.perf_counter()
            import spacy
            # Disable parser/lemmatizer to reduce memory (we only need NER + tok2vec)
            _spacy_nlp = spacy.load(model_name, exclude=["tagger", "parser", "lemmatizer", "attribute_ruler"])
            elapsed = time.perf_counter() - t0
            logger.info("Loaded SpaCy %s in %.1fs", model_name, elapsed)
            if model_name == "en_core_web_sm":
                logger.info("Using en_core_web_sm (dev fallback); upgrade to en_core_web_trf in prod")
            return _spacy_nlp
        except Exception as e:
            logger.warning("SpaCy %s load failed: %s", model_name, e)
            _spacy_nlp = None
            continue
    logger.exception("No SpaCy model available")
    return None
