#!/bin/bash
# Puppy Stardew Server Entrypoint Script - Steam Guard Final Fix Version
# 小狗星谷服务器启动脚本 - Steam Guard 最终修复版本

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
STEAM_AUTH_SUCCESS=false
GAME_DOWNLOADED=false
MAX_RETRIES=3
RETRY_COUNT=0

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

# Check if this is a retry
if [ "$1" = "--retry" ]; then
    RETRY_COUNT=$((RETRY_COUNT + 1))
    log_info "Retry attempt $RETRY_COUNT of $MAX_RETRIES"
    log_info "重试次数 $RETRY_COUNT / $MAX_RETRIES"

    if [ $RETRY_COUNT -gt $MAX_RETRIES ]; then
        log_error "Maximum retry attempts reached!"
        log_error "达到最大重试次数！"
        exit 1
    fi
fi

# Create a state file to track progress
STATE_FILE="/tmp/stardew-state.txt"

# Save state
save_state() {
    echo "$1" > "$STATE_FILE"
}

# Load state
load_state() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    fi
}

# Steam Guard Interactive Handler
handle_steam_guard() {
    log_steam ""
    log_steam "========================================"
    log_steam "STEAM GUARD CODE REQUIRED"
    log_steam "需要输入 STEAM 令牌验证码"
    log_steam "========================================"
    log_steam ""
    log_steam "Please use docker attach to input the code:"
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

    # Run SteamCMD in a way that allows interactive input
    # This will keep the process running and waiting for input
    /home/steam/steamcmd/steamcmd.sh \
        +force_install_dir /home/steam/stardewvalley \
        +login "$STEAM_USERNAME" "$STEAM_PASSWORD" \
        +app_update 413150 validate \
        +quit
}

# ============================================
# Step 1: Validate Steam Credentials
# ============================================
log_step "Step 1: Checking Steam credentials..."

# Check if game is already downloaded
if [ -f "/home/steam/stardewvalley/Stardew Valley.dll" ]; then
    log_info "Game files already exist. Skipping Steam credential validation."
    log_info "游戏文件已存在。跳过 Steam 凭证验证。"
    GAME_DOWNLOADED=true
    save_state "game_downloaded"
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

# ============================================
# Step 2: Download Stardew Valley via Steam
# ============================================
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

    # Ensure proper permissions
    chown -R steam:steam /home/steam/Steam 2>/dev/null || true

    # Try to download the game
    # If Steam Guard is needed, this will stop and wait for input
    log_info "Starting Steam authentication and download..."

    # Create a wrapper script that will retry if needed
    cat > /tmp/download_with_guard.sh << 'EOF'
#!/bin/bash
set +e  # Don't exit on error so we can handle retries

# Run SteamCMD
/home/steam/steamcmd/steamcmd.sh \
    +force_install_dir /home/steam/stardewvalley \
    +login "$STEAM_USERNAME" "$STEAM_PASSWORD" \
    +app_update 413150 validate \
    +quit 2>&1 | tee /tmp/steam_download.log

EXIT_CODE=$?

# Check for Steam Guard requirement
if grep -q "Two-factor code" /tmp/steam_download.log || \
   grep -q "Guard code" /tmp/steam_download.log || \
   grep -q "This computer has not been authenticated" /tmp/steam_download.log; then
    echo "STEAM_GUARD_NEEDED"
    exit 100
fi

# Check for success
if grep -q "Success! App '413150' fully installed" /tmp/steam_download.log; then
    echo "SUCCESS"
    exit 0
fi

# Check for authentication failure
if grep -q "Login Failed" /tmp/steam_download.log || \
   grep -q "Invalid Password" /tmp/steam_download.log; then
    echo "AUTH_FAILED"
    exit 1
fi

# Unknown error
echo "UNKNOWN_ERROR"
exit $EXIT_CODE
EOF

    chmod +x /tmp/download_with_guard.sh

    # Execute the download
    /tmp/download_with_guard.sh
    RESULT=$?

    case $RESULT in
        0)
            log_info "Game downloaded successfully!"
            log_info "游戏下载完成！"
            GAME_DOWNLOADED=true
            save_state "game_downloaded"
            ;;
        100)
            log_warn "Steam Guard authentication required!"
            log_warn "需要 Steam 令牌验证！"

            # Call the Steam Guard handler
            handle_steam_guard

            # If we get here, the user entered the code and it succeeded
            log_info "Authentication successful!"
            log_info "认证成功！"
            GAME_DOWNLOADED=true
            save_state "game_downloaded"
            ;;
        1)
            log_error "Steam authentication failed!"
            log_error "Steam认证失败！"

            if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
                log_warn "Container will restart for retry..."
                log_warn "容器将重启重试..."
                sleep 5
                exec /home/steam/entrypoint.sh --retry
            else
                log_error "Maximum retries reached. Please check credentials."
                log_error "达到最大重试次数。请检查凭证。"
                exit 1
            fi
            ;;
        *)
            log_error "Download failed with exit code: $RESULT"
            log_error "下载失败，退出码：$RESULT"
            exit 1
            ;;
    esac
else
    log_info "Game files found. Skipping download."
    log_info "已找到游戏文件。跳过下载。"
fi

# ============================================
# Step 3: Install SMAPI if needed
# ============================================
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

# ============================================
# Step 4: Copy preinstalled mods
# ============================================
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

# ============================================
# Step 5: Setup virtual display (Xvfb)
# ============================================
log_step "Step 5: Starting virtual display..."

rm -f /tmp/.X99-lock /tmp/.X11-unix/X99 2>/dev/null

Xvfb :99 -screen 0 1280x720x24 -ac +extension GLX +render -noreset &
export DISPLAY=:99
sleep 3

log_info "Virtual display started on :99"

# ============================================
# Step 6: Start VNC server (if enabled)
# ============================================
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

# ============================================
# Step 7: Display configuration info
# ============================================
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

# ============================================
# Step 8: Start the game server
# ============================================
log_step "Step 8: Starting Stardew Valley server..."
log_info "Server is starting. This may take a minute..."
log_info "服务器正在启动。可能需要一分钟..."
log_warn ""
log_warn "FIRST RUN: You must create or load a save via VNC!"
log_warn "首次运行：您必须通过 VNC 创建或加载存档！"
log_warn ""

cd /home/steam/stardewvalley
exec ./StardewModdingAPI --server