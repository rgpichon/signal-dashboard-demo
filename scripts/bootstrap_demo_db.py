#!/usr/bin/env python3
"""Apply demo_data/seed.sql when the DB has no instruments (public demo boot).

Supports pg_dump format including COPY ... FROM stdin (psql if present,
otherwise a psycopg2 COPY-aware loader).
"""
from __future__ import annotations

import io
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SEED = ROOT / "demo_data" / "seed.sql"


def _normalize_url(url: str) -> str:
    if url.startswith("postgres://"):
        url = "postgresql://" + url[len("postgres://") :]
    if "sslmode=" not in url and ("render.com" in url or "amazonaws.com" in url):
        url += ("&" if "?" in url else "?") + "sslmode=require"
    return url


def _instrument_count() -> int:
    from signals.db.connection import get_connection

    with get_connection() as conn:
        cur = conn.cursor()
        cur.execute(
            "SELECT COUNT(*) FROM information_schema.tables "
            "WHERE table_schema='public' AND table_name='instruments'"
        )
        has_table = cur.fetchone()[0] > 0
        n = 0
        if has_table:
            cur.execute("SELECT COUNT(*) FROM instruments")
            n = cur.fetchone()[0]
        cur.close()
    return n


def _apply_with_psql(url: str) -> None:
    print("[bootstrap] applying seed via psql …")
    subprocess.check_call(
        ["psql", url, "-v", "ON_ERROR_STOP=1", "-f", str(SEED)]
    )


def _is_comment_or_empty(stmt: str) -> bool:
    for line in stmt.splitlines():
        s = line.strip()
        if not s:
            continue
        if s.startswith("--"):
            continue
        return False
    return True


def _exec_ddl(cur, text: str) -> None:
    buf: list[str] = []
    for line in text.splitlines(True):
        buf.append(line)
        if line.rstrip().endswith(";"):
            stmt = "".join(buf).strip()
            buf = []
            if not stmt or _is_comment_or_empty(stmt):
                continue
            cur.execute(stmt)
    tail = "".join(buf).strip()
    if tail and not _is_comment_or_empty(tail):
        cur.execute(tail)


def _apply_with_psycopg2(url: str) -> None:
    import psycopg2

    print("[bootstrap] applying seed via psycopg2 (COPY-aware) …")
    lines = SEED.read_text().splitlines(keepends=True)
    conn = psycopg2.connect(url)
    try:
        cur = conn.cursor()
        buf: list[str] = []
        i = 0
        while i < len(lines):
            line = lines[i]
            if line.startswith("COPY ") and line.rstrip().endswith("FROM stdin;"):
                if buf:
                    _exec_ddl(cur, "".join(buf))
                    buf = []
                copy_sql = line
                i += 1
                data = io.StringIO()
                while i < len(lines):
                    if lines[i].rstrip("\r\n") == "\\.":
                        i += 1
                        break
                    data.write(lines[i])
                    i += 1
                data.seek(0)
                cur.copy_expert(copy_sql, data)
                continue
            buf.append(line)
            i += 1
        if buf:
            _exec_ddl(cur, "".join(buf))
        conn.commit()
        cur.close()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def main() -> int:
    sys.path.insert(0, str(ROOT))
    os.chdir(ROOT)

    if not SEED.is_file():
        print(f"[bootstrap] missing seed file: {SEED}", file=sys.stderr)
        return 1

    from signals.db.connection import get_database_url

    url = _normalize_url(get_database_url())
    os.environ["DATABASE_URL"] = url

    try:
        n = _instrument_count()
    except Exception as e:
        print(f"[bootstrap] DB not ready yet ({e}); will try seed anyway")
        n = 0

    if n > 0:
        print(f"[bootstrap] instruments={n} — skip seed")
        return 0

    try:
        if shutil.which("psql"):
            _apply_with_psql(url)
        else:
            _apply_with_psycopg2(url)
    except Exception as e:
        print(f"[bootstrap] seed failed: {e}", file=sys.stderr)
        return 1

    print("[bootstrap] seed applied")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
