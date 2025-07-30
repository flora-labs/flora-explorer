import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { resolve } from 'path'

export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': resolve(__dirname, './src'),
      '@intlify/shared': resolve(__dirname, 'node_modules/@intlify/core-base/node_modules/@intlify/shared/dist/shared.esm-bundler.js')
    }
  },
  server: {
    port: 5173,
    host: true
  },
  optimizeDeps: {
    include: ['@intlify/shared']
  }
})