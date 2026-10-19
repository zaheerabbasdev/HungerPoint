import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import { defineConfig, loadEnv } from 'vite'

// https://vite.dev/config/
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  return {
    plugins: [react(), tailwindcss()],
    // Where the site is served from: '/' for its own (sub)domain, or e.g.
    // '/hungerpoint/' when uploaded into a subfolder. Set VITE_BASE in .env.production.
    base: env.VITE_BASE || '/',
  }
})
