# Astro Docker 部署脚本 (Windows PowerShell 版本)
# 使用方法:
#   .\deploy.ps1              # 使用最新的 main 分支镜像
#   .\deploy.ps1 abc12345     # 使用指定的 SHA 版本 (8 位)
#   .\deploy.ps1 latest       # 使用 latest 标签

param(
    [Parameter(Position=0)]
    [string]$ShaVersion = ""
)

$ErrorActionPreference = "Stop"

# 配置变量
$Registry = "ghcr.io"
$RepoOwner = $env:REPO_OWNER
$RepoName = $env:REPO_NAME
$ImageName = "${Registry}/${RepoOwner}/${RepoName}"
$ContainerName = "astro-app"
$ComposeProjectName = "astro"

# 颜色输出函数
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# 获取镜像标签
function Get-ImageTag {
    param([string]$ShaVersion)
    
    if ([string]::IsNullOrEmpty($ShaVersion)) {
        Write-Info "未指定版本，尝试从 GitHub 获取最新的提交 SHA..."
        
        try {
            $response = Invoke-RestMethod -Uri "https://api.github.com/repos/${RepoOwner}/${RepoName}/commits?sha=main&per_page=1" -UseBasicParsing
            $LatestSha = $response[0].sha.Substring(0, 8)
            Write-Info "找到最新提交 SHA: ${LatestSha}"
            return $LatestSha
        } catch {
            Write-Error-Custom "无法获取最新提交 SHA，请手动指定版本"
            exit 1
        }
    } elseif ($ShaVersion -eq "latest") {
        Write-Info "使用 latest 标签"
        return "latest"
    } else {
        # 验证 SHA 格式 (8 位十六进制)
        if ($ShaVersion -notmatch '^[a-f0-9]{8}$') {
            Write-Error-Custom "无效的 SHA 格式：$ShaVersion (应该是 8 位十六进制)"
            exit 1
        }
        Write-Info "使用指定版本：$ShaVersion"
        return $ShaVersion
    }
}

# 拉取镜像
function Pull-Image {
    param([string]$Tag)
    $FullImageName = "${ImageName}:${Tag}"
    
    Write-Info "正在拉取镜像：${FullImageName}"
    
    # 检查 Docker 是否登录
    $dockerInfo = docker info 2>&1 | Out-String
    if ($dockerInfo -notmatch "Username") {
        Write-Warn "Docker 未登录，正在尝试登录 ghcr.io..."
        try {
            $token = Read-Host "请输入 GHCR Token"
            $username = Read-Host "请输入 GHCR 用户名"
            echo $token | docker login ghcr.io -u $username --password-stdin 2>$null
        } catch {
            Write-Warn "自动登录失败，请手动执行：docker login ghcr.io"
        }
    }
    
    # 拉取镜像
    docker pull $FullImageName
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "拉取镜像失败：${FullImageName}"
        exit 1
    }
    
    Write-Info "镜像拉取成功：${FullImageName}"
}

# 停止并清理旧容器
function Cleanup-OldContainers {
    Write-Info "检查并清理旧的容器..."
    
    $containers = docker ps -a --format "{{.Names}}" | Select-String "^${ContainerName}$"
    if ($containers) {
        Write-Warn "发现运行中的容器，正在停止..."
        docker compose -p $ComposeProjectName down
        Write-Info "旧容器已停止"
    }
}

# 启动新容器
function Start-Container {
    param([string]$Tag)
    
    Write-Info "正在启动新容器 (镜像标签：${Tag})..."
    
    # 设置环境变量
    $env:IMAGE_TAG = $Tag
    $env:REGISTRY = $Registry
    $env:REPO_OWNER = $RepoOwner
    $env:REPO_NAME = $RepoName
    
    # 使用 docker compose 启动
    Write-Info "使用 docker compose 启动..."
    docker compose -p $ComposeProjectName up -d
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "容器启动失败，请查看日志：docker logs ${ContainerName}"
        exit 1
    }
    
    # 等待容器启动
    Start-Sleep -Seconds 5
    
    # 检查容器状态
    $runningContainers = docker ps --format "{{.Names}}" | Select-String "^${ContainerName}$"
    if ($runningContainers) {
        Write-Info "✅ 容器启动成功!"
        Write-Info "容器名称：${ContainerName}"
        Write-Info "镜像：${ImageName}:${Tag}"
        Write-Info "访问地址：http://localhost:4321"
    } else {
        Write-Error-Custom "❌ 容器启动失败，请查看日志：docker logs ${ContainerName}"
        exit 1
    }
}

# 主函数
function Main {
    Write-Info "🚀 开始部署 Astro 应用..."
    
    # 获取镜像标签
    $imageTag = Get-ImageTag -ShaVersion $ShaVersion
    
    # 清理旧容器
    Cleanup-OldContainers
    
    # 拉取镜像
    Pull-Image -Tag $imageTag
    
    # 启动新容器
    Start-Container -Tag $imageTag
    
    Write-Info "🎉 部署完成!"
}

# 执行主函数
Main
