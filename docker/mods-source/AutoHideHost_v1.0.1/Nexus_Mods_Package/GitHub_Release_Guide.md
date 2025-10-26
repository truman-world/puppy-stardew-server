# GitHub 发布步骤

## 1. Git 提交
```bash
git add AutoHideHost_v1.0.1_FIX/
git commit -m "Fix: Add menu check to prevent black screen issue (v1.0.1)

- Fixed black screen when selling items and sleeping in multiplayer
- Added check for activeClickableMenu before triggering sleep
- Updated version to 1.0.1
- Tested and confirmed working

🤖 Generated with Claude Code

Co-Authored-By: Claude <noreply@anthropic.com>"
git push origin main
```

## 2. 创建 GitHub Release
1. 访问: https://github.com/truman-world/puppy-stardew-server/releases
2. 点击 "Create a new release"
3. 选择 "Choose a tag"
4. 创建新标签: `v1.0.1`
5. 标题: `AutoHideHost v1.0.1 - Black Screen Fix`
6. 内容: 复制 RELEASE_NOTES.md 中的内容
7. 上传文件:
   - AutoHideHost.dll
   - manifest.json
   - config.json
   - ModEntry.cs (可选，供开发者参考)
8. 点击 "Publish release"

## 3. 更新 README.md
在项目根目录的 README.md 中添加:
```
## 更新日志
### v1.0.1 (2025-01-26)
- 🐛 修复了多人游戏中卖东西后睡觉黑屏的问题
- ⚡ 改进了睡眠检测机制，避免与结算菜单冲突
```
