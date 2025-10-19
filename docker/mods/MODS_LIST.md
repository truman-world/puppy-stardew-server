# Puppy Stardew Server - Included Mods

This document lists all the mods included in the Puppy Stardew Server Docker image.

## Mod List

### 1. Always On Server
- **Author**: funny-snek & Zuberii
- **Version**: 1.20.3-unofficial.5-mikkoperkele
- **Description**: A Headless server mod.
- **Unique ID**: mikko.Always_On_Server
- **Nexus Link**: https://www.nexusmods.com/stardewvalley/mods/2677
- **Files**:
  - Always On Server.dll (44K)
  - config.json (909 bytes)
  - manifest.json (305 bytes)
  - ConnectionsCount.txt (1 byte)
  - data/ directory with 3 JSON files (111 bytes each)

### 2. Server Auto Load
- **Author**: Puppy-Stardew
- **Version**: 1.1.0
- **Description**: Save management and auto-load helper for dedicated servers. Automatically loads the most recent save on startup.
- **Unique ID**: puppystardew.ServerAutoLoad
- **Files**:
  - ServerAutoLoad.dll (24K)
  - config.json (45 bytes)
  - manifest.json (354 bytes)
- **Features**:
  - **Automatic save loading** - No manual VNC loading required!
  - Automatic save file detection and sorting by date
  - Auto-loads most recent save or configured save
  - Save monitoring and logging
  - Configuration tracking

### 3. AutoHideHost
- **Author**: AI Developer
- **Version**: 1.0.0
- **Description**: Automatically hides the host player in multiplayer servers and provides seamless day-night transitions without waiting prompts.
- **Unique ID**: AIdev.AutoHideHost
- **Files**:
  - AutoHideHost.dll
  - config.json
  - manifest.json

## Installation

These mods are pre-installed in the Docker image and will be automatically loaded when the server starts. Each mod's configuration can be customized by mounting a volume to the `/home/steam/stardewvalley/Mods/` directory in the container.

## Mod Requirements

- **SMAPI**: All mods require SMAPI (Stardew Modding API) version 4.0.0 or higher
- **Game Version**: Stardew Valley 1.6+

## Notes

- **Always On Server**: Enables headless 24/7 server operation
- **Server Auto Load**: Helps manage and monitor saves in headless mode. Displays save information and loading instructions on startup
- **AutoHideHost**: Ensures the host player remains hidden and handles day/night transitions seamlessly with instant sleep functionality

## Usage

### First Time Setup

1. Start the container
2. **For existing saves**: Server Auto Load will automatically detect and load the most recent save
3. **For new saves**: Connect via VNC (port 5900) to create a new farm
4. Once loaded, the game runs continuously

### After Container Restart

- **Automatic!** Server Auto Load will automatically load the most recent save
- No manual VNC loading required
- The game continues running 24/7 via Always On Server

### Manual Configuration (Optional)

If you want to load a specific save instead of the most recent one:
1. Edit `/home/steam/stardewvalley/Mods/ServerAutoLoad/config.json`
2. Set `"SaveFileName": "your_save_name_here"`
3. Restart the container
