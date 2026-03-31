# Astro Docker Deployment Script (Windows PowerShell Version)
# Usage:
#   .\deploy.ps1              # Use latest main branch image
#   .\deploy.ps1 abc12345     # Use specified SHA version (8 characters)
#   .\deploy.ps1 latest       # Use latest tag

param(
    [Parameter(Position=0)]
    [string]$ShaVersion = ""
)

$ErrorActionPreference = "Stop"

# Configuration variables
$Registry = "ghcr.io"
$RepoOwner = $env:REPO_OWNER
$RepoName = $env:REPO_NAME
$ImageName = "${Registry}/${RepoOwner}/${RepoName}"
$ContainerName = "astro-app"
$ComposeProjectName = "astro"

# Color output functions
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

# Get image tag
function Get-ImageTag {
    param([string]$ShaVersion)
    
    if ([string]::IsNullOrEmpty($ShaVersion)) {
        Write-Info "No version specified, attempting to get latest commit SHA from GitHub..."
        
        try {
            $response = Invoke-RestMethod -Uri "https://api.github.com/repos/${RepoOwner}/${RepoName}/commits?sha=main&per_page=1" -UseBasicParsing
            $LatestSha = $response[0].sha.Substring(0, 8)
            Write-Info "Found latest commit SHA: ${LatestSha}"
            return $LatestSha
        } catch {
            Write-Error-Custom "Failed to get latest commit SHA, please specify version manually"
            exit 1
        }
    } elseif ($ShaVersion -eq "latest") {
        Write-Info "Using latest tag"
        return "latest"
    } else {
        # Validate SHA format (8 hexadecimal characters)
        if ($ShaVersion -notmatch '^[a-f0-9]{8}$') {
            Write-Error-Custom "Invalid SHA format: $ShaVersion (should be 8 hexadecimal characters)"
            exit 1
        }
        Write-Info "Using specified version: $ShaVersion"
        return $ShaVersion
    }
}

# Pull image
function Pull-Image {
    param([string]$Tag)
    $FullImageName = "${ImageName}:${Tag}"
    
    Write-Info "Pulling image: ${FullImageName}"
    
    # Check if Docker is logged in
    $dockerInfo = docker info 2>&1 | Out-String
    if ($dockerInfo -notmatch "Username") {
        Write-Warn "Docker not logged in, attempting to log in to ghcr.io..."
        try {
            $token = Read-Host "Enter GHCR Token"
            $username = Read-Host "Enter GHCR Username"
            echo $token | docker login ghcr.io -u $username --password-stdin 2>$null
        } catch {
            Write-Warn "Automatic login failed, please manually execute: docker login ghcr.io"
        }
    }
    
    # Pull image
    docker pull $FullImageName
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Failed to pull image: ${FullImageName}"
        exit 1
    }
    
    Write-Info "Image pulled successfully: ${FullImageName}"
}

# Stop and clean up old containers
function Cleanup-OldContainers {
    Write-Info "Checking and cleaning up old containers..."
    
    $containers = docker ps -a --format "{{.Names}}" | Select-String "^${ContainerName}$"
    if ($containers) {
        Write-Warn "Running containers found, stopping..."
        docker compose -p $ComposeProjectName down
        Write-Info "Old containers stopped"
    }
}

# Start new container
function Start-Container {
    param([string]$Tag)
    
    Write-Info "Starting new container (image tag: ${Tag})..."
    
    # Set environment variables
    $env:IMAGE_TAG = $Tag
    $env:REGISTRY = $Registry
    $env:REPO_OWNER = $RepoOwner
    $env:REPO_NAME = $RepoName
    
    # Use docker compose to start
    Write-Info "Using docker compose to start..."
    docker compose -p $ComposeProjectName up -d
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Container failed to start, please check logs: docker logs ${ContainerName}"
        exit 1
    }
    
    # Wait for container to start
    Start-Sleep -Seconds 5
    
    # Check container status
    $runningContainers = docker ps --format "{{.Names}}" | Select-String "^${ContainerName}$"
    if ($runningContainers) {
        Write-Info "✅ Container started successfully!"
        Write-Info "Container name: ${ContainerName}"
        Write-Info "Image: ${ImageName}:${Tag}"
        Write-Info "Access URL: http://localhost:4321"
    } else {
        Write-Error-Custom "❌ Container failed to start, please check logs: docker logs ${ContainerName}"
        exit 1
    }
}

# Main function
function Main {
    Write-Info "🚀 Starting Astro app deployment..."
    
    # Get image tag
    $imageTag = Get-ImageTag -ShaVersion $ShaVersion
    
    # Clean up old containers
    Cleanup-OldContainers
    
    # Pull image
    Pull-Image -Tag $imageTag
    
    # Start new container
    Start-Container -Tag $imageTag
    
    Write-Info "🎉 Deployment completed!"
}

# Execute main function
Main
