# ===== Build Stage =====
FROM node:22-alpine AS builder

WORKDIR /app

RUN apk add --no-cache git

# Clone basics 示例
RUN git clone --depth 1 https://github.com/withastro/astro.git /tmp/astro && \
    cp -r /tmp/astro/examples/basics/. . && \
    rm -rf /tmp/astro

RUN npm install

# 安装 Node adapter 和 MDX
RUN npx astro add node --yes
RUN npm install @astrojs/mdx

# 复制修改后的配置（必须放在 npm install 之后）
COPY astro.config.mjs ./astro.config.mjs

# 构建
RUN npm run build

# ===== Runtime Stage =====
FROM node:22-alpine AS runtime

WORKDIR /app

COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./

RUN mkdir -p /app/content/blog /app/data

RUN addgroup -g 1001 -S nodejs && \
    adduser -S astro -u 1001 -G nodejs && \
    chown -R astro:nodejs /app

USER astro

ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=4321

EXPOSE 4321

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://127.0.0.1:4321/ || exit 1

CMD ["node", "./dist/server/entry.mjs"]