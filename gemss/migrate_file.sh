#!/bin/bash
set -e

if [ $# -ne 1 ]; then
  >&2 echo "Usage: migrate_file.sh </path/to/file>"
  exit 1
fi

SRC_ROOT="/storage/disk"
DST_ROOT="/storage/tape"

# Relative path with respect to SRC_ROOT
file="$1"
REL_PATH="${file#$SRC_ROOT/}"

DST_FILE="$DST_ROOT/$REL_PATH"

DST_DIR=$(dirname "$DST_FILE")
mkdir -p "$DST_DIR"

echo "Migrating: $file on tape"

cp "$file" "$DST_FILE"
attr -r storm.premigrate "$file"
attr -s storm.migrated -V "" "$file"
