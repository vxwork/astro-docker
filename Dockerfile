# ===== Build Stage =====
FROM node:22-alpine AS builder

WORKDIR /app

# 安装 git
RUN apk add --no-cache git

# Clone Astro basics 示例并初始化项目
RUN git clone --depth 1 https://github.com/withastro/astro.git /tmp/astro && \
    cp -r /tmp/astro/examples/basics/. . && \
    rm -rf /tmp/astro

# 安装依赖
RUN npm ci

# 安装 Node adapter（SSR 支持）
RUN npx astro add node --yes

# 复制自定义配置（覆盖默认）
COPY astro.config.mjs ./astro.config.mjs

# 安装额外依赖（MDX + Content Collections 支持，可选但推荐）
RUN npm install @astrojs/mdx

# 构建（使用 hybrid 模式，更灵活）
RUN npm run build

# ===== Runtime Stage =====
FROM node:22-alpine AS runtime

WORKDIR /app

# 只复制必要文件
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./

# 创建动态内容目录（用于挂载）
RUN mkdir -p /app/content/blog /app/data

# 非 root 用户（安全）
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