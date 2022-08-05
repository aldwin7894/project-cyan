/* eslint-disable global-require */
const cssnano = require("cssnano")({
  preset: "advanced",
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
    ...(process.env.NODE_ENV === "production" ? [cssnano] : []),
  ],
};
