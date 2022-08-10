import { defineConfig, splitVendorChunkPlugin } from "vite";
import RubyPlugin from "vite-plugin-ruby";
import FullReload from "vite-plugin-full-reload";
import { brotliCompressSync } from "zlib";
import gzipPlugin from "rollup-plugin-gzip";

export default defineConfig({
  plugins: [
    RubyPlugin(),
    FullReload(["config/routes.rb", "app/views/**/*"], { delay: 200 }),
    gzipPlugin(),
    gzipPlugin({
      customCompression: (content) => brotliCompressSync(Buffer.from(content)),
      fileName: ".br",
    }),
    splitVendorChunkPlugin(),
  ],
  build: {
    emptyOutDir: true,
    assetsInlineLimit: 24000,
    cssCodeSplit: true,
    target: "esnext",
    sourcemap: false,
  },
});
