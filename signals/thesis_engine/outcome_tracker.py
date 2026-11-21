"""
Daily path tracking for active theses.
Updates thesis_outcome_paths and rebuilds
thesis_track_record.
Called from scheduler — not from the API layer.
"""

import logging
from datetime import date

logger = logging.getLogger("signals.thesis_engine")

HORIZON_MAP = {
    "short": 90,
    "medium": 270,
    "long": 540,
}

ASSET_CLASS_PREFIX = {
    "EQ.": "equity",
    "CM.": "commodity",
    "FX.": "fx",
    "RATES.": "rates",
    "CREDIT.": "credit",
    "MACRO.": "macro",
}


def _infer_asset_class(series_id: str) -> str:
    for prefix, cls in ASSET_CLASS_PREFIX.items():
        if series_id.startswith(prefix):
            return cls
    return "other"


def _predicted_direction(pct: float) -> str:
    if pct is None:
        return "neutral"
    if pct > 0.5:
        return "up"
    if pct < -0.5:
        return "down"
    return "neutral"


def get_active_theses_for_tracking(conn) -> list:
    """
    Returns all research_theses where engine_version
    is set and addressed array is non-empty.
    """
    cur = conn.cursor()
    try:
        cur.execute(
            """
            SELECT id, created_at,
                   metadata->>'focal_series_id'
                     as focal,
                   metadata->>'time_horizon'
                     as time_horizon,
                   metadata->'addressed'
                     as addressed
            FROM research_theses
            WHERE
              metadata->>'engine_version'
                IS NOT NULL
              AND jsonb_array_length(
                COALESCE(
                  metadata->'addressed',
                  '[]'::jsonb
                )
              ) > 0
            ORDER BY created_at DESC
            """
        )
        rows = cur.fetchall()
        result = []
        for row in rows:
            import json

            addressed = row[4]
            if isinstance(addressed, str):
                addressed = json.loads(addressed)
            if not addressed:
                continue
            result.append(
                {
                    "id": str(row[0]),
                    "created_at": row[1],
                    "focal": row[2],
                    "time_horizon": row[3] or "medium",
                    "addressed": addressed,
                }
            )
        return result
    finally:
        cur.close()


def get_or_create_outcome_paths(conn, thesis: dict) -> None:
    """
    For each addressed variable with a non-null
    predicted_move_pct: INSERT if not already present.
    Uses ON CONFLICT DO NOTHING.
    """
    cur = conn.cursor()
    try:
        horizon_days = HORIZON_MAP.get(thesis["time_horizon"], 270)

        for var in thesis["addressed"]:
            series_id = var.get("series_id")
            predicted = var.get("predicted_move_pct")
            if not series_id or predicted is None:
                continue

            direction = _predicted_direction(predicted)

            cur.execute(
                """
                INSERT INTO thesis_outcome_paths
                  (thesis_id, series_id,
                   predicted_move_pct,
                   predicted_direction,
                   horizon_days,
                   thesis_created_at,
                   status)
                VALUES
                  (%s, %s, %s, %s, %s, %s, 'active')
                ON CONFLICT (thesis_id, series_id)
                DO NOTHING
                """,
                (
                    thesis["id"],
                    series_id,
                    predicted,
                    direction,
                    horizon_days,
                    thesis["created_at"],
                ),
            )
        conn.commit()
    finally:
        cur.close()


def update_path_records(conn, thesis: dict) -> int:
    """
    For each active path row for this thesis:
    1. Get price at thesis_created_at and today
    2. Compute current_move_pct
    3. Update max_favourable / max_adverse from
       full price history between creation and today
    4. Set milestone flags (never unset once set)
    5. Set target_reached if 90% of predicted achieved
    6. Set status='completed' if past horizon

    Returns count of rows updated.
    """
    from signals.research.data import get_aligned_returns

    cur = conn.cursor()
    updated = 0

    try:
        cur.execute(
            """
            SELECT id, series_id,
                   predicted_move_pct,
                   predicted_direction,
                   horizon_days,
                   thesis_created_at,
                   correct_at_30pct,
                   correct_at_60pct,
                   correct_at_100pct,
                   target_reached,
                   status
            FROM thesis_outcome_paths
            WHERE thesis_id = %s
              AND status = 'active'
            """,
            (thesis["id"],),
        )
        paths = cur.fetchall()

        today = date.today()

        for path in paths:
            (
                path_id,
                series_id,
                predicted,
                direction,
                horizon_days,
                thesis_created_at,
                c30,
                c60,
                c100,
                target_reached,
                status,
            ) = path

            try:
                created_date = (
                    thesis_created_at.date()
                    if hasattr(thesis_created_at, "date")
                    else thesis_created_at
                )
                days_elapsed = (today - created_date).days

                lookback = days_elapsed + 5
                if lookback < 5:
                    continue

                df = get_aligned_returns(conn, [series_id], min(lookback, 365))
                if df is None or df.empty:
                    continue
                df = df.dropna()
                if len(df) < 2:
                    continue

                price_baseline = float(df.iloc[0][series_id])
                price_today = float(df.iloc[-1][series_id])

                if price_baseline == 0:
                    continue

                # Note: get_aligned_returns returns pct_chg not prices.
                # Fetch prices directly instead.
                cur2 = conn.cursor()
                cur2.execute(
                    """
                    SELECT date, value
                    FROM market_data
                    WHERE series_id = %s
                      AND date >= %s
                      AND date <= %s
                      AND value IS NOT NULL
                    ORDER BY date ASC
                    """,
                    (series_id, created_date, today),
                )
                price_rows = cur2.fetchall()
                cur2.close()

                if len(price_rows) < 2:
                    continue

                p_start = float(price_rows[0][1])
                p_end = float(price_rows[-1][1])
                if p_start == 0:
                    continue

                current_move = ((p_end / p_start) - 1) * 100

                all_moves = [
                    ((float(r[1]) / p_start) - 1) * 100
                    for r in price_rows
                    if float(r[1]) and p_start
                ]

                if direction == "up":
                    max_fav = max(all_moves)
                    max_adv = min(all_moves)
                elif direction == "down":
                    max_fav = min(all_moves)
                    max_adv = max(all_moves)
                else:
                    max_fav = max(all_moves, key=abs)
                    max_adv = 0.0

                def dir_correct(move, pred_dir):
                    if pred_dir == "up":
                        return move > 0
                    if pred_dir == "down":
                        return move < 0
                    return True

                correct = dir_correct(current_move, direction)

                new_c30 = c30
                new_c60 = c60
                new_c100 = c100

                if new_c30 is None and horizon_days and days_elapsed >= (horizon_days * 0.30):
                    new_c30 = correct

                if new_c60 is None and horizon_days and days_elapsed >= (horizon_days * 0.60):
                    new_c60 = correct

                if new_c100 is None and horizon_days and days_elapsed >= (horizon_days * 1.0):
                    new_c100 = correct

                new_target_reached = target_reached
                new_target_at = None
                if (not target_reached) and predicted is not None and predicted != 0:
                    if direction == "up":
                        hit = current_move >= (predicted * 0.90)
                    elif direction == "down":
                        hit = current_move <= (predicted * 0.90)
                    else:
                        hit = False
                    if hit:
                        new_target_reached = True
                        new_target_at = today

                new_status = status
                if horizon_days and days_elapsed >= horizon_days:
                    new_status = "completed"

                cur.execute(
                    """
                    UPDATE thesis_outcome_paths
                    SET
                      current_move_pct   = %s,
                      max_favourable_pct = %s,
                      max_adverse_pct    = %s,
                      correct_at_30pct   = %s,
                      correct_at_60pct   = %s,
                      correct_at_100pct  = %s,
                      target_reached     = %s,
                      target_reached_at  = %s,
                      status             = %s,
                      last_updated       = NOW()
                    WHERE id = %s
                    """,
                    (
                        round(current_move, 2),
                        round(max_fav, 2),
                        round(max_adv, 2),
                        new_c30,
                        new_c60,
                        new_c100,
                        new_target_reached,
                        new_target_at,
                        new_status,
                        path_id,
                    ),
                )
                updated += 1

            except Exception as e:
                logger.warning(
                    "update_path_records row failed %s/%s: %s",
                    thesis["id"],
                    series_id,
                    e,
                )
                continue

        conn.commit()
        return updated

    finally:
        cur.close()


def rebuild_track_record(conn) -> None:
    """
    Reads all completed thesis_outcome_paths,
    computes aggregate statistics, and rebuilds
    thesis_track_record with one new row.
    Only uses rows with status = 'completed'.
    """
    import json

    cur = conn.cursor()
    try:
        cur.execute(
            """
            SELECT
              p.series_id,
              p.predicted_move_pct,
              p.current_move_pct,
              p.correct_at_30pct,
              p.correct_at_60pct,
              p.correct_at_100pct,
              p.thesis_id
            FROM thesis_outcome_paths p
            WHERE p.status = 'completed'
              AND p.predicted_move_pct IS NOT NULL
              AND p.current_move_pct IS NOT NULL
            """
        )
        rows = cur.fetchall()

        if not rows:
            logger.info("rebuild_track_record: no completed paths yet")
            return

        total_vars = len(rows)
        thesis_ids = set(str(r[6]) for r in rows)
        total_theses = len(thesis_ids)

        def acc(flag_idx):
            valid = [r for r in rows if r[flag_idx] is not None]
            if not valid:
                return None
            return round(sum(1 for r in valid if r[flag_idx]) / len(valid), 3)

        acc_30 = acc(3)
        acc_60 = acc(4)
        acc_100 = acc(5)

        ratios = []
        for r in rows:
            pred = r[1]
            actual = r[2]
            if pred and pred != 0 and actual is not None:
                ratios.append(actual / pred)

        if ratios:
            ratios_sorted = sorted(ratios)
            n = len(ratios_sorted)
            avg_ratio = round(sum(ratios) / n, 3)
            p25 = round(ratios_sorted[int(0.25 * n)], 3)
            p75 = round(ratios_sorted[int(0.75 * n)], 3)
        else:
            avg_ratio = p25 = p75 = None

        by_class = {}
        for r in rows:
            cls = _infer_asset_class(r[0])
            if cls not in by_class:
                by_class[cls] = {"n": 0, "correct_60": [], "ratios": []}
            by_class[cls]["n"] += 1
            if r[4] is not None:
                by_class[cls]["correct_60"].append(r[4])
            if r[1] and r[1] != 0 and r[2] is not None:
                by_class[cls]["ratios"].append(r[2] / r[1])

        by_class_out = {}
        for cls, d in by_class.items():
            c60 = d["correct_60"]
            rat = d["ratios"]
            by_class_out[cls] = {
                "n": d["n"],
                "dir_acc_60": round(sum(c60) / len(c60), 3) if c60 else None,
                "avg_magnitude_ratio": round(sum(rat) / len(rat), 3) if rat else None,
            }

        cur.execute(
            """
            INSERT INTO thesis_track_record (
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
            ) VALUES (
                NOW(), %s, %s, %s, %s, %s,
                %s, %s, %s, %s, %s
            )
            """,
            (
                total_theses,
                total_vars,
                acc_30,
                acc_60,
                acc_100,
                avg_ratio,
                p25,
                p75,
                json.dumps(by_class_out),
                json.dumps({}),
            ),
        )
        conn.commit()
        logger.info(
            "rebuild_track_record: %d theses, %d variables",
            total_theses,
            total_vars,
        )

    finally:
        cur.close()


def run_path_tracking(conn) -> dict:
    """
    Main entry point for the daily job.
    1. Get active theses
    2. For each: create missing paths, update records
    3. Rebuild track record
    Returns summary dict.
    """
    try:
        theses = get_active_theses_for_tracking(conn)
        logger.info("run_path_tracking: found %d active theses", len(theses))

        total_paths = 0
        for thesis in theses:
            try:
                get_or_create_outcome_paths(conn, thesis)
                n = update_path_records(conn, thesis)
                total_paths += n
            except Exception as e:
                logger.warning("run_path_tracking thesis %s failed: %s", thesis["id"], e)
                continue

        rebuild_track_record(conn)

        return {"theses_processed": len(theses), "paths_updated": total_paths}

    except Exception as e:
        logger.error("run_path_tracking failed: %s", e)
        return {"theses_processed": 0, "paths_updated": 0, "error": str(e)}
