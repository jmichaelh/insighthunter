import { defineConfig }  from 'astro/config';
import cloudflare        from '@astrojs/cloudflare';
import svelte            from '@astrojs/svelte';
import sitemap           from '@astrojs/sitemap';
import path              from 'path';

export default defineConfig({
  output:  'server',
  adapter: cloudflare({ mode: 'directory', platformProxy: { enabled: true } }),

  integrations: [svelte(), sitemap()],

  site: 'https://insighthunter.app',

  vite: {
    resolve: {
      alias: {
        '@': path.resolve('./src'),
      },
    },
    ssr: {
      // Use pre-built dist of the workspace package rather than bundling source
      external: ['@insighthunter/auth-middleware'],
    },
    css: {
      preprocessorOptions: {
        scss: {
          api: 'modern-compiler',
        },
      },
    },
  },
});
