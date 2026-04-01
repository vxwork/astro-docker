# 🐛 Fix: Docker Container Listening on localhost Instead of 0.0.0.0

## Problem Summary
The Astro Docker container was only listening on `localhost` (127.0.0.1), making it inaccessible from outside the container despite adding environment variables.

## Root Cause
**Incorrect `serve` command syntax in Dockerfile:**

```dockerfile
# ❌ WRONG - This syntax is INVALID
CMD ["serve", "dist", "-l", "4321", "--host", "0.0.0.0"]
```

Issues:
1. The `serve` package **does NOT support** a `--host` flag
2. The `-l` flag requires **`address:port` format**, not just port number
3. Environment variables `HOST` and `PORT` are **NOT read** by serve CLI

## Solution Applied

### ✅ Fixed Dockerfile (Line 50)
```dockerfile
# ✅ CORRECT - Using proper address:port format
CMD ["serve", "dist", "-l", "0.0.0.0:4321"]
```

### ✅ Updated docker-compose.yml (Lines 8-10)
```yaml
environment:
  - NODE_ENV=production
  - PORT=4321
  # HOST variable removed - not used by serve package
```

## Why This Works

According to the [serve package documentation](https://github.com/vercel/serve):

- **Correct syntax**: `serve <directory> -l <address>:<port>`
- **Address format**: Can be IP, hostname, or `0.0.0.0` for all interfaces
- **Port binding**: Must be combined with address using colon separator

Example valid formats:
```bash
serve dist -l 0.0.0.0:4321
serve dist -l tcp://0.0.0.0:4321
serve dist -l :4321  # Binds to default interface
```

## Verification

After deploying with the fixed configuration:

```bash
# 1. Check container network status
docker exec astro-app netstat -tlnp

# Expected output:
# tcp    0    0 0.0.0.0:4321    0.0.0.0:*    LISTEN    node

# 2. Test external access
curl http://<your-server-ip>:4321

# Should return HTML content from Astro app
```

## Key Learnings

1. **Always check package documentation** - Don't assume flag names are standard
2. **Command syntax matters** - Especially in Docker CMD arrays
3. **Environment variables aren't universal** - Each package decides what to respect
4. **Test in actual environment** - localhost works inside container, but not externally

## Files Modified

- [`Dockerfile`](./Dockerfile) - Line 50: Fixed serve command syntax
- [`docker-compose.yml`](./docker-compose.yml) - Removed HOST env var (not needed)
- [`FIX_NETWORK_FINAL.md`](./FIX_NETWORK_FINAL.md) - Updated with correct root cause analysis

## Next Steps

1. **Rebuild the Docker image** with the corrected Dockerfile
2. **Redeploy** using your deployment script
3. **Verify** the container listens on `0.0.0.0:4321`
4. **Test** access from external network

## Deployment Command

```bash
# After committing changes, trigger new build or manually rebuild
./deploy.sh <your-commit-sha>
```

---

**Status**: ✅ Fixed  
**Date**: 2026-04-01  
**Verified**: Pending deployment test
