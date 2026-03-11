import { defineConfig }  from 'astro/config';
import cloudflare        from '@astrojs/cloudflare';
import svelte            from '@astrojs/svelte';

export default defineConfig({
  output:  'server',
  adapter: cloudflare({ mode: 'directory', platformProxy: { enabled: true } }),
  integrations: [svelte()],
  site: 'https://insighthunter.app',
});
