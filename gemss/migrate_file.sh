#!/bin/bash
set -e

if [ $# -ne 1 ]; then
  >&2 echo "Usage: migrate_file.sh </path/to/file>"
  exit 1
fi

ROOT_DIR=${ROOT_DIR:-"/storage/disk"}
TAPE_DIR=${TAPE_DIR:-"/storage/tape"}

# Relative path with respect to ROOT_DIR
file="$1"
REL_PATH="${file#$ROOT_DIR/}"

DST_FILE="$TAPE_DIR/$REL_PATH"

DST_DIR=$(dirname "$DST_FILE")
mkdir -p "$DST_DIR"

echo "Migrating $file on tape"

cp "$file" "$DST_FILE"
attr -r storm.premigrate "$file"
attr -s storm.migrated -V "" "$file"
