#!/bin/bash
# Puppy Stardew Server Entrypoint Script - Robust Version
# 小狗星谷服务器启动脚本 - 稳健版本

set -e

# Color codes for pretty logging
# 彩色日志输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
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

# Check if this is a retry
if [ "$1" = "--retry" ]; then
    RETRY_COUNT=$((RETRY_COUNT + 1))
    log_info "Retry attempt $RETRY_COUNT of $MAX_RETRIES"
    log_info "重试次数 $RETRY_COUNT / $MAX_RETRIES"

    if [ $RETRY_COUNT -gt $MAX_RETRIES ]; then
        log_error "Maximum retry attempts reached!"
        log_error "达到最大重试次数！"
        log_error ""
        log_error "Please check your Steam credentials and try again:"
        log_error "请检查您的Steam凭证并重试："
        log_error "1. Stop container: docker compose stop"
        log_error "2. Update credentials in .env file"
        log_error "3. Restart: docker compose up -d"
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

# ============================================
# Step 1: Validate Steam Credentials
# 步骤 1: 验证 Steam 凭证
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
else
    log_info "Steam username: $STEAM_USERNAME"

    # Check if we previously failed authentication
    if [ "$(load_state)" = "auth_failed" ]; then
        log_warn "Previous authentication attempt failed."
        log_warn "之前的认证尝试失败。"

        # If we've exceeded retries, wait for manual intervention
        if [ $RETRY_COUNT -ge 1 ]; then
            log_error "Authentication failed multiple times."
            log_error "认证多次失败。"
            log_error ""
            log_error "Please check:"
            log_error "请检查："
            log_error "1. Steam username and password are correct"
            log_error "   Steam用户名和密码是否正确"
            log_error "2. Steam Guard is not blocking authentication"
            log_error "   Steam Guard没有阻止认证"
            log_error "3. Your account owns Stardew Valley"
            log_error "   您的账户拥有星露谷物语"
            exit 1
        fi
    fi
fi

# ============================================
# Step 2: Download Stardew Valley via Steam
# 步骤 2: 通过 Steam 下载星露谷物语
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

    # Create Steam download script with better error handling
    cat > /tmp/download_game.sh << 'EOF'
#!/bin/bash
set -e

# Check for Steam Guard
GUARD_NEEDED=false

# Function to handle Steam Guard
handle_steam_guard() {
    if [ "$GUARD_NEEDED" = "true" ]; then
        echo ""
        echo "============================================="
        echo "STEAM GUARD REQUIRED"
        echo "需要 STEAM 令牌验证"
        echo "============================================="
        echo ""
        echo "Container is stopping for manual input:"
        echo "容器停止，等待手动输入："
        echo ""
        echo "1. Run: docker attach puppy-stardew"
        echo "2. Enter Steam Guard code when prompted"
        echo "3. Press Ctrl+P, then Ctrl+Q to detach"
        echo ""
        echo "After entering the code, the container will restart automatically."
        echo "输入验证码后，容器会自动重启。"
        echo ""

        # Signal that we need Steam Guard
        touch /tmp/steam_guard_needed

        # Stop container to allow attachment
        exit 2
    fi
}

# Run SteamCMD with timeout and error handling
timeout 600s /home/steam/steamcmd/steamcmd.sh \
    +force_install_dir /home/steam/stardewvalley \
    +login "$STEAM_USERNAME" "$STEAM_PASSWORD" \
    +app_update 413150 validate \
    +quit 2>&1 | tee /tmp/steam_output.log

# Check output for Steam Guard requirement
if grep -q "Two-factor code" /tmp/steam_output.log; then
    GUARD_NEEDED=true
    handle_steam_guard
fi

# Check for authentication errors
if grep -q "Login Failed" /tmp/steam_output.log || grep -q "Invalid Password" /tmp/steam_output.log; then
    echo "Authentication failed!"
    exit 1
fi

# Check for disk write failure
if grep -q "Disk write failure" /tmp/steam_output.log; then
    echo "Disk write failure detected!"
    echo "Please check disk space and permissions."
    exit 3
fi

# Check for successful download
if grep -q "Success! App '413150' fully installed" /tmp/steam_output.log; then
    echo "Game downloaded successfully!"
    exit 0
else
    echo "Download failed for unknown reason"
    exit 4
fi
EOF

    chmod +x /tmp/download_game.sh

    # Execute download script
    if /tmp/download_game.sh; then
        save_state "game_downloaded"
        log_info "Game downloaded successfully!"
        log_info "游戏下载完成！"
        GAME_DOWNLOADED=true
    else
        exit_code=$?

        case $exit_code in
            1)
                log_error "Steam authentication failed!"
                log_error "Steam认证失败！"
                save_state "auth_failed"
                log_error "Container will restart for retry..."
                log_error "容器将重启重试..."
                # Trigger restart with retry flag
                exec /home/steam/entrypoint.sh --retry
                ;;
            2)
                # Steam Guard needed - container stopped
                log_error "Steam Guard authentication required!"
                log_error "需要Steam令牌验证！"
                log_error "Use 'docker attach puppy-stardew' to enter code"
                exit 2
                ;;
            3)
                log_error "Disk write failure!"
                log_error "磁盘写入失败！"
                log_error ""
                log_error "To fix:"
                log_error "修复方法："
                log_error "1. Stop container: docker compose stop"
                log_error "2. Check disk space: df -h"
                log_error "3. Fix permissions: chown -R 1000:1000 data/"
                log_error "4. Restart: docker compose up -d"
                exit 3
                ;;
            *)
                log_error "Download failed with exit code: $exit_code"
                log_error "下载失败，退出码：$exit_code"
                exit 4
                ;;
        esac
    fi
else
    log_info "Game files found. Skipping download."
    log_info "已找到游戏文件。跳过下载。"
fi

# ============================================
# Step 3: Install SMAPI if needed
# 步骤 3: 安装 SMAPI（如需要）
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
# 步骤 4: 复制预装模组
# ============================================
log_step "Step 4: Installing mods..."

mkdir -p /home/steam/stardewvalley/Mods

# Copy mods from image to game directory
# 从镜像复制模组到游戏目录
if [ -d "/home/steam/preinstalled-mods" ]; then
    log_info "Installing preinstalled mods..."
    # Remove existing mods directory and recreate to avoid permission issues
    rm -rf /home/steam/stardewvalley/Mods
    mkdir -p /home/steam/stardewvalley/Mods
    # Copy all mods
    cp -r /home/steam/preinstalled-mods/* /home/steam/stardewvalley/Mods/

    log_info "Installed mods:"
    log_info "已安装模组："
    ls -1 /home/steam/stardewvalley/Mods/ | while read mod; do
        log_info "  ✓ $mod"
    done
fi

# ============================================
# Step 5: Setup virtual display (Xvfb)
# 步骤 5: 设置虚拟显示
# ============================================
log_step "Step 5: Starting virtual display..."

# Clean up any existing X11 lock files
rm -f /tmp/.X99-lock /tmp/.X11-unix/X99 2>/dev/null

# Start Xvfb (X Virtual Framebuffer)
Xvfb :99 -screen 0 1280x720x24 -ac +extension GLX +render -noreset &
export DISPLAY=:99
sleep 3

log_info "Virtual display started on :99"

# ============================================
# Step 6: Start VNC server (if enabled)
# 步骤 6: 启动 VNC 服务器（如启用）
# ============================================
if [ "$ENABLE_VNC" = "true" ]; then
    log_step "Step 6: Starting VNC server..."

    VNC_PASSWORD=${VNC_PASSWORD:-"stardew123"}

    # VNC protocol only supports 8 characters
    # VNC 协议仅支持 8 个字符
    if [ ${#VNC_PASSWORD} -gt 8 ]; then
        log_warn "VNC password is longer than 8 characters!"
        log_warn "VNC 密码超过 8 个字符！"
        log_warn "Only the first 8 characters will be used."
        log_warn "仅使用前 8 个字符。"
        VNC_PASSWORD="${VNC_PASSWORD:0:8}"
    fi

    # Write password to file (x11vnc requires file for background mode)
    VNC_PASSWD_FILE=/tmp/vncpasswd
    echo -n "$VNC_PASSWORD" > "$VNC_PASSWD_FILE"
    chmod 600 "$VNC_PASSWD_FILE"

    # Start openbox window manager
    openbox &

    # Start x11vnc with password file
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
# 步骤 7: 显示配置信息
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
# 步骤 8: 启动游戏服务器
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