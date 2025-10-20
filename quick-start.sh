#!/bin/bash
# =============================================================================
# Puppy Stardew Server - Quick Start Script
# 小狗星谷服务器 - 快速启动脚本
# =============================================================================
# This script will help you set up a Stardew Valley dedicated server in minutes!
# 此脚本将帮助您在几分钟内设置星露谷物语专用服务器！
# =============================================================================

# Don't exit on error - we handle errors manually
set +e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# =============================================================================
# Helper Functions
# =============================================================================

print_header() {
    echo ""
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}${BOLD}  🐶 Puppy Stardew Server - Quick Start${NC}"
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
# Main Setup Functions
# =============================================================================

check_docker() {
    print_step "Step 1: Checking Docker installation..."

    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed!"
        echo ""
        echo "Please install Docker first:"
        echo "  Ubuntu/Debian: curl -fsSL https://get.docker.com | sh"
        echo "  Other systems: https://docs.docker.com/get-docker/"
        echo ""
        exit 1
    fi

    if ! docker compose version &> /dev/null; then
        print_error "Docker Compose is not available!"
        echo ""
        echo "Please update Docker to a newer version that includes Docker Compose."
        echo "Visit: https://docs.docker.com/compose/install/"
        echo ""
        exit 1
    fi

    if ! docker ps &> /dev/null; then
        print_error "Docker daemon is not running or requires sudo!"
        echo ""
        echo "Try one of these:"
        echo "  1. Start Docker: sudo systemctl start docker"
        echo "  2. Add your user to docker group: sudo usermod -aG docker \$USER"
        echo "     (Then log out and back in)"
        echo ""
        exit 1
    fi

    print_success "Docker is installed and running!"
}

download_files() {
    print_step "Step 2: Downloading configuration files..."

    # Check if we're already in the repo
    if [ -f "docker-compose.yml" ] && [ -f ".env.example" ]; then
        print_success "Configuration files found!"
        return
    fi

    # Try to clone the repository
    if command -v git &> /dev/null; then
        print_info "Cloning repository..."
        git clone https://github.com/truman-world/puppy-stardew-server.git
        cd puppy-stardew-server
        print_success "Repository cloned!"
    else
        # Download files individually
        print_info "Git not found, downloading files individually..."

        if ! command -v wget &> /dev/null && ! command -v curl &> /dev/null; then
            print_error "Neither wget nor curl found!"
            echo "Please install git, wget, or curl to continue."
            exit 1
        fi

        mkdir -p puppy-stardew-server
        cd puppy-stardew-server

        BASE_URL="https://raw.githubusercontent.com/truman-world/puppy-stardew-server/main"

        if command -v curl &> /dev/null; then
            curl -fsSL "$BASE_URL/docker-compose.yml" -o docker-compose.yml
            curl -fsSL "$BASE_URL/.env.example" -o .env.example
        else
            wget -q "$BASE_URL/docker-compose.yml" -O docker-compose.yml
            wget -q "$BASE_URL/.env.example" -O .env.example
        fi

        print_success "Files downloaded!"
    fi
}

configure_steam() {
    print_step "Step 3: Steam configuration..."

    echo ""
    print_warning "IMPORTANT: You MUST own Stardew Valley on Steam!"
    print_info "Game files will be downloaded via your Steam account."
    echo ""

    # Check if .env already exists
    if [ -f ".env" ]; then
        ask_question ".env file already exists. Do you want to reconfigure? (y/n)"
        read -r reconfigure
        if [[ ! $reconfigure =~ ^[Yy]$ ]]; then
            print_info "Using existing .env file"
            return
        fi
    fi

    # Copy .env.example to .env
    cp .env.example .env

    # Ask for Steam username
    echo ""
    ask_question "Enter your Steam username:"
    read -r steam_username

    # Ask for Steam password (hidden input)
    echo ""
    ask_question "Enter your Steam password (input hidden):"
    read -rs steam_password
    echo ""

    # Validate inputs
    if [ -z "$steam_username" ] || [ -z "$steam_password" ]; then
        print_error "Steam username and password cannot be empty!"
        exit 1
    fi

    # Ask about Steam Guard
    echo ""
    print_info "If you have Steam Guard enabled, you'll need to enter a code later."
    print_info "Consider using the Steam Guard mobile app for faster codes."

    # Ask for VNC password
    echo ""
    ask_question "Enter VNC password (max 8 chars, press Enter for default 'stardew123'):"
    read -r vnc_password
    if [ -z "$vnc_password" ]; then
        vnc_password="stardew123"
    fi

    # Update .env file
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/STEAM_USERNAME=.*/STEAM_USERNAME=$steam_username/" .env
        sed -i '' "s/STEAM_PASSWORD=.*/STEAM_PASSWORD=$steam_password/" .env
        sed -i '' "s/VNC_PASSWORD=.*/VNC_PASSWORD=$vnc_password/" .env
    else
        # Linux
        sed -i "s/STEAM_USERNAME=.*/STEAM_USERNAME=$steam_username/" .env
        sed -i "s/STEAM_PASSWORD=.*/STEAM_PASSWORD=$steam_password/" .env
        sed -i "s/VNC_PASSWORD=.*/VNC_PASSWORD=$vnc_password/" .env
    fi

    print_success "Steam credentials configured!"
}

setup_directories() {
    print_step "Step 4: Setting up data directories..."

    # Create directories
    mkdir -p data/{saves,game,steam}

    # Fix permissions (UID 1000 is the steam user in the container)
    print_info "Setting correct permissions (UID 1000)..."

    # Check if we need sudo
    if [ -w "data" ]; then
        chown -R 1000:1000 data/
    else
        print_info "Need sudo to set permissions..."
        sudo chown -R 1000:1000 data/
    fi

    print_success "Directories created and permissions set!"
}

start_server() {
    print_step "Step 5: Starting the server..."

    echo ""
    print_info "Pulling Docker image (this may take a few minutes)..."
    docker compose pull

    echo ""
    print_info "Starting server..."
    docker compose up -d

    print_success "Server started!"

    echo ""
    print_info "Waiting for server to initialize (5 seconds)..."
    sleep 5

    # Check if container is running
    if ! docker ps | grep -q puppy-stardew; then
        print_error "Container failed to start!"
        echo ""
        echo "Check logs with: docker logs puppy-stardew"
        exit 1
    fi

    print_success "Server is running!"
}

show_next_steps() {
    print_step "🎉 Setup Complete! Here's what to do next:"

    echo ""
    echo -e "${BOLD}1. Monitor the download progress:${NC}"
    echo "   docker logs -f puppy-stardew"
    echo ""
    echo -e "${YELLOW}   The first startup will download ~1.5GB game files.${NC}"
    echo -e "${YELLOW}   This usually takes 5-15 minutes depending on your internet speed.${NC}"
    echo ""

    echo -e "${BOLD}2. If Steam Guard is enabled:${NC}"
    echo "   - You'll see a message asking for a Steam Guard code"
    echo "   - Attach to the container:"
    echo -e "     ${CYAN}docker attach puppy-stardew${NC}"
    echo "   - Enter your Steam Guard code from email/mobile app"
    echo -e "   - Press ${YELLOW}Ctrl+P Ctrl+Q${NC} to detach (NOT Ctrl+C!)"
    echo ""

    echo -e "${BOLD}3. Initial setup via VNC (first time only):${NC}"
    echo "   - Download a VNC client (RealVNC, TightVNC, etc.)"
    echo -e "   - Connect to: ${CYAN}$(get_server_ip):5900${NC}"
    echo -e "   - Password: ${CYAN}$(grep VNC_PASSWORD .env | cut -d'=' -f2)${NC}"
    echo "   - Create or load a save file in the game"
    echo "   - The save will auto-load on future restarts!"
    echo ""

    echo -e "${BOLD}4. Players can connect:${NC}"
    echo "   - Open Stardew Valley"
    echo "   - Click \"Co-op\" → \"Join LAN Game\""
    echo -e "   - Server should appear, or manually enter: ${CYAN}$(get_server_ip):24642${NC}"
    echo ""

    echo -e "${BOLD}Useful commands:${NC}"
    echo -e "   View logs:        ${CYAN}docker logs -f puppy-stardew${NC}"
    echo -e "   Restart server:   ${CYAN}docker compose restart${NC}"
    echo -e "   Stop server:      ${CYAN}docker compose down${NC}"
    echo -e "   Check health:     ${CYAN}./health-check.sh${NC}"
    echo -e "   Backup saves:     ${CYAN}./backup.sh${NC}"
    echo ""

    echo -e "${GREEN}${BOLD}🌟 Enjoy your instant-sleep Stardew Valley server!${NC}"
    echo ""

    # Ask if user wants to see logs
    ask_question "Do you want to watch the logs now? (y/n)"
    read -r watch_logs
    if [[ $watch_logs =~ ^[Yy]$ ]]; then
        echo ""
        print_info "Showing logs... (Press Ctrl+C to exit)"
        echo ""
        docker logs -f puppy-stardew
    fi
}

get_server_ip() {
    # Try to get public IP
    if command -v curl &> /dev/null; then
        public_ip=$(curl -s ifconfig.me 2>/dev/null || echo "")
        if [ -n "$public_ip" ]; then
            echo "$public_ip"
            return
        fi
    fi

    # Fall back to local IP
    if command -v hostname &> /dev/null; then
        hostname -I 2>/dev/null | awk '{print $1}' || echo "your-server-ip"
    else
        echo "your-server-ip"
    fi
}

# =============================================================================
# Main Script
# =============================================================================

main() {
    print_header

    check_docker
    download_files
    configure_steam
    setup_directories
    start_server
    show_next_steps
}

# Run main function
main
