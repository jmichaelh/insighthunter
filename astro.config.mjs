import { defineConfig } from 'astro/config';
// Root config is not used directly — each app has its own astro.config.mjs
// This file exists to satisfy tooling that scans the repo root.
export default defineConfig({
  root: 'apps/insighthunter-main',
});