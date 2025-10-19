# Release Notes Template for GitHub Releases

This file serves as a template for creating GitHub Releases. Copy the content below and paste it into the GitHub Release description.

---

### 🚀 One-Command Stardew Valley Server Deployment

Deploy your own **Stardew Valley dedicated server** in just **3 minutes** with a single command! Support for **all platforms** - PC, Mac, Linux, iOS, and Android players can join together.

Perfect for remote multiplayer, cross-platform gaming, and 24/7 always-on servers.

---

### ✨ Key Features

- 🚀 **One-Command Deploy** - Deploy in 3 minutes with a single command
- 📱 **Cross-Platform Support** - PC, Mac, Linux, iOS, Android all supported
- ⚡ **24/7 Dedicated Server** - Runs independently without requiring the host to be online
- 🐳 **Docker Compose** - Easy deployment and management
- 💪 **Resource Efficient** - Runs smoothly on servers with only 2GB RAM
- 💾 **Auto-Save Loading** - Automatically loads your save on server restart
- 🖥️ **VNC Remote Access** - Built-in VNC for easy first-time setup
- 🛏️ **Instant Sleep (Bonus)** - Players can sleep at any time without waiting
- 👻 **Hidden Host (Bonus)** - Host player is automatically hidden for seamless gameplay

---

### 📺 Demo

![Instant Sleep Demo](https://raw.githubusercontent.com/truman-world/puppy-stardew-server/main/screenshots/game/instant-sleep-demo.gif)

*Bonus Feature: Instant sleep - Click bed → Sleep instantly → New day begins!*

---

### 🚀 Quick Start

Deploy your Stardew Valley server in just one command:

```bash
curl -sSL https://raw.githubusercontent.com/truman-world/puppy-stardew-server/main/quick-start.sh | bash
```

The script automatically:
- ✅ Checks Docker installation
- ✅ Downloads configuration files
- ✅ Guides you through Steam credentials setup
- ✅ Creates necessary directories with correct permissions
- ✅ Starts the server

**That's it!** Server will be ready in ~3 minutes.

---

### 📖 Documentation

- **Full Documentation**: [README.md](https://github.com/truman-world/puppy-stardew-server#readme)
- **Quick Start Guide**: [One-Command Deployment](https://github.com/truman-world/puppy-stardew-server#-quick-start-2-options)
- **Initial Setup**: [VNC Connection Tutorial](https://github.com/truman-world/puppy-stardew-server#-initial-setup-first-run-only)
- **Troubleshooting**: [Common Issues](https://github.com/truman-world/puppy-stardew-server#-troubleshooting)

---

### 🔧 What's New in This Release

<!-- Update this section for each release -->

- ✅ Improved one-click deployment script
- ✅ Enhanced health check functionality
- ✅ Updated documentation with video demos
- ✅ Added cross-platform connection tutorials
- ✅ Fixed permission issues on certain Linux distributions
- ✅ Optimized Docker image size
- ✅ SEO optimization for better discoverability

---

### 📦 System Requirements

**Server**:
- **CPU**: 1+ cores (2+ recommended)
- **RAM**: 2GB minimum (4GB recommended for 4+ players)
- **Disk**: 2GB free space
- **OS**: Linux, Windows (Docker Desktop), macOS (Docker Desktop)
- **Network**: Open port 24642/UDP (and 5900/TCP for VNC)

**Clients**:
- Stardew Valley on any platform (PC, Mac, Linux, iOS, Android)
- Same game version as server
- LAN or internet connection to server

---

### 🎯 Perfect For

- ✅ **Remote Multiplayer** - Play with friends from anywhere
- ✅ **Cross-Platform Gaming** - Mobile and PC players together
- ✅ **24/7 Server** - Always online, join anytime
- ✅ **Easy Setup** - No technical knowledge required
- ✅ **Self-Hosted** - Full control over your game server

---

### 🐳 Docker Hub

Pull the latest image:

```bash
docker pull truemanlive/puppy-stardew-server:latest
```

**Docker Hub**: https://hub.docker.com/r/truemanlive/puppy-stardew-server

---

### 📱 Mobile Players (iOS/Android)

This server works perfectly with Stardew Valley Mobile:

1. Set up the server (3 minutes)
2. Open Stardew Valley on your phone/tablet
3. Tap "Co-op" → "Join LAN Game"
4. Enter server address: `server-ip:24642`
5. Start playing!

**Cross-platform multiplayer made easy!**

---

### 🔗 Links

- **GitHub Repository**: https://github.com/truman-world/puppy-stardew-server
- **Docker Hub**: https://hub.docker.com/r/truemanlive/puppy-stardew-server
- **Issue Tracker**: https://github.com/truman-world/puppy-stardew-server/issues
- **Discussions**: https://github.com/truman-world/puppy-stardew-server/discussions

---

### 💬 Support

- **Bug Reports**: [GitHub Issues](https://github.com/truman-world/puppy-stardew-server/issues)
- **Questions**: [GitHub Discussions](https://github.com/truman-world/puppy-stardew-server/discussions)

---

### ⭐ Support This Project

If this project helps you, please consider:
- ⭐ Starring the repository
- 🔄 Sharing with friends
- 🐛 Reporting bugs
- 💡 Suggesting features

---

### 📜 Legal

- **License**: MIT License - free to use, modify, and distribute
- **Requirement**: You MUST own Stardew Valley on Steam
- **Game Files**: Downloaded via your Steam account
- **Not Piracy**: This is a legitimate server solution for game owners

---

### 🙏 Credits

- **Stardew Valley** by [ConcernedApe](https://www.stardewvalley.net/)
- **SMAPI** by [Pathoschild](https://smapi.io/)
- **Always On Server** by funny-snek & Zuberii
- **Docker** by Docker, Inc.

---

## 📥 Installation

### Method 1: One-Command Deployment (Recommended)

```bash
curl -sSL https://raw.githubusercontent.com/truman-world/puppy-stardew-server/main/quick-start.sh | bash
```

### Method 2: Manual Deployment

```bash
# Clone repository
git clone https://github.com/truman-world/puppy-stardew-server.git
cd puppy-stardew-server

# Copy environment template
cp .env.example .env

# Edit with your Steam credentials
nano .env

# Set permissions
mkdir -p data/{saves,game,steam}
chown -R 1000:1000 data/

# Start server
docker compose up -d
```

### Method 3: Docker Run

```bash
docker run -d \
  --name puppy-stardew \
  -p 24642:24642/udp \
  -p 5900:5900/tcp \
  -e STEAM_USERNAME=your_username \
  -e STEAM_PASSWORD=your_password \
  -e ENABLE_VNC=true \
  -e VNC_PASSWORD=stardew123 \
  -v $(pwd)/data/game:/home/steam/.local/share/StardewValley \
  -v $(pwd)/data/saves:/home/steam/stardewvalley \
  -v $(pwd)/data/steam:/home/steam/.steam \
  truemanlive/puppy-stardew-server:latest
```

---

## 🔄 Upgrading

```bash
docker compose down
docker pull truemanlive/puppy-stardew-server:latest
docker compose up -d
```

---

**Made with ❤️ for the Stardew Valley community**

**为星露谷物语社区用爱制作**

---

**Full Changelog**: https://github.com/truman-world/puppy-stardew-server/compare/v1.2.0...v1.2.1
