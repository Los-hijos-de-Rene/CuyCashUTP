#!/usr/bin/env bash
# Desde cualquier carpeta; solo consulta la API y usa una BD de pruebas explícita.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
python_bin=${CUYCASH_PYTHON:-"$root/services/api/.venv/bin/python"}
: "${TEST_POSTGRES_URL:?Define una base aislada terminada en _test; pytest borra su esquema}"
api_url=${CUYCASH_API_URL:-http://127.0.0.1:8001}
case "$api_url" in http://127.0.0.1:*|http://localhost:*) ;; *) echo 'Este validador exige API local'; exit 2;; esac
curl --fail --silent --show-error --max-time 15 "$api_url/health"
curl --fail --silent --show-error --max-time 15 "$api_url/health/db"
cd "$root/services/api"
"$python_bin" -m pip check
"$python_bin" -m ruff check app tests scripts
"$python_bin" -m pytest -q -rs --cov --cov-report=term
cd "$root"
git diff --check
if command -v flutter >/dev/null; then
  flutter pub get
  flutter analyze
  flutter test
else
  echo 'NO EJECUTADO: Flutter analyze/test (SDK ausente).'
  exit 3
fi
