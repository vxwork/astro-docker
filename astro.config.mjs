// astro.config.mjs
import { defineConfig } from 'astro/config';
import node from '@astrojs/node';
import mdx from '@astrojs/mdx';   // 如果你安装了 @astrojs/mdx

export default defineConfig({
  // output: 'hybrid'   ← 删除这一行！现在默认就是以前的 hybrid 行为
  output: 'static',     // 推荐明确写上（虽然默认就是 static）

  adapter: node({
    mode: 'standalone'
  }),

  integrations: [mdx()],

  server: {
    host: true,
    port: 4321
  }
});