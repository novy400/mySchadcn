import path from "path"
import tailwindcss from "@tailwindcss/vite"
import react from "@vitejs/plugin-react"
import { defineConfig, loadEnv } from "vite"

const ibmIDevProxyTarget = loadEnv("development", process.cwd(), "").IBM_I_DEV_PROXY_TARGET

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), tailwindcss()],
  server: ibmIDevProxyTarget
    ? {
        proxy: {
          "^/web/services/SERVIWS3(?:/|\\?|$)": {
            target: ibmIDevProxyTarget,
            changeOrigin: true,
          },
        },
      }
    : undefined,
  build: {
    rolldownOptions: {
      output: {
        codeSplitting: {
          groups: [
            {
              name: "react-vendor",
              test: /node_modules[\\/](react|react-dom|react-router|react-redux|redux)[\\/]/,
              priority: 40,
            },
            {
              name: "admin-vendor",
              test: /node_modules[\\/](ra-core|@tanstack|react-hook-form)[\\/]/,
              priority: 30,
            },
            {
              name: "ui-vendor",
              test: /node_modules[\\/](@radix-ui|radix-ui|lucide-react|vaul|sonner|cmdk)[\\/]/,
              priority: 20,
            },
            {
              name: "vendor",
              test: /node_modules/,
              priority: 10,
            },
          ],
        },
      },
    },
  },
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
})
