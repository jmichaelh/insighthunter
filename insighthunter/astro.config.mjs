import { defineConfig } from 'astro/config';
import cloudflare from '@astrojs/cloudflare';
import svelte from '@astrojs/svelte';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://insighthunter.com',
  output: 'server',
  adapter: cloudflare({
    platformProxy: { enabled: true },
    imageService: 'passthrough',
    routes: {
      extend: {
        exclude: [{ pattern: '/cdn-cgi/*' }],
      },
    },
  }),
  integrations: [svelte(), sitemap()],
  vite: {
    css: {
      preprocessorOptions: {
        scss: {
          additionalData: `@use "/src/styles/theme" as *;`,
        },
      },
    },
    resolve: {
      alias: {
        '~': '/src',
      },
    },
  },
});
