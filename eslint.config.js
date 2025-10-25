import { defineConfig, globalIgnores } from "eslint/config";
import { fixupConfigRules, fixupPluginRules } from "@eslint/compat";
import _import from "eslint-plugin-import";
import tailwindcss from "eslint-plugin-tailwindcss";
import prettier from "eslint-plugin-prettier";
import globals from "globals";
import path from "path";
import { fileURLToPath } from "url";
import js from "@eslint/js";
import { FlatCompat } from "@eslint/eslintrc";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const compat = new FlatCompat({
  baseDirectory: __dirname,
  recommendedConfig: js.configs.recommended,
  allConfig: js.configs.all,
});

export default defineConfig([
  globalIgnores(["**/package.json"]),
  {
    extends: fixupConfigRules(
      compat.extends(
        "eslint:recommended",
        "plugin:tailwindcss/recommended",
        "plugin:import/recommended",
        "plugin:prettier/recommended",
        "prettier/prettier",
      ),
    ),
    plugins: {
      import: fixupPluginRules(_import),
      tailwindcss: fixupPluginRules(tailwindcss),
      prettier: fixupPluginRules(prettier),
    },
    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.node,
      },
      ecmaVersion: "latest",
      sourceType: "module",
    },
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
      "no-unused-vars": [
        "error",
        {
          argsIgnorePattern: "^_",
        },
      ],
      "import/enforce-node-protocol-usage": "off",
    },
  },
]);
