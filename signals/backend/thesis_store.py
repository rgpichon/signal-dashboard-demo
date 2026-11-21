import json
from datetime import datetime, timezone
from typing import Any

from signals.db.connection import get_connection


def _row_to_thesis(row: tuple, cols: list[str]) -> dict[str, Any]:
    d = dict(zip(cols, row))
    # Normalize JSONB coming back as str in some drivers
    if "metadata" in d and not isinstance(d["metadata"], dict):
        try:
            d["metadata"] = json.loads(d["metadata"] or "{}")
        except Exception:
            d["metadata"] = {}
    if "canvas_layout" in d and d["canvas_layout"] is not None and not isinstance(d["canvas_layout"], dict):
        try:
            d["canvas_layout"] = json.loads(d["canvas_layout"])
        except Exception:
            d["canvas_layout"] = None
    # Normalize UUID to string
    if d.get("id") is not None:
        d["id"] = str(d["id"])
    if d.get("created_at") is not None and hasattr(d["created_at"], "isoformat"):
        d["created_at"] = d["created_at"].isoformat()
    if d.get("updated_at") is not None and hasattr(d["updated_at"], "isoformat"):
        d["updated_at"] = d["updated_at"].isoformat()
    if d.get("last_auto_saved") is not None and hasattr(d["last_auto_saved"], "isoformat"):
        d["last_auto_saved"] = d["last_auto_saved"].isoformat()
    # tags may come back as list/tuple already
    if "tags" in d and d["tags"] is None:
        d["tags"] = []
    return d


def _row_to_version(row: tuple, cols: list[str]) -> dict[str, Any]:
    d = dict(zip(cols, row))
    if d.get("id") is not None:
        d["id"] = str(d["id"])
    if d.get("thesis_id") is not None:
        d["thesis_id"] = str(d["thesis_id"])
    if "metadata" in d and not isinstance(d["metadata"], dict):
        try:
            d["metadata"] = json.loads(d["metadata"] or "{}")
        except Exception:
            d["metadata"] = {}
    if "canvas_layout" in d and d["canvas_layout"] is not None and not isinstance(d["canvas_layout"], dict):
        try:
            d["canvas_layout"] = json.loads(d["canvas_layout"])
        except Exception:
            d["canvas_layout"] = None
    if "tags" in d and d["tags"] is None:
        d["tags"] = []
    if d.get("created_at") is not None and hasattr(d["created_at"], "isoformat"):
        d["created_at"] = d["created_at"].isoformat()
    return d


def create_thesis(title: str = "Untitled Thesis") -> dict[str, Any]:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO research_theses (title, content_html, tags, status, metadata)
                VALUES (%s, %s, %s, %s, %s)
                RETURNING id, title, content_html, tags, status,
                          created_at, updated_at, last_auto_saved, metadata, canvas_layout
                """,
                (title or "Untitled Thesis", "", [], "draft", json.dumps({})),
            )
            row = cur.fetchone()
            cols = [d[0] for d in cur.description]
    return _row_to_thesis(row, cols)


def get_thesis(thesis_id: str) -> dict[str, Any] | None:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT id, title, content_html, tags, status,
                       created_at, updated_at, last_auto_saved, metadata, canvas_layout
                FROM research_theses
                WHERE id = %s
                """,
                (thesis_id,),
            )
            row = cur.fetchone()
            if not row:
                return None
            cols = [d[0] for d in cur.description]
    return _row_to_thesis(row, cols)


def list_theses(status: str | None = None, tag: str | None = None) -> list[dict[str, Any]]:
    conditions = []
    params: list[Any] = []
    if status:
        conditions.append("status = %s")
        params.append(status)
    if tag:
        conditions.append("%s = ANY(tags)")
        params.append(tag)
    where = ("WHERE " + " AND ".join(conditions)) if conditions else ""
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                f"""
                SELECT id, title, content_html, tags, status,
                       created_at, updated_at, last_auto_saved, metadata, canvas_layout
                FROM research_theses
                {where}
                ORDER BY updated_at DESC
                """,
                params,
            )
            rows = cur.fetchall()
            cols = [d[0] for d in cur.description]
    return [_row_to_thesis(r, cols) for r in rows]


def update_thesis(
    thesis_id: str,
    title: str | None = None,
    content_html: str | None = None,
    tags: list | None = None,
    status: str | None = None,
    metadata: dict | None = None,
    canvas_layout: dict | None = None,
    is_auto_save: bool = False,
) -> dict[str, Any] | None:
    fields = ["updated_at = NOW()"]
    params: list[Any] = []
    if title is not None:
        fields.append("title = %s")
        params.append(title)
    if content_html is not None:
        fields.append("content_html = %s")
        params.append(content_html)
    if tags is not None:
        fields.append("tags = %s")
        params.append(tags)
    if status is not None:
        fields.append("status = %s")
        params.append(status)
    if metadata is not None:
        fields.append("metadata = %s")
        params.append(json.dumps(metadata))
    if canvas_layout is not None:
        fields.append("canvas_layout = %s")
        params.append(json.dumps(canvas_layout))
    if is_auto_save:
        fields.append("last_auto_saved = NOW()")
    params.append(thesis_id)
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                f"""
                UPDATE research_theses
                SET {', '.join(fields)}
                WHERE id = %s
                RETURNING id, title, content_html, tags, status,
                          created_at, updated_at, last_auto_saved, metadata, canvas_layout
                """,
                params,
            )
            row = cur.fetchone()
            if not row:
                return None
            cols = [d[0] for d in cur.description]
    return _row_to_thesis(row, cols)


def delete_thesis(thesis_id: str) -> bool:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute("DELETE FROM research_theses WHERE id = %s", (thesis_id,))
            return cur.rowcount > 0


def create_version(
    thesis_id: str,
    version_label: str | None = None,
    is_auto_save: bool = False,
) -> dict[str, Any] | None:
    thesis = get_thesis(thesis_id)
    if not thesis:
        return None

    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT COALESCE(MAX(version_number), 0) + 1
                FROM research_thesis_versions
                WHERE thesis_id = %s
                """,
                (thesis_id,),
            )
            next_version = cur.fetchone()[0]
            cur.execute(
                """
                INSERT INTO research_thesis_versions
                    (thesis_id, version_number, version_label, content_html,
                     metadata, canvas_layout, tags, status, is_auto_save, created_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, NOW())
                RETURNING id, thesis_id, version_number, version_label,
                          content_html, metadata, canvas_layout, tags, status,
                          created_at, created_by, is_auto_save
                """,
                (
                    thesis_id,
                    next_version,
                    version_label,
                    thesis.get("content_html") or "",
                    json.dumps(thesis.get("metadata") or {}),
                    json.dumps(thesis.get("canvas_layout")) if thesis.get("canvas_layout") is not None else None,
                    thesis.get("tags") or [],
                    thesis.get("status") or "draft",
                    bool(is_auto_save),
                ),
            )
            row = cur.fetchone()
            cols = [d[0] for d in cur.description]
    return _row_to_version(row, cols)


def list_versions(thesis_id: str, include_auto_saves: bool = False) -> list[dict[str, Any]]:
    extra = "" if include_auto_saves else "AND is_auto_save = FALSE"
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                f"""
                SELECT id, thesis_id, version_number, version_label,
                       content_html, metadata, canvas_layout, tags, status,
                       created_at, created_by, is_auto_save
                FROM research_thesis_versions
                WHERE thesis_id = %s {extra}
                ORDER BY version_number DESC
                """,
                (thesis_id,),
            )
            rows = cur.fetchall()
            cols = [d[0] for d in cur.description]
    return [_row_to_version(r, cols) for r in rows]


def restore_version(thesis_id: str, version_id: str) -> dict[str, Any] | None:
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT content_html, metadata, tags, status
                FROM research_thesis_versions
                WHERE id = %s AND thesis_id = %s
                """,
                (version_id, thesis_id),
            )
            row = cur.fetchone()
            if not row:
                return None

    # Pre-restore snapshot (auto-save)
    create_version(thesis_id, version_label="Pre-restore snapshot", is_auto_save=True)

    content_html, metadata, canvas_layout, tags, status = row[0], row[1], row[2], row[3], row[4]
    if not isinstance(metadata, dict):
        try:
            metadata = json.loads(metadata or "{}")
        except Exception:
            metadata = {}

    return update_thesis(
        thesis_id,
        content_html=content_html,
        metadata=metadata,
        canvas_layout=canvas_layout,
        tags=list(tags) if tags is not None else [],
        status=status,
        is_auto_save=True,
    )

