#!/bin/bash
# =============================================================================
# Puppy Stardew Server - Backup Script
# 小狗星谷服务器 - 备份脚本
# =============================================================================
# This script backs up your Stardew Valley save files.
# 此脚本备份您的星露谷物语存档文件。
# =============================================================================

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

# Configuration
SAVES_DIR="./data/saves"
BACKUP_DIR="./backups"
MAX_BACKUPS=7  # Keep last 7 backups
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="stardew-backup-$TIMESTAMP.tar.gz"

# =============================================================================
# Helper Functions
# =============================================================================

print_header() {
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}${BOLD}  💾 Puppy Stardew Server - Backup${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# =============================================================================
# Main Functions
# =============================================================================

check_saves_dir() {
    if [ ! -d "$SAVES_DIR" ]; then
        print_error "Saves directory not found: $SAVES_DIR"
        echo ""
        echo "Make sure you're running this script from the puppy-stardew-server directory."
        exit 1
    fi

    # Check if saves directory is empty
    if [ -z "$(ls -A $SAVES_DIR 2>/dev/null)" ]; then
        print_warning "Saves directory is empty!"
        echo ""
        echo "No save files found. Have you created a save yet?"
        exit 1
    fi
}

create_backup() {
    # Create backup directory
    mkdir -p "$BACKUP_DIR"

    print_info "Creating backup: $BACKUP_FILE"

    # Create compressed archive
    tar -czf "$BACKUP_DIR/$BACKUP_FILE" -C data saves

    # Get backup size
    backup_size=$(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)

    print_success "Backup created: $BACKUP_FILE ($backup_size)"
}

cleanup_old_backups() {
    # Count existing backups
    backup_count=$(ls -1 "$BACKUP_DIR"/stardew-backup-*.tar.gz 2>/dev/null | wc -l)

    if [ "$backup_count" -gt "$MAX_BACKUPS" ]; then
        print_info "Cleaning up old backups (keeping last $MAX_BACKUPS)..."

        # Remove oldest backups
        ls -t "$BACKUP_DIR"/stardew-backup-*.tar.gz | tail -n +$((MAX_BACKUPS + 1)) | xargs rm -f

        print_success "Old backups removed"
    fi
}

list_backups() {
    echo ""
    echo -e "${BOLD}Available backups:${NC}"
    echo ""

    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A $BACKUP_DIR 2>/dev/null)" ]; then
        print_info "No backups found yet."
        return
    fi

    # List backups with details
    ls -lth "$BACKUP_DIR"/stardew-backup-*.tar.gz | awk '{
        size = $5
        date = $6 " " $7 " " $8
        file = $9
        gsub(/.*\//, "", file)
        printf "  📦 %-40s %8s  %s\n", file, size, date
    }'

    echo ""
    total_size=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
    echo -e "${BLUE}Total backup size: $total_size${NC}"
}

show_restore_instructions() {
    echo ""
    echo -e "${BOLD}To restore a backup:${NC}"
    echo ""
    echo "1. Stop the server:"
    echo "   ${CYAN}docker compose down${NC}"
    echo ""
    echo "2. Backup current saves (just in case):"
    echo "   ${CYAN}mv data/saves data/saves.old${NC}"
    echo ""
    echo "3. Extract backup:"
    echo "   ${CYAN}tar -xzf backups/BACKUP_FILE_NAME -C data${NC}"
    echo ""
    echo "4. Start the server:"
    echo "   ${CYAN}docker compose up -d${NC}"
    echo ""
}

# =============================================================================
# Main Script
# =============================================================================

main() {
    print_header

    # Check if saves exist
    check_saves_dir

    # Create backup
    create_backup

    # Clean up old backups
    cleanup_old_backups

    # List all backups
    list_backups

    # Show restore instructions
    show_restore_instructions

    echo -e "${GREEN}${BOLD}✨ Backup complete!${NC}"
    echo ""
}

# Run main function
main
