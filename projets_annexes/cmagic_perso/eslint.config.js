import typescriptEslint from '@typescript-eslint/eslint-plugin';
import typescriptParser from '@typescript-eslint/parser';

export default [
    {
        ignores: ['dist/**', 'out/**', 'src/language/generated/**']
    },
    {
        files: ['src/**/*.ts'],
        languageOptions: {
            parser: typescriptParser,
            parserOptions: {
                ecmaVersion: 2022,
                sourceType: 'module'
            }
        },
        plugins: {
            '@typescript-eslint': typescriptEslint
        }
    }
];
