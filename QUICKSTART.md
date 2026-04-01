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

## 🚀 SSR Configuration (New)

This project now uses **SSR (Server-Side Rendering)** with Node.js adapter for dynamic page generation.

### Key Features:

- **SSR Mode**: All pages are rendered on-demand at request time
- **Standalone Node.js Server**: Uses `@astrojs/node` adapter in standalone mode
- **Multi-stage Docker Build**: Optimized image size (~150-300MB)
- **Dynamic Content Support**: Perfect for blogs, dashboards, and real-time content

### Architecture:

```
┌─────────────┐
│   Browser   │
└──────┬──────┘
       │ HTTP Request
       ▼
┌─────────────────────────┐
│  Node.js Container      │
│  (Port 4321)            │
│  ┌───────────────────┐  │
│  │ dist/server/      │  │
│  │ entry.mjs         │  │
│  │ (SSR Entry Point) │  │
│  └───────────────────┘  │
└─────────────────────────┘
```

### Configuration Files:

**astro.config.mjs:**
```javascript
export default defineConfig({
  output: 'server',           // Enable SSR
  adapter: node({
    mode: 'standalone'        // Standalone server mode
  }),
  server: {
    host: '0.0.0.0',          // Required for Docker
    port: 4321
  }
});
```

**Dockerfile:**
- Stage 1 (Builder): Clones Astro basics example, installs dependencies, builds SSR app
- Stage 2 (Runtime): Minimal Node.js runtime with only production files

### Local Development:

```bash
# Install Node adapter (if modifying the project)
npx astro add node --yes

# Run development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

### Docker Commands:

```bash
# Build Docker image
docker build -t astro-blog-ssr:latest .

# Run container
docker run -d \
  --name astro-blog \
  -p 8080:4321 \
  astro-blog-ssr:latest

# Or use docker-compose
docker compose up -d --build

# Access application
curl http://localhost:8080
```

### Hybrid Rendering (Optional):

For static pages, add to your page file:
```javascript
// src/pages/about.astro
export const prerender = true;  // This page will be pre-rendered as static HTML
```

### Environment Variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `NODE_ENV` | `production` | Node environment |
| `HOST` | `0.0.0.0` | Server binding address |
| `PORT` | `4321` | Server port |

### Troubleshooting SSR:

**Issue: Cannot access container from outside**
- Verify `HOST=0.0.0.0` in Dockerfile and docker-compose.yml
- Check `host: true` or `host: '0.0.0.0'` in astro.config.mjs
- Ensure port 4321 is exposed in Dockerfile and mapped in docker-compose.yml

**Issue: Build fails**
- Run `npm run build` locally first to verify it works
- Check that `dist/server/entry.mjs` exists after build

**Issue: Dynamic features not working**
- Confirm `output: 'server'` is set in astro.config.mjs
- Verify `@astrojs/node` is installed and configured

### Production Recommendations:

1. **Reverse Proxy**: Use Nginx/Traefik in front for HTTPS, caching, and load balancing
2. **Environment Variables**: Pass sensitive config via `.env` or docker-compose environment
3. **Volume Mounts**: Mount `/app/content` or similar for persistent blog content
4. **CI/CD**: Automate builds with GitHub Actions
5. **Monitoring**: Set up health checks and logging

---

## 📞 Getting Help

- Full documentation: [README.md](README.md)
- Astro Docs: https://docs.astro.build/
- Docker Docs: https://docs.docker.com/
- GitHub Actions Docs: https://docs.github.com/en/actions
- SSR Guide: https://docs.astro.build/en/guides/ssr/
