#!/bin/bash
set -e

has_attr() {
    local file=$1
    local attr=$2
    getfattr --absolute-names -n "user.${attr}" "$file" &>/dev/null
}

get_attr_value() {
    local file=$1
    local attr=$2
    getfattr --absolute-names -n "user.${attr}" "$file" 2>/dev/null \
      | awk -F '"' '/^user\./ {print $2}'
}

get_block_size() {
    local file=$1
    stat -c %b "$file" 2>/dev/null || echo 0
}

stubbify_file() {
    local file=$1

    size=$(get_block_size "$file")
    if fallocate -l 1400000 -p "$file" 2>/dev/null; then
        echo "Stubbifying file $file..."
    else
        echo "Failed to stubbify file $file"
    fi
}

set -a
source config.sh
set +a

if [ ! -d "$LOG_DIR" ]; then
  mkdir -p "$LOG_DIR"
fi

TS=$(date +%Y%m%d_%H%M)
LOG_FILE="${LOG_DIR}/${TS}_stubbify.log"
STUBBIFY_FILE="${LOG_DIR}/${TS}_stubbified_files"

: > "${LOG_FILE}"
: > "${STUBBIFY_FILE}"

exec >"${LOG_FILE}" 2>&1

echo "--------------------------------------------------"
echo "--------------------------------------------------"
echo "$(date):"
echo "Start scanning files to be stubbified at $ROOT_DIR"
echo "Log file saved in $LOG_FILE"
echo "--------------------------------------------------"

TOTAL=0
PROCESSED=0

set +e
while IFS= read -r file; do

    [ ! -r "$file" ] && continue
    ((TOTAL++))

    # 512 byte blocks
    BLOCKS=$(get_block_size "$file")
    if (( BLOCKS == 0 )); then
        continue
    fi

    if ! has_attr "$file" "storm.migrated"; then
        continue
    fi

    if has_attr "$file" "storm.pinned"; then
        PINVAL=$(get_attr_value "$file" "storm.pinned")
        CURRENT_TS=$(date +%s)
        if (( CURRENT_TS < PINVAL )); then
            continue
        fi
    fi

    stubbify_file "$file" || continue
    ((PROCESSED++))
    printf '%s\n' "$file" >> "${STUBBIFY_FILE}"
    echo "File "$file" stubbified"

done < <(find "$ROOT_DIR" -type f 2>/dev/null)
set -e

echo "--------------------------------------------------"
echo "Stubbification completed at $(date)"
echo "Total files: $TOTAL"
echo "Number of stubbified files: $PROCESSED"
echo "List of stubbified files saved in $STUBBIFY_FILE"
echo "--------------------------------------------------"