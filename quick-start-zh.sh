#!/bin/bash
# =============================================================================
# Puppy Stardew Server - 快速启动脚本（中文版）
# =============================================================================
# 此脚本将帮助您在几分钟内设置星露谷物语专用服务器！
# =============================================================================

# 不在错误时退出 - 我们手动处理错误
set +e

# 输出颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # 无颜色
BOLD='\033[1m'

# =============================================================================
# 辅助函数
# =============================================================================

print_header() {
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}${BOLD}  🐶 小狗星谷服务器 - 快速启动${NC}"
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

print_step() {
    echo ""
    echo -e "${BOLD}$1${NC}"
}

ask_question() {
    echo -e "${CYAN}❓ $1${NC}"
}

# =============================================================================
# 主要设置函数
# =============================================================================

check_docker() {
    print_step "步骤 1: 检查 Docker 安装..."

    if ! command -v docker &> /dev/null; then
        print_error "Docker 未安装！"
        echo ""
        echo "请先安装 Docker："
        echo "  Ubuntu/Debian: curl -fsSL https://get.docker.com | sh"
        echo "  其他系统: https://docs.docker.com/get-docker/"
        echo ""
        exit 1
    fi

    if ! docker compose version &> /dev/null; then
        print_error "Docker Compose 不可用！"
        echo ""
        echo "请更新 Docker 到包含 Docker Compose 的新版本。"
        echo "访问: https://docs.docker.com/compose/install/"
        echo ""
        exit 1
    fi

    if ! docker ps &> /dev/null; then
        print_error "Docker 守护进程未运行或需要 sudo 权限！"
        echo ""
        echo "尝试以下方法之一："
        echo "  1. 启动 Docker: sudo systemctl start docker"
        echo "  2. 将用户添加到 docker 组: sudo usermod -aG docker \$USER"
        echo "     (然后注销并重新登录)"
        echo ""
        exit 1
    fi

    print_success "Docker 已安装并正在运行！"
}

download_files() {
    print_step "步骤 2: 下载配置文件..."

    if [ ! -d "puppy-stardew-server" ]; then
        print_info "克隆仓库..."
        if git clone https://github.com/truman-world/puppy-stardew-server.git; then
            print_success "仓库已克隆！"
        else
            print_error "克隆失败！请检查网络连接。"
            exit 1
        fi
    else
        print_info "目录已存在，跳过克隆"
    fi

    cd puppy-stardew-server || exit 1
}

configure_steam() {
    print_step "步骤 3: Steam 配置..."
    echo ""
    print_warning "重要：您必须在 Steam 上拥有星露谷物语！"
    print_info "游戏文件将通过您的 Steam 账户下载。"
    echo ""

    if [ -f ".env" ]; then
        ask_question ".env 文件已存在。是否要重新配置？(y/n)"
        read -r reconfigure
        if [[ ! $reconfigure =~ ^[Yy]$ ]]; then
            print_info "使用现有 .env 文件"
            return
        fi
    fi

    cp .env.example .env

    echo ""
    ask_question "请输入您的 Steam 用户名："
    read -r steam_username

    echo ""
    ask_question "请输入您的 Steam 密码："
    read -rs steam_password
    echo ""

    # 更新 .env 文件
    sed -i "s/^STEAM_USERNAME=.*/STEAM_USERNAME=$steam_username/" .env
    sed -i "s/^STEAM_PASSWORD=.*/STEAM_PASSWORD=$steam_password/" .env

    print_success "Steam 配置已保存！"
}

setup_directories() {
    print_step "步骤 4: 设置数据目录..."

    mkdir -p data/{saves,game,steam}

    print_info "设置正确的权限 (UID 1000)..."
    if chown -R 1000:1000 data/ 2>/dev/null; then
        print_success "目录已创建并设置权限！"
    else
        print_warning "无法设置权限，尝试使用 sudo..."
        if sudo chown -R 1000:1000 data/; then
            print_success "目录已创建并设置权限！"
        else
            print_error "设置权限失败！请手动运行: sudo chown -R 1000:1000 data/"
            exit 1
        fi
    fi
}

start_server() {
    print_step "步骤 5: 启动服务器..."
    echo ""

    print_info "拉取 Docker 镜像（可能需要几分钟）..."
    if docker compose pull 2>&1 | grep -q "Error"; then
        print_warning "拉取镜像时出现错误，尝试启动..."
    fi

    print_info "启动服务器..."
    if docker compose up -d; then
        print_success "服务器已启动！"
    else
        print_error "启动失败！"
        echo ""
        echo "查看日志以了解详情:"
        echo -e "  ${CYAN}docker compose logs${NC}"
        exit 1
    fi

    print_info "等待服务器初始化（5秒）..."
    sleep 5

    if docker ps | grep -q puppy-stardew; then
        print_success "服务器正在运行！"
    else
        print_error "容器启动失败！"
        echo ""
        echo "查看日志:"
        echo -e "  ${CYAN}docker logs puppy-stardew${NC}"
        exit 1
    fi
}

get_server_ip() {
    # 尝试获取公网 IP
    if command -v curl &> /dev/null; then
        public_ip=$(curl -s ifconfig.me 2>/dev/null || curl -s ip.sb 2>/dev/null || echo "")
        if [ -n "$public_ip" ]; then
            echo "$public_ip"
            return
        fi
    fi

    # 回退到本地 IP
    if command -v hostname &> /dev/null; then
        hostname -I 2>/dev/null | awk '{print $1}' || echo "your-server-ip"
    else
        echo "your-server-ip"
    fi
}

print_next_steps() {
    echo ""
    echo -e "${GREEN}${BOLD}🎉 设置完成！接下来该做什么：${NC}"
    echo ""

    echo -e "${BOLD}1. 监控下载进度：${NC}"
    echo "   docker logs -f puppy-stardew"
    echo ""
    echo -e "${YELLOW}   首次启动将下载约 1.5GB 游戏文件。${NC}"
    echo -e "${YELLOW}   根据您的网络速度，通常需要 5-15 分钟。${NC}"
    echo ""

    echo -e "${BOLD}2. 如果启用了 Steam 令牌：${NC}"
    echo "   - 您会看到要求输入 Steam 令牌代码的消息"
    echo "   - 附加到容器："
    echo -e "     ${CYAN}docker attach puppy-stardew${NC}"
    echo "   - 输入从邮件/手机应用获取的 Steam 令牌代码"
    echo -e "   - 按 ${YELLOW}Ctrl+P Ctrl+Q${NC} 分离（不要按 Ctrl+C！）"
    echo ""

    echo -e "${BOLD}3. 通过 VNC 初始设置（仅首次）：${NC}"
    echo "   - 下载 VNC 客户端（RealVNC、TightVNC 等）"
    echo -e "   - 连接到: ${CYAN}$(get_server_ip):5900${NC}"
    echo -e "   - 密码: ${CYAN}$(grep VNC_PASSWORD .env 2>/dev/null | cut -d'=' -f2 || echo 'stardew123')${NC}"
    echo "   - 在游戏中创建或加载存档文件"
    echo "   - 存档将在未来重启时自动加载！"
    echo ""

    echo -e "${BOLD}4. 玩家可以连接：${NC}"
    echo "   - 打开星露谷物语"
    echo "   - 点击"合作" → "加入局域网游戏""
    echo -e "   - 服务器应该会出现，或手动输入: ${CYAN}$(get_server_ip):24642${NC}"
    echo ""

    echo -e "${BOLD}常用命令：${NC}"
    echo -e "   查看日志:        ${CYAN}docker logs -f puppy-stardew${NC}"
    echo -e "   重启服务器:      ${CYAN}docker compose restart${NC}"
    echo -e "   停止服务器:      ${CYAN}docker compose down${NC}"
    echo -e "   检查健康:        ${CYAN}./health-check.sh${NC}"
    echo -e "   备份存档:        ${CYAN}./backup.sh${NC}"
    echo ""

    echo -e "${GREEN}${BOLD}🌟 享受您的即时睡眠星露谷服务器！${NC}"
    echo ""

    # 询问是否查看日志
    ask_question "现在要查看日志吗？(y/n)"
    read -r watch_logs
    if [[ $watch_logs =~ ^[Yy]$ ]]; then
        echo ""
        print_info "显示日志...（按 Ctrl+C 退出）"
        echo ""
        docker logs -f puppy-stardew
    fi
}

# =============================================================================
# 主流程
# =============================================================================

main() {
    print_header
    check_docker
    download_files
    configure_steam
    setup_directories
    start_server
    print_next_steps
}

# 运行主函数
main
