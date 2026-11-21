"""
Shared database connection context manager.
All pipeline layers use this module; never open raw psycopg2 connections in adapters.
"""
import os
from contextlib import contextmanager
from typing import Generator

import psycopg2
from psycopg2.extensions import connection as Connection

# Load .env if present (e.g. for DATABASE_URL). Prefer signals/.env when running from repo root.
try:
    from pathlib import Path
    from dotenv import load_dotenv
    load_dotenv()
    _pkg_dir = Path(__file__).resolve().parent.parent
    load_dotenv(_pkg_dir / ".env")
except ImportError:
    pass


def get_database_url() -> str:
    """Build connection string from env. Prefer DATABASE_URL; fallback to components."""
    url = os.environ.get("DATABASE_URL")
    if url:
        # Render / Heroku style URLs
        if url.startswith("postgres://"):
            url = "postgresql://" + url[len("postgres://") :]
        if "sslmode=" not in url and (
            "render.com" in url or "amazonaws.com" in url
        ):
            url += ("&" if "?" in url else "?") + "sslmode=require"
        return url
    host = os.environ.get("PGHOST", "localhost")
    port = os.environ.get("PGPORT", "5432")
    dbname = os.environ.get("PGDATABASE", "signal")
    user = os.environ.get("PGUSER", "postgres")
    password = os.environ.get("PGPASSWORD", "")
    return f"host={host} port={port} dbname={dbname} user={user} password={password}"


@contextmanager
def get_connection() -> Generator[Connection, None, None]:
    """
    Yield a single database connection. Caller must not hold it across long operations.
    Connection is closed on exit (commit on success, rollback on exception).
    """
    conn = psycopg2.connect(get_database_url())
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def run_sql_file(sql_path: str) -> None:
    """
    Execute a SQL file against the DB.
    Safe to call at startup — uses IF NOT EXISTS throughout so
    re-running does not error on already-created objects.
    """
    import os
    if not os.path.exists(sql_path):
        print(f"[migration] File not found, skipping: {sql_path}")
        return
    with open(sql_path, 'r') as f:
        sql = f.read()
    with get_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(sql)
        conn.commit()
    print(f"[migration] Applied: {sql_path}")
