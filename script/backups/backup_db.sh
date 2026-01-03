#!/usr/bin/env bash
set -euo pipefail

timestamp="$(date +"%Y%m%d_%H%M%S")"
backup_dir="${BACKUP_DIR:-$(pwd)/backups}"

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "DATABASE_URL must be set for pg_dump." >&2
  exit 1
fi

mkdir -p "$backup_dir"
pg_dump "$DATABASE_URL" > "$backup_dir/waystation_db_${timestamp}.sql"
