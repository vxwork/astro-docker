import { defineConfig } from 'astro/config';

// https://docs.astro.build/en/reference/configuration-reference/
export default defineConfig({
  output: 'static',
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
