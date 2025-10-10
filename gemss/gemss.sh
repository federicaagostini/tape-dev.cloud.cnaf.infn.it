#!/bin/bash
set -e

set -a
source config.sh
set +a

if [ ! -d "$LOG_DIR" ]; then
  mkdir -p "$LOG_DIR"
fi

TS=$(date +%Y%m%d_%H%M)
LOG_FILE="${LOG_DIR}/${TS}_gemss.log"
MIGRATE_FILE="${LOG_DIR}/${TS}_migrated_files"
RECALL_FILE="${LOG_DIR}/${TS}_recall_files"

: > "${LOG_FILE}"
: > "${MIGRATE_FILE}"
: > "${RECALL_FILE}"

exec >"${LOG_FILE}" 2>&1

echo "--------------------------------------------------"
echo "--------------------------------------------------"
echo "$(date):"
echo "Start scanning files to be migrated at $ROOT_DIR"
echo "Log file saved in $LOG_FILE"
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
    printf '%s\n' "$f" >> "${MIGRATE_FILE}"
    echo "File "$f" migrated"
  fi
done < <(find "$ROOT_DIR" -type f 2>/dev/null)
set -e

echo "--------------------------------------------------"
echo "Migration completed at $(date)"
echo "Total files: $TOTAL"
echo "Number of migrated files: $FOUND"
echo "List of migrated files saved in $MIGRATE_FILE"
echo "--------------------------------------------------"

echo "--------------------------------------------------"
echo "$(date):"
echo "Start scanning files to be recalled in $ROOT_DIR"
echo "Log file saved in $LOG_FILE"
echo "--------------------------------------------------"

curl "https://$STORM_TAPE_ENDPOINT/recalltable/tasks" -H "Content-Type:text/plain" \
  -u "$GEMSS_USER:$GEMSS_PWD" -X PUT -d first="$RECALL_QUEUE" -ks >> "$RECALL_FILE" 2>&1 || true

TOTAL=0

set +e
while IFS= read -r line; do
  # Skip empty lines
  [ -z "$line" ] && continue
  STORM_TAPE_ROOT_PATH=$(echo "$line" | awk '{print $2}')
  recall_file.sh "$STORM_TAPE_ROOT_PATH"
  ((TOTAL++))
  echo "File "$STORM_TAPE_ROOT_PATH" recalled"
done < "$RECALL_FILE"
set -e

echo "--------------------------------------------------"
echo "Recall completed at $(date)"
echo "Number of recalled files: $TOTAL"
echo "List of recalled files saved in $RECALL_FILE"
echo "--------------------------------------------------"
echo "--------------------------------------------------"