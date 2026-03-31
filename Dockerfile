# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Clone Astro framework repository
RUN apk add --no-cache git && \
    git clone --depth 1 https://github.com/withastro/astro.git astro-framework

# Install Astro framework dependencies
WORKDIR /app/astro-framework
RUN npm install

# Build Astro framework (optional, if needed for examples)
RUN npm run build || true

# Copy package files for our app
WORKDIR /app
COPY package*.json ./

# Install app dependencies
RUN npm install

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Production stage
FROM node:20-alpine

WORKDIR /app

# Copy built application from builder stage first
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/public ./public

# Copy package files for production (from builder stage where they were already copied)
COPY --from=builder /app/package*.json ./

# Install only production dependencies
RUN npm install --omit=dev && npm cache clean --force

# Expose port
EXPOSE 4321

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:4321/ || exit 1

# Start the application
CMD ["npm", "run", "preview"]
