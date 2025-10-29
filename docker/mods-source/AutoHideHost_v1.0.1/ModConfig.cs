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
    }
}
