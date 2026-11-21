#!/usr/bin/env bash
# SIGNAL — First-time DB setup (Mac, Homebrew, PostgreSQL 15)
# Run from repo root. Exits on first failure.

set -e
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_ROOT"

echo "==> 1. Checking Homebrew..."
# Add Homebrew to PATH if installed in common locations (e.g. not in non-login shell PATH)
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
if ! command -v brew &>/dev/null; then
  echo "     Homebrew not found. Installing (may prompt for sudo password)..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
    echo "ERROR: Homebrew install failed. Install manually from https://brew.sh (you may need to run in a terminal to enter sudo password), then re-run ./setup_db.sh"
    exit 1
  }
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi
echo "     Homebrew OK: $(brew --version | head -1)"

echo ""
echo "==> 2. Installing PostgreSQL 15..."
if ! brew list postgresql@15 &>/dev/null; then
  brew install postgresql@15 || {
    echo "ERROR: brew install postgresql@15 failed."
    exit 1
  }
else
  echo "     postgresql@15 already installed."
fi

echo ""
echo "==> 3. Starting PostgreSQL 15..."
brew services start postgresql@15 || {
  echo "ERROR: brew services start postgresql@15 failed."
  exit 1
}

echo ""
echo "==> 4. Waiting 3 seconds for Postgres to start..."
sleep 3

echo ""
echo "==> 5. Adding postgresql@15 to PATH for this session..."
PG_BIN="$(brew --prefix)/opt/postgresql@15/bin"
export PATH="$PG_BIN:$PATH"
if ! command -v psql &>/dev/null; then
  echo "ERROR: psql not found at $PG_BIN. Check postgresql@15 install."
  exit 1
fi
echo "     Using: $(which psql)"

echo ""
echo "==> 6. Creating database 'signal'..."
createdb signal 2>/dev/null && echo "     Created database signal." || {
  if psql -d signal -c 'SELECT 1' &>/dev/null; then
    echo "     Database signal already exists, skipping."
  else
    echo "ERROR: Could not create database 'signal' and it does not exist."
    exit 1
  fi
}

echo ""
echo "==> 7. Applying schema (signals/db/schema.sql)..."
psql -d signal -f signals/db/schema.sql || {
  echo "ERROR: Schema apply failed."
  exit 1
}
echo "     Schema applied."

echo ""
echo "==> 8. Writing signals/.env..."
mkdir -p signals
cat > signals/.env << 'ENVFILE'
DATABASE_URL=postgresql://localhost/signal
FRED_API_KEY=
ANTHROPIC_API_KEY=
ENVFILE
echo "     Wrote signals/.env (DATABASE_URL, FRED_API_KEY, ANTHROPIC_API_KEY)."

echo ""
echo "==> 9. Seeding universe..."
PYTHONPATH=. python -m signals.db.seed_universe || {
  echo "ERROR: seed_universe failed."
  exit 1
}

echo ""
echo "==> 10. Running pipeline once..."
PYTHONPATH=. python -m signals.main --once || {
  echo "ERROR: Pipeline run failed."
  exit 1
}

echo ""
echo "Done. Database is ready and pipeline ran successfully."
