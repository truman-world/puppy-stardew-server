#!/bin/bash
# Puppy Stardew Server Log Manager
# 小狗星谷服务器日志管理器
#
# Features:
# - Automatic log rotation and compression
# - Smart retention policy (7 days detailed + 30 days archived)
# - Low performance impact
# - Separated log categories

set -e

# Configuration
LOG_BASE_DIR="/home/steam/.config/StardewValley/ErrorLogs"
ARCHIVE_DIR="/home/steam/.local/share/puppy-stardew/logs/archive"
KEEP_DAYS=7           # Keep uncompressed logs for 7 days
ARCHIVE_DAYS=30       # Keep compressed archives for 30 days
MAX_LOG_SIZE_MB=50    # Rotate if log exceeds this size

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[Log-Manager]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[Log-Manager]${NC} $1"
}

# Create archive directory
mkdir -p "$ARCHIVE_DIR"

# Function to rotate a log file
rotate_log() {
    local log_file="$1"
    local log_name=$(basename "$log_file")
    local timestamp=$(date +%Y%m%d_%H%M%S)

    if [ -f "$log_file" ]; then
        local size_mb=$(du -m "$log_file" | cut -f1)

        # Check if rotation is needed
        if [ "$size_mb" -ge "$MAX_LOG_SIZE_MB" ]; then
            log_info "Rotating $log_name (${size_mb}MB)"

            # Compress and archive
            gzip -c "$log_file" > "$ARCHIVE_DIR/${log_name%.txt}_${timestamp}.txt.gz"

            # Truncate original file (keep file handle for running processes)
            > "$log_file"

            log_info "Archived to ${log_name%.txt}_${timestamp}.txt.gz"
        fi
    fi
}

# Function to clean old archives
clean_old_logs() {
    log_info "Cleaning old log archives..."

    # Remove uncompressed logs older than KEEP_DAYS
    find "$LOG_BASE_DIR" -name "*.txt" -type f -mtime +$KEEP_DAYS -delete 2>/dev/null || true

    # Remove compressed archives older than ARCHIVE_DAYS
    find "$ARCHIVE_DIR" -name "*.gz" -type f -mtime +$ARCHIVE_DAYS -delete 2>/dev/null || true

    # Remove empty directories
    find "$ARCHIVE_DIR" -type d -empty -delete 2>/dev/null || true

    log_info "Cleanup complete"
}

# Function to generate log summary
generate_summary() {
    local log_file="$LOG_BASE_DIR/SMAPI-latest.txt"

    if [ ! -f "$log_file" ]; then
        return
    fi

    log_info "Generating log summary..."

    # Ensure archive directory exists
    mkdir -p "$ARCHIVE_DIR"

    # Count errors and warnings
    local error_count=$(grep -c "ERROR" "$log_file" 2>/dev/null || echo "0")
    local warn_count=$(grep -c "WARN" "$log_file" 2>/dev/null || echo "0")

    # Get last few errors
    local recent_errors=$(grep "ERROR" "$log_file" 2>/dev/null | tail -5 || echo "")

    # Create summary file
    local summary_file="$ARCHIVE_DIR/summary_$(date +%Y%m%d).txt"

    {
        echo "=== Puppy Stardew Server Log Summary ==="
        echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        echo "Statistics:"
        echo "  Errors: $error_count"
        echo "  Warnings: $warn_count"
        echo ""
        if [ -n "$recent_errors" ]; then
            echo "Recent Errors:"
            echo "$recent_errors"
        fi
        echo ""
        echo "Full logs available in: $ARCHIVE_DIR"
    } > "$summary_file"

    log_info "Summary saved to $summary_file"
}

# Main execution
log_info "Starting log management cycle..."

# Rotate logs if needed
rotate_log "$LOG_BASE_DIR/SMAPI-latest.txt"

# Clean old logs
clean_old_logs

# Generate summary
generate_summary

# Show current disk usage
log_info "Log disk usage:"
echo "  Current logs: $(du -sh "$LOG_BASE_DIR" 2>/dev/null | cut -f1 || echo "0K")"
echo "  Archives: $(du -sh "$ARCHIVE_DIR" 2>/dev/null | cut -f1 || echo "0K")"

log_info "Log management complete"
