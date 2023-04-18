import { defineConfig, splitVendorChunkPlugin } from "vite";
import RubyPlugin from "vite-plugin-ruby";
import FullReload from "vite-plugin-full-reload";
import { brotliCompressSync } from "zlib";
import gzipPlugin from "rollup-plugin-gzip";

export default defineConfig({
  plugins: [
    RubyPlugin(),
    ...(process.env.NODE_ENV === "production"
      ? [FullReload(["config/routes.rb", "app/views/**/*"], { delay: 200 })]
      : []),
    gzipPlugin(),
    gzipPlugin({
      customCompression: content => brotliCompressSync(Buffer.from(content)),
      fileName: ".br",
    }),
    splitVendorChunkPlugin(),
  ],
  build: {
    emptyOutDir: true,
    assetsInlineLimit: 24000,
    cssCodeSplit: true,
    target: ["chrome87", "firefox78"],
    minify: "terser",
    sourcemap: false,
    rollupOptions: {
      output: {
        compact: true,
      },
    },
    terserOptions: {
      compress: {
        defaults: true,
        drop_console: true,
        ecma: 2021,
      },
      format: {
        comments: false,
      },
    },
  },
  server: {
    watch: {
      ignored: ["**/.trunk/**"],
    },
  },
});
