/* eslint-disable global-require */
import importPlugin from "postcss-import";
import tailwindPlugin from "tailwindcss";
import flexBugsFixesPlugin from "postcss-flexbugs-fixes";
import presetEnvPlugin from "postcss-preset-env";
import autoprefixerPlugin from "autoprefixer";
import cssnanoPlugin from "cssnano";

export default {
  plugins: [
    importPlugin,
    tailwindPlugin,
    flexBugsFixesPlugin,
    presetEnvPlugin({
      autoprefixer: {
        flexbox: "no-2009",
      },
      stage: 3,
    }),
    autoprefixerPlugin,
    ...(process.env.NODE_ENV === "production"
      ? [
          cssnanoPlugin({
            preset: "advanced",
          }),
        ]
      : []),
  ],
};
