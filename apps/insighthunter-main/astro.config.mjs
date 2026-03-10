import { defineConfig }  from 'astro/config';
import cloudflare        from '@astrojs/cloudflare';
import svelte            from '@astrojs/svelte';
import sitemap           from '@astrojs/sitemap';
import path              from 'path';

export default defineConfig({
  output:  'server',
  adapter: cloudflare({ mode: 'directory' }),

  integrations: [svelte(), sitemap()],

  site: 'https://insighthunter.app',

  vite: {
    resolve: {
      alias: {
        '@': path.resolve('./src'),
      },
    },
    ssr: {
      noExternal: ['@insighthunter/auth-middleware'],
    },
    optimizeDeps: {
      exclude: ['@insighthunter/auth-middleware'],
    },
  },
});
