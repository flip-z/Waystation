#!/usr/bin/env bash
set -euo pipefail

timestamp="$(date +"%Y%m%d_%H%M%S")"
backup_dir="${BACKUP_DIR:-$(pwd)/backups}"
archive_path="$backup_dir/waystation_files_${timestamp}.tar.gz"

mkdir -p "$backup_dir"
tar -czf "$archive_path" storage content
