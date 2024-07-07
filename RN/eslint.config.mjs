import { FlatCompat } from "@eslint/eslintrc";
import path from "path";
import { fileURLToPath } from "url";

import tsConfigs from "@typescript-eslint/eslint-plugin";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const compat = new FlatCompat({
  baseDirectory: __dirname,
  recommendedConfig: tsConfigs.configs.recommended,
});

const config = [
  ...compat.config({
    extends: [
      "eslint-config-airbnb/rules/react",
      "eslint-config-airbnb/rules/react-a11y",
      "eslint-config-airbnb-base/rules/best-practices",
      "eslint-config-airbnb-base/rules/errors",
      "eslint-config-airbnb-base/rules/node",
      "eslint-config-airbnb-base/rules/style",
      "eslint-config-airbnb-base/rules/variables",
      "eslint-config-airbnb-base/rules/es6",
      "eslint-config-airbnb-base/rules/strict",
    ],
    parserOptions: {
      ecmaVersion: 2018,
      sourceType: "module",
    },
  }),
  ...compat.config({
    extends: ["plugin:react/recommended"],
  }),
  ...compat.config({
    env: { node: true },
    parser: "@typescript-eslint/parser",
    extends: [
      "plugin:@typescript-eslint/eslint-recommended",
      "plugin:@typescript-eslint/recommended",
      "plugin:@typescript-eslint/recommended-type-checked",
    ],
    plugins: ["@typescript-eslint"],
    parserOptions: {
      project: "./tsconfig.json",
      ecmaVersion: 2018,
      ecmaFeatures: {
        jsx: true,
      },
      jsDocParsingMode: "type-info",
      sourceType: "module",
    },
  }),
  ...compat.config({
    extends: ["prettier"],
    plugins: ["prettier"],
    rules: {
      "prettier/prettier": [
        "error",
        {
          singleQuote: true,
          trailingComma: "all",
          arrowParens: "always",
          useTabs: false,
          tabWidth: 2,
        },
      ],
    },
  }),
  {
    ignores: [
      "/__tests__/*",
      "/coverage/*",
      "babel.config.js",
      "eslint.config.mjs",
      "metro.config.js",
    ],
  },
  {
    name: "Repo config",
    languageOptions: {
      globals: {
        __DEV__: false,
        GLOBAL: false,
      },
    },
    rules: {
      "react/react-in-jsx-scope": "off",
      "max-len": "off",
      "prefer-promise-reject-errors": "off",
      "react/no-did-update-set-state": "off",
      "global-require": "off",
      "no-use-before-define": "off",
      "@typescript-eslint/no-use-before-define": ["error"],
      "@typescript-eslint/no-var-requires": "off",
      "@typescript-eslint/unbound-method": "off",
      "@typescript-eslint/naming-convention": [
        "error",
        {
          selector: ["variable", "parameter"],
          format: ["camelCase"],
          leadingUnderscore: "allow",
        },
        {
          selector: ["function"],
          format: ["camelCase", "PascalCase"],
        },
        {
          selector: ["variable"],
          modifiers: ["const"],
          format: ["camelCase", "UPPER_CASE", "PascalCase"],
        },
        {
          selector: ["typeLike"],
          format: ["PascalCase"],
        },
        {
          selector: ["default"],
          modifiers: ["readonly"],
          format: ["UPPER_CASE"],
        },
      ],
      "react/jsx-filename-extension": [
        1,
        { extensions: [".js", ".jsx", ".tsx"] },
      ],
      "no-unused-vars": "off",
      "@typescript-eslint/no-unused-vars": [
        "error",
        {
          vars: "all",
          args: "after-used",
          ignoreRestSiblings: true,
        },
      ],
      "flowtype/space-after-type-colon": "off",
      "flowtype/no-types-missing-file-annotation": "off",
      "@typescript-eslint/explicit-function-return-type": "off",
      "@typescript-eslint/interface-name-prefix": "off",
      "@typescript-eslint/no-empty-function": "off",
      "@typescript-eslint/no-unsafe-call": "off",
      "@typescript-eslint/no-unsafe-assignment": "off",
      "@typescript-eslint/no-floating-promises": "off",
      "no-console": ["warn"],
      "no-underscore-dangle": ["warn", { allowAfterThis: true }],
      "no-plusplus": 0,
      "prefer-destructuring": [
        "error",
        {
          VariableDeclarator: {
            array: false,
            object: true,
          },
          AssignmentExpression: {
            array: false,
            object: true,
          },
        },
      ],
      "react/forbid-prop-types": 0,
      "react/sort-comp": [
        1,
        {
          order: [
            "type-annotations",
            "static-methods",
            "lifecycle",
            "everything-else",
            "render",
          ],
        },
      ],
      "react/sort-prop-types": [
        "error",
        {
          callbacksLast: true,
          requiredFirst: false,
        },
      ],
      "react/require-default-props": 0,
      "no-void": 0,
      "no-restricted-exports": 0,
      "react/function-component-definition": 0,
      // "import/prefer-default-export": "off",
      // "import/extensions": [
      //   "error",
      //   {
      //     "js": "never",
      //     "ts": "never",
      //     "tsx": "never"
      //   }
      // ],
      // "import/no-extraneous-dependencies": ["error", { "devDependencies": true }],
      // "import/order": [
      //   "error",
      //   {
      //     "groups": [["builtin", "external"], "internal", ["parent", "sibling", "index"]],
      //     "newlines-between": "always-and-inside-groups"
      //   }
      // ],
      // "react-hooks/rules-of-hooks": "error",
      // "react-hooks/exhaustive-deps": "warn",
    },
  },
];

export default config;
