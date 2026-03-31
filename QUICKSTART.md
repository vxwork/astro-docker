# 快速参考指南

## 📋 使用流程

### 1. 首次设置

```bash
# 复制环境变量示例文件
cp .env.example .env

# 编辑 .env 文件，填入你的 GitHub 信息
# REPO_OWNER=your-github-username
# REPO_NAME=your-repo-name
```

### 2. 配置 GitHub

在 GitHub 仓库 Settings → Secrets and variables → Actions 中确保有：
- `GITHUB_TOKEN` (自动提供，无需手动配置)

如需手动登录 GHCR，添加：
- `GHCR_USERNAME`: 你的 GitHub 用户名
- `GHCR_TOKEN`: Personal Access Token (需要 `write:packages` 权限)

### 3. 推送代码触发构建

```bash
git add .
git commit -m "Initial commit"
git push origin main
```

GitHub Actions 会自动构建并推送镜像到 ghcr.io

### 4. 部署应用

#### Linux/Mac:

```bash
# 自动部署最新版本
./deploy.sh

# 部署指定 SHA 版本
./deploy.sh abc12345

# 使用 latest 标签
./deploy.sh latest
```

#### Windows PowerShell:

```powershell
# 自动部署最新版本
.\deploy.ps1

# 部署指定 SHA 版本
.\deploy.ps1 abc12345

# 使用 latest 标签
.\deploy.ps1 latest
```

### 5. 验证部署

```bash
# 查看运行状态
docker ps

# 访问应用
curl http://localhost:4321

# 查看日志
docker logs astro-app
```

---

## 🔧 常用命令

### Docker 相关

```bash
# 查看容器状态
docker ps

# 停止容器
docker compose down

# 启动容器
docker compose up -d

# 重启容器
docker compose restart

# 查看日志
docker logs -f astro-app

# 进入容器
docker exec -it astro-app sh

# 删除容器和镜像
docker compose down -v
```

### GitHub Actions 相关

```bash
# 手动触发工作流（需要安装 GitHub CLI）
gh workflow run docker-build.yml

# 查看工作流运行记录
gh run list

# 查看特定运行的日志
gh run view <run-id> --log
```

---

## 🏷️ 镜像标签说明

| 标签类型 | 示例 | 说明 |
|---------|------|------|
| SHA | `abc12345` | 8 位提交哈希，推荐用于生产环境 |
| Branch | `main` | 分支名称，指向最新提交 |
| Tag | `v1.0.0` | Git 标签，用于版本发布 |
| Latest | `latest` | 最新构建（不推荐用于生产） |

---

## 🚨 故障排查

### 问题：无法拉取镜像

**解决方案：**
```bash
# 登录 GHCR
docker login ghcr.io
# 输入 GitHub 用户名和 Personal Access Token
```

### 问题：端口被占用

**解决方案：**
修改 `docker-compose.yml`：
```yaml
ports:
  - "8080:4321"  # 改为其他端口
```

### 问题：权限不足

**解决方案：**
```bash
# Linux/Mac 给脚本添加执行权限
chmod +x deploy.sh

# Windows 以管理员身份运行 PowerShell
```

### 问题：GitHub Actions 构建失败

**检查项：**
1. 确认 `GITHUB_TOKEN` 权限足够
2. 检查 Dockerfile 语法
3. 查看 Actions 日志获取详细错误

---

## 📊 监控和维护

### 健康检查

```bash
# 检查容器健康状态
docker inspect --format='{{.State.Health.Status}}' astro-app

# 测试应用响应
curl -I http://localhost:4321
```

### 资源使用

```bash
# 查看容器资源使用
docker stats astro-app
```

### 日志管理

```bash
# 实时查看日志
docker logs -f astro-app

# 查看最近 100 行日志
docker logs --tail 100 astro-app

# 查看特定时间范围的日志
docker logs --since 2024-01-01T00:00:00 astro-app
```

---

## 🔄 更新策略

### 滚动更新

```bash
# 部署新版本
./deploy.sh newsha123

# 验证新版本的 SHA
docker inspect astro-app | grep Image
```

### 回滚

```bash
# 回滚到之前的版本
./deploy.sh oldsha456
```

---

## 💡 最佳实践

1. **生产环境使用固定 SHA**：不要使用 `latest` 标签
2. **定期清理旧镜像**：避免占用过多存储空间
3. **监控容器健康**：设置告警通知
4. **备份重要数据**：如果有持久化数据，定期备份
5. **测试后再部署**：在 staging 环境测试后再部署到生产

---

## 📞 获取帮助

- 查看完整文档：[README.md](README.md)
- Astro 文档：https://docs.astro.build/
- Docker 文档：https://docs.docker.com/
- GitHub Actions 文档：https://docs.github.com/en/actions
