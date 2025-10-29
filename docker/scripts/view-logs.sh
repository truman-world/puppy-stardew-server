#!/bin/bash
# Puppy Stardew Server - Log Viewer
# 小狗星谷服务器 - 日志查看器
#
# Usage: docker exec -it puppy-stardew /home/steam/scripts/view-logs.sh [option]
# 使用方法：docker exec -it puppy-stardew /home/steam/scripts/view-logs.sh [选项]

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Log directories
CATEGORIZED_DIR="/home/steam/.local/share/puppy-stardew/logs/categorized"
ARCHIVE_DIR="/home/steam/.local/share/puppy-stardew/logs/archive"

show_menu() {
    echo -e "${GREEN}=== Puppy Stardew Server Log Viewer ===${NC}"
    echo ""
    echo "1) View all errors (错误日志)"
    echo "2) View mod logs (模组日志)"
    echo "3) View server logs (服务器日志)"
    echo "4) View game logs (游戏日志)"
    echo "5) Show log statistics (日志统计)"
    echo "6) View archived logs (归档日志)"
    echo "7) Tail live game log (实时日志)"
    echo "0) Exit (退出)"
    echo ""
    read -p "Select option (选择选项): " option

    case $option in
        1)
            if [ -f "$CATEGORIZED_DIR/errors.log" ]; then
                echo -e "${RED}=== Error Logs (错误日志) ===${NC}"
                tail -50 "$CATEGORIZED_DIR/errors.log"
            else
                echo -e "${YELLOW}No error logs found.${NC}"
            fi
            ;;
        2)
            if [ -f "$CATEGORIZED_DIR/mods.log" ]; then
                echo -e "${BLUE}=== Mod Logs (模组日志) ===${NC}"
                tail -50 "$CATEGORIZED_DIR/mods.log"
            else
                echo -e "${YELLOW}No mod logs found.${NC}"
            fi
            ;;
        3)
            if [ -f "$CATEGORIZED_DIR/server.log" ]; then
                echo -e "${GREEN}=== Server Logs (服务器日志) ===${NC}"
                tail -50 "$CATEGORIZED_DIR/server.log"
            else
                echo -e "${YELLOW}No server logs found.${NC}"
            fi
            ;;
        4)
            if [ -f "$CATEGORIZED_DIR/game.log" ]; then
                echo -e "${BLUE}=== Game Logs (游戏日志) ===${NC}"
                tail -50 "$CATEGORIZED_DIR/game.log"
            else
                echo -e "${YELLOW}No game logs found.${NC}"
            fi
            ;;
        5)
            echo -e "${GREEN}=== Log Statistics (日志统计) ===${NC}"
            echo ""
            echo "Disk Usage:"
            if [ -d "$CATEGORIZED_DIR" ]; then
                echo "  Current logs: $(du -sh $CATEGORIZED_DIR 2>/dev/null | cut -f1 || echo '0K')"
            fi
            if [ -d "$ARCHIVE_DIR" ]; then
                echo "  Archives: $(du -sh $ARCHIVE_DIR 2>/dev/null | cut -f1 || echo '0K')"
            fi
            echo ""
            if [ -f "$CATEGORIZED_DIR/errors.log" ]; then
                echo "Error count: $(wc -l < "$CATEGORIZED_DIR/errors.log" 2>/dev/null || echo '0')"
            fi
            if [ -f "$CATEGORIZED_DIR/mods.log" ]; then
                echo "Mod entries: $(wc -l < "$CATEGORIZED_DIR/mods.log" 2>/dev/null || echo '0')"
            fi
            ;;
        6)
            echo -e "${BLUE}=== Archived Logs (归档日志) ===${NC}"
            if [ -d "$ARCHIVE_DIR" ]; then
                ls -lh "$ARCHIVE_DIR"/*.gz 2>/dev/null | tail -20 || echo "No archived logs found."
            else
                echo "No archive directory found."
            fi
            ;;
        7)
            echo -e "${GREEN}=== Live Game Log (实时日志) ===${NC}"
            echo "Press Ctrl+C to stop"
            tail -f /home/steam/.config/StardewValley/ErrorLogs/SMAPI-latest.txt 2>/dev/null || echo "Log file not found"
            ;;
        0)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option!${NC}"
            ;;
    esac

    echo ""
    read -p "Press ENTER to continue..."
    show_menu
}

# Check if running as steam user
if [ "$(whoami)" != "steam" ]; then
    echo -e "${YELLOW}Warning: This script should be run as the steam user.${NC}"
    echo "Use: docker exec -it puppy-stardew /home/steam/scripts/view-logs.sh"
fi

# Start menu
show_menu
