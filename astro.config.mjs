import { defineConfig } from 'astro/config';
import node from '@astrojs/node';

export default defineConfig({
  output: 'server',                    // 全动态 SSR
  adapter: node({
    mode: 'standalone'
  }),
  server: {
    host: true,
    port: 4321
  }
});