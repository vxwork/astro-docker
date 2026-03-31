# DEPLOYMENT GUIDE

## Quick Fix for Network Binding Issue

### Problem
The Astro `preview` command doesn't support the `--host` flag. The container was only listening on `localhost`, making it inaccessible from outside the container.

### Solution
Created `astro.config.mjs` to configure the server to listen on all network interfaces (`0.0.0.0`).

## Deployment Steps

### 1. Build New Image with Configuration

```bash
# Build the image with the new astro.config.mjs
docker build -t ghcr.io/vxwork/astro-docker:207cd630 .
```

### 2. Push to Container Registry

```bash
# Push to GitHub Container Registry
docker push ghcr.io/vxwork/astro-docker:207cd630
```

### 3. Deploy Using Script

```bash
# Deploy the updated version
./deploy.sh 207cd630
```

### 4. Verify Deployment

```bash
# Check if container is running
docker ps

# Check what address the server is listening on
docker exec astro-app netstat -tlnp

# Test from external (replace with your server IP)
curl http://YOUR_SERVER_IP:4321
```

## Expected Result

The container should now listen on `0.0.0.0:4321` instead of `127.0.0.1:4321`, allowing external access.

## Technical Details

### Configuration File: `astro.config.mjs`

```javascript
import { defineConfig } from 'astro/config';

export default defineConfig({
  output: 'static',
  server: {
    host: '0.0.0.0',  // Listen on all network interfaces
    port: 4321
  },
  prefetch: true,
  vite: {
    server: {
      host: '0.0.0.0'  // Vite dev server configuration
    }
  }
});
```

### Why This Works

- **`astro dev`**: Supports `--host` CLI flag
- **`astro preview`**: Does NOT support `--host` flag (production preview mode)
- **Solution**: Use `astro.config.mjs` which works for both modes

### Dockerfile Changes

The Dockerfile now copies the custom `astro.config.mjs` after cloning the Astro basics example, overriding the default configuration.

## Troubleshooting

### Still showing localhost?

Check the container logs:
```bash
docker logs astro-app
```

Look for messages indicating the server is listening on `0.0.0.0`.

### Can't access from external network?

1. Check firewall rules:
   ```bash
   iptables -L -n | grep 4321
   ```

2. Verify security group settings (for cloud servers)

3. Test locally first:
   ```bash
   curl http://localhost:4321
   ```

## Next Steps

For future deployments, the configuration is now part of the Docker image. Simply rebuild and push whenever you update the application code.
