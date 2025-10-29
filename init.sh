#!/bin/bash
# Puppy Stardew Server - Initialization Script
# 小狗星谷服务器 - 初始化脚本
#
# This script sets up the required data directories with correct permissions
# 此脚本创建必需的数据目录并设置正确的权限

set -e

echo "=========================================="
echo "Puppy Stardew Server - Initialization"
echo "小狗星谷服务器 - 初始化"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    SUDO=""
    echo "✓ Running as root"
else
    SUDO="sudo"
    echo "⚠ Running as non-root user, will use sudo for permission changes"
    echo "⚠ 以非 root 用户运行，将使用 sudo 修改权限"
fi

# Create data directories
echo ""
echo "Creating data directories..."
echo "创建数据目录..."
mkdir -p data/{saves,game,steam,logs}
echo "✓ Directories created: data/saves, data/game, data/steam, data/logs"
echo "✓ 目录已创建: data/saves, data/game, data/steam, data/logs"

# Fix permissions (UID 1000 is the steam user inside container)
echo ""
echo "Setting permissions (UID 1000:1000)..."
echo "设置权限 (UID 1000:1000)..."
$SUDO chown -R 1000:1000 data/
echo "✓ Permissions set successfully"
echo "✓ 权限设置成功"

# Verify permissions
echo ""
echo "Verifying permissions..."
echo "验证权限..."
ls -la data/
echo ""

echo "=========================================="
echo "✓ Initialization complete!"
echo "✓ 初始化完成！"
echo "=========================================="
echo ""
echo "Next steps:"
echo "下一步："
echo "  1. Configure .env file with your Steam credentials"
echo "  1. 在 .env 文件中配置您的 Steam 凭证"
echo "  2. Run: docker compose up -d"
echo "  2. 运行: docker compose up -d"
echo ""
