#!/bin/bash
# Puppy Stardew Server Entrypoint Script - Fixed Steam Guard Logic
# 小狗星谷服务器启动脚本 - 修复Steam Guard逻辑

set -e

# Color codes for pretty logging
# 彩色日志输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables
GAME_DOWNLOADED=false
MAX_RETRIES=3
RETRY_COUNT=0
RETRY_DELAY=300  # 5 minutes between retries

log_info() {
    echo -e "${GREEN}[Puppy-Stardew]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[Puppy-Stardew]${NC} $1"
}

log_error() {
    echo -e "${RED}[Puppy-Stardew]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[Puppy-Stardew]${NC} $1"
}

log_steam() {
    echo -e "${CYAN}[Steam-Guard]${NC} $1"
}

# Fix libcurl compatibility for SteamCMD
log_step "Step 1: Setting up environment..."
log_info "Fixing libcurl compatibility for SteamCMD..."
if [ -f "/usr/lib/x86_64-linux-gnu/libcurl.so.4" ]; then
    # Remove conflicting 64-bit libcurl that causes issues
    rm -f /usr/lib/x86_64-linux-gnu/libcurl.so.4 2>/dev/null || true
    # Create symlink to 32-bit version if it exists
    if [ -f "/usr/lib/i386-linux-gnu/libcurl.so.4" ]; then
        ln -sf /usr/lib/i386-linux-gnu/libcurl.so.4 /usr/lib/x86_64-linux-gnu/libcurl.so.4
    fi
fi

# CRITICAL: Fix Steam directory permissions BEFORE any Steam operations
log_info "Setting up critical Steam directory permissions..."
chown -R steam:steam /home/steam/Steam 2>/dev/null || true
chown -R steam:steam /home/steam/stardewvalley 2>/dev/null || true
chown -R steam:steam /home/steam/.config 2>/dev/null || true

# Ensure critical directories exist with correct permissions
mkdir -p /home/steam/Steam/config
mkdir -p /home/steam/Steam/logs
mkdir -p /home/steam/stardewvalley
chown steam:steam /home/steam/Steam/config /home/steam/Steam/logs /home/steam/stardewvalley 2>/dev/null || true

log_step "Step 2: Checking Steam credentials..."

# Check if game is already downloaded
if [ -f "/home/steam/stardewvalley/Stardew Valley.dll" ]; then
    log_info "Game files already exist. Skipping Steam credential validation."
    log_info "游戏文件已存在。跳过 Steam 凭证验证。"
    GAME_DOWNLOADED=true
elif [ -z "$STEAM_USERNAME" ] || [ -z "$STEAM_PASSWORD" ]; then
    log_error "============================================"
    log_error "ERROR: Steam credentials not provided!"
    log_error "错误：未提供 Steam 凭证！"
    log_error "============================================"
    log_error ""
    log_error "Please set environment variables:"
    log_error "请设置以下环境变量："
    log_error "  STEAM_USERNAME=your_steam_username"
    log_error "  STEAM_PASSWORD=your_steam_password"
    log_error ""
    log_error "For Steam Guard codes:"
    log_error "对于 Steam 令牌验证："
    log_error "  docker attach puppy-stardew"
    log_error "============================================"
    exit 1
fi

log_info "Steam username: $STEAM_USERNAME"

# Download game if needed
if [ "$GAME_DOWNLOADED" = false ]; then
    log_step "Step 2: Downloading game files..."
    log_warn "Game files not found. Downloading Stardew Valley..."
    log_warn "未找到游戏文件。正在下载星露谷物语..."
    log_warn "This will take 5-10 minutes depending on your connection."
    log_warn "根据网络情况，此过程需要 5-10 分钟。"
    log_warn ""

    # Clean up any existing Steam files that might be corrupted
    log_info "Cleaning up any corrupted Steam files..."
    rm -rf /home/steam/Steam/config/*
    rm -rf /home/steam/Steam/logs/*
    rm -rf /tmp/steam*
    rm -f /tmp/steam_*.log

    # Ensure proper permissions before download
    log_info "Setting up proper permissions for Steam data..."
    chown -R steam:steam /home/steam/Steam 2>/dev/null || true
    chown -R steam:steam /home/steam/stardewvalley 2>/dev/null || true

    # First, try to detect if Steam Guard is needed
    log_info "Checking if Steam Guard authentication is required..."

    # Run a quick test to check for Steam Guard requirement
    timeout 30 /home/steam/steamcmd/steamcmd.sh \
        +login "$STEAM_USERNAME" "$STEAM_PASSWORD" \
        +quit 2>&1 | tee /tmp/steam_guard_test.log

    # Check the timeout status
    TIMEOUT_STATUS=$?

    # Check for rate limit FIRST (this takes priority)
    if grep -q "Rate Limit Exceeded" /tmp/steam_guard_test.log || \
       grep -q "ERROR (Rate Limit Exceeded)" /tmp/steam_guard_test.log; then

        log_error "Steam API rate limit detected. Please wait before retrying."
        log_error "检测到 Steam API 速率限制。请等待后重试。"
        log_error "建议等待 30 分钟后再试。"
        exit 1

    # Check if timeout occurred - this might indicate Steam Guard is required
    elif [ $TIMEOUT_STATUS -eq 124 ] || [ $TIMEOUT_STATUS -eq 137 ]; then

        # Timeout occurred - likely Steam Guard is required but test couldn't complete
        log_warn "Steam Guard test timed out - authentication likely required!"
        log_warn "Steam Guard 测试超时 - 可能需要验证码！"

        log_steam ""
        log_steam "========================================"
        log_steam "STEAM GUARD CODE REQUIRED"
        log_steam "需要输入 STEAM 令牌验证码"
        log_steam "========================================"
        log_steam ""
        log_steam "Container will now restart in interactive mode for Steam Guard"
        log_steam "容器将以交互模式重启以进行 Steam Guard 验证"
        log_steam ""
        log_steam "To input code:"
        log_steam "输入验证码步骤："
        log_steam "1. Wait for container restart (30 seconds)"
        log_steam "1. 等待容器重启（30秒）"
        log_steam "2. Run: docker attach puppy-stardew"
        log_steam "2. 运行：docker attach puppy-stardew"
        log_steam "3. Enter Steam Guard code when prompted"
        log_steam "3. 提示时输入 Steam Guard 验证码"
        log_steam "4. Press ENTER after code"
        log_steam "4. 输入验证码后按回车"
        log_steam "========================================"

        # Run SteamCMD in interactive mode for Steam Guard
        log_info "Starting Steam authentication with Steam Guard..."
        /home/steam/steamcmd/steamcmd.sh \
            +force_install_dir /home/steam/stardewvalley \
            +login "$STEAM_USERNAME" "$STEAM_PASSWORD" \
            +app_update 413150 validate \
            +quit

        # Check if download was successful
        if [ ! -f "/home/steam/stardewvalley/StardewValley" ]; then
            log_error "Game download failed after Steam Guard verification"
            log_error "Steam Guard 验证后游戏下载失败"
            exit 1
        fi

        log_info "Game downloaded successfully after Steam Guard verification!"
        log_info "Steam Guard 验证后游戏下载完成！"
        GAME_DOWNLOADED=true

    # Then check for Steam Guard from log analysis
    elif grep -q "Two-factor code" /tmp/steam_guard_test.log || \
         grep -q "Guard code" /tmp/steam_guard_test.log || \
         grep -q "This computer has not been authenticated" /tmp/steam_guard_test.log; then

        # Steam Guard is required - provide interactive instructions
        log_warn "Steam Guard authentication required!"
        log_warn "需要 Steam 令牌验证！"

        log_steam ""
        log_steam "========================================"
        log_steam "STEAM GUARD CODE REQUIRED"
        log_steam "需要输入 STEAM 令牌验证码"
        log_steam "========================================"
        log_steam ""
        log_steam "Container will now restart in interactive mode for Steam Guard"
        log_steam "容器将以交互模式重启以进行 Steam Guard 验证"
        log_steam ""
        log_steam "To input code:"
        log_steam "输入验证码步骤："
        log_steam "1. Wait for container restart (30 seconds)"
        log_steam "1. 等待容器重启（30秒）"
        log_steam "2. Run: docker attach puppy-stardew"
        log_steam "2. 运行：docker attach puppy-stardew"
        log_steam "3. Enter Steam Guard code when prompted"
        log_steam "3. 提示时输入 Steam Guard 验证码"
        log_steam "4. Press ENTER after code"
        log_steam "4. 输入验证码后按回车"
        log_steam "========================================"

        # Run SteamCMD in interactive mode for Steam Guard
        log_info "Starting Steam authentication with Steam Guard..."
        /home/steam/steamcmd/steamcmd.sh \
            +force_install_dir /home/steam/stardewvalley \
            +login "$STEAM_USERNAME" "$STEAM_PASSWORD" \
            +app_update 413150 validate \
            +quit

        # Check if download was successful
        if [ ! -f "/home/steam/stardewvalley/StardewValley" ]; then
            log_error "Game download failed after Steam Guard verification"
            log_error "Steam Guard 验证后游戏下载失败"
            exit 1
        fi

        log_info "Game downloaded successfully after Steam Guard verification!"
        log_info "Steam Guard 验证后游戏下载完成！"
        GAME_DOWNLOADED=true

    # If no Steam Guard, proceed with normal download
    else
        log_info "Starting Steam authentication and download..."
    timeout 900 /home/steam/steamcmd/steamcmd.sh \
        +force_install_dir /home/steam/stardewvalley \
        +login "$STEAM_USERNAME" "$STEAM_PASSWORD" \
        +app_update 413150 validate \
        +quit 2>&1 | tee /tmp/steam_download.log

    # Check the result
    if grep -q "Success! App '413150' fully installed" /tmp/steam_download.log; then
        log_info "Game downloaded successfully!"
        log_info "游戏下载完成！"
        GAME_DOWNLOADED=true
    elif grep -q "Two-factor code" /tmp/steam_download.log || \
         grep -q "Guard code" /tmp/steam_download.log || \
         grep -q "This computer has not been authenticated" /tmp/steam_download.log; then

        # Steam Guard is required - handle it interactively
        log_warn "Steam Guard authentication required!"
        log_warn "需要 Steam 令牌验证！"

        log_steam ""
        log_steam "========================================"
        log_steam "STEAM GUARD CODE REQUIRED"
        log_steam "需要输入 STEAM 令牌验证码"
        log_steam "========================================"
        log_steam ""
        log_steam "Please use docker attach to input code:"
        log_steam "请使用 docker attach 输入验证码："
        log_steam "  docker attach puppy-stardew"
        log_steam ""
        log_steam "After attaching, you will see the Steam Guard prompt."
        log_steam "连接后，您将看到 Steam Guard 提示。"
        log_steam ""
        log_steam "Enter your Steam Guard code and press ENTER"
        log_steam "输入您的 Steam 令牌验证码并按回车"
        log_steam ""
        log_steam "To detach after entering code:"
        log_steam "输入验证码后要分离："
        log_steam "Press Ctrl+P, then Ctrl+Q"
        log_steam "========================================"

        # CRITICAL: Fix permissions again BEFORE Steam Guard download
        log_info "Setting up permissions for Steam Guard download..."
        chown -R steam:steam /home/steam/Steam 2>/dev/null || true
        chown -R steam:steam /home/steam/stardewvalley 2>/dev/null || true
        chown -R steam:steam /home/steam/.config 2>/dev/null || true
        sleep 2  # Give permission changes time to take effect

        # Run SteamCMD in interactive mode for Steam Guard
        log_info "Starting Steam authentication with Steam Guard..."
        /home/steam/steamcmd/steamcmd.sh \
            +force_install_dir /home/steam/stardewvalley \
            +login "$STEAM_USERNAME" "$STEAM_PASSWORD" \
            +app_update 413150 validate \
            +quit

        # Check if download was successful
        if [ ! -f "/home/steam/stardewvalley/StardewValley" ]; then
            log_error "Game download failed after Steam Guard verification"
            log_error "Steam Guard 验证后游戏下载失败"
            exit 1
        fi

        log_info "Game downloaded successfully after Steam Guard verification!"
        log_info "Steam Guard 验证后游戏下载完成！"
        GAME_DOWNLOADED=true
    elif grep -q "Login Failed" /tmp/steam_download.log || \
         grep -q "Invalid Password" /tmp/steam_download.log; then
        log_error "Steam authentication failed. Please check your credentials."
        log_error "Steam 认证失败。请检查您的凭证。"
        exit 1
    elif grep -q "ERROR (Rate Limit Exceeded)" /tmp/steam_download.log; then
        log_error "Steam API rate limit exceeded. Waiting before retry..."
        log_error "Steam API 速率限制。等待后重试..."

        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            RETRY_COUNT=$((RETRY_COUNT + 1))
            log_warn "Retry attempt $RETRY_COUNT of $MAX_RETRIES in $RETRY_DELAY seconds..."
            log_warn "重试次数 $RETRY_COUNT / $MAX_RETRIES，$RETRY_DELAY 秒后..."
            sleep $RETRY_DELAY

            # Retry with exponential backoff
            RETRY_DELAY=$((RETRY_DELAY * 2))
            exec /home/steam/entrypoint.sh
        else
            log_error "Maximum retry attempts reached due to rate limiting."
            log_error "达到最大重试次数（速率限制）。"
            log_error "Please wait a few hours before trying again."
            log_error "请等待几小时后再重试。"
            exit 1
        fi
    else
        log_error "Unknown error occurred during download"
        log_error "下载过程中发生未知错误"
        log_error "Check /tmp/steam_download.log for details"
        exit 1
    fi
fi

# Install SMAPI if needed
log_step "Step 3: Checking SMAPI installation..."

if [ ! -f "/home/steam/stardewvalley/StardewModdingAPI" ]; then
    log_info "Installing SMAPI..."
    log_info "正在安装 SMAPI..."

    # Run SMAPI installer in automated mode
    cd /home/steam
    echo "1" | dotnet smapi/SMAPI*/internal/linux/SMAPI.Installer.dll --install --game-path /home/steam/stardewvalley

    if [ $? -ne 0 ]; then
        log_error "Failed to install SMAPI!"
        log_error "SMAPI 安装失败！"
        exit 1
    fi

    log_info "SMAPI installed successfully!"
    log_info "SMAPI 安装完成！"
else
    log_info "SMAPI already installed."
    log_info "SMAPI 已安装。"
fi

# Copy preinstalled mods
log_step "Step 4: Installing mods..."

mkdir -p /home/steam/stardewvalley/Mods

if [ -d "/home/steam/preinstalled-mods" ]; then
    log_info "Installing preinstalled mods..."
    rm -rf /home/steam/stardewvalley/Mods
    mkdir -p /home/steam/stardewvalley/Mods
    cp -r /home/steam/preinstalled-mods/* /home/steam/stardewvalley/Mods/

    log_info "Installed mods:"
    log_info "已安装模组："
    ls -1 /home/steam/stardewvalley/Mods/ | while read mod; do
        log_info "  ✓ $mod"
    done
fi

# Setup virtual display
log_step "Step 5: Starting virtual display..."

rm -f /tmp/.X99-lock /tmp/.X11-unix/X99 2>/dev/null

Xvfb :99 -screen 0 1280x720x24 -ac +extension GLX +render -noreset &
export DISPLAY=:99
sleep 3

log_info "Virtual display started on :99"

# Start VNC server (if enabled)
if [ "$ENABLE_VNC" = "true" ]; then
    log_step "Step 6: Starting VNC server..."

    VNC_PASSWORD=${VNC_PASSWORD:-"stardew123"}

    if [ ${#VNC_PASSWORD} -gt 8 ]; then
        log_warn "VNC password is longer than 8 characters!"
        log_warn "VNC 密码超过 8 个字符！"
        VNC_PASSWORD="${VNC_PASSWORD:0:8}"
    fi

    VNC_PASSWD_FILE=/tmp/vncpasswd
    echo -n "$VNC_PASSWORD" > "$VNC_PASSWD_FILE"
    chmod 600 "$VNC_PASSWD_FILE"

    openbox &
    x11vnc -display :99 -forever -shared -passwdfile "$VNC_PASSWD_FILE" -rfbport 5900 &

    log_info "==================================="
    log_info "VNC Server Started / VNC 服务器已启动"
    log_info "Address / 地址: [Your Server IP]:5900"
    log_info "Password / 密码: $VNC_PASSWORD"
    log_info "==================================="
    log_warn "First run: Use VNC to create or load a save!"
    log_warn "首次运行：使用 VNC 创建或加载存档！"
fi

# Display configuration info
log_step "Step 7: Server configuration"

log_info "==================================="
log_info "Puppy Stardew Server Ready!"
log_info "小狗星谷服务器准备就绪！"
log_info "==================================="
log_info "Game Port / 游戏端口: 24642/udp"
if [ "$ENABLE_VNC" = "true" ]; then
    log_info "VNC Port / VNC 端口: 5900/tcp"
fi
log_info "==================================="

# Start game server
log_step "Step 8: Starting Stardew Valley server..."
log_info "Server is starting. This may take a minute..."
log_info "服务器正在启动。可能需要一分钟..."
log_warn ""
log_warn "FIRST RUN: You must create or load a save via VNC!"
log_warn "首次运行：您必须通过 VNC 创建或加载存档！"
log_warn ""

cd /home/steam/stardewvalley
exec ./StardewModdingAPI --server

fi