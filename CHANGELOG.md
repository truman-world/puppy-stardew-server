# v1.0.21 Release Notes

## 主要改进

### 自动权限修复
- 容器以 root 启动，自动修复挂载卷权限
- 无需手动运行 init.sh 或 chown 命令
- 自动切换到 steam 用户运行游戏

### 提升可靠性
- 修复游戏存在时的容器重启循环问题
- 改进错误处理和日志输出

## 升级说明

从 v1.0.20 升级到 v1.0.21：
```bash
docker-compose down
docker-compose pull
docker-compose up -d
```

无需其他操作！

