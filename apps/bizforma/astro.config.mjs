import { defineConfig } from 'astro/config';
import svelte from '@astrojs/svelte';
import tailwind from '@astrojs/tailwind';
import cloudflare from '@astrojs/cloudflare';

export default defineConfig({
  // Cloudflare Workers adapter — SSR + static assets
  output: 'static',
  adapter: cloudflare({
    mode: 'directory',
    functionPerRoute: false,
  }),

  integrations: [
    svelte(),
    tailwind({
      applyBaseStyles: false,
    }),
  ],

  vite: {
    resolve: {
      alias: {
        '@': '/src',
        '@components': '/src/components',
        '@stores': '/src/stores',
        '@lib': '/src/lib',
      },
    },
    // Proxy API to worker during local dev
    server: {
      proxy: {
        '/api': {
          target: 'http://localhost:8787',
          changeOrigin: true,
        },
      },
    },
  },
});
