import promise from "eslint-plugin-promise";
import path from "node:path";
import { fileURLToPath } from "node:url";
import js from "@eslint/js";
import { FlatCompat } from "@eslint/eslintrc";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const compat = new FlatCompat({
    baseDirectory: __dirname,
    recommendedConfig: js.configs.recommended,
    allConfig: js.configs.all
});

export default [...compat.extends("eslint:recommended"), {
    plugins: {
        promise,
    },

    languageOptions: {
        ecmaVersion: 2017,
        sourceType: "script",
    },

    rules: {
        "no-console": "off",
        "no-regex-spaces": "off",
        "no-debugger": "off",
        "no-unused-vars": "off",
        "no-mixed-spaces-and-tabs": "off",
        "no-undef": "off",
        "no-template-curly-in-string": 1,
        "consistent-return": 1,
        "array-callback-return": 1,
        eqeqeq: 2,
        "no-alert": 2,
        "no-caller": 2,
        "no-eq-null": 2,
        "no-eval": 2,
        "no-extend-native": 1,
        "no-extra-bind": 1,
        "no-extra-label": 1,
        "no-floating-decimal": 2,
        "no-implicit-coercion": 1,
        "no-loop-func": 1,
        "no-new-func": 2,
        "no-new-wrappers": 1,
        "no-throw-literal": 2,
        "prefer-promise-reject-errors": 2,
        "for-direction": 2,
        "getter-return": 2,
        "no-await-in-loop": 2,
        "no-compare-neg-zero": 2,
        "no-catch-shadow": 1,
        "no-shadow-restricted-names": 2,
        "callback-return": 2,
        "handle-callback-err": 2,
        "no-path-concat": 1,
        "prefer-arrow-callback": 1,
        "promise/always-return": 2,
        "promise/catch-or-return": 2,
        "promise/no-nesting": 1,
    },
}];