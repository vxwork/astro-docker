# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Install git
RUN apk add --no-cache git

# Clone the Astro example project (basics template)
RUN git clone --depth 1 https://github.com/withastro/astro.git temp-astro && \
    cp -r temp-astro/examples/basics/. . && \
    rm -rf temp-astro

# Verify package.json exists
RUN ls -la && cat package.json

# Install dependencies
RUN npm install

# Build the cloned Astro example first
RUN npm run build

# Production stage
FROM node:20-alpine

WORKDIR /app

# Copy built application from builder stage
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./

# Install production dependencies
RUN npm install --omit=dev && npm cache clean --force

# Expose port
EXPOSE 4321

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:4321/ || exit 1

# Start the application
CMD ["npm", "run", "preview"]
