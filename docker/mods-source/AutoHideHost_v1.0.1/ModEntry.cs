using System;
using System.Linq;
using Microsoft.Xna.Framework;
using StardewModdingAPI;
using StardewModdingAPI.Events;
using StardewValley;
using StardewValley.Locations;

namespace AutoHideHost
{
    /// <summary>AutoHideHost 模组主入口 - v1.4.0: 使用Team Ready API</summary>
    public class ModEntry : Mod
    {
        private ModConfig Config;
        private bool isHostHidden = false;
        private bool hasTriggeredSleep = false;
        private bool needToSleep = false;
        private int sleepDelayTicks = 0;
        private bool isSleepInProgress = false;
        private bool handledReadyCheck = false;  // v1.4.0: 防止重复处理同一个ReadyCheck

        public override void Entry(IModHelper helper)
        {
            this.Config = helper.ReadConfig<ModConfig>();
            this.Monitor.Log($"AutoHideHost v{this.ModManifest.Version} 已加载", LogLevel.Info);
            this.Monitor.Log($"配置: 隐藏={Config.HideMethod}, 暂停={Config.PauseWhenEmpty}, 即时睡眠={Config.InstantSleepWhenReady}", LogLevel.Info);

            helper.Events.GameLoop.SaveLoaded += OnSaveLoaded;
            helper.Events.GameLoop.DayStarted += OnDayStarted;
            helper.Events.GameLoop.UpdateTicked += OnUpdateTicked;
            helper.Events.GameLoop.Saving += OnSaving;
            helper.Events.Display.MenuChanged += OnMenuChanged;  // v1.4.0: 处理菜单变化
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
            isSleepInProgress = false;
            handledReadyCheck = false;  // v1.4.0: 重置ReadyCheck标志

            LogDebug("新的一天，房主重新隐藏");
        }

        /// <summary>
        /// v1.4.0: 处理菜单变化 - 自动处理ShippingMenu和LevelUpMenu
        /// </summary>
        private void OnMenuChanged(object sender, MenuChangedEventArgs e)
        {
            if (!Context.IsMainPlayer || !Config.Enabled)
                return;

            // 重置ReadyCheck标志（新菜单出现时）
            if (e.OldMenu != null && e.OldMenu.GetType().Name == "ReadyCheckDialog")
            {
                handledReadyCheck = false;
            }

            if (e.NewMenu == null)
                return;

            string menuType = e.NewMenu.GetType().Name;
            this.Monitor.Log($"菜单变化: {e.OldMenu?.GetType().Name ?? "null"} → {menuType}", LogLevel.Debug);

            // 1. ShippingMenu（结算菜单）
            if (e.NewMenu is StardewValley.Menus.ShippingMenu shippingMenu)
            {
                this.Monitor.Log("检测到ShippingMenu，自动点击OK", LogLevel.Info);
                try
                {
                    // 使用反射调用okClicked方法
                    this.Helper.Reflection.GetMethod(shippingMenu, "okClicked").Invoke();
                    this.Monitor.Log("✓ ShippingMenu已自动关闭", LogLevel.Info);
                }
                catch (Exception ex)
                {
                    this.Monitor.Log($"关闭ShippingMenu失败: {ex.Message}", LogLevel.Error);
                }
                return;
            }

            // 2. LevelUpMenu（升级菜单）- 重要！会阻塞睡眠
            if (e.NewMenu is StardewValley.Menus.LevelUpMenu levelUpMenu)
            {
                this.Monitor.Log("检测到LevelUpMenu，自动选择并关闭", LogLevel.Info);
                try
                {
                    // 尝试获取okButton
                    var okButton = this.Helper.Reflection.GetField<StardewValley.Menus.ClickableTextureComponent>(
                        levelUpMenu, "okButton", required: false)?.GetValue();

                    if (okButton != null)
                    {
                        // 点击OK按钮的中心
                        levelUpMenu.receiveLeftClick(okButton.bounds.Center.X, okButton.bounds.Center.Y, true);
                        this.Monitor.Log("✓ LevelUpMenu已自动关闭", LogLevel.Info);
                    }
                    else
                    {
                        // 回退：点击屏幕中下方（OK按钮通常位置）
                        levelUpMenu.receiveLeftClick(640, 500, true);
                        this.Monitor.Log("✓ LevelUpMenu已通过坐标关闭", LogLevel.Info);
                    }
                }
                catch (Exception ex)
                {
                    this.Monitor.Log($"关闭LevelUpMenu失败: {ex.Message}", LogLevel.Error);
                }
                return;
            }
        }

        /// <summary>
        /// v1.3.4: OnSaving - 确保房主位置正确，处理菜单
        /// </summary>
        private void OnSaving(object sender, SavingEventArgs e)
        {
            if (!Context.IsMainPlayer || !Config.Enabled)
                return;

            this.Monitor.Log($"OnSaving事件触发 - 当前位置: {Game1.player.currentLocation?.Name}", LogLevel.Info);
            this.Monitor.Log($"lastSleepLocation: {Game1.player.lastSleepLocation.Value}, lastSleepPoint: {Game1.player.lastSleepPoint.Value}", LogLevel.Info);

            // v1.3.4: CRITICAL - 如果房主不在FarmHouse，强制设置睡眠位置
            if (Game1.player.currentLocation?.Name != "FarmHouse")
            {
                this.Monitor.Log($"警告：房主在{Game1.player.currentLocation?.Name}，强制设置睡眠唤醒位置", LogLevel.Warn);

                int bedX = 9, bedY = 9;
                int houseUpgradeLevel = Game1.player.HouseUpgradeLevel;
                if (houseUpgradeLevel == 1)
                {
                    bedX = 21; bedY = 4;
                }
                else if (houseUpgradeLevel >= 2)
                {
                    bedX = 27; bedY = 13;
                }

                Game1.player.lastSleepLocation.Value = "FarmHouse";
                Game1.player.lastSleepPoint.Value = new Point(bedX, bedY);
                this.Monitor.Log($"✓ 强制设置睡眠唤醒: FarmHouse ({bedX}, {bedY})", LogLevel.Info);
            }

            // 自动点击ShippingMenu的OK按钮
            if (Game1.activeClickableMenu is StardewValley.Menus.ShippingMenu)
            {
                this.Monitor.Log("检测到ShippingMenu（结算菜单），自动点击OK", LogLevel.Info);
                try
                {
                    this.Helper.Reflection.GetMethod(Game1.activeClickableMenu, "okClicked").Invoke();
                    this.Monitor.Log("✓ ShippingMenu已自动关闭", LogLevel.Info);
                }
                catch (Exception ex)
                {
                    this.Monitor.Log($"关闭ShippingMenu失败: {ex.Message}", LogLevel.Error);
                }
            }

            // ShippingMenu关闭后可能出现DialogueBox
            if (Game1.activeClickableMenu is StardewValley.Menus.DialogueBox)
            {
                this.Monitor.Log("OnSaving期间检测到DialogueBox，自动点击关闭", LogLevel.Info);
                Game1.activeClickableMenu.receiveLeftClick(10, 10);
            }
        }

        private void OnUpdateTicked(object sender, UpdateTickedEventArgs e)
        {
            if (!Config.Enabled || !Context.IsMainPlayer)
                return;

            // v1.4.0: 全局菜单和Ready状态处理
            if (e.Ticks % 30 == 0)  // 每0.5秒执行一次
            {
                // 1. 处理DialogueBox
                if (Game1.activeClickableMenu != null && Game1.activeClickableMenu is StardewValley.Menus.DialogueBox)
                {
                    this.Monitor.Log("检测到DialogueBox，自动点击关闭", LogLevel.Info);
                    Game1.activeClickableMenu.receiveLeftClick(10, 10);
                }

                // 2. v1.4.0: 使用Team Ready API - 更可靠的方案
                try
                {
                    // 检查是否有活跃的"sleep"准备检查
                    if (Game1.player?.team != null)
                    {
                        // 尝试通过反射获取ready check状态
                        var readyCheckName = GetActiveReadyCheckName();

                        if (!string.IsNullOrEmpty(readyCheckName) && !handledReadyCheck)
                        {
                            this.Monitor.Log($"检测到活跃的ReadyCheck: '{readyCheckName}'", LogLevel.Info);

                            // 直接设置房主为准备状态
                            try
                            {
                                var setReadyMethod = this.Helper.Reflection.GetMethod(
                                    Game1.player.team, "SetLocalReady", required: false);

                                if (setReadyMethod != null)
                                {
                                    setReadyMethod.Invoke(readyCheckName, true);
                                    this.Monitor.Log($"✓ 房主已设置为准备状态（SetLocalReady）", LogLevel.Info);
                                    handledReadyCheck = true;
                                }
                                else
                                {
                                    this.Monitor.Log("未找到SetLocalReady方法，尝试UI点击", LogLevel.Debug);
                                    // 回退到UI点击
                                    TryClickReadyCheckDialog();
                                }
                            }
                            catch (Exception ex)
                            {
                                this.Monitor.Log($"SetLocalReady失败: {ex.Message}，尝试UI点击", LogLevel.Debug);
                                TryClickReadyCheckDialog();
                            }
                        }
                    }
                }
                catch (Exception ex)
                {
                    this.Monitor.Log($"ReadyCheck处理出错: {ex.Message}", LogLevel.Trace);
                }

                // 3. 自动跳过可跳过的事件
                if (Game1.CurrentEvent != null && Game1.CurrentEvent.skippable)
                {
                    this.Monitor.Log("跳过可跳过的事件", LogLevel.Info);
                    Game1.CurrentEvent.skipEvent();
                }
            }

            // v1.3.5: 睡眠期间维持房主睡眠状态 + 强制睡眠位置
            if (isSleepInProgress)
            {
                if (!Game1.player.isInBed.Value || Game1.player.timeWentToBed.Value == 0)
                {
                    Game1.player.isInBed.Value = true;
                    Game1.player.timeWentToBed.Value = Game1.timeOfDay;
                    LogDebug("持续维持房主睡眠状态");
                }

                // v1.3.5: CRITICAL FIX - 每个tick强制设置睡眠位置
                // 防止被其他代码覆盖
                if (Game1.player.lastSleepLocation.Value != "FarmHouse")
                {
                    int bedX = 9, bedY = 9;
                    int houseUpgradeLevel = Game1.player.HouseUpgradeLevel;
                    if (houseUpgradeLevel == 1)
                    {
                        bedX = 21; bedY = 4;
                    }
                    else if (houseUpgradeLevel >= 2)
                    {
                        bedX = 27; bedY = 13;
                    }

                    Game1.player.lastSleepLocation.Value = "FarmHouse";
                    Game1.player.lastSleepPoint.Value = new Point(bedX, bedY);
                    this.Monitor.Log($"睡眠期间强制修正lastSleepLocation: FarmHouse ({bedX}, {bedY})", LogLevel.Warn);
                }

                return;  // 睡眠期间跳过其他检查
            }

            // 处理延迟睡眠逻辑
            if (needToSleep)
            {
                sleepDelayTicks++;
                if (sleepDelayTicks >= 1)
                {
                    ExecuteSleep();
                    needToSleep = false;
                    sleepDelayTicks = 0;
                }
                return;
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
        /// v1.2.2: 借鉴Always On Server的实现 - 使用startSleep()方法
        /// 关键发现：startSleep是Location对象的方法，不是Farmer的方法！
        /// </summary>
        private void CheckAndAutoSleep()
        {
            if (!Context.IsMainPlayer || !Config.InstantSleepWhenReady)
                return;

            if (!Context.IsWorldReady || hasTriggeredSleep || needToSleep)
                return;

            // 跳过菜单检查
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
                // 检查所有玩家是否真正上床睡觉
                bool allFarmhandsInBed = onlineFarmhands.All(farmer =>
                    farmer.isInBed.Value && farmer.timeWentToBed.Value > 0);

                if (!allFarmhandsInBed)
                    return;

                // 所有玩家都在床上了，触发睡眠
                this.Monitor.Log($"检测到所有 {onlineFarmhands.Count} 名玩家已上床，准备让主机睡觉", LogLevel.Info);

                // v1.2.2: 使用Always On Server的方法
                GoToBed();

                hasTriggeredSleep = true;
                this.Monitor.Log("✓ 主机已进入睡眠流程", LogLevel.Info);
            }
            catch (Exception ex)
            {
                this.Monitor.Log($"触发睡眠时出错: {ex.Message}", LogLevel.Error);
                this.Monitor.Log($"堆栈: {ex.StackTrace}", LogLevel.Debug);
            }
        }

        /// <summary>
        /// v1.3.2: 修复Desert唤醒问题 - 确保房主在FarmHouse醒来
        /// 关键：设置lastSleepLocation和lastSleepPoint确保正确唤醒
        /// </summary>
        private void GoToBed()
        {
            try
            {
                // 获取床的坐标
                int bedX, bedY;
                int houseUpgradeLevel = Game1.player.HouseUpgradeLevel;

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

                this.Monitor.Log($"传送主机到FarmHouse床上 ({bedX}, {bedY})", LogLevel.Info);

                // 预先标记事件
                PreventSleepEvents();

                // 设置睡眠进行标志
                isSleepInProgress = true;

                // 传送到FarmHouse
                Game1.warpFarmer("FarmHouse", bedX, bedY, false);

                // 调用startSleep
                var startSleepMethod = this.Helper.Reflection.GetMethod(Game1.currentLocation, "startSleep");
                startSleepMethod.Invoke();

                // v1.3.3: CRITICAL FIX - 在startSleep()之后设置睡眠位置
                // startSleep()内部可能会设置lastSleepLocation，所以必须在它之后覆盖
                Game1.player.lastSleepLocation.Value = "FarmHouse";
                Game1.player.lastSleepPoint.Value = new Point(bedX, bedY);

                this.Monitor.Log($"✓ startSleep()已调用", LogLevel.Info);
                this.Monitor.Log($"✓ 设置睡眠唤醒位置: FarmHouse ({bedX}, {bedY})", LogLevel.Info);

                Game1.displayHUD = true;
            }
            catch (Exception ex)
            {
                this.Monitor.Log($"GoToBed出错: {ex.Message}", LogLevel.Error);
                this.Monitor.Log($"堆栈: {ex.StackTrace}", LogLevel.Error);
            }
        }

        /// <summary>
        /// 预先标记常见的睡眠特殊事件为"已看过"，防止它们打断睡眠流程
        /// </summary>
        private void PreventSleepEvents()
        {
            try
            {
                // 地震事件 (Spring 3) - 这是最常见导致问题的事件
                if (!Game1.player.eventsSeen.Contains("60367"))
                {
                    Game1.player.eventsSeen.Add("60367");
                    this.Monitor.Log("已预防地震事件 (60367)", LogLevel.Info);
                }

                // 其他常见睡眠事件ID列表
                var commonSleepEvents = new[]
                {
                    "558291",  // Marnie的信件事件
                    "831125",  // 升级提示
                    "502261",  // 梦境事件
                    "26",      // Shane 1心事件
                    "27",      // Shane 2心事件
                    "733330",  // 其他睡眠事件
                };

                foreach (var eventId in commonSleepEvents)
                {
                    if (!Game1.player.eventsSeen.Contains(eventId))
                    {
                        Game1.player.eventsSeen.Add(eventId);
                        this.Monitor.Log($"已预防睡眠事件 ({eventId})", LogLevel.Debug);
                    }
                }

                this.Monitor.Log("✓ 特殊事件预防完成", LogLevel.Info);
            }
            catch (Exception ex)
            {
                this.Monitor.Log($"PreventSleepEvents出错: {ex.Message}", LogLevel.Warn);
            }
        }

        /// <summary>
        /// 准备睡眠：设置床的位置信息（不传送房主，避免黑屏延迟）
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

                // 不传送房主，只设置床的位置信息
                // 这样可以避免传送导致的黑屏延迟
                this.Monitor.Log($"设置床位置: {homeLocationName} ({bedX}, {bedY})", LogLevel.Info);
                Game1.player.mostRecentBed = new Microsoft.Xna.Framework.Vector2(bedX * 64, bedY * 64);
            }
            catch (Exception ex)
            {
                this.Monitor.Log($"PrepareToBed出错: {ex.Message}", LogLevel.Error);
            }
        }

        /// <summary>
        /// 执行睡眠：v1.1.5 新方案 - 传送到床上并模拟点击床的行为
        /// v1.1.4失败原因：只是传送和设置状态，但没有触发床的互动逻辑
        /// 新方案：传送 → 查找床对象 → 触发床的checkAction
        /// </summary>
        private void ExecuteSleep()
        {
            try
            {
                this.Monitor.Log("=== v1.1.5: 开始新的睡眠方案 ===", LogLevel.Info);

                // 获取房主的homeLocation和床坐标
                string homeLocationName = Game1.player.homeLocation.Value;
                int bedX, bedY;
                int houseUpgradeLevel = Game1.player.HouseUpgradeLevel;

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

                this.Monitor.Log($"房屋等级 {houseUpgradeLevel}, 床坐标: ({bedX}, {bedY})", LogLevel.Info);

                // CRITICAL FIX: 预先标记所有常见特殊事件为"已看过"，避免地震等事件干扰
                PreventSleepEvents();

                // 关闭所有活动菜单
                if (Game1.activeClickableMenu != null)
                {
                    this.Monitor.Log($"关闭菜单: {Game1.activeClickableMenu.GetType().Name}", LogLevel.Debug);
                    Game1.activeClickableMenu = null;
                }

                // 第一步：将房主传送到FarmHouse的床旁边（不是床上，而是床前）
                this.Monitor.Log($"传送房主从 {Game1.currentLocation.Name} 到 {homeLocationName}", LogLevel.Info);
                Game1.warpFarmer(homeLocationName, bedX, bedY, false);

                // 传送后立即在下一个tick尝试查找床对象并模拟点击
                // 使用Helper的事件来延迟执行
                void HandleAfterWarp(object s, EventArgs ev)
                {
                    try
                    {
                        this.Monitor.Log("传送完成，开始查找床对象...", LogLevel.Debug);

                        var farmHouse = Game1.currentLocation as StardewValley.Locations.FarmHouse;
                        if (farmHouse != null)
                        {
                            // 查找床对象（BedFurniture）
                            var bed = farmHouse.furniture.FirstOrDefault(f =>
                                f is StardewValley.Objects.BedFurniture &&
                                f.TileLocation.X == bedX &&
                                f.TileLocation.Y == bedY);

                            if (bed != null)
                            {
                                this.Monitor.Log($"找到床对象: {bed.GetType().Name} at ({bedX}, {bedY})", LogLevel.Info);

                                // 模拟点击床
                                var bedFurniture = bed as StardewValley.Objects.BedFurniture;
                                if (bedFurniture != null)
                                {
                                    // 调用床的checkForAction方法，模拟玩家点击床
                                    bool clicked = bedFurniture.checkForAction(Game1.player, false);
                                    this.Monitor.Log($"模拟点击床: {clicked}", LogLevel.Info);
                                }
                            }
                            else
                            {
                                this.Monitor.Log($"× 未找到床对象 at ({bedX}, {bedY})", LogLevel.Warn);
                                this.Monitor.Log($"FarmHouse家具数量: {farmHouse.furniture.Count}", LogLevel.Debug);

                                // 备用方案：直接设置睡眠状态
                                Game1.player.isInBed.Value = true;
                                Game1.player.timeWentToBed.Value = Game1.timeOfDay;
                                Game1.player.lastSleepLocation.Value = homeLocationName;
                                Game1.player.lastSleepPoint.Value = new Microsoft.Xna.Framework.Point(bedX, bedY);
                                this.Monitor.Log("使用备用方案：直接设置睡眠状态", LogLevel.Warn);
                            }
                        }
                        else
                        {
                            this.Monitor.Log("× 当前位置不是FarmHouse", LogLevel.Error);
                        }

                        // 设置睡眠进行标志
                        isSleepInProgress = true;

                        // 取消订阅事件
                        this.Helper.Events.GameLoop.UpdateTicked -= HandleAfterWarp;
                    }
                    catch (Exception ex)
                    {
                        this.Monitor.Log($"HandleAfterWarp出错: {ex.Message}", LogLevel.Error);
                        this.Monitor.Log($"堆栈: {ex.StackTrace}", LogLevel.Error);
                        this.Helper.Events.GameLoop.UpdateTicked -= HandleAfterWarp;
                    }
                }

                // 订阅一次性事件，在下一个tick执行
                this.Helper.Events.GameLoop.UpdateTicked += HandleAfterWarp;

                this.Monitor.Log("✓ 传送已触发，等待下一个tick执行点击床逻辑...", LogLevel.Info);
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

        /// <summary>
        /// v1.4.0: 获取当前活跃的ReadyCheck名称（如"sleep"）
        /// </summary>
        private string GetActiveReadyCheckName()
        {
            try
            {
                // 检查是否有ReadyCheckDialog打开
                if (Game1.activeClickableMenu != null &&
                    Game1.activeClickableMenu.GetType().Name == "ReadyCheckDialog")
                {
                    // 尝试通过反射获取readyCheckId字段
                    var idField = this.Helper.Reflection.GetField<string>(
                        Game1.activeClickableMenu, "checkId", required: false);

                    if (idField != null)
                    {
                        return idField.GetValue();
                    }

                    // 回退：尝试其他可能的字段名
                    var altField = this.Helper.Reflection.GetField<string>(
                        Game1.activeClickableMenu, "readyCheckId", required: false);

                    if (altField != null)
                    {
                        return altField.GetValue();
                    }

                    // 默认返回"sleep"（最常见情况）
                    return "sleep";
                }

                return null;
            }
            catch (Exception ex)
            {
                this.Monitor.Log($"获取ReadyCheck名称失败: {ex.Message}", LogLevel.Trace);
                return null;
            }
        }

        /// <summary>
        /// v1.4.0: 回退方案 - 通过UI点击ReadyCheckDialog
        /// </summary>
        private void TryClickReadyCheckDialog()
        {
            try
            {
                if (Game1.activeClickableMenu == null ||
                    Game1.activeClickableMenu.GetType().Name != "ReadyCheckDialog")
                {
                    return;
                }

                // 尝试通过反射获取OK按钮
                var okButton = this.Helper.Reflection.GetField<object>(
                    Game1.activeClickableMenu, "okButton", required: false)?.GetValue();

                if (okButton is StardewValley.Menus.ClickableTextureComponent button)
                {
                    // 点击按钮中心
                    Game1.activeClickableMenu.receiveLeftClick(
                        button.bounds.Center.X,
                        button.bounds.Center.Y,
                        true);
                    this.Monitor.Log("✓ ReadyCheckDialog已通过反射点击", LogLevel.Info);
                    handledReadyCheck = true;
                    return;
                }

                // 最后的回退：使用估算的坐标
                Game1.activeClickableMenu.receiveLeftClick(640, 460, true);
                this.Monitor.Log("✓ ReadyCheckDialog已通过坐标点击（回退方案）", LogLevel.Info);
                handledReadyCheck = true;
            }
            catch (Exception ex)
            {
                this.Monitor.Log($"点击ReadyCheckDialog失败: {ex.Message}", LogLevel.Error);
            }
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
