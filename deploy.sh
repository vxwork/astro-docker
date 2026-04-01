#!/bin/bash

# Astro Docker Deployment Script
# Usage:
#   ./deploy.sh              # Use latest main branch image
#   ./deploy.sh abc12345     # Use specified SHA version (8 characters)
#   ./deploy.sh latest       # Use latest tag
#
# Architecture:
#   - Multi-stage Docker build with Nginx web server
#   - Stage 1: Build Astro application with Node.js
#   - Stage 2: Serve static files with Nginx 1.29 Alpine
#   - Optimized for production with gzip compression and caching

set -e

# Configuration variables
REGISTRY="ghcr.io"
REPO_OWNER="vxwork"
REPO_NAME="astro-docker"
IMAGE_NAME="${REGISTRY}/${REPO_OWNER}/${REPO_NAME}"
CONTAINER_NAME="astro-app"
COMPOSE_PROJECT_NAME="astro"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Get image tag
get_image_tag() {
    local sha_version="$1"
    
    if [ -z "$sha_version" ]; then
        # If no version is provided, try to get the latest main branch SHA
        log_info "No version specified, trying to get latest commit SHA from GitHub..."
        
        # Get latest commit SHA (8 characters) from GitHub API
        LATEST_SHA=$(curl -s "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/commits?sha=main&per_page=1" | grep -o '"sha": "[a-f0-9]*"' | head -1 | cut -d'"' -f4 | cut -c1-8)
        
        if [ -n "$LATEST_SHA" ]; then
            log_info "Found latest commit SHA: ${LATEST_SHA}"
            echo "$LATEST_SHA"
        else
            log_error "Failed to get latest commit SHA, please specify a version manually"
            exit 1
        fi
    elif [ "$sha_version" = "latest" ]; then
        log_info "Using latest tag"
        echo "latest"
    else
        # Validate SHA format (8 hexadecimal characters)
        if [[ ! "$sha_version" =~ ^[a-f0-9]{8}$ ]]; then
            log_error "Invalid SHA format: $sha_version (should be 8 hexadecimal characters)"
            exit 1
        fi
        log_info "Using specified version: $sha_version"
        echo "$sha_version"
    fi
}

# Pull image
pull_image() {
    local tag="$1"
    local full_image_name="${IMAGE_NAME}:${tag}"
    
    log_info "Pulling image: ${full_image_name}"
    
    # Pull image
    if ! docker pull "${full_image_name}"; then
        log_error "Failed to pull image: ${full_image_name}"
        exit 1
    fi
    
    log_info "Image pulled successfully: ${full_image_name}"
}

# Stop and clean up old containers
cleanup_old_containers() {
    log_info "Checking and cleaning up old containers..."
    
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_warn "Running container found, stopping..."
        docker compose -p "${COMPOSE_PROJECT_NAME}" down || docker-compose -p "${COMPOSE_PROJECT_NAME}" down
        log_info "Old container stopped"
    fi
}

# Start new container
start_container() {
    local tag="$1"
    
    log_info "Starting new container (image tag: ${tag})..."
    
    # Set environment variables
    export IMAGE_TAG="${tag}"
    export REGISTRY="${REGISTRY}"
    export REPO_OWNER="${REPO_OWNER}"
    export REPO_NAME="${REPO_NAME}"
    
    # Use docker compose to start
    if command -v docker &> /dev/null && docker compose version &> /dev/null; then
        log_info "Using docker compose to start..."
        docker compose -p "${COMPOSE_PROJECT_NAME}" up -d
    elif command -v docker-compose &> /dev/null; then
        log_info "Using docker-compose to start..."
        docker-compose -p "${COMPOSE_PROJECT_NAME}" up -d
    else
        log_error "docker compose or docker-compose command not found"
        exit 1
    fi
    
    # Wait for container to start
    sleep 5
    
    # Check container status
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log_info "✅ Container started successfully!"
        log_info "Container name: ${CONTAINER_NAME}"
        log_info "Image: ${IMAGE_NAME}:${tag}"
        log_info "Access URL: http://localhost:4321"
    else
        log_error "❌ Container failed to start, please check logs: docker logs ${CONTAINER_NAME}"
        exit 1
    fi
}

# Show help information
show_help() {
    cat << EOF
Astro Docker Deployment Script

Usage:
  $0 [VERSION]

Parameters:
  VERSION    Optional, image version tag
             - 8-character SHA (e.g.: abc12345)
             - latest (use latest tag)
             - Leave empty (automatically get latest main branch SHA)

Examples:
  $0                  # Automatically deploy latest version
  $0 abc12345        # Deploy specified SHA version
  $0 latest          # Deploy latest tag version

Environment variables:
  GHCR_USERNAME      GitHub Container Registry username
  GHCR_TOKEN         GitHub Container Registry access token

EOF
}

# Main function
main() {
    log_info "🚀 Starting Astro app deployment..."
    
    # Get image tag
    IMAGE_TAG=$(get_image_tag "$1")
    
    # Clean up old containers
    cleanup_old_containers
    
    # Pull image
    pull_image "${IMAGE_TAG}"
    
    # Start new container
    start_container "${IMAGE_TAG}"
    
    log_info "🎉 Deployment completed!"
}

# Execute main function
main "$@"
