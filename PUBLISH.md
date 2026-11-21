# SIGNAL — portfolio demo (real dashboard)

Public packaging of the **real** `signals/dashboard/` UI + FastAPI API (not `signal_mockup.html`).

- `SIGNAL_DEMO=1` blocks pipeline / thesis / resolve writes
- Same-origin static UI from the API process
- Seed: `demo_data/seed.sql` (snapshot of a local research DB)

## Local

```bash
# Postgres with DATABASE_URL in signals/.env
export SIGNAL_DEMO=1 PYTHONPATH=.
python scripts/bootstrap_demo_db.py   # no-op if already seeded
uvicorn signals.api.server:app --host 127.0.0.1 --port 8000
# open http://127.0.0.1:8000/
```

## Render

1. Push this repo (or a deploy subtree) to GitHub.
2. New Blueprint → `render.yaml` (web + free Postgres), or:
   - Build: `pip install -r requirements-demo.txt`
   - Start: `bash scripts/start_demo.sh`
   - Env: `SIGNAL_DEMO=1`, `DATABASE_URL` from Render Postgres
3. First boot runs `bootstrap_demo_db.py` when `instruments` is empty.

Refresh seed from a local DB:

```bash
pg_dump -d signal --no-owner --no-acl | grep -v '^\\restrict' | grep -v '^\\unrestrict' > demo_data/seed.sql
```
