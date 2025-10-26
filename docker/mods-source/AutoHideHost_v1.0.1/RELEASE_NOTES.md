# AutoHideHost v1.0.1 Release Notes

## 🐛 Bug Fixes

### Fixed: Black screen when selling items and sleeping in multiplayer

**Issue:** In multiplayer games, when players sell items during the day and then sleep at night, the game would display a black screen and become unresponsive after the sleep transition.

**Root Cause:** AutoHideHost was triggering instant sleep while the game's settlement menu (showing day's earnings) was trying to display, causing a conflict that resulted in a black screen.

**Solution:** Added a critical check in `CheckAndAutoSleep()` function to wait for any active menu (including settlement menu) to complete before triggering sleep. The fix ensures:
- The settlement menu displays properly showing daily earnings
- Sleep transition happens only after menu is closed
- No more black screen freeze issues

**Files Changed:**
- `ModEntry.cs` - Added menu check before triggering sleep

## 📋 Installation

1. Replace the old `AutoHideHost.dll` in your `Mods/AutoHideHost` folder
2. Update `manifest.json` to version 1.0.1 (included)
3. Restart your server

## ⚠️ Important

- Make sure to replace ALL files in the mod folder
- This fix is compatible with SMAPI 4.0.0+
- No configuration changes needed

## 🙏 Acknowledgments

Special thanks to the community for reporting and helping test this fix.

## 📄 License

Same as original mod license.
