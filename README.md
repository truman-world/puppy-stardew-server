# 🐶 Puppy Stardew Server | 星露谷物语服务器一键搭建开服联机

<div align="center">

[![Docker Pulls](https://img.shields.io/docker/pulls/truemanlive/puppy-stardew-server)](https://hub.docker.com/r/truemanlive/puppy-stardew-server)
[![Docker Image Size](https://img.shields.io/docker/image-size/truemanlive/puppy-stardew-server)](https://hub.docker.com/r/truemanlive/puppy-stardew-server)
[![GitHub Stars](https://img.shields.io/github/stars/truman-world/puppy-stardew-server)](https://github.com/truman-world/puppy-stardew-server)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

[English](#english) | [中文](#中文)

**One-Command Stardew Valley Server Deployment | Cross-Platform Multiplayer Support**

**一键部署星露谷物语服务器 | 全平台联机支持**

</div>

---

## English

### 🚀 Deploy Your Stardew Valley Server in 3 Minutes

Setting up a **Stardew Valley dedicated server** has never been easier! With **one simple command**, you can have your own 24/7 multiplayer server running on **any platform** - PC, Mac, Linux, iOS, and Android players can all join together.

**Perfect for:**
- ✅ **Remote Multiplayer** - Play with friends anywhere in the world
- ✅ **Cross-Platform Gaming** - iOS, Android, and PC players together
- ✅ **24/7 Always-On Server** - Join anytime, no need for host to be online
- ✅ **Easy Setup** - One command deployment with Docker Compose
- ✅ **Low Resource Usage** - Runs smoothly on just 2GB RAM

### ✨ Key Features

- **One-Command Deploy** 🚀 - Deploy in 3 minutes with a single command
- **Cross-Platform Support** 📱 - PC, Mac, Linux, iOS, Android all supported
- **24/7 Dedicated Server** ⚡ - Runs independently without requiring the host to be online
- **Docker Compose** 🐳 - Easy deployment and management
- **Resource Efficient** 💪 - Runs smoothly on servers with only 2GB RAM
- **Auto-Save Loading** 💾 - Automatically loads your save on server restart
- **VNC Remote Access** 🖥️ - Built-in VNC for easy first-time setup
- **Instant Sleep** 🛏️ - Bonus feature: Players can sleep at any time without waiting
- **Hidden Host** 👻 - Host player is automatically hidden for seamless gameplay

<div align="center">

![Instant Sleep Demo](https://raw.githubusercontent.com/truman-world/puppy-stardew-server/main/screenshots/game/instant-sleep-demo.gif)

*Bonus Feature: Instant sleep - Click bed → Sleep instantly → New day begins!*

</div>

### 🚀 Quick Start (2 Options)

#### 📺 Watch the One-Command Deployment in Action

[![asciicast](https://asciinema.org/a/SYBS2qWsb5ZlSolbFPuoA7EJY.svg)](https://asciinema.org/a/SYBS2qWsb5ZlSolbFPuoA7EJY)

<details open>
<summary><h4>⭐ Option 1: One-Command Deployment (Recommended for Beginners)</h4></summary>

**English Version:**

```bash
curl -sSL https://raw.githubusercontent.com/truman-world/puppy-stardew-server/main/quick-start.sh | bash
```

**中文版 (Chinese Version):**

```bash
curl -sSL https://raw.githubusercontent.com/truman-world/puppy-stardew-server/main/quick-start-zh.sh | bash
```

The script will:
- ✅ Check your Docker installation
- ✅ Guide you to enter Steam credentials
- ✅ Create all necessary directories with correct permissions
- ✅ Generate configuration files
- ✅ Start the server
- ✅ Show you connection information

**That's it!** ☕ Grab a coffee while it downloads the game (~1.5GB).

</details>

<details>
<summary><h4>Option 2: Manual Setup (For Advanced Users)</h4></summary>

#### Prerequisites

- Docker and Docker Compose installed ([Get Docker](https://docs.docker.com/get-docker/))
- A Steam account **with Stardew Valley purchased**
- 2GB RAM minimum, 4GB recommended
- 2GB free disk space

#### Step 1: Download Configuration Files

```bash
# Clone the repository
git clone https://github.com/truman-world/puppy-stardew-server.git
cd puppy-stardew-server

# Or download files directly
mkdir puppy-stardew && cd puppy-stardew
wget https://raw.githubusercontent.com/truman-world/puppy-stardew-server/main/docker-compose.yml
wget https://raw.githubusercontent.com/truman-world/puppy-stardew-server/main/.env.example
```

#### Step 2: Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit with your Steam credentials
nano .env  # or use your favorite editor
```

**`.env` example:**
```env
STEAM_USERNAME=your_steam_username
STEAM_PASSWORD=your_steam_password
ENABLE_VNC=true
VNC_PASSWORD=stardew123
```

⚠️ **Important**: You MUST own Stardew Valley on Steam. Game files are downloaded via your account.

#### Step 3: Fix Permissions (Critical!)

```bash
# Create data directories
mkdir -p data/{saves,game,steam}

# Set correct ownership (steam user in container is UID 1000)
chown -R 1000:1000 data/

# Or use sudo if needed
sudo chown -R 1000:1000 data/
```

#### Step 4: Start the Server

```bash
# Start the server
docker compose up -d

# View logs
docker logs -f puppy-stardew
```

**If Steam Guard is enabled**, you'll need to enter the code:

```bash
docker attach puppy-stardew
# Enter your Steam Guard code
# Press Ctrl+P Ctrl+Q to detach (NOT Ctrl+C!)
```

</details>

### 🎮 Initial Setup (First Run Only)

After the server starts, you need to create or load a save file **once**:

1. **Connect to VNC:**
   - Address: `your-server-ip:5900`
   - Password: The `VNC_PASSWORD` from your `.env` file
   - VNC Client: [RealVNC](https://www.realvnc.com/en/connect/download/viewer/), [TightVNC](https://www.tightvnc.com/), or any VNC viewer

2. **In the VNC window:**
   - Create a new farm, or
   - Load an existing save

3. **Once loaded:**
   - The ServerAutoLoad mod will remember your save
   - Future restarts will auto-load this save
   - You can disconnect from VNC

4. **Players can now connect!**
   - Open Stardew Valley
   - Click "Co-op" → "Join LAN Game"
   - Your server should appear in the list
   - Or manually enter: `your-server-ip:24642`

### 📦 What's Inside

#### Pre-installed Mods

| Mod | Version | Purpose |
|-----|---------|---------|
| **AutoHideHost** | v1.0.0 | Custom mod - Hides host player and enables instant sleep |
| **Always On Server** | v1.20.3 | Keeps server running 24/7 without host player |
| **ServerAutoLoad** | v1.2.1 | Custom mod - Automatically loads your save on startup |

All mods are pre-configured and ready to use!

### 🛠️ Common Tasks

<details>
<summary><b>View Server Logs</b></summary>

#### 📺 Demo: Viewing Server Logs

[![asciicast](https://asciinema.org/a/ny9f5DL7FPXhAfApmu2HGhkI8.svg)](https://asciinema.org/a/ny9f5DL7FPXhAfApmu2HGhkI8)

```bash
# Real-time logs
docker logs -f puppy-stardew

# Last 100 lines
docker logs --tail 100 puppy-stardew
```
</details>

<details>
<summary><b>Restart Server</b></summary>

```bash
docker compose restart
```
</details>

<details>
<summary><b>Stop Server</b></summary>

```bash
docker compose down
```
</details>

<details>
<summary><b>Update to Latest Version</b></summary>

```bash
docker compose down
docker pull truemanlive/puppy-stardew-server:latest
docker compose up -d
```
</details>

<details>
<summary><b>Backup Your Saves</b></summary>

#### 📺 Demo: Creating a Backup

[![asciicast](https://asciinema.org/a/6xBjsP6Pi7MxLKs8vNraHpLre.svg)](https://asciinema.org/a/6xBjsP6Pi7MxLKs8vNraHpLre)

```bash
# Manual backup
tar -czf backup-$(date +%Y%m%d).tar.gz data/saves/

# Or use the backup script (after running quick-start.sh)
./backup.sh
```
</details>

<details>
<summary><b>Check Server Health</b></summary>

#### 📺 Demo: Health Check Script

[![asciicast](https://asciinema.org/a/nvKlK8nCOKPSke52z9ZjGuUTX.svg)](https://asciinema.org/a/nvKlK8nCOKPSke52z9ZjGuUTX)

```bash
# Use the health check script (after running quick-start.sh)
./health-check.sh

# Or manually
docker ps | grep puppy-stardew  # Should show "healthy"
```
</details>

### ❓ Troubleshooting

<details>
<summary><b>Error: "Disk write failure" when downloading game</b></summary>

**Cause**: Data directories have wrong permissions.

**Fix**:
```bash
chown -R 1000:1000 data/
docker compose restart
```

The container runs as user ID 1000, so files must be owned by UID 1000.
</details>

<details>
<summary><b>Steam Guard code required</b></summary>

If you have Steam Guard enabled:

```bash
docker attach puppy-stardew
# Enter the code from your email/mobile app
# Press Ctrl+P Ctrl+Q to detach (NOT Ctrl+C!)
```

**Tip**: Consider using Steam Guard mobile app for faster codes.
</details>

<details>
<summary><b>Game won't start</b></summary>

1. Check logs: `docker logs puppy-stardew`
2. Verify Steam credentials in `.env`
3. Ensure you own Stardew Valley on Steam
4. Check disk space: `df -h`
5. Restart: `docker compose restart`
</details>

<details>
<summary><b>Players can't connect</b></summary>

1. **Check firewall**: Port `24642/udp` must be open
   ```bash
   # Ubuntu/Debian
   sudo ufw allow 24642/udp

   # CentOS/RHEL
   sudo firewall-cmd --add-port=24642/udp --permanent
   sudo firewall-cmd --reload
   ```

2. **Verify server is running**:
   ```bash
   docker ps | grep puppy-stardew
   ```

3. **Check if save is loaded**: Connect via VNC or check logs for "Save loaded"

4. **Ensure game versions match**: Server and clients must have same Stardew Valley version
</details>

<details>
<summary><b>VNC won't connect</b></summary>

1. Check port `5900/tcp` is accessible
2. Verify VNC password (max 8 characters)
3. Try a different VNC client ([RealVNC](https://www.realvnc.com/en/connect/download/viewer/))
4. Check logs: `docker logs puppy-stardew | grep -i vnc`
</details>

<details>
<summary><b>Server uses too much RAM</b></summary>

Edit `docker-compose.yml` to reduce memory limit:

```yaml
deploy:
  resources:
    limits:
      memory: 1.5G  # Reduce from 2G
```

Then restart:
```bash
docker compose up -d
```
</details>

### 🔧 Advanced Configuration

<details>
<summary><b>Customize Mod Settings</b></summary>

Mod configs are in `/home/steam/stardewvalley/Mods/` inside the container:

```bash
# Edit AutoHideHost config
docker exec puppy-stardew nano /home/steam/stardewvalley/Mods/AutoHideHost/config.json

# Edit Always On Server config
docker exec puppy-stardew nano /home/steam/stardewvalley/Mods/AlwaysOnServer/config.json

# Edit ServerAutoLoad config
docker exec puppy-stardew nano /home/steam/stardewvalley/Mods/ServerAutoLoad/config.json
```

After editing, restart the server:
```bash
docker compose restart
```
</details>

<details>
<summary><b>Change Port Numbers</b></summary>

Edit `docker-compose.yml`:

```yaml
ports:
  - "24642:24642/udp"  # Change first number to your desired port
  - "5900:5900/tcp"    # VNC port
```

Restart after changes:
```bash
docker compose up -d
```
</details>

<details>
<summary><b>Disable VNC After Setup</b></summary>

Edit `.env`:
```env
ENABLE_VNC=false
```

Restart:
```bash
docker compose up -d
```

This saves ~50MB RAM.
</details>

### 📝 System Requirements

**Server:**
- **CPU**: 1+ cores (2+ recommended)
- **RAM**: 2GB minimum (4GB recommended for 4+ players)
- **Disk**: 2GB free space
- **OS**: Linux, Windows (Docker Desktop), macOS (Docker Desktop)
- **Network**: Open port 24642/UDP (and 5900/TCP for VNC)

**Clients:**
- Stardew Valley (any platform: PC, Mac, Linux, iOS, Android)
- Same game version as server
- LAN or internet connection to server

### 📊 Performance Tips

- **Low RAM servers** (2GB): Set memory limit to 1.5G in docker-compose.yml
- **Multiple players**: Increase to 4GB RAM for 4+ concurrent players
- **Reduce bandwidth**: Players on slow connections should avoid hosting events
- **SSD recommended**: Faster load times for saves

### 📜 License & Legal

**License**: MIT License - free to use, modify, and distribute.

**Important Legal Notes:**
- ✅ You MUST own Stardew Valley on Steam
- ✅ Game files are downloaded via YOUR Steam account
- ✅ This is NOT a piracy tool
- ✅ Mods follow their original licenses:
  - Always On Server: [GPL-3.0](https://github.com/funny-snek/Always-On-Server-for-Multiplayer)
  - ServerAutoLoad: MIT (custom mod for this project)
  - AutoHideHost: MIT (custom mod for this project)

### 🙏 Credits

- **Stardew Valley** by [ConcernedApe](https://www.stardewvalley.net/)
- **SMAPI** by [Pathoschild](https://smapi.io/)
- **Always On Server** by funny-snek & Zuberii
- **Docker** by Docker, Inc.

### 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Submit a pull request

### 💬 Support & Community

- **Bug Reports**: [GitHub Issues](https://github.com/truman-world/puppy-stardew-server/issues)
- **Questions**: [GitHub Discussions](https://github.com/truman-world/puppy-stardew-server/discussions)
- **Docker Hub**: [truemanlive/puppy-stardew-server](https://hub.docker.com/r/truemanlive/puppy-stardew-server)

### ⭐ Star History

If this project helps you, consider giving it a star! ⭐

---

## 中文

### 🚀 3分钟搭建星露谷物语服务器

搭建**星露谷物语专用服务器**从未如此简单！通过**一条命令**，您就可以拥有自己的 24/7 多人联机服务器，支持**全平台**联机 - PC、Mac、Linux、iOS 和 Android 玩家都可以一起游戏。

**完美适用于：**
- ✅ **远程联机** - 与世界各地的朋友一起玩
- ✅ **跨平台游戏** - iOS、Android 和 PC 玩家一起联机
- ✅ **24/7 在线服务器** - 随时加入，无需房主在线
- ✅ **简单搭建** - 使用 Docker Compose 一键部署
- ✅ **低资源占用** - 仅需 2GB 内存即可流畅运行

### ✨ 核心功能

- **一键部署** 🚀 - 一条命令 3 分钟完成部署
- **全平台支持** 📱 - PC、Mac、Linux、iOS、Android 全支持
- **24/7 专用服务器** ⚡ - 服务器独立运行，不需要房主在线
- **Docker Compose** 🐳 - 轻松部署和管理
- **资源高效** 💪 - 2GB 内存服务器也能流畅运行
- **自动加载存档** 💾 - 重启容器，存档自动加载
- **VNC 远程访问** 🖥️ - 内置 VNC，首次设置超简单
- **即时睡眠** 🛏️ - 附加功能：玩家随时可以睡觉，无需等待
- **隐藏房主** 👻 - 房主玩家自动隐藏，零干扰

<div align="center">

![即时睡眠演示](https://raw.githubusercontent.com/truman-world/puppy-stardew-server/main/screenshots/game/instant-sleep-demo.gif)

*附加功能：即时睡眠 - 点击床 → 立即睡眠 → 新的一天开始！*

</div>

### 🚀 快速开始（2 种方式）

#### 📺 观看一键部署演示

[![asciicast](https://asciinema.org/a/SYBS2qWsb5ZlSolbFPuoA7EJY.svg)](https://asciinema.org/a/SYBS2qWsb5ZlSolbFPuoA7EJY)

<details open>
<summary><h4>⭐ 方式 1：一键部署（推荐小白使用）</h4></summary>

**英文版 (English Version):**

```bash
curl -sSL https://raw.githubusercontent.com/truman-world/puppy-stardew-server/main/quick-start.sh | bash
```

**中文版:**

```bash
curl -sSL https://raw.githubusercontent.com/truman-world/puppy-stardew-server/main/quick-start-zh.sh | bash
```

脚本会自动：
- ✅ 检查 Docker 安装
- ✅ 引导输入 Steam 凭证
- ✅ 创建必要目录并设置正确权限
- ✅ 生成配置文件
- ✅ 启动服务器
- ✅ 显示连接信息

**就这么简单！** ☕ 下载游戏文件时去喝杯咖啡（约 1.5GB）。

</details>

<details>
<summary><h4>方式 2：手动部署（进阶用户）</h4></summary>

#### 前置要求

- 已安装 Docker 和 Docker Compose（[安装 Docker](https://docs.docker.com/get-docker/)）
- 一个 Steam 账户，**并且已购买星露谷物语**
- 最低 2GB 内存，推荐 4GB
- 2GB 可用磁盘空间

#### 步骤 1：下载配置文件

```bash
# 克隆仓库
git clone https://github.com/truman-world/puppy-stardew-server.git
cd puppy-stardew-server

# 或者直接下载文件
mkdir puppy-stardew && cd puppy-stardew
wget https://raw.githubusercontent.com/truman-world/puppy-stardew-server/main/docker-compose.yml
wget https://raw.githubusercontent.com/truman-world/puppy-stardew-server/main/.env.example
```

#### 步骤 2：配置环境变量

```bash
# 复制环境变量模板
cp .env.example .env

# 编辑并填写您的 Steam 凭证
nano .env  # 或使用您喜欢的编辑器
```

**`.env` 示例：**
```env
STEAM_USERNAME=your_steam_username
STEAM_PASSWORD=your_steam_password
ENABLE_VNC=true
VNC_PASSWORD=stardew123
```

⚠️ **重要**：您必须在 Steam 上拥有星露谷物语。游戏文件通过您的账户下载。

#### 步骤 3：修复权限（关键步骤！）

```bash
# 创建数据目录
mkdir -p data/{saves,game,steam}

# 设置正确的所有权（容器内 steam 用户的 UID 是 1000）
chown -R 1000:1000 data/

# 如果需要，使用 sudo
sudo chown -R 1000:1000 data/
```

#### 步骤 4：启动服务器

```bash
# 启动服务器
docker compose up -d

# 查看日志
docker logs -f puppy-stardew
```

**如果启用了 Steam 令牌**，您需要输入验证码：

```bash
docker attach puppy-stardew
# 输入您的 Steam 令牌代码
# 按 Ctrl+P Ctrl+Q 分离（不是 Ctrl+C！）
```

</details>

### 🎮 初始设置（仅首次运行）

服务器启动后，您需要**一次性**创建或加载存档：

1. **连接到 VNC：**
   - 地址：`服务器IP:5900`
   - 密码：您在 `.env` 文件中设置的 `VNC_PASSWORD`
   - VNC 客户端：[RealVNC](https://www.realvnc.com/en/connect/download/viewer/)、[TightVNC](https://www.tightvnc.com/) 或任何 VNC 查看器

2. **在 VNC 窗口中：**
   - 创建新农场，或
   - 加载现有存档

3. **加载完成后：**
   - ServerAutoLoad 模组会记住您的存档
   - 以后重启会自动加载此存档
   - 您可以断开 VNC 连接了

4. **玩家现在可以连接了！**
   - 打开星露谷物语
   - 点击"合作" → "加入局域网游戏"
   - 您的服务器应该出现在列表中
   - 或手动输入：`服务器IP:24642`

### 📦 包含内容

#### 预装模组

| 模组 | 版本 | 用途 |
|-----|------|------|
| **AutoHideHost** | v1.0.0 | 自定义模组 - 隐藏房主玩家并启用即时睡眠 |
| **Always On Server** | v1.20.3 | 保持服务器 24/7 运行，不需要房主在线 |
| **ServerAutoLoad** | v1.2.1 | 自定义模组 - 启动时自动加载存档 |

所有模组都已预配置，开箱即用！

### 🛠️ 常用操作

<details>
<summary><b>查看服务器日志</b></summary>

#### 📺 演示：查看服务器日志

[![asciicast](https://asciinema.org/a/ny9f5DL7FPXhAfApmu2HGhkI8.svg)](https://asciinema.org/a/ny9f5DL7FPXhAfApmu2HGhkI8)

```bash
# 实时日志
docker logs -f puppy-stardew

# 最后 100 行
docker logs --tail 100 puppy-stardew
```
</details>

<details>
<summary><b>重启服务器</b></summary>

```bash
docker compose restart
```
</details>

<details>
<summary><b>停止服务器</b></summary>

```bash
docker compose down
```
</details>

<details>
<summary><b>更新到最新版本</b></summary>

```bash
docker compose down
docker pull truemanlive/puppy-stardew-server:latest
docker compose up -d
```
</details>

<details>
<summary><b>备份存档</b></summary>

#### 📺 演示：创建备份

[![asciicast](https://asciinema.org/a/6xBjsP6Pi7MxLKs8vNraHpLre.svg)](https://asciinema.org/a/6xBjsP6Pi7MxLKs8vNraHpLre)

```bash
# 手动备份
tar -czf backup-$(date +%Y%m%d).tar.gz data/saves/

# 或使用备份脚本（运行 quick-start.sh 后可用）
./backup.sh
```
</details>

<details>
<summary><b>检查服务器健康状态</b></summary>

#### 📺 演示：健康检查脚本

[![asciicast](https://asciinema.org/a/nvKlK8nCOKPSke52z9ZjGuUTX.svg)](https://asciinema.org/a/nvKlK8nCOKPSke52z9ZjGuUTX)

```bash
# 使用健康检查脚本（运行 quick-start.sh 后可用）
./health-check.sh

# 或手动检查
docker ps | grep puppy-stardew  # 应该显示 "healthy"
```
</details>

### ❓ 故障排除

<details>
<summary><b>错误："Disk write failure" 下载游戏时</b></summary>

**原因**：数据目录权限不正确。

**解决方法**：
```bash
chown -R 1000:1000 data/
docker compose restart
```

容器以用户 ID 1000 运行，所以文件必须归 UID 1000 所有。
</details>

<details>
<summary><b>需要 Steam 令牌代码</b></summary>

如果您启用了 Steam 令牌：

```bash
docker attach puppy-stardew
# 输入您邮箱/手机应用中的代码
# 按 Ctrl+P Ctrl+Q 分离（不是 Ctrl+C！）
```

**提示**：建议使用 Steam 令牌手机应用，获取代码更快。
</details>

<details>
<summary><b>游戏无法启动</b></summary>

1. 检查日志：`docker logs puppy-stardew`
2. 验证 `.env` 中的 Steam 凭证
3. 确保您在 Steam 上拥有星露谷物语
4. 检查磁盘空间：`df -h`
5. 重启：`docker compose restart`
</details>

<details>
<summary><b>玩家无法连接</b></summary>

1. **检查防火墙**：端口 `24642/udp` 必须开放
   ```bash
   # Ubuntu/Debian
   sudo ufw allow 24642/udp

   # CentOS/RHEL
   sudo firewall-cmd --add-port=24642/udp --permanent
   sudo firewall-cmd --reload
   ```

2. **验证服务器正在运行**：
   ```bash
   docker ps | grep puppy-stardew
   ```

3. **检查存档是否已加载**：通过 VNC 连接或检查日志中的 "Save loaded"

4. **确保游戏版本匹配**：服务器和客户端必须是相同的星露谷物语版本
</details>

<details>
<summary><b>VNC 无法连接</b></summary>

1. 检查端口 `5900/tcp` 是否可访问
2. 验证 VNC 密码（最多 8 个字符）
3. 尝试不同的 VNC 客户端（[RealVNC](https://www.realvnc.com/en/connect/download/viewer/)）
4. 检查日志：`docker logs puppy-stardew | grep -i vnc`
</details>

<details>
<summary><b>服务器占用太多内存</b></summary>

编辑 `docker-compose.yml` 减少内存限制：

```yaml
deploy:
  resources:
    limits:
      memory: 1.5G  # 从 2G 减少
```

然后重启：
```bash
docker compose up -d
```
</details>

### 🔧 高级配置

<details>
<summary><b>自定义模组设置</b></summary>

模组配置文件在容器内的 `/home/steam/stardewvalley/Mods/` 目录：

```bash
# 编辑 AutoHideHost 配置
docker exec puppy-stardew nano /home/steam/stardewvalley/Mods/AutoHideHost/config.json

# 编辑 Always On Server 配置
docker exec puppy-stardew nano /home/steam/stardewvalley/Mods/AlwaysOnServer/config.json

# 编辑 ServerAutoLoad 配置
docker exec puppy-stardew nano /home/steam/stardewvalley/Mods/ServerAutoLoad/config.json
```

编辑后重启服务器：
```bash
docker compose restart
```
</details>

<details>
<summary><b>更改端口号</b></summary>

编辑 `docker-compose.yml`：

```yaml
ports:
  - "24642:24642/udp"  # 更改第一个数字为您想要的端口
  - "5900:5900/tcp"    # VNC 端口
```

更改后重启：
```bash
docker compose up -d
```
</details>

<details>
<summary><b>设置完成后禁用 VNC</b></summary>

编辑 `.env`：
```env
ENABLE_VNC=false
```

重启：
```bash
docker compose up -d
```

这可以节省约 50MB 内存。
</details>

### 📝 系统要求

**服务器：**
- **CPU**：1+ 核心（推荐 2+）
- **内存**：最低 2GB（4+ 玩家推荐 4GB）
- **磁盘**：2GB 可用空间
- **操作系统**：Linux、Windows（Docker Desktop）、macOS（Docker Desktop）
- **网络**：开放端口 24642/UDP（VNC 需要 5900/TCP）

**客户端：**
- 星露谷物语（任何平台：PC、Mac、Linux、iOS、Android）
- 与服务器相同的游戏版本
- 局域网或互联网连接到服务器

### 📊 性能优化建议

- **低内存服务器**（2GB）：在 docker-compose.yml 中设置内存限制为 1.5G
- **多玩家**：4+ 同时在线玩家，增加到 4GB 内存
- **减少带宽**：网速慢的玩家避免主办活动
- **推荐 SSD**：存档加载更快

### 📜 许可证与法律

**许可证**：MIT 许可证 - 免费使用、修改和分发。

**重要法律说明：**
- ✅ 您必须在 Steam 上拥有星露谷物语
- ✅ 游戏文件通过您的 Steam 账户下载
- ✅ 这不是盗版工具
- ✅ 模组遵循其原始许可证：
  - Always On Server：[GPL-3.0](https://github.com/funny-snek/Always-On-Server-for-Multiplayer)
  - ServerAutoLoad：MIT（本项目自定义模组）
  - AutoHideHost：MIT（本项目自定义模组）

### 🙏 致谢

- **星露谷物语** by [ConcernedApe](https://www.stardewvalley.net/)
- **SMAPI** by [Pathoschild](https://smapi.io/)
- **Always On Server** by funny-snek & Zuberii
- **Docker** by Docker, Inc.

### 🤝 贡献

欢迎贡献！请：

1. Fork 本仓库
2. 创建功能分支
3. 提交 Pull Request

### 💬 支持与社区

- **错误报告**：[GitHub Issues](https://github.com/truman-world/puppy-stardew-server/issues)
- **问题讨论**：[GitHub Discussions](https://github.com/truman-world/puppy-stardew-server/discussions)
- **Docker Hub**：[truemanlive/puppy-stardew-server](https://hub.docker.com/r/truemanlive/puppy-stardew-server)

### ⭐ Star 历史

如果这个项目帮助了您，请考虑给个 Star！⭐

---

<div align="center">

**Made with ❤️ for the Stardew Valley community**

**为星露谷物语社区用爱制作**

[⬆ Back to Top](#-puppy-stardew-server--小狗星谷服务器)

</div>
