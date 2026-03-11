import type { Config } from 'tailwindcss';
import forms from '@tailwindcss/forms';
import typography from '@tailwindcss/typography';

export default {
  content: ['./src/**/*.{html,js,svelte,ts}'],
  theme: {
    extend: {
      colors: {
        sand: {
          50: '#FDFAF5', 100: '#F5F0E8', 200: '#EDE8DE',
          300: '#D4C9B5', 400: '#B8A88A', 500: '#9B8A6E',
          600: '#7D6E56', 700: '#5E5240', 800: '#3F372A', 900: '#2C2416'
        },
        accent: { DEFAULT: '#D4A853', dark: '#B8893A', light: '#E8C37A' }
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        display: ['Playfair Display', 'serif']
      }
    }
  },
  plugins: [forms, typography]
} satisfies Config;
