#!/bin/bash
# Auto-Enable Always On Server - Background Script
# 自动启用 Always On Server 的后台脚本

SMAPI_LOG="/home/steam/.config/StardewValley/ErrorLogs/SMAPI-latest.txt"
MAX_WAIT=120  # 最多等待 120 秒
CHECK_INTERVAL=2  # 每 2 秒检查一次

log() {
    echo -e "\033[0;36m[Auto-Enable-Server]\033[0m $1"
}

log "启动 Always On Server 自动启用服务..."

# 等待 tmux 会话完全初始化
log "等待 tmux 会话初始化..."
sleep 5

# 确认 tmux 会话存在
while ! tmux list-sessions 2>/dev/null | grep -q "smapi"; do
    log "等待 tmux 会话创建..."
    sleep 2
done
log "✓ tmux 会话已就绪"

log "等待存档加载完成..."

elapsed=0
while [ $elapsed -lt $MAX_WAIT ]; do
    # 检查 SMAPI 日志文件是否存在
    if [ -f "$SMAPI_LOG" ]; then
        # 检查存档是否加载成功
        if grep -q "SAVE LOADED SUCCESSFULLY\|Context: loaded save" "$SMAPI_LOG" 2>/dev/null; then
            log "✓ 检测到存档已加载"

            # 额外等待 5 秒，确保所有模组初始化完成
            log "等待模组初始化..."
            sleep 5

            # 发送 server 命令到 SMAPI（重试最多3次）
            MAX_RETRIES=3
            RETRY=0
            SUCCESS=false

            while [ $RETRY -lt $MAX_RETRIES ]; do
                log "发送 'server' 命令启用 Always On Server (尝试 $((RETRY + 1))/$MAX_RETRIES)..."

                # 通过 tmux 发送命令
                if command -v tmux >/dev/null 2>&1; then
                    tmux send-keys -t smapi "server" ENTER 2>/dev/null
                    if [ $? -eq 0 ]; then
                        log "✓ 命令已发送到 tmux"
                        sleep 3

                        # 验证是否成功
                        if grep -q "Auto [Mm]ode [Oo]n" "$SMAPI_LOG" 2>/dev/null; then
                            log "✅ Always On Server 已成功启用！"
                            log "✅ 自动暂停功能已激活（无玩家时暂停，有玩家时继续）"
                            SUCCESS=true
                            break
                        else
                            log "⚠ 未检测到成功消息，等待后重试..."
                            sleep 2
                        fi
                    else
                        log "⚠ tmux send-keys 失败"
                    fi
                fi

                RETRY=$((RETRY + 1))
            done

            if [ "$SUCCESS" = true ]; then
                exit 0
            else
                log "⚠ 自动启用失败，请手动操作："
                log "   方法1: 通过 VNC 连接，在游戏中按 F9 键"
                log "   方法2: 在游戏控制台输入: server"
                exit 1
            fi
        fi
    fi

    sleep $CHECK_INTERVAL
    elapsed=$((elapsed + CHECK_INTERVAL))
done

log "⚠ 等待超时（${MAX_WAIT}秒），存档未加载"
log "请通过 VNC 手动加载存档并按 F9 启用 Always On Server"
exit 1
