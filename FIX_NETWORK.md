# Final Fix for Network Binding Issue

## Root Cause

The Astro `preview` command supports the `--host` flag according to official documentation, but the configuration must be properly set in `astro.config.mjs`.

## Solution Applied

### 1. Created `astro.config.mjs` with comprehensive server configuration

```javascript
import { defineConfig } from 'astro/config';

export default defineConfig({
  output: 'static',
  server: {
    host: '0.0.0.0',  // Listen on all network interfaces
    port: 4321
  },
  vite: {
    server: {
      host: '0.0.0.0',
      port: 4321
    },
    preview: {
      host: '0.0.0.0',  // Explicitly configure preview server
      port: 4321
    }
  }
});
```

### 2. Updated Dockerfile

- Copies `astro.config.mjs` after cloning the Astro basics example
- Overrides default configuration to enable external access

## Deployment Steps

### Option 1: Wait for GitHub Actions (Recommended)

1. **Push changes to GitHub**:
   ```bash
   git add .
   git commit -m "fix: add astro.config.mjs for proper network binding"
   git push origin main
   ```

2. **Wait for automatic build** (5-10 minutes):
   - GitHub Actions will automatically build a new image
   - Check status at: https://github.com/YOUR_USERNAME/astro-docker/actions

3. **Deploy the new version**:
   ```bash
   # Get the latest SHA from GitHub
   ./deploy.sh
   ```

### Option 2: Manual Build and Push (Immediate)

If you need the fix immediately:

1. **Build locally**:
   ```bash
   docker build -t ghcr.io/vxwork/astro-docker:manual-fix .
   ```

2. **Push to registry**:
   ```bash
   docker push ghcr.io/vxwork/astro-docker:manual-fix
   ```

3. **Deploy**:
   ```bash
   ./deploy.sh manual-fix
   ```

## Verification

After deployment, verify the fix:

```bash
# Check what address the container is listening on
docker exec astro-app netstat -tlnp

# Expected output should show: 0.0.0.0:4321
# NOT: 127.0.0.1:4321

# Test from external network
curl http://YOUR_SERVER_IP:4321
```

## Why Previous Images Didn't Work

Images built before adding `astro.config.mjs` don't include the configuration file, so they continue to listen only on localhost.

**Key Point**: The image tag `02065445` was built from code that didn't have the `astro.config.mjs` file yet.

## Technical Details

### How Astro Preview Server Works

- **Development mode** (`astro dev`): Reads `server.host` from config
- **Preview mode** (`astro preview`): Reads both `server.host` and `vite.preview.host`
- **Production**: Uses adapter-specific configuration

### Configuration Priority

1. CLI flags (e.g., `--host 0.0.0.0`) - Highest priority
2. `astro.config.mjs` settings
3. Environment variables
4. Default values

## Troubleshooting

### Still showing localhost?

1. **Check if astro.config.mjs exists in the image**:
   ```bash
   docker run --rm ghcr.io/vxwork/astro-docker:TAG ls -la /app/astro.config.mjs
   ```

2. **View container logs**:
   ```bash
   docker logs astro-app
   ```
   Look for messages about server configuration.

3. **Force rebuild**:
   ```bash
   # Stop old container
   docker compose down
   
   # Remove cached image
   docker rmi ghcr.io/vxwork/astro-docker:02065445
   
   # Deploy again
   ./deploy.sh <new-sha>
   ```

### Need help?

- Check GitHub Actions logs: https://github.com/YOUR_USERNAME/astro-docker/actions
- Review Astro docs: https://docs.astro.build/en/reference/configuration-reference/
