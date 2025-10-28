# Puppy Stardew Server - Public Version
# 小狗星谷服务器 - 公开版本
#
# This Docker image does NOT include the game files.
# Users must provide their own Steam credentials to download Stardew Valley.
# 此镜像不包含游戏本体文件。
# 用户需要提供自己的 Steam 账号来下载星露谷物语。

FROM ubuntu:22.04

# Prevent interactive prompts during installation
# 避免安装过程中的交互提示
ENV DEBIAN_FRONTEND=noninteractive

LABEL maintainer="truemanlive" \
      description="Stardew Valley dedicated server with instant sleep functionality" \
      version="1.0.20"

# Enable 32-bit architecture for SteamCMD
# 启用32位架构支持以安装SteamCMD
RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install -y --no-install-recommends \
    wget \
    curl \
    unzip \
    ca-certificates \
    lib32gcc-s1 \
    libsdl2-2.0-0 \
    libcurl3-gnutls:i386 \
    && rm -rf /var/lib/apt/lists/*

# Install virtual display and VNC dependencies
# 安装虚拟显示和 VNC 依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    xvfb \
    x11vnc \
    openbox \
    expect \
    && rm -rf /var/lib/apt/lists/*

# Install .NET runtime (required for game mods)
# 安装 .NET 运行时（模组需要）
RUN apt-get update && apt-get install -y --no-install-recommends \
    dotnet-runtime-6.0 \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
# 创建非 root 用户以提高安全性
RUN useradd -m -s /bin/bash steam && \
    mkdir -p /home/steam/steamcmd /home/steam/stardewvalley /home/steam/.config/StardewValley && \
    chown -R steam:steam /home/steam

# Set working directory and switch to steam user
WORKDIR /home/steam
USER steam

# Download and extract SteamCMD
# 下载并解压 SteamCMD
RUN wget -qO- 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz' | \
    tar zxvf - -C /home/steam/steamcmd

# Download and install SMAPI (Stardew Modding API)
# 下载并安装 SMAPI（星露谷模组API）
RUN wget -qO smapi.zip 'https://github.com/Pathoschild/SMAPI/releases/download/4.3.2/SMAPI-4.3.2-installer.zip' && \
    unzip -q smapi.zip -d smapi && \
    rm smapi.zip

# Copy pre-configured mods to a temporary location
# 将预配置的模组复制到临时位置
USER root
COPY mods/ /home/steam/preinstalled-mods/
RUN chown -R steam:steam /home/steam/preinstalled-mods && \
    chmod -R 755 /home/steam/preinstalled-mods
USER steam

# Copy entrypoint script
# 复制启动脚本
USER root
COPY --chown=steam:steam scripts/entrypoint.sh /home/steam/entrypoint.sh
RUN chmod +x /home/steam/entrypoint.sh
USER steam

# Expose game port (UDP) and VNC port (TCP)
# 暴露游戏端口（UDP）和 VNC 端口（TCP）
EXPOSE 24642/udp 5900/tcp

# Health check to ensure server is running
# 健康检查确保服务器正在运行
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD pgrep -f "StardewModdingAPI" > /dev/null || exit 1

# Set entrypoint
# 设置启动脚本
ENTRYPOINT ["/home/steam/entrypoint.sh"]
