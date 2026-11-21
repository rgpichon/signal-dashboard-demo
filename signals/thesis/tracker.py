"""
Daily job: check active theses for timeframe expiry; optionally invalidation from market_data.
Set status='expired' and closed_at when timeframe has passed. Log summary.
"""
import logging
import re
from datetime import datetime, timezone, timedelta
from typing import Optional

logger = logging.getLogger("signals.thesis")


def _parse_timeframe_from_doc(full_doc: str) -> Optional[int]:
    """
    Heuristic: look for 'timeframe=X weeks/months/quarters' or 'X-week' etc.
    Return approximate days, or None if not found.
    """
    if not full_doc:
        return None
    text = full_doc.upper()
    # e.g. "timeframe=3 months" or "3-month" or "2 weeks"
    m = re.search(r"(\d+)\s*WEEK", text)
    if m:
        return int(m.group(1)) * 7
    m = re.search(r"(\d+)\s*MONTH", text)
    if m:
        return int(m.group(1)) * 30
    m = re.search(r"(\d+)\s*QUARTER", text)
    if m:
        return int(m.group(1)) * 90
    return None


def run_tracker(conn) -> tuple:
    """
    For each thesis with status='active': check timeframe expiry.
    Returns (checked_count, expired_count, invalidated_count).
    """
    cur = conn.cursor()
    cur.execute("SELECT id, thesis_id, generated_at, full_doc FROM theses WHERE status = 'active'")
    rows = cur.fetchall()
    cur.close()

    checked = len(rows)
    expired = 0
    invalidated = 0

    now = datetime.now(timezone.utc)
    for (tid, thesis_id, generated_at, full_doc) in rows:
        if not generated_at:
            continue
        if generated_at.tzinfo is None:
            generated_at = generated_at.replace(tzinfo=timezone.utc)
        days_ago = (now - generated_at).days
        max_days = _parse_timeframe_from_doc(full_doc or "")
        if max_days is not None and days_ago >= max_days:
            cur = conn.cursor()
            try:
                cur.execute(
                    "UPDATE theses SET status = 'expired', closed_at = %s WHERE id = %s",
                    (now, tid),
                )
                conn.commit()
                if cur.rowcount:
                    expired += 1
                    logger.info("Thesis %s expired (timeframe %s days, %s days ago)", thesis_id, max_days, days_ago)
            finally:
                cur.close()
        # Invalidation from market_data: skip for MVP (full outcome tracking post-MVP)

    logger.info("Tracker: %s active theses checked, %s expired, %s invalidated", checked, expired, invalidated)
    return checked, expired, invalidated
