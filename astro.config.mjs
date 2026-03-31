import { defineConfig } from 'astro/config';

// https://docs.astro.build/en/reference/cli-reference/#astro-preview
export default defineConfig({
  output: 'static',
  server: {
    host: '0.0.0.0',  // Listen on all network interfaces
    port: 4321
  },
  prefetch: true,
  vite: {
    server: {
      host: '0.0.0.0'  // Also configure Vite dev server for consistency
    }
  }
});
