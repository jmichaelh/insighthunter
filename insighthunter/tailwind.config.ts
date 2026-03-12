import type { Config } from 'tailwindcss';
import forms from '@tailwindcss/forms';
import typography from '@tailwindcss/typography';

export default {
  content: ['./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        sand: {
          50:  '#faf7f2',
          100: '#f4ede0',
          200: '#e8d9bf',
          300: '#d9c098',
          400: '#c8a472',
          500: '#bc8f56',
          600: '#a97a48',
          700: '#8b623b',
          800: '#714f35',
          900: '#5c422d',
        },
        taupe: {
          50:  '#f5f3f0',
          100: '#e8e4de',
          200: '#d3cabd',
          300: '#b8ac98',
          400: '#9e8e78',
          500: '#8b7b66',
          600: '#7a6b58',
          700: '#64574a',
          800: '#53483e',
          900: '#463d35',
        },
        navy: {
          50:  '#f0f4ff',
          100: '#e0e9ff',
          200: '#c0d2fe',
          300: '#93b0fd',
          400: '#6085fa',
          500: '#3d5ef6',
          600: '#2940eb',
          700: '#2131d8',
          800: '#222baf',
          900: '#1a1a2e',
          950: '#0d0d1a',
        },
        accent: '#22c55e',
        gold: '#f59e0b',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'Fira Code', 'monospace'],
      },
      backgroundImage: {
        'hero-gradient': 'linear-gradient(135deg, #0d0d1a 0%, #1a1a2e 50%, #0f2040 100%)',
        'card-gradient': 'linear-gradient(135deg, rgba(255,255,255,0.06) 0%, rgba(255,255,255,0.02) 100%)',
        'gold-gradient': 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)',
        'green-gradient': 'linear-gradient(135deg, #22c55e 0%, #16a34a 100%)',
      },
    },
  },
  plugins: [forms, typography],
} satisfies Config;
