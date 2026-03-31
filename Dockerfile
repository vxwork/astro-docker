# Build stage
FROM node:22-alpine AS builder

WORKDIR /app

# Install git
RUN apk add --no-cache git

# Clone the Astro example project (basics template)
RUN git clone --depth 1 https://github.com/withastro/astro.git temp-astro && \
    cp -r temp-astro/examples/basics/. . && \
    rm -rf temp-astro

# Copy Astro configuration file to override default settings
COPY astro.config.mjs ./astro.config.mjs

# Verify package.json exists
RUN ls -la && cat package.json

# Install dependencies
RUN npm install

# Build the cloned Astro example first
RUN npm run build

# Production stage
FROM node:22-alpine

WORKDIR /app

# Copy built application from builder stage
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./
COPY --from=builder /app/astro.config.mjs ./astro.config.mjs

# Install serve package globally for static file serving
RUN npm install -g serve && npm cache clean --force

# Expose port
EXPOSE 4321

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:4321/ || exit 1

# Start the application using serve to host static files
CMD ["serve", "dist", "-l", "4321", "--host", "0.0.0.0"]
