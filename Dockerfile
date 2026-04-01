# ===== Build Stage =====
FROM node:22-alpine AS builder

WORKDIR /app

# 安装 git
RUN apk add --no-cache git

# Clone Astro basics 示例
RUN git clone --depth 1 https://github.com/withastro/astro.git /tmp/astro && \
    cp -r /tmp/astro/examples/basics/. . && \
    rm -rf /tmp/astro

# 安装依赖
RUN npm install

# 安装 Node adapter 和 SQLite ORM
RUN npx astro add node --yes
RUN npm install drizzle-orm better-sqlite3

# 复制自定义文件
COPY astro.config.mjs ./astro.config.mjs
COPY src/ ./src/

# 构建 Astro 项目（全 SSR）
RUN npm run build

# ===== Runtime Stage =====
FROM node:22-alpine AS runtime

WORKDIR /app

COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./

# 创建数据目录
RUN mkdir -p /app/data

# 非 root 用户运行（安全）
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