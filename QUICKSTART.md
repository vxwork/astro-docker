# Quick Start Guide

## 📋 Workflow

### 1. Initial Setup

```bash
# Copy environment variables template
cp .env.example .env

# Edit .env file with your GitHub information
# REPO_OWNER=your-github-username
# REPO_NAME=your-repo-name
```

### 2. Configure GitHub

In repository Settings → Secrets and variables → Actions, ensure:
- `GITHUB_TOKEN` (automatically provided, no manual configuration needed)

For manual GHCR login, add:
- `GHCR_USERNAME`: Your GitHub username
- `GHCR_TOKEN`: Personal Access Token (requires `write:packages` permission)

### 3. Push Code to Trigger Build

```bash
git add .
git commit -m "Initial commit"
git push origin main
```

GitHub Actions will automatically build and push the image to ghcr.io

### 4. Deploy Application

#### Linux/Mac:

```bash
# Auto-deploy latest version
./deploy.sh

# Deploy specific SHA version
./deploy.sh abc12345

# Use latest tag
./deploy.sh latest
```

#### Windows PowerShell:

```powershell
# Auto-deploy latest version
.\deploy.ps1

# Deploy specific SHA version
.\deploy.ps1 abc12345

# Use latest tag
.\deploy.ps1 latest
```

### 5. Verify Deployment

```bash
# Check running status
docker ps

# Access application
curl http://localhost:4321

# View logs
docker logs astro-app
```

---

## 🔧 Common Commands

### Docker Commands

```bash
# Check container status
docker ps

# Stop container
docker compose down

# Start container
docker compose up -d

# Restart container
docker compose restart

# View logs
docker logs -f astro-app

# Enter container
docker exec -it astro-app sh

# Remove containers and images
docker compose down -v
```

### GitHub Actions Commands

```bash
# Manually trigger workflow (requires GitHub CLI)
gh workflow run docker-build.yml

# List workflow runs
gh run list

# View logs for specific run
gh run view <run-id> --log
```

---

## 🏷️ Image Tags Reference

| Tag Type | Example | Description |
|----------|---------|-------------|
| SHA | `abc12345` | 8-character commit hash, recommended for production |
| Branch | `main` | Branch name, points to latest commit |
| Tag | `v1.0.0` | Git tag for versioned releases |
| Latest | `latest` | Latest build (not recommended for production) |

---

## 🚨 Troubleshooting

### Issue: Unable to Pull Image

**Solution:**
```bash
# Login to GHCR
docker login ghcr.io
# Enter GitHub username and Personal Access Token
```

### Issue: Port Already in Use

**Solution:**
Modify `docker-compose.yml`:
```yaml
ports:
  - "8080:4321"  # Change to different port
```

### Issue: Permission Denied

**Solution:**
```bash
# Linux/Mac: Add execute permission to script
chmod +x deploy.sh

# Windows: Run PowerShell as Administrator
```

### Issue: GitHub Actions Build Failed

**Checklist:**
1. Verify `GITHUB_TOKEN` has sufficient permissions
2. Check Dockerfile syntax
3. Review Actions logs for detailed errors

---

## 📊 Monitoring and Maintenance

### Health Checks

```bash
# Check container health status
docker inspect --format='{{.State.Health.Status}}' astro-app

# Test application response
curl -I http://localhost:4321
```

### Resource Usage

```bash
# Check container resource usage
docker stats astro-app
```

### Log Management

```bash
# Real-time logs
docker logs -f astro-app

# Last 100 lines
docker logs --tail 100 astro-app

# Logs since specific timestamp
docker logs --since 2024-01-01T00:00:00 astro-app
```

---

## 🔄 Update Strategy

### Rolling Update

```bash
# Deploy new version
./deploy.sh newsha123

# Verify new version SHA
docker inspect astro-app | grep Image
```

### Rollback

```bash
# Rollback to previous version
./deploy.sh oldsha456
```

---

## 💡 Best Practices

1. **Use fixed SHA in production**: Avoid using `latest` tag
2. **Clean up old images regularly**: Prevent excessive storage usage
3. **Monitor container health**: Set up alerting notifications
4. **Backup important data**: Regular backups if using persistent data
5. **Test before deployment**: Test in staging environment before production

---

## 📞 Getting Help

- Full documentation: [README.md](README.md)
- Astro Docs: https://docs.astro.build/
- Docker Docs: https://docs.docker.com/
- GitHub Actions Docs: https://docs.github.com/en/actions
