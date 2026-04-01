# ===== Build Stage - Build Astro application with SSR =====
FROM node:22-alpine AS builder

WORKDIR /app

# Install git for cloning the Astro repository
RUN apk add --no-cache git

# Clone the Astro repository and extract the basics example
RUN git clone --depth 1 https://github.com/withastro/astro.git temp-astro && \
    cp -r temp-astro/examples/basics/. . && \
    rm -rf temp-astro

# Verify package.json exists and show project structure
RUN echo "=== Project Structure ===" && ls -la && echo "=== package.json ===" && cat package.json

# Install all dependencies (including @astrojs/node for SSR)
RUN npm install

# Install Node.js adapter for SSR support
RUN npx astro add node --yes

# Copy custom Astro configuration (if needed, otherwise use auto-generated one)
COPY astro.config.mjs ./astro.config.mjs

# Build the Astro application in SSR mode
RUN npm run build

# Verify build output
RUN echo "=== Build Output ===" && ls -la dist/ && ls -la dist/server/ 2>/dev/null || echo "Server directory check complete"

# ===== Production Runtime Stage =====
FROM node:22-alpine AS runtime

WORKDIR /app

# Copy only production-ready files from builder stage
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./package.json

# Set production environment variables
ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=4321

# Expose port 4321 for the standalone Node.js server
EXPOSE 4321

# Health check for the SSR application
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:4321/ || exit 1

# Start the standalone Node.js server (SSR entry point)
CMD ["node", "./dist/server/entry.mjs"]
