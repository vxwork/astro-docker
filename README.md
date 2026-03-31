# Astro Docker 部署方案

本项目提供了一套完整的 Astro 应用 Docker 构建和部署解决方案，支持：

- ✅ 自动构建包含 8 位 SHA 的 Docker 镜像
- ✅ 推送镜像到 GitHub Container Registry (ghcr.io)
- ✅ GitHub Actions 自动化工作流
- ✅ 一键部署脚本 (`deploy.sh`)
- ✅ Docker Compose 配置

## 📦 文件结构

```
.
├── Dockerfile                          # Docker 构建文件
├── docker-compose.yml                  # Docker Compose 配置
├── deploy.sh                           # 部署脚本
├── .dockerignore                       # Docker 忽略文件
├── .env.example                        # 环境变量示例
└── .github/
    └── workflows/
        └── docker-build.yml           # GitHub Actions 工作流
```

## 🚀 快速开始

### 1. 准备工作

确保你已经安装并配置好以下工具：

- [Astro](https://astro.build/) 项目
- Docker 和 Docker Compose
- GitHub 账号

### 2. 配置 GitHub Secrets

在 GitHub 仓库中，GitHub Actions 会自动使用 `GITHUB_TOKEN`，无需额外配置。

如果需要手动登录 GHCR，创建 Personal Access Token：

1. 访问 GitHub Settings > Developer settings > Personal access tokens
2. 生成一个新的 token，勾选 `write:packages` 权限
3. 在仓库 Settings > Secrets and variables > Actions 中添加：
   - `GHCR_USERNAME`: 你的 GitHub 用户名
   - `GHCR_TOKEN`: 生成的 token

### 3. 自定义配置

#### 修改 `.env.example` 为 `.env`

```bash
cp .env.example .env
```

编辑 `.env` 文件，填入你的 GitHub 用户名和仓库信息。

#### 调整 Dockerfile（可选）

如果你的 Astro 项目有特殊需求，可以修改 [`Dockerfile`](Dockerfile)：

- 修改 Node.js 版本（当前使用 node:20-alpine）
- 添加额外的构建步骤
- 修改端口号（默认 4321）

### 4. 自动构建和推送

推送到 main/master 分支时，GitHub Actions 会自动：

1. 构建 Docker 镜像
2. 生成包含 8 位提交 SHA 的标签
3. 推送到 ghcr.io

例如：`ghcr.io/username/repo:abc12345`

## 🛠️ 使用方法

### 方式一：使用部署脚本（推荐）

```bash
# 自动获取最新版本并部署
./deploy.sh

# 部署指定 SHA 版本（8 位）
./deploy.sh abc12345

# 使用 latest 标签
./deploy.sh latest
```

部署脚本会：
1. 自动从 ghcr.io 拉取镜像
2. 停止旧的容器
3. 使用 Docker Compose 启动新容器

### 方式二：手动使用 Docker Compose

```bash
# 设置环境变量
export IMAGE_TAG=abc12345
export REPO_OWNER=your-username
export REPO_NAME=your-repo

# 拉取镜像
docker pull ghcr.io/${REPO_OWNER}/${REPO_NAME}:${IMAGE_TAG}

# 启动容器
docker compose up -d
```

### 方式三：直接使用 Docker

```bash
docker run -d \
  --name astro-app \
  -p 4321:4321 \
  --restart unless-stopped \
  ghcr.io/your-username/your-repo:abc12345
```

## 📝 配置说明

### Docker Compose 环境变量

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| `REGISTRY` | 镜像仓库地址 | `ghcr.io` |
| `REPO_OWNER` | GitHub 用户名或组织 | 从 git remote 获取 |
| `REPO_NAME` | 仓库名称 | 从 git remote 获取 |
| `IMAGE_TAG` | 镜像标签（SHA 或 latest） | `latest` |

### 端口映射

默认情况下，Astro 应用在 **4321** 端口运行。

如需修改，编辑 [`docker-compose.yml`](docker-compose.yml)：

```yaml
ports:
  - "8080:4321"  # 将外部 8080 端口映射到内部 4321 端口
```

## 🔍 验证部署

```bash
# 查看容器状态
docker ps

# 查看日志
docker logs astro-app

# 进入容器
docker exec -it astro-app sh

# 健康检查
curl http://localhost:4321
```

## 🔄 更新策略

### 自动更新（推荐）

使用部署脚本自动获取最新版本：

```bash
./deploy.sh
```

### 手动更新

```bash
# 停止旧容器
docker compose down

# 拉取新镜像
docker pull ghcr.io/your-username/your-repo:newsha

# 启动新容器
docker compose up -d
```

### 回滚到旧版本

```bash
# 使用之前的 SHA 重新部署
./deploy.sh oldsha123
```

## 🐛 故障排查

### 无法拉取镜像

确保已登录 GHCR：

```bash
docker login ghcr.io
# 输入 GitHub 用户名和 Personal Access Token
```

### 容器启动失败

查看日志：

```bash
docker logs astro-app
```

### 端口冲突

修改 [`docker-compose.yml`](docker-compose.yml) 中的端口映射：

```yaml
ports:
  - "新端口:4321"
```

## 📊 GitHub Actions 工作流说明

工作流文件：[`.github/workflows/docker-build.yml`](.github/workflows/docker-build.yml)

触发条件：
- Push 到 main/master 分支
- 创建 tag
- Pull Request

构建内容：
- 多平台镜像（amd64, arm64）
- 包含 8 位 SHA 的标签
- 最新提交标签
- Semver 标签（如果是 tag 触发）

## 🔐 安全建议

1. **不要提交敏感信息**：确保 `.env` 文件在 `.gitignore` 中
2. **使用 Secrets**：在 GitHub Actions 中使用 Secrets 管理凭证
3. **限制包可见性**：在 GitHub 仓库设置中控制 Container packages 的可见性
4. **定期更新 Token**：定期更换 Personal Access Token

## 📚 相关资源

- [Astro 官方文档](https://docs.astro.build/)
- [Docker 文档](https://docs.docker.com/)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [GitHub Actions 文档](https://docs.github.com/en/actions)

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License
