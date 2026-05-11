import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// Use relative asset paths so the app works on GitHub Pages
// without hardcoding the repository name.
export default defineConfig({
  base: './',
  plugins: [vue()],
})
