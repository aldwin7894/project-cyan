module.exports = {
  env: {
    browser: true,
    es2021: true,
  },
  extends: [
    "airbnb-base",
  ],
  parserOptions: {
    ecmaVersion: "latest",
    sourceType: "module",
  },
  plugins: ["import"],
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
