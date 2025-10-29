#!/bin/bash
# Puppy Stardew Server Log Monitor
# 实时监控并分类游戏日志
#
# This script runs in the background and monitors game logs
# 此脚本在后台运行并监控游戏日志

set -e

# Configuration
SMAPI_LOG="/home/steam/.config/StardewValley/ErrorLogs/SMAPI-latest.txt"
OUTPUT_DIR="/home/steam/.local/share/puppy-stardew/logs/categorized"
ERROR_LOG="$OUTPUT_DIR/errors.log"
MOD_LOG="$OUTPUT_DIR/mods.log"
SERVER_LOG="$OUTPUT_DIR/server.log"
GAME_LOG="$OUTPUT_DIR/game.log"

# Performance settings
CHECK_INTERVAL=30  # Check every 30 seconds
BATCH_SIZE=100     # Process logs in batches to reduce I/O

# Create output directories
mkdir -p "$OUTPUT_DIR"

# Initialize log files if they don't exist
touch "$ERROR_LOG" "$MOD_LOG" "$SERVER_LOG" "$GAME_LOG"

# Track last processed line
LAST_LINE=0
if [ -f "$OUTPUT_DIR/.last_line" ]; then
    LAST_LINE=$(cat "$OUTPUT_DIR/.last_line")
fi

# Function to categorize and append log entry
process_log_line() {
    local line="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Skip empty lines
    if [ -z "$line" ]; then
        return
    fi

    # Categorize based on content
    if echo "$line" | grep -qE "ERROR|FATAL|Exception"; then
        echo "[$timestamp] $line" >> "$ERROR_LOG"
    fi

    if echo "$line" | grep -qE "\[.*\]" | grep -qE "Always On Server|AutoHideHost|Server Auto Load"; then
        echo "[$timestamp] $line" >> "$MOD_LOG"
    fi

    if echo "$line" | grep -qE "Server|Multiplayer|Connection|Player"; then
        echo "[$timestamp] $line" >> "$SERVER_LOG"
    fi

    # Always append to general game log
    echo "[$timestamp] $line" >> "$GAME_LOG"
}

# Main monitoring loop
monitor_logs() {
    while true; do
        if [ -f "$SMAPI_LOG" ]; then
            # Get total lines in log file
            local total_lines=$(wc -l < "$SMAPI_LOG" 2>/dev/null || echo "0")

            # Process new lines if any
            if [ "$total_lines" -gt "$LAST_LINE" ]; then
                # Calculate lines to process
                local lines_to_process=$((total_lines - LAST_LINE))

                # Limit batch size for performance
                if [ "$lines_to_process" -gt "$BATCH_SIZE" ]; then
                    lines_to_process=$BATCH_SIZE
                fi

                # Process new lines
                tail -n +"$((LAST_LINE + 1))" "$SMAPI_LOG" | head -n "$lines_to_process" | while IFS= read -r line; do
                    process_log_line "$line"
                done

                # Update last processed line
                LAST_LINE=$((LAST_LINE + lines_to_process))
                echo "$LAST_LINE" > "$OUTPUT_DIR/.last_line"
            fi
        fi

        # Wait before next check
        sleep "$CHECK_INTERVAL"
    done
}

# Trap signals for graceful shutdown
trap 'echo "Log monitor stopped"; exit 0' SIGTERM SIGINT

# Start monitoring
echo "[Log-Monitor] Starting log monitoring..."
echo "[Log-Monitor] Checking every ${CHECK_INTERVAL}s"
echo "[Log-Monitor] Output directory: $OUTPUT_DIR"

monitor_logs
