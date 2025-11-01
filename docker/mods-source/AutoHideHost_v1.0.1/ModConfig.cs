namespace AutoHideHost
{
    public class ModConfig
    {
        public bool Enabled { get; set; } = true;
        public bool AutoHideOnLoad { get; set; } = true;
        public bool AutoHideDaily { get; set; } = true;
        public bool PauseWhenEmpty { get; set; } = false;  // 默认改为false，避免服务器暂停导致客户端无法连接
        public bool InstantSleepWhenReady { get; set; } = true;
        public string HideMethod { get; set; } = "warp";
        public string WarpLocation { get; set; } = "Desert";
        public int WarpX { get; set; } = 0;
        public int WarpY { get; set; } = 0;
        public bool DebugMode { get; set; } = true;

        // v1.1.8: 守护窗口机制 - 防止玩家连接后房主被传送到Farm
        public bool PreventHostFarmWarp { get; set; } = true;  // 启用防传送机制
        public int PeerConnectGuardSeconds { get; set; } = 30;  // 守护窗口时长（秒）
        public int RehideDelayTicks { get; set; } = 1;  // 重新隐藏延迟（游戏帧数）
        public bool DebugTraceMenus { get; set; } = false;  // 启用菜单堆栈追踪
    }
}
