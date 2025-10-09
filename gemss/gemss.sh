#!/bin/bash
set -e

source config.sh

if [ ! -d "$LOG_DIR" ]; then
  mkdir -p "$LOG_DIR"
fi

TS=$(date +%Y%m%d_%H%M)
OUTPUT_FILE="${LOG_DIR}/${TS}_migrated_files"
LOG_FILE="${LOG_DIR}/${TS}_gemss.log"

: > "${OUTPUT_FILE}"
: > "${LOG_FILE}"

exec >"${LOG_FILE}" 2>&1

echo "--------------------------------------------------"
echo "$(date):"
echo "Look for files to be migrated at"
echo "$ROOT_DIR"
echo "Log file saved in $LOG_FILE"
echo "--------------------------------------------------"
echo "--------------------------------------------------"

if ! command -v getfattr >/dev/null 2>&1; then
  echo "Error: getfattr not found. Please install the 'attr' package."
  exit 2
fi

FOUND=0
TOTAL=0

set +e
while IFS= read -r f; do
  ((TOTAL++))
  # Scan files to be migrated:
  # select the ones with "storm.premigrate" attribute
  if getfattr -n user.storm.premigrate --absolute-names --only-values -- "$f"; then
    ((FOUND++))
    migrate_file.sh "$f"
    printf '%s\n' "$f" >> "${OUTPUT_FILE}"
    echo "File "$f" migrated"
    echo "--------------------------------------------------"
  fi
done < <(find "$ROOT_DIR" -type f 2>/dev/null)
set -e

echo "--------------------------------------------------"
echo "Migration completed at $(date)"
echo "Total files: $TOTAL"
echo "Migrated files: $FOUND"
echo "List of migrated files saved in ${OUTPUT_FILE}"
echo "--------------------------------------------------"
