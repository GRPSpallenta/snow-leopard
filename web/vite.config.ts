import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

// Vite config
// - envDir '..' makes Vite read env from the repo root .env
//   Only variables prefixed with VITE_ are exposed to the client bundle.
// - dev server proxies /api to the Express API at :4000
export default defineConfig({
  plugins: [react()],
  envDir: path.resolve(__dirname, '..'),
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:4000',
        changeOrigin: true
      }
    }
  }
})
