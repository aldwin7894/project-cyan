module.exports = {
  root: true,
  env: {
    browser: true,
    es2021: true,
  },
  extends: ["airbnb-base", "plugin:tailwindcss/recommended", "prettier"],
  parserOptions: {
    ecmaVersion: "latest",
    sourceType: "module",
  },
  plugins: ["import", "html-erb", "tailwindcss", "prettier"],
  settings: {
    "import/resolver": {
      alias: {
        map: [["~", "./app/frontend"]],
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
    "comma-dangle": ["error", "only-multiline"],
    "no-undef": "warn",
    "prettier/prettier": "error",
    "import/no-extraneous-dependencies": "off",
  },
};
