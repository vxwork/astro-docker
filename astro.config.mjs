import { defineConfig } from 'astro/config';
import node from '@astrojs/node';

// https://docs.astro.build/en/reference/configuration-reference/
export default defineConfig({
  // Enable SSR mode for dynamic page generation
  output: 'server',
  
  // Configure Node.js adapter in standalone mode
  adapter: node({
    mode: 'standalone'
  }),
  
  // Server configuration for both dev and preview modes
  server: {
    host: '0.0.0.0',  // Listen on all network interfaces (required for Docker)
    port: 4321
  },
  
  prefetch: true,
  
  // Vite configuration for additional control
  vite: {
    server: {
      host: '0.0.0.0',
      port: 4321
    },
    preview: {
      host: '0.0.0.0',  // Explicitly configure preview server
      port: 4321
    }
  }
});
