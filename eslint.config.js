import unicorn from "eslint-plugin-unicorn";
import globals from "globals";
import path from "node:path";
import { fileURLToPath } from "node:url";
import js from "@eslint/js";
import { FlatCompat } from "@eslint/eslintrc";
import jestPlugin from "eslint-plugin-jest";
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const compat = new FlatCompat({
    baseDirectory: __dirname,
    recommendedConfig: js.configs.recommended,
    allConfig: js.configs.all,
});

export default [
    {
        ignores: [
            "app//builds**",
            "**/node_modules/",
            "**/vendor/",
            "**/tmp/",
            "**.config.js",
            "public/**",
            "app//libs/**",
            "coverage/**",
            "**/gems/**",
            "**/haml_lint*/**",
            "**/openid_connect*/**",
            ".codeql/**",
            "**/iodine*/**",
            "log/**",
            "storage/**",
            "config/**",
            "**/generated/**",
            "scripts/**",
        ],
    },
    ...compat.extends("eslint:recommended", "plugin:unicorn/recommended"),
    {
        plugins: {
            unicorn,
        },
        languageOptions: {
            globals: {
                ...globals.browser,
            },

            ecmaVersion: "latest",
            sourceType: "module",
        },

        rules: {
            "unicorn/filename-case": "off",
            "unicorn/no-anonymous-default-export": "off",
            "unicorn/no-empty-file": "off",
            "unicorn/no-document-cookie": "off",
        },
    },
    // Updated Jest test configuration
    {
        files: ["test/javascript/**/*.js"],
        plugins: {
            jest: jestPlugin,
        },
        languageOptions: {
            globals: {
                ...globals.jest,
                ...globals.browser,
                ...globals.node,
            },
            parserOptions: {
                ecmaVersion: "latest",
                sourceType: "module",
            },
        },
        rules: {
            ...jestPlugin.configs.recommended.rules,
        },
    },
];
