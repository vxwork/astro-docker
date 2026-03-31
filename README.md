# Astro Docker Deployment Solution

A comprehensive Docker-based build and deployment solution for Astro applications, featuring:

- ✅ Automated Docker image builds with 8-character SHA tags
- ✅ Push to GitHub Container Registry (ghcr.io)
- ✅ GitHub Actions CI/CD workflows
- ✅ One-click deployment scripts (`deploy.sh`)
- ✅ Docker Compose orchestration

## 📦 Project Structure

```
.
├── Dockerfile                          # Multi-stage Docker build
├── docker-compose.yml                  # Docker Compose configuration
├── deploy.sh                           # Deployment script (Linux/Mac)
├── deploy.ps1                          # Deployment script (Windows)
├── .dockerignore                       # Docker build context optimization
├── .env.example                        # Environment variables template
├── .gitignore                          # Git ignore rules
└── .github/
    └── workflows/
        └── docker-build.yml           # GitHub Actions workflow
```

## 🚀 Quick Start

### 1. Prerequisites

Ensure you have the following installed and configured:

- [Astro](https://astro.build/) project
- Docker and Docker Compose
- GitHub account

### 2. Configure GitHub Secrets

GitHub Actions will automatically use `GITHUB_TOKEN` in your repository—no additional configuration required.

For manual GHCR login, create a Personal Access Token:

1. Go to GitHub Settings > Developer settings > Personal access tokens
2. Generate a new token with `write:packages` permission
3. Add to repository Settings > Secrets and variables > Actions:
   - `GHCR_USERNAME`: Your GitHub username
   - `GHCR_TOKEN`: Generated token

### 3. Custom Configuration

#### Copy `.env.example` to `.env`

```bash
cp .env.example .env
```

Edit `.env` file with your GitHub username and repository information.

#### Adjust Dockerfile (Optional)

If your Astro project has specific requirements, modify [`Dockerfile`](Dockerfile):

- Change Node.js version (currently using node:20-alpine)
- Add additional build steps
- Modify port number (default 4321)

### 4. Automated Build and Push

When pushing to main/master branch, GitHub Actions will automatically:

1. Build Docker image
2. Generate tag with 8-character commit SHA
3. Push to ghcr.io

Example: `ghcr.io/username/repo:abc12345`

## 🛠️ Usage

### Method 1: Using Deployment Script (Recommended)

```bash
# Auto-detect and deploy latest version
./deploy.sh

# Deploy specific SHA version (8 characters)
./deploy.sh abc12345

# Use latest tag
./deploy.sh latest
```

The deployment script will:
1. Automatically pull image from ghcr.io
2. Stop old containers
3. Start new container using Docker Compose

### Method 2: Manual Docker Compose

```bash
# Set environment variables
export IMAGE_TAG=abc12345
export REPO_OWNER=your-username
export REPO_NAME=your-repo

# Pull image
docker pull ghcr.io/${REPO_OWNER}/${REPO_NAME}:${IMAGE_TAG}

# Start container
docker compose up -d
```

### Method 3: Direct Docker

```bash
docker run -d \
  --name astro-app \
  -p 4321:4321 \
  --restart unless-stopped \
  ghcr.io/your-username/your-repo:abc12345
```

## 📝 Configuration

### Docker Compose Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `REGISTRY` | Image registry URL | `ghcr.io` |
| `REPO_OWNER` | GitHub username or organization | From git remote |
| `REPO_NAME` | Repository name | From git remote |
| `IMAGE_TAG` | Image tag (SHA or latest) | `latest` |

### Port Mapping

By default, Astro application runs on port **4321**.

To modify, edit [`docker-compose.yml`](docker-compose.yml):

```yaml
ports:
  - "8080:4321"  # Map external port 8080 to internal port 4321
```

## 🔍 Verify Deployment

```bash
# Check container status
docker ps

# View logs
docker logs astro-app

# Enter container
docker exec -it astro-app sh

# Health check
curl http://localhost:4321
```

## 🔄 Update Strategy

### Automatic Update (Recommended)

Use deployment script to auto-fetch latest version:

```bash
./deploy.sh
```

### Manual Update

```bash
# Stop old container
docker compose down

# Pull new image
docker pull ghcr.io/your-username/your-repo:newsha

# Start container
docker compose up -d
```

### Rollback to Previous Version

```bash
# Redeploy with previous SHA
./deploy.sh oldsha123
```

## 🐛 Troubleshooting

### Unable to Pull Image

Ensure you're logged into GHCR:

```bash
docker login ghcr.io
# Enter GitHub username and Personal Access Token
```

### Container Failed to Start

Check logs:

```bash
docker logs astro-app
```

### Port Conflict

Modify port mapping in [`docker-compose.yml`](docker-compose.yml):

```yaml
ports:
  - "NEW_PORT:4321"
```

## 📊 GitHub Actions Workflow

Workflow file: [`.github/workflows/docker-build.yml`](.github/workflows/docker-build.yml)

Triggers:
- Push to main/master branch
- Tag creation
- Pull Request

Build outputs:
- Multi-platform images (amd64, arm64)
- 8-character SHA tags
- Latest commit tag
- Semver tags (if triggered by tag)

## 🔐 Security Recommendations

1. **Never commit sensitive information**: Ensure `.env` is in `.gitignore`
2. **Use Secrets**: Manage credentials via GitHub Actions Secrets
3. **Limit package visibility**: Control Container packages visibility in repository settings
4. **Rotate tokens regularly**: Periodically update Personal Access Tokens

## 📚 Related Resources

- [Astro Documentation](https://docs.astro.build/)
- [Docker Documentation](https://docs.docker.com/)
- [GitHub Container Registry](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## 🤝 Contributing

Issues and Pull Requests are welcome!

## 📄 License

MIT License
