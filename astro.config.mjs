import { defineConfig } from 'astro/config';
import node from '@astrojs/node';
import mdx from '@astrojs/mdx';

export default defineConfig({
  output: 'hybrid',           // 推荐！大部分静态，部分动态
  adapter: node({
    mode: 'standalone'
  }),
  integrations: [mdx()],
  server: {
    host: true,
    port: 4321
  }
});