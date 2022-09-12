module.exports = {
  env: {
    browser: true,
    es2021: true,
  },
  extends: [
    "airbnb-base",
    "plugin:tailwindcss/recommended",
  ],
  parserOptions: {
    ecmaVersion: "latest",
    sourceType: "module",
  },
  plugins: [
    "import",
    "html-erb",
    "tailwindcss",
  ],
  settings: {
    "import/resolver": {
      alias: {
        map: [
          ["~", "./app/frontend"],
        ],
      },
    },
  },
  rules: {
    quotes: [
      "error",
      "double",
      {
        avoidEscape: true,
        allowTemplateLiterals: true,
      },
    ],
    "no-underscore-dangle": "off",
    "no-param-reassign": "off",
  },
};
