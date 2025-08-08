import js from "@eslint/js";
import globals from "globals";
import { defineConfig } from "eslint/config";
import prettier from "eslint-plugin-prettier";
import eslintConfigPrettier from "eslint-config-prettier";

export default defineConfig([
  {
    files: ["**/*.{js,mjs,cjs}"],
    plugins: { js, prettier },
    extends: ["js/recommended", eslintConfigPrettier],
    languageOptions: { globals: globals.browser },
    rules: {
      "prettier/prettier": "warn",
      "no-unused-vars": ["off", { varsIgnorePattern: "^_", argsIgnorePattern: "^_" }],
    },
  },
]);
