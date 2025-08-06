import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    host: true, // Listen on all interfaces for Fly.io
    port: 5173,
    allowedHosts: ['localhost', '127.0.0.1', '.fly.dev'], // Allow all Fly.io subdomains
  },
  build: {
    outDir: 'dist',
    sourcemap: false, // Disable source maps for production builds
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
          convex: ['convex'],
          pixi: ['pixi.js', '@pixi/react'],
        },
      },
    },
  },
  preview: {
    host: true,
    port: 5173,
  },
});
