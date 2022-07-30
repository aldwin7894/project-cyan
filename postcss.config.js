/* eslint-disable global-require */
const cssnano = require("cssnano")({
  preset: "default",
});

module.exports = {
  plugins: [
    require("postcss-import"),
    require("tailwindcss"),
    require("postcss-flexbugs-fixes"),
    require("postcss-preset-env")({
      autoprefixer: {
        flexbox: "no-2009",
      },
      stage: 3,
    }),
    require("autoprefixer"),

    // only needed if you want to purge
    ...(process.env.NODE_ENV === "production" ? [cssnano] : []),
  ],
};
