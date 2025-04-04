#!/bin/bash
set -euo pipefail

PROMETHEUS_ENDPOINT="http://localhost:9090/"
REPORT_FILE="$HOME/juno-benchmark/sync_report.txt"
BLOCKS_TO_MONITOR=${BLOCKS_TO_MONITOR:-10000}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$REPORT_FILE"
}

get_current_block_from_prometheus() {
    local result
    result=$(curl -s "$PROMETHEUS_ENDPOINT" | grep "sync_blockchain_height" | grep -v "^#" | awk '{print $2}')
    
    if [[ -z "$result" ]] || ! [[ "$result" =~ ^[0-9]+$ ]]; then
        echo "0"
    else
        echo "$result"
    fi
}

echo "Juno Sync Report - $(date)" > "$REPORT_FILE"
echo "--------------------------------" >> "$REPORT_FILE"

START_TIME=$(date +%s)
log "Sync started at $(date -u)"

INITIAL_BLOCK=$(get_current_block_from_prometheus)
TARGET_BLOCK=$((INITIAL_BLOCK + BLOCKS_TO_MONITOR))
log "Starting from block: $INITIAL_BLOCK"
log "Target block: $TARGET_BLOCK"

while true; do
    CURRENT_BLOCK=$(get_current_block_from_prometheus)
    
    CURRENT_TIME=$(date +%s)
    ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
    ELAPSED_MINUTES=$(echo "scale=2; $ELAPSED_TIME / 60" | bc)
    
    echo "Current block: $CURRENT_BLOCK / $TARGET_BLOCK (Elapsed: $ELAPSED_MINUTES minutes)"
    
    if [[ "$CURRENT_BLOCK" -ge "$TARGET_BLOCK" ]]; then
        END_TIME=$(date +%s)
        SYNC_DURATION=$((END_TIME - START_TIME))
        SYNC_MINUTES=$(echo "scale=2; $SYNC_DURATION / 60" | bc)
        
        log "Sync completed in: $SYNC_MINUTES minutes"
        log "Blocks synced: $((CURRENT_BLOCK - INITIAL_BLOCK))"
        log "Average speed: $(echo "scale=2; ($CURRENT_BLOCK - $INITIAL_BLOCK) / $SYNC_DURATION" | bc) blocks/second"
        
        log "Sync report saved to: $REPORT_FILE"
        break
    fi
    sleep 5
done