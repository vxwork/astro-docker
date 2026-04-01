# ===== Build Stage =====
FROM node:22-alpine AS builder

WORKDIR /app

# 安装 git（用于 clone 示例）
RUN apk add --no-cache git

# Clone Astro basics 示例
RUN git clone --depth 1 https://github.com/withastro/astro.git /tmp/astro && \
    cp -r /tmp/astro/examples/basics/. . && \
    rm -rf /tmp/astro

# 关键修复：先生成 package-lock.json，然后安装依赖
RUN npm install

# 安装 Node adapter（SSR 支持）并自动更新配置
RUN npx astro add node --yes

# 安装 MDX 支持（可选，但推荐用于博客 Markdown）
RUN npm install @astrojs/mdx

# 复制你的自定义配置（强烈建议）
COPY astro.config.mjs ./astro.config.mjs

# 构建项目（推荐使用 hybrid 模式，支持动态页面）
RUN npm run build

# ===== Runtime Stage =====
FROM node:22-alpine AS runtime

WORKDIR /app

COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./

# 创建用于动态添加博客的目录
RUN mkdir -p /app/content/blog /app/data

# 非 root 用户运行（安全最佳实践）
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