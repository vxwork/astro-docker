# Build stage - Build Astro application
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

# Production stage - Use Nginx to serve static files
FROM nginx:1.29.7-alpine

# Remove default nginx static content
RUN rm -rf /usr/share/nginx/html/*

# Copy built Astro application from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html
COPY --from=builder /app/public /usr/share/nginx/html/public

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 4321
EXPOSE 4321

# Health check using wget (available in Alpine)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:4321/ || exit 1

# Start Nginx in foreground mode (Docker best practice)
CMD ["nginx", "-g", "daemon off;"]
