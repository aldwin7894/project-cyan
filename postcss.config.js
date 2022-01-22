/* eslint-disable global-require */
const purgecss = require("@fullhuman/postcss-purgecss")({
  content: [
    "./app/**/*.html.erb",
    "./app/**/*.rb",
    "./app/**/*.js",
    "./app/**/*.js.erb",
  ],
  defaultExtractor: (content) => content.match(/[\w-/:]+(?<!:)/g) || [],
});

module.exports = {
  plugins: [
    require("postcss-import"),
    require("tailwindcss"),
    require("autoprefixer"),
    require("postcss-flexbugs-fixes"),
    require("postcss-preset-env")({
      autoprefixer: {
        flexbox: "no-2009",
      },
      stage: 3,
    }),

    // only needed if you want to purge
    ...(process.env.NODE_ENV === "production" ? [purgecss] : []),
  ],
};
