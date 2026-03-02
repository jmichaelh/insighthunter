// apps/insighthunter-lite/astro.config.mjs
import { defineConfig } from 'astro/config';
import svelte from '@astrojs/svelte';
import cloudflare from '@astrojs/cloudflare';

export default defineConfig({
  output: 'server',
  adapter: cloudflare({
    platformProxy: { enabled: true }, // enables env bindings locally via wrangler
    imageService: 'cloudflare',
  }),
  integrations: [svelte()],
  vite: {
    // Ensure Svelte stores work correctly in SSR
    ssr: { noExternal: ['@insighthunter/types', '@insighthunter/utils'] },
  },
});
