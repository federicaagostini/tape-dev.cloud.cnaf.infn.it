#!/bin/bash

set -e

# Check if file has "storm.premigrate" extended attribute
has_premigrate_attr() {
  local file="$1"

  if getfattr -n user.storm.premigrate --absolute-names --only-values -- "$file" >/dev/null 2>&1; then
    return 0
  fi

  if getfattr -n storm.premigrate --absolute-names --only-values -- "$file" >/dev/null 2>&1; then
    return 0
  fi
  if getfattr -d --absolute-names -- "$file" 2>/dev/null | grep -q "storm.premigrate"; then
    return 0
  fi

  return 1
}

LOG_DIR={LOG_DIR:-"/var/log/gemss"}

if [ ! -d "$LOG_DIR" ]; then
  mkdir -p "$LOG_DIR"
fi

TS=$(date +%Y%m%d_%H%M)
OUTPUT_FILE="${LOG_DIR}/${TS}_files_to_be_migrated"
LOG_FILE="${LOG_DIR}/${TS}_files_to_be_migrated.log"

touch "${OUTPUT_FILE}"
touch "${LOG_FILE}"

exec >"${LOGFILE}" 2>&1

ROOT_DIR={ROOT_DIR:-"/storage/disk"}

echo "-----------------------------------------"
echo "Start scanning directory $ROOT_DIR files at $(date)"
echo "Log file saved in $LOG_FILE"
echo "-----------------------------------------"

if ! command -v getfattr >/dev/null 2>&1; then
  echo "Error: getfattr not found. Installa il pacchetto 'attr' o equivalente."
  exit 2
fi

while IFS= read -r -d '' f; do
  if has_premigrate_attr "$f"; then
    printf '%s\n' "$f" >> "${OUTPUT_FILE}"
  fi
done < <(find "$ROOT_DIR" -type f -print0 2>/dev/null)

echo "Done. Files to be migrated saved in ${OUTPUT_FILE}"