#!/bin/bash
# Puppy Stardew Server Entrypoint Script - Steam Guard Auto-Handler Version v1.0.4
# 小狗星谷服务器启动脚本 - Steam Guard 自动处理版本 v1.0.4

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

# Function to read Steam Guard code from environment or file
get_steam_guard_code() {
    local code=""

    # Try environment variable first
    if [ -n "$STEAM_GUARD_CODE" ]; then
        echo "$STEAM_GUARD_CODE"
        return 0
    fi

    # Try file
    if [ -f "/tmp/steam_guard_code.txt" ]; then
        code=$(cat /tmp/steam_guard_code.txt 2>/dev/null)
        if [ -n "$code" ]; then
            echo "$code"
            return 0
        fi
    fi

    return 1
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
    log_error "For Steam Guard codes, set STEAM_GUARD_CODE environment variable."
    log_error "对于 Steam 令牌验证，设置STEAM_GUARD_CODE环境变量。"
    log_error "============================================"
    exit 1
else
    log_info "Steam username: $STEAM_USERNAME"
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

    # Clean up any existing Steam files that might be corrupted
    log_info "Cleaning up any corrupted Steam files..."
    rm -rf /home/steam/Steam/config/*
    rm -rf /home/steam/Steam/logs/*
    rm -rf /tmp/steam*

    # Ensure proper permissions
    chown -R steam:steam /home/steam/Steam 2>/dev/null || true

    # Create expect script for Steam Guard handling
    cat > /tmp/steam_expect.exp << 'EOF'
#!/usr/bin/expect -f
set timeout 600
set username [lindex $argv 0]
set password [lindex $argv 1]
set guard_code [lindex $argv 2]

spawn /home/steam/steamcmd/steamcmd.sh +force_install_dir /home/steam/stardewvalley +login \$username \$password +app_update 413150 validate +quit

expect {
    "Two-factor code:" {
        if {\$guard_code != ""} {
            send "\$guard_code\r"
            log_info "Using Steam Guard code from environment"
        } else {
            puts "\n[!] Steam Guard code required!"
            puts "\n[!] Options:"
            puts "\n[!] 1. Set STEAM_GUARD_CODE environment variable"
            puts "\n[!] 2. Create /tmp/steam_guard_code.txt with the code"
            puts "\n[!] 3. Use 'docker attach puppy-stardew' and enter code manually"
            puts "\n[!] Container will restart in 30 seconds..."
            sleep 30
            exit 1
        }
        exp_continue
    }
    "Login Failed" {
        puts "\n[-] Login failed!"
        exit 1
    }
    "Success! App '413150' fully installed" {
        puts "\n[+] Game downloaded successfully!"
        exit 0
    }
    "ERROR! Failed to install app '413150'" {
        puts "\n[-] Download failed!"
        if {[string match "*disk write failure*" \$expect_out(buffer)]} {
            puts "\n[-] Disk write failure detected!"
        }
        exit 2
    }
    timeout {
        puts "\n[-] Operation timed out!"
        exit 3
    }
    eof {
        exit 0
    }
}
EOF

    chmod +x /tmp/steam_expect.exp

    # Get Steam Guard code if available
    STEAM_GUARD_CODE_TO_USE=$(get_steam_guard_code || echo "")

    # Always use expect script to handle potential Steam Guard prompts
    log_info "Using expect script for Steam authentication (handles Steam Guard automatically)"
    /tmp/steam_expect.exp "$STEAM_USERNAME" "$STEAM_PASSWORD" "$STEAM_GUARD_CODE_TO_USE"

        # Check if Steam Guard was requested
        if grep -q "Two-factor code" /tmp/steam_output.log; then
            log_warn "Steam Guard is required for this account!"
            log_warn "此账户需要Steam Guard！"
            log_warn ""
            log_warn "Please choose one option:"
            log_warn "请选择一个选项："
            log_warn ""
            log_warn "1. Set STEAM_GUARD_CODE environment variable:"
            log_warn "   docker run -e STEAM_GUARD_CODE=your_code ..."
            log_warn ""
            log_warn "2. Create file with the code:"
            log_warn "   docker exec puppy-stardew sh -c 'echo \"your_code\" > /tmp/steam_guard_code.txt'"
            log_warn ""
            log_warn "3. Use docker attach to enter code manually:"
            log_warn "   docker attach puppy-stardew"
            log_warn ""
            log_warn "After setting the code, container will restart automatically."
            log_warn "设置代码后，容器将自动重启。"

            # Wait for user to set code
            log_info "Waiting for Steam Guard code..."
            for i in {1..300}; do
                sleep 2
                if [ -f "/tmp/steam_guard_code.txt" ]; then
                    CODE_TO_USE=$(cat /tmp/steam_guard_code.txt 2>/dev/null)
                    if [ -n "$CODE_TO_USE" ]; then
                        log_info "Steam Guard code received: ${CODE_TO_USE:0:3}****"
                        break
                    fi
                fi
                if [ -n "$STEAM_GUARD_CODE" ]; then
                    log_info "Steam Guard code set in environment!"
                    break
                fi
            done

            # Retry with Steam Guard code
            if [ -n "$CODE_TO_USE" ] || [ -n "$STEAM_GUARD_CODE" ]; then
                CODE_TO_USE=${STEAM_GUARD_CODE:-$CODE_TO_USE}
                /tmp/steam_expect.exp "$STEAM_USERNAME" "$STEAM_PASSWORD" "$CODE_TO_USE"
            fi
        fi
    fi

    # Check result
    EXIT_CODE=$?

    case $EXIT_CODE in
        0)
            save_state "game_downloaded"
            log_info "Game downloaded successfully!"
            log_info "游戏下载完成！"
            GAME_DOWNLOADED=true
            ;;
        1)
            log_error "Steam authentication failed!"
            log_error "Steam认证失败！"
            save_state "auth_failed"
            exit 1
            ;;
        2)
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
        3)
            log_error "Download timed out!"
            log_error "下载超时！"
            save_state "auth_failed"
            exit 1
            ;;
        *)
            log_error "Download failed with exit code: $EXIT_CODE"
            log_error "下载失败，退出码：$EXIT_CODE"
            save_state "auth_failed"
            exit 1
            ;;
    esac

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
# Step 8: Start game server
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
exec /home/steam/smapi/StardewModdingAPI --server