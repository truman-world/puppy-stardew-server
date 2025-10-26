using System;
using System.Linq;
using Microsoft.Xna.Framework;
using StardewModdingAPI;
using StardewModdingAPI.Events;
using StardewValley;

namespace AutoHideHost
{
    /// <summary>AutoHideHost 模组主入口</summary>
    public class ModEntry : Mod
    {
        /*****************
         * 私有字段
         *****************/
        private ModConfig Config;
        private bool isHostHidden = false;

        /*****************
         * SMAPI入口
         *****************/
        public override void Entry(IModHelper helper)
        {
            // 1. 加载配置
            this.Config = helper.ReadConfig<ModConfig>();

            // 2. 输出版本信息
            this.Monitor.Log($"AutoHideHost v{this.ModManifest.Version} 已加载", LogLevel.Info);
            this.Monitor.Log($"配置: 隐藏={Config.HideMethod}, 暂停={Config.PauseWhenEmpty}, 睡眠={Config.InstantSleepWhenReady}", LogLevel.Info);

            // 3. 注册事件
            helper.Events.GameLoop.SaveLoaded += OnSaveLoaded;
            helper.Events.GameLoop.DayStarted += OnDayStarted;
            helper.Events.GameLoop.UpdateTicked += OnUpdateTicked;

            // 4. 注册控制台命令
            RegisterCommands();
        }

        /*****************
         * 事件处理
         *****************/

        /// <summary>存档加载完成时</summary>
        private void OnSaveLoaded(object sender, SaveLoadedEventArgs e)
        {
            if (!Context.IsMainPlayer || !Config.Enabled || !Config.AutoHideOnLoad)
                return;

            HideHost();
            this.Monitor.Log("存档已加载，房主自动隐藏", LogLevel.Info);
        }

        /// <summary>每天开始时</summary>
        private void OnDayStarted(object sender, DayStartedEventArgs e)
        {
            if (!Context.IsMainPlayer || !Config.Enabled || !Config.AutoHideDaily)
                return;

            HideHost();
            LogDebug("新的一天，房主重新隐藏");
        }

        /// <summary>每帧更新</summary>
        private void OnUpdateTicked(object sender, UpdateTickedEventArgs e)
        {
            if (!Config.Enabled || !Context.IsMainPlayer)
                return;

            // 每15帧检查一次睡眠状态（约0.25秒）
            if (e.Ticks % 15 == 0)
            {
                CheckAndAutoSleep();
            }

            // 每60帧检查一次暂停状态（约1秒）
            if (e.Ticks % 60 == 0)
            {
                CheckAndAutoPause();
            }
        }

        /*****************
         * 核心功能实现
         *****************/

        /// <summary>
        /// F-001 & F-002: 自动隐藏房主
        /// </summary>
        private void HideHost()
        {
            if (!Context.IsMainPlayer)
                return;

            switch (Config.HideMethod.ToLower())
            {
                case "warp":
                    // 方法1: 传送到远离游戏区域的地图
                    Game1.warpFarmer(Config.WarpLocation, Config.WarpX, Config.WarpY, false);
                    LogDebug($"房主已传送至 {Config.WarpLocation} ({Config.WarpX}, {Config.WarpY})");
                    break;

                case "invisible":
                    // 方法2: 设置为隐形
                    Game1.player.isInvisible = true;
                    Game1.player.temporarilyInvincible = true;
                    LogDebug("房主已设置为隐形");
                    break;

                case "offmap":
                    // 方法3: 移动到地图外
                    Game1.player.Position = new Vector2(-999999, -999999);
                    LogDebug("房主已移动到地图外");
                    break;

                default:
                    this.Monitor.Log($"未知的隐藏方式: {Config.HideMethod}，使用默认warp方式", LogLevel.Warn);
                    Game1.warpFarmer("Desert", 0, 0, false);
                    break;
            }

            isHostHidden = true;
        }

        /// <summary>
        /// F-003: 自动暂停与恢复
        /// </summary>
        private void CheckAndAutoPause()
        {
            if (!Context.IsMainPlayer || !Config.PauseWhenEmpty || !Context.IsWorldReady)
                return;

            // 获取在线真人玩家数量（不包括房主）
            // 修复：只统计真正在线的玩家（isActive为true），排除离线的农工小屋
            int onlineFarmhands = Game1.otherFarmers.Values
                .Count(farmer => farmer != null && farmer.isActive());

            bool shouldPause = (onlineFarmhands == 0);

            if (shouldPause && !Game1.paused)
            {
                Game1.paused = true;
                this.Monitor.Log("服务器无玩家在线，已自动暂停", LogLevel.Info);
            }
            else if (!shouldPause && Game1.paused)
            {
                Game1.paused = false;
                this.Monitor.Log($"检测到 {onlineFarmhands} 名玩家在线，已自动恢复", LogLevel.Info);
            }
        }

        /// <summary>
        /// F-004: 瞬时睡眠转换（核心功能）
        /// 这是整个模组最重要的功能！
        /// </summary>
        private void CheckAndAutoSleep()
        {
            // 1. 前置检查
            if (!Context.IsMainPlayer || !Config.InstantSleepWhenReady)
            {
                LogDebug($"[睡眠检查] 跳过 - IsMainPlayer={Context.IsMainPlayer}, InstantSleepWhenReady={Config.InstantSleepWhenReady}");
                return;
            }

            if (!Context.IsWorldReady)
            {
                LogDebug("[睡眠检查] 跳过 - 世界未就绪");
                return;
            }

            // 重要修复：等待结算菜单完成
            // 如果有任何活动菜单（如结算界面），等待其完成
            if (Game1.activeClickableMenu != null)
            {
                LogDebug($"[睡眠检查] 跳过 - 有活动菜单: {Game1.activeClickableMenu.GetType().Name}");
                return;
            }

            // 2. 获取所有在线真人玩家（不包括房主）
            // 修复：只统计真正在线的玩家（isActive为true），排除离线的农工小屋
            var onlineFarmhands = Game1.otherFarmers.Values
                .Where(farmer => farmer != null && farmer.isActive())
                .ToList();

            LogDebug($"[睡眠检查] 总农工小屋数: {Game1.otherFarmers.Count}, 在线玩家数: {onlineFarmhands.Count}");

            if (onlineFarmhands.Count == 0)
            {
                // 无真人玩家在线，无需检查
                LogDebug("[睡眠检查] 无在线玩家，跳过检查");
                return;
            }

            // 3. 检查是否所有在线真人玩家都已准备好睡觉
            try
            {
                // 详细检查每个玩家的状态
                LogDebug($"[睡眠检查] 开始检查 {onlineFarmhands.Count} 名在线玩家的睡眠状态");

                for (int i = 0; i < onlineFarmhands.Count; i++)
                {
                    var farmer = onlineFarmhands[i];
                    bool isReady = Game1.netReady != null &&
                                   Game1.netReady.IsReady("sleep", farmer.UniqueMultiplayerID);
                    LogDebug($"[睡眠检查] 玩家 {i + 1} - 名称: {farmer.Name}, ID: {farmer.UniqueMultiplayerID}, 准备睡觉: {isReady}");
                }

                bool allFarmhandsReadyToSleep = onlineFarmhands.All(farmer =>
                    Game1.netReady != null &&
                    Game1.netReady.IsReady("sleep", farmer.UniqueMultiplayerID)
                );

                LogDebug($"[睡眠检查] 所有玩家准备状态: {allFarmhandsReadyToSleep}");

                if (!allFarmhandsReadyToSleep)
                {
                    // 还有玩家没准备好，等待
                    LogDebug($"[睡眠检查] 等待中... 在线玩家数: {onlineFarmhands.Count}");
                    return;
                }

                // 4. 所有真人玩家都准备好了！让房主自动上床睡觉
                bool hostReady = Game1.player.team != null &&
                                 Game1.player.team.isPlayerReady("sleep", Game1.player.UniqueMultiplayerID);

                LogDebug($"[睡眠检查] 房主准备状态: {hostReady}");
                LogDebug($"[睡眠检查] 房主位置: {Game1.player.currentLocation?.Name ?? "null"} ({Game1.player.Position.X}, {Game1.player.Position.Y})");
                LogDebug($"[睡眠检查] 房主是否在床上: {Game1.player.isInBed()}");

                if (Game1.player.team != null && !hostReady)
                {
                    this.Monitor.Log(
                        $"[睡眠检查] 检测到所有 {onlineFarmhands.Count} 名在线玩家已准备睡觉，房主开始自动睡觉流程",
                        LogLevel.Info
                    );

                    // 步骤1: 如果房主不在农场，先传送回农场
                    if (Game1.player.currentLocation?.Name != "FarmHouse")
                    {
                        this.Monitor.Log("[睡眠检查] 房主不在农舍，传送到农舍", LogLevel.Debug);
                        Game1.warpFarmer("FarmHouse", 9, 9, false);
                        // 等待一帧让传送完成
                        return;
                    }

                    // 步骤2: 如果房主不在床上，让房主上床
                    if (!Game1.player.isInBed())
                    {
                        this.Monitor.Log("[睡眠检查] 房主不在床上，尝试让房主上床", LogLevel.Debug);

                        // 找到农舍中的床
                        var farmHouse = Game1.player.currentLocation;
                        if (farmHouse != null)
                        {
                            // 获取床的位置（通常在农舍的特定位置）
                            var bedLocation = farmHouse.GetPlayerBed(Game1.player.UniqueMultiplayerID);
                            if (bedLocation != null)
                            {
                                // 将房主传送到床的位置
                                Game1.player.Position = new Vector2(bedLocation.X * 64, bedLocation.Y * 64);
                                this.Monitor.Log($"[睡眠检查] 房主已移动到床位置: ({bedLocation.X}, {bedLocation.Y})", LogLevel.Debug);
                            }
                        }
                    }

                    // 步骤3: 标记房主准备睡觉
                    this.Monitor.Log("[睡眠检查] 标记房主准备睡觉", LogLevel.Info);
                    Game1.player.team.SetPlayerReady("sleep", true);

                    this.Monitor.Log("[睡眠检查] 房主已标记为准备睡觉，昼夜转换已触发", LogLevel.Info);
                }
                else if (hostReady)
                {
                    LogDebug("[睡眠检查] 房主已经准备好，等待转换...");
                }
            }
            catch (Exception ex)
            {
                // 捕获任何异常，避免崩溃
                this.Monitor.Log($"[睡眠检查] 错误: {ex.Message}", LogLevel.Error);
                this.Monitor.Log($"[睡眠检查] 堆栈: {ex.StackTrace}", LogLevel.Error);
            }
        }

        /// <summary>显示房主（传送回农场）</summary>
        private void ShowHost()
        {
            if (!Context.IsMainPlayer)
                return;

            // 传送回农场
            Game1.warpFarmer("Farm", 64, 15, false);
            Game1.player.isInvisible = false;
            Game1.player.temporarilyInvincible = false;

            isHostHidden = false;
            this.Monitor.Log("房主已显示在农场", LogLevel.Debug);
        }

        /*****************
         * 控制台命令
         *****************/

        private void RegisterCommands()
        {
            this.Helper.ConsoleCommands.Add("hidehost", "立即隐藏房主", OnCommand_HideHost);
            this.Helper.ConsoleCommands.Add("showhost", "显示房主", OnCommand_ShowHost);
            this.Helper.ConsoleCommands.Add("togglehost", "切换房主可见性", OnCommand_ToggleHost);
            this.Helper.ConsoleCommands.Add("autohide_status", "显示模组状态", OnCommand_Status);
            this.Helper.ConsoleCommands.Add("autohide_reload", "重新加载配置", OnCommand_Reload);
            this.Helper.ConsoleCommands.Add("autohide_sleep_debug", "显示详细睡眠状态", OnCommand_SleepDebug);
        }

        private void OnCommand_HideHost(string command, string[] args)
        {
            if (!Context.IsMainPlayer)
            {
                this.Monitor.Log("只有房主可以执行此命令", LogLevel.Error);
                return;
            }

            HideHost();
            this.Monitor.Log("房主已隐藏", LogLevel.Info);
        }

        private void OnCommand_ShowHost(string command, string[] args)
        {
            if (!Context.IsMainPlayer)
            {
                this.Monitor.Log("只有房主可以执行此命令", LogLevel.Error);
                return;
            }

            ShowHost();
            this.Monitor.Log("房主已显示", LogLevel.Info);
        }

        private void OnCommand_ToggleHost(string command, string[] args)
        {
            if (!Context.IsMainPlayer)
            {
                this.Monitor.Log("只有房主可以执行此命令", LogLevel.Error);
                return;
            }

            if (isHostHidden)
                ShowHost();
            else
                HideHost();
        }

        private void OnCommand_Status(string command, string[] args)
        {
            this.Monitor.Log("=== AutoHideHost 模组状态 ===", LogLevel.Info);
            this.Monitor.Log($"模组版本: {this.ModManifest.Version}", LogLevel.Info);
            this.Monitor.Log($"启用状态: {Config.Enabled}", LogLevel.Info);
            this.Monitor.Log($"房主隐藏: {isHostHidden}", LogLevel.Info);

            if (Context.IsWorldReady)
            {
                int activePlayers = Game1.otherFarmers.Values.Count(f => f != null && f.isActive());
                int totalFarmhands = Game1.otherFarmers.Count();
                this.Monitor.Log($"在线玩家数: {activePlayers} (总农工小屋: {totalFarmhands})", LogLevel.Info);
                this.Monitor.Log($"游戏暂停: {Game1.paused}", LogLevel.Info);
            }

            this.Monitor.Log($"隐藏方式: {Config.HideMethod}", LogLevel.Info);
            this.Monitor.Log($"自动暂停: {Config.PauseWhenEmpty}", LogLevel.Info);
            this.Monitor.Log($"即时睡眠: {Config.InstantSleepWhenReady}", LogLevel.Info);
        }

        private void OnCommand_Reload(string command, string[] args)
        {
            this.Config = this.Helper.ReadConfig<ModConfig>();
            this.Monitor.Log("配置文件已重新加载", LogLevel.Info);
            OnCommand_Status(command, args);
        }

        private void OnCommand_SleepDebug(string command, string[] args)
        {
            this.Monitor.Log("=== 睡眠状态详细调试信息 ===", LogLevel.Info);

            if (!Context.IsWorldReady)
            {
                this.Monitor.Log("世界未就绪，无法检查睡眠状态", LogLevel.Warn);
                return;
            }

            // 房主信息
            this.Monitor.Log($"房主名称: {Game1.player.Name}", LogLevel.Info);
            this.Monitor.Log($"房主ID: {Game1.player.UniqueMultiplayerID}", LogLevel.Info);
            this.Monitor.Log($"房主位置: {Game1.player.currentLocation?.Name ?? "null"}", LogLevel.Info);
            this.Monitor.Log($"房主坐标: ({Game1.player.Position.X}, {Game1.player.Position.Y})", LogLevel.Info);
            this.Monitor.Log($"房主是否在床上: {Game1.player.isInBed()}", LogLevel.Info);

            bool hostReady = Game1.player.team != null &&
                             Game1.player.team.isPlayerReady("sleep", Game1.player.UniqueMultiplayerID);
            this.Monitor.Log($"房主睡眠准备状态: {hostReady}", LogLevel.Info);

            // 其他玩家信息
            this.Monitor.Log($"\n总农工小屋数: {Game1.otherFarmers.Count}", LogLevel.Info);

            var onlineFarmhands = Game1.otherFarmers.Values
                .Where(farmer => farmer != null && farmer.isActive())
                .ToList();

            this.Monitor.Log($"在线玩家数: {onlineFarmhands.Count}", LogLevel.Info);

            if (onlineFarmhands.Count > 0)
            {
                this.Monitor.Log("\n在线玩家详情:", LogLevel.Info);
                for (int i = 0; i < onlineFarmhands.Count; i++)
                {
                    var farmer = onlineFarmhands[i];
                    bool isReady = Game1.netReady != null &&
                                   Game1.netReady.IsReady("sleep", farmer.UniqueMultiplayerID);

                    this.Monitor.Log($"  玩家 {i + 1}:", LogLevel.Info);
                    this.Monitor.Log($"    名称: {farmer.Name}", LogLevel.Info);
                    this.Monitor.Log($"    ID: {farmer.UniqueMultiplayerID}", LogLevel.Info);
                    this.Monitor.Log($"    位置: {farmer.currentLocation?.Name ?? "null"}", LogLevel.Info);
                    this.Monitor.Log($"    坐标: ({farmer.Position.X}, {farmer.Position.Y})", LogLevel.Info);
                    this.Monitor.Log($"    是否在床上: {farmer.isInBed()}", LogLevel.Info);
                    this.Monitor.Log($"    睡眠准备状态: {isReady}", LogLevel.Info);
                }
            }

            // 游戏状态
            this.Monitor.Log($"\n游戏暂停: {Game1.paused}", LogLevel.Info);
            this.Monitor.Log($"当前时间: {Game1.timeOfDay}", LogLevel.Info);
            this.Monitor.Log($"Game1.netReady 是否为null: {Game1.netReady == null}", LogLevel.Info);
            this.Monitor.Log($"Game1.player.team 是否为null: {Game1.player.team == null}", LogLevel.Info);
        }

        /*****************
         * 工具方法
         *****************/

        private void LogDebug(string message)
        {
            if (Config.DebugMode)
            {
                this.Monitor.Log(message, LogLevel.Debug);
            }
        }
    }
}
