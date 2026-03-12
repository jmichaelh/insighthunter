// vite.config.ts
import { defineConfig } from 'vite'

export default defineConfig({
  root: '.', // must point to the dir containing index.html
  build: {
    outDir: 'dist',
  },
})
