import js from '@eslint/js'
import globals from 'globals'
import reactHooks from 'eslint-plugin-react-hooks'
import reactRefresh from 'eslint-plugin-react-refresh'
import tseslint from 'typescript-eslint'
import { defineConfig, globalIgnores } from 'eslint/config'

export default defineConfig([
  globalIgnores(['dist', 'src/**/*.spec.ts', 'src/**/*.spec.tsx']),
  {
    files: ['**/*.{ts,tsx}'],
    extends: [
      js.configs.recommended,
      tseslint.configs.recommended,
      reactHooks.configs.flat.recommended,
      reactRefresh.configs.vite,
    ],
    languageOptions: {
      ecmaVersion: 2020,
      globals: globals.browser,
    },
    rules: {
      '@typescript-eslint/no-unused-vars': [
        'error',
        {
          argsIgnorePattern: '^_',
          varsIgnorePattern: '^_',
          caughtErrorsIgnorePattern: '^_',
        },
      ],
    },
  },
  {
    files: [
      'src/components/admin/**/*.{ts,tsx}',
      'src/components/ui/**/*.{ts,tsx}',
      'src/components/rich-text-input/**/*.{ts,tsx}',
    ],
    rules: {
      'react-refresh/only-export-components': 'off',
    },
  },
  {
    files: [
      'src/components/admin/date-time-input.tsx',
      'src/components/rich-text-input/minimal-tiptap/components/measured-container.tsx',
      'src/components/rich-text-input/minimal-tiptap/extensions/image/components/image-view-block.tsx',
    ],
    rules: {
      'react-hooks/refs': 'off',
    },
  },
  {
    files: [
      'src/components/rich-text-input/minimal-tiptap/hooks/use-throttle.ts',
      'src/components/ui/sidebar.tsx',
    ],
    rules: {
      'react-hooks/purity': 'off',
    },
  },
  {
    files: ['src/components/admin/date-input.tsx'],
    rules: {
      'react-hooks/immutability': 'off',
    },
  },
  {
    files: ['**/*.d.ts'],
    rules: {
      '@typescript-eslint/no-explicit-any': 'off',
    },
  },
])
