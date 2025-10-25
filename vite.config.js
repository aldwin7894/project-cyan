import { defineConfig } from "vite";
import RubyPlugin from "vite-plugin-ruby";
import FullReload from "vite-plugin-full-reload";
import { brotliCompressSync } from "zlib";
import gzipPlugin from "rollup-plugin-gzip";
import { visualizer } from "rollup-plugin-visualizer";

export default defineConfig({
  plugins: [
    RubyPlugin(),
    ...(process.env.NODE_ENV === "production"
      ? []
      : [
          FullReload(["config/routes.rb", "app/views/**/*"], { delay: 200 }),
          visualizer({
            brotliSize: true,
            gzipSize: true,
            template: "treemap",
          }),
        ]),
    gzipPlugin(),
    gzipPlugin({
      customCompression: content => brotliCompressSync(Buffer.from(content)),
      fileName: ".br",
    }),
  ],
  build: {
    emptyOutDir: true,
    assetsInlineLimit: 24000,
    cssCodeSplit: true,
    minify: "terser",
    sourcemap: false,
    rollupOptions: {
      output: {
        compact: true,
        generatedCode: "es2015",
      },
    },
    terserOptions: {
      compress: {
        defaults: true,
        drop_console: true,
        ecma: 2021,
        unsafe: true,
      },
      format: {
        comments: false,
      },
    },
  },
  server: {
    watch: {
      ignored: ["**/tmp/**", "**/log/**"],
    },
  },
});
