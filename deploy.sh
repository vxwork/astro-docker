#!/bin/bash

# Astro Docker 部署脚本
# 使用方法:
#   ./deploy.sh              # 使用最新的 main 分支镜像
#   ./deploy.sh abc12345     # 使用指定的 SHA 版本 (8 位)
#   ./deploy.sh latest       # 使用 latest 标签

set -e

# 配置变量
REGISTRY="ghcr.io"
REPO_OWNER="$(echo '${{ github.repository }}' | cut -d'/' -f1)"
REPO_NAME="$(echo '${{ github.repository }}' | cut -d'/' -f2)"
IMAGE_NAME="${REGISTRY}/${REPO_OWNER}/${REPO_NAME}"
CONTAINER_NAME="astro-app"
COMPOSE_PROJECT_NAME="astro"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 获取镜像标签
get_image_tag() {
    local sha_version="$1"
    
    if [ -z "$sha_version" ]; then
        # 如果没有提供版本，尝试获取最新的 main 分支 SHA
        log_info "未指定版本，尝试从 GitHub 获取最新的提交 SHA..."
        
        # 从 GitHub API 获取最新提交 SHA (8 位)
        LATEST_SHA=$(curl -s "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/commits?sha=main&per_page=1" | grep -o '"sha": "[a-f0-9]*"' | head -1 | cut -d'"' -f4 | cut -c1-8)
        
        if [ -n "$LATEST_SHA" ]; then
            log_info "找到最新提交 SHA: ${LATEST_SHA}"
            echo "$LATEST_SHA"
        else
            log_error "无法获取最新提交 SHA，请手动指定版本"
            exit 1
        fi
    elif [ "$sha_version" = "latest" ]; then
        log_info "使用 latest 标签"
        echo "latest"
    else
        # 验证 SHA 格式 (8 位十六进制)
        if [[ ! "$sha_version" =~ ^[a-f0-9]{8}$ ]]; then
            log_error "无效的 SHA 格式：$sha_version (应该是 8 位十六进制)"
            exit 1
        fi
        log_info "使用指定版本：$sha_version"
        echo "$sha_version"
    fi
}

# 拉取镜像
pull_image() {
    local tag="$1"
    local full_image_name="${IMAGE_NAME}:${tag}"
    
    log_info "正在拉取镜像：${full_image_name}"
    
    # 登录到 ghcr.io
    if ! docker info 2>/dev/null | grep -q "Username"; then
        log_warn "Docker 未登录，正在尝试登录 ghcr.io..."
        echo "${GHCR_TOKEN}" | docker login ghcr.io -u "${GHCR_USERNAME}" --password-stdin 2>/dev/null || {
            log_warn "自动登录失败，请确保您已执行：docker login ghcr.io"
        }
    fi
    
    # 拉取镜像
    if ! docker pull "${full_image_name}"; then
        log_error "拉取镜像失败：${full_image_name}"
        exit 1
    fi
    
    log_info "镜像拉取成功：${full_image_name}"
}

# 停止并清理旧容器
cleanup_old_containers() {
    log_info "检查并清理旧的容器..."
    
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_warn "发现运行中的容器，正在停止..."
        docker compose -p "${COMPOSE_PROJECT_NAME}" down || docker-compose -p "${COMPOSE_PROJECT_NAME}" down
        log_info "旧容器已停止"
    fi
}

# 启动新容器
start_container() {
    local tag="$1"
    
    log_info "正在启动新容器 (镜像标签：${tag})..."
    
    # 设置环境变量
    export IMAGE_TAG="${tag}"
    export REGISTRY="${REGISTRY}"
    export REPO_OWNER="${REPO_OWNER}"
    export REPO_NAME="${REPO_NAME}"
    
    # 使用 docker compose 启动
    if command -v docker &> /dev/null && docker compose version &> /dev/null; then
        log_info "使用 docker compose 启动..."
        docker compose -p "${COMPOSE_PROJECT_NAME}" up -d
    elif command -v docker-compose &> /dev/null; then
        log_info "使用 docker-compose 启动..."
        docker-compose -p "${COMPOSE_PROJECT_NAME}" up -d
    else
        log_error "未找到 docker compose 或 docker-compose 命令"
        exit 1
    fi
    
    # 等待容器启动
    sleep 5
    
    # 检查容器状态
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_info "✅ 容器启动成功!"
        log_info "容器名称：${CONTAINER_NAME}"
        log_info "镜像：${IMAGE_NAME}:${tag}"
        log_info "访问地址：http://localhost:4321"
    else
        log_error "❌ 容器启动失败，请查看日志：docker logs ${CONTAINER_NAME}"
        exit 1
    fi
}

# 显示帮助信息
show_help() {
    cat << EOF
Astro Docker 部署脚本

使用方法:
  $0 [VERSION]

参数:
  VERSION    可选，镜像版本标签
             - 8 位 SHA (例如：abc12345)
             - latest (使用 latest 标签)
             - 留空 (自动获取最新的 main 分支 SHA)

示例:
  $0                  # 自动部署最新版本
  $0 abc12345        # 部署指定 SHA 版本
  $0 latest          # 部署 latest 标签版本

环境变量:
  GHCR_USERNAME      GitHub Container Registry 用户名
  GHCR_TOKEN         GitHub Container Registry 访问令牌

EOF
}

# 主函数
main() {
    log_info "🚀 开始部署 Astro 应用..."
    
    # 获取镜像标签
    IMAGE_TAG=$(get_image_tag "$1")
    
    # 清理旧容器
    cleanup_old_containers
    
    # 拉取镜像
    pull_image "${IMAGE_TAG}"
    
    # 启动新容器
    start_container "${IMAGE_TAG}"
    
    log_info "🎉 部署完成!"
}

# 执行主函数
main "$@"
