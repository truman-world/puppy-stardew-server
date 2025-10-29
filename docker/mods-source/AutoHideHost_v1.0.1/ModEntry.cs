using System;
using System.Linq;
using Microsoft.Xna.Framework;
using StardewModdingAPI;
using StardewModdingAPI.Events;
using StardewValley;
using StardewValley.Locations;

namespace AutoHideHost
{
    /// <summary>AutoHideHost 模组主入口 - v1.0.3: 修复睡眠触发时机</summary>
    public class ModEntry : Mod
    {
        private ModConfig Config;
        private bool isHostHidden = false;
        private bool hasTriggeredSleep = false;
        private bool needToSleep = false;  // 新增：延迟睡眠标志
        private int sleepDelayTicks = 0;   // 新增：睡眠延迟计数器

        public override void Entry(IModHelper helper)
        {
            this.Config = helper.ReadConfig<ModConfig>();
            this.Monitor.Log($"AutoHideHost v{this.ModManifest.Version} 已加载", LogLevel.Info);
            this.Monitor.Log($"配置: 隐藏={Config.HideMethod}, 暂停={Config.PauseWhenEmpty}, 即时睡眠={Config.InstantSleepWhenReady}", LogLevel.Info);

            helper.Events.GameLoop.SaveLoaded += OnSaveLoaded;
            helper.Events.GameLoop.DayStarted += OnDayStarted;
            helper.Events.GameLoop.UpdateTicked += OnUpdateTicked;
            RegisterCommands();
        }

        private void OnSaveLoaded(object sender, SaveLoadedEventArgs e)
        {
            if (!Context.IsMainPlayer || !Config.Enabled || !Config.AutoHideOnLoad)
                return;
            HideHost();
            this.Monitor.Log("存档已加载，房主自动隐藏", LogLevel.Info);
        }

        private void OnDayStarted(object sender, DayStartedEventArgs e)
        {
            if (!Context.IsMainPlayer || !Config.Enabled || !Config.AutoHideDaily)
                return;
            HideHost();
            hasTriggeredSleep = false;
            LogDebug("新的一天，房主重新隐藏");
        }

        private void OnUpdateTicked(object sender, UpdateTickedEventArgs e)
        {
            if (!Config.Enabled || !Context.IsMainPlayer)
                return;

            // 处理延迟睡眠逻辑
            if (needToSleep)
            {
                sleepDelayTicks++;
                if (sleepDelayTicks >= 30)  // 等待30 ticks（约0.5秒）确保传送完成
                {
                    ExecuteSleep();
                    needToSleep = false;
                    sleepDelayTicks = 0;
                }
                return;  // 睡眠期间跳过其他检查
            }

            if (e.Ticks % 15 == 0 && Config.InstantSleepWhenReady)
            {
                CheckAndAutoSleep();
            }

            if (e.Ticks % 60 == 0)
            {
                CheckAndAutoPause();
            }
        }

        private void HideHost()
        {
            if (!Context.IsMainPlayer)
                return;

            switch (Config.HideMethod.ToLower())
            {
                case "warp":
                    Game1.warpFarmer(Config.WarpLocation, Config.WarpX, Config.WarpY, false);
                    LogDebug($"房主已传送至 {Config.WarpLocation} ({Config.WarpX}, {Config.WarpY})");
                    break;
                case "invisible":
                    this.Monitor.Log("隐形方式在1.6版本中不可用，使用warp方式", LogLevel.Warn);
                    Game1.warpFarmer("Desert", 0, 0, false);
                    break;
                case "offmap":
                    Game1.player.Position = new Vector2(-999999, -999999);
                    LogDebug("房主已移动到地图外");
                    break;
                default:
                    Game1.warpFarmer("Desert", 0, 0, false);
                    break;
            }
            isHostHidden = true;
        }

        private void CheckAndAutoPause()
        {
            // v1.0.3: 完全禁用自动暂停功能，因为它会导致服务器重启后客户端无法连接
            // 暂停功能与ServerAutoLoad的自动加载存档功能冲突
            return;

            /*
            if (!Context.IsMainPlayer || !Config.PauseWhenEmpty || !Context.IsWorldReady)
                return;

            // 修复：只统计真正在线的玩家
            int onlineFarmhands = Game1.getOnlineFarmers()
                .Count(f => f.UniqueMultiplayerID != Game1.player.UniqueMultiplayerID);
            bool shouldPause = (onlineFarmhands == 0);

            if (shouldPause && !Game1.paused)
            {
                Game1.paused = true;
                this.Monitor.Log("服务器无玩家在线，已自动暂停", LogLevel.Info);
            }
            else if (!shouldPause && Game1.paused)
            {
                Game1.paused = false;
                hasTriggeredSleep = false;
                this.Monitor.Log($"检测到 {onlineFarmhands} 名玩家在线，已自动恢复", LogLevel.Info);
            }
            */
        }

        /// <summary>
        /// F-004: 瞬时睡眠转换 - v1.0.3修复：先传送再延迟触发睡眠
        /// </summary>
        private void CheckAndAutoSleep()
        {
            if (!Context.IsMainPlayer || !Config.InstantSleepWhenReady)
                return;

            if (!Context.IsWorldReady || hasTriggeredSleep || needToSleep)
                return;

            // CRITICAL FIX: Wait for settlement menu to complete
            // If any active menu (like settlement interface), wait for it to finish
            if (Game1.activeClickableMenu != null)
            {
                LogDebug($"[睡眠检查] 跳过 - 有活动菜单: {Game1.activeClickableMenu.GetType().Name}");
                return;
            }

            var onlineFarmhands = Game1.getOnlineFarmers()
                .Where(f => f.UniqueMultiplayerID != Game1.player.UniqueMultiplayerID)
                .ToList();

            if (onlineFarmhands.Count == 0)
                return;

            try
            {
                // 调试：打印所有玩家状态
                foreach (var farmer in onlineFarmhands)
                {
                    this.Monitor.Log($"玩家 {farmer.Name}: isInBed={farmer.isInBed.Value}, timeWentToBed={farmer.timeWentToBed.Value}", LogLevel.Info);
                }

                bool allFarmhandsInBed = onlineFarmhands.All(farmer => farmer.isInBed.Value);

                if (!allFarmhandsInBed)
                    return;

                // 所有玩家都在床上了，准备触发睡眠
                this.Monitor.Log($"检测到所有 {onlineFarmhands.Count} 名玩家已上床，准备传送房主并触发睡眠", LogLevel.Info);

                // 第一步：传送房主到床
                PrepareToBed();

                // 第二步：设置延迟睡眠标志，让OnUpdateTicked在几个tick后执行真正的睡眠
                needToSleep = true;
                sleepDelayTicks = 0;
                hasTriggeredSleep = true;

                this.Monitor.Log("✓ 房主已传送，等待30 ticks后触发睡眠...", LogLevel.Info);
            }
            catch (Exception ex)
            {
                this.Monitor.Log($"触发睡眠时出错: {ex.Message}", LogLevel.Error);
                this.Monitor.Log($"堆栈: {ex.StackTrace}", LogLevel.Debug);
            }
        }

        /// <summary>
        /// 准备睡眠：传送房主到床的位置
        /// </summary>
        private void PrepareToBed()
        {
            try
            {
                // 获取房主的homeLocation
                string homeLocationName = Game1.player.homeLocation.Value;
                this.Monitor.Log($"房主的homeLocation: {homeLocationName}", LogLevel.Info);

                // 获取床的坐标（根据房屋升级等级）
                int bedX, bedY;
                int houseUpgradeLevel = Game1.player.HouseUpgradeLevel;
                this.Monitor.Log($"房屋升级等级: {houseUpgradeLevel}", LogLevel.Info);

                if (houseUpgradeLevel == 0)
                {
                    bedX = 9;
                    bedY = 9;
                }
                else if (houseUpgradeLevel == 1)
                {
                    bedX = 21;
                    bedY = 4;
                }
                else
                {
                    bedX = 27;
                    bedY = 13;
                }

                // 传送房主到床的位置
                this.Monitor.Log($"传送房主到 {homeLocationName} ({bedX}, {bedY})", LogLevel.Info);
                Game1.warpFarmer(homeLocationName, bedX, bedY, false);

                // 设置房主为在床上状态
                Game1.player.isInBed.Value = true;
                Game1.player.mostRecentBed = new Microsoft.Xna.Framework.Vector2(bedX * 64, bedY * 64);
            }
            catch (Exception ex)
            {
                this.Monitor.Log($"PrepareToBed出错: {ex.Message}", LogLevel.Error);
            }
        }

        /// <summary>
        /// 执行睡眠：在传送完成后调用（延迟30 ticks）
        /// </summary>
        private void ExecuteSleep()
        {
            try
            {
                this.Monitor.Log("开始执行睡眠流程...", LogLevel.Info);

                // 此时Game1.currentLocation应该已经是FarmHouse了
                this.Monitor.Log($"当前location: {Game1.currentLocation.Name}", LogLevel.Info);

                // 调用startSleep方法
                this.Helper.Reflection.GetMethod(Game1.currentLocation, "startSleep").Invoke();

                Game1.displayHUD = true;
                this.Monitor.Log("✓ startSleep已调用！", LogLevel.Info);
            }
            catch (Exception ex)
            {
                this.Monitor.Log($"ExecuteSleep出错: {ex.Message}", LogLevel.Error);
                this.Monitor.Log($"堆栈: {ex.StackTrace}", LogLevel.Error);
            }
        }

        private void ShowHost()
        {
            if (!Context.IsMainPlayer)
                return;
            Game1.warpFarmer("Farm", 64, 15, false);
            Game1.player.temporarilyInvincible = false;
            isHostHidden = false;
            this.Monitor.Log("房主已显示在农场", LogLevel.Debug);
        }

        private void RegisterCommands()
        {
            this.Helper.ConsoleCommands.Add("hidehost", "立即隐藏房主", OnCommand_HideHost);
            this.Helper.ConsoleCommands.Add("showhost", "显示房主", OnCommand_ShowHost);
            this.Helper.ConsoleCommands.Add("togglehost", "切换房主可见性", OnCommand_ToggleHost);
            this.Helper.ConsoleCommands.Add("autohide_status", "显示模组状态", OnCommand_Status);
            this.Helper.ConsoleCommands.Add("autohide_reload", "重新加载配置", OnCommand_Reload);
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
                // 修复：显示真实在线玩家数
                int onlinePlayers = Game1.getOnlineFarmers()
                    .Count(f => f.UniqueMultiplayerID != Game1.player.UniqueMultiplayerID);
                int totalCabins = Game1.otherFarmers.Count();
                this.Monitor.Log($"在线玩家数: {onlinePlayers} (总小屋: {totalCabins})", LogLevel.Info);
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

        private void LogDebug(string message)
        {
            if (Config.DebugMode)
            {
                this.Monitor.Log(message, LogLevel.Debug);
            }
        }
    }
}
