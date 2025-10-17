/**
 * @ignore
 */

const globals = require('globals');
const jsdoc = require('eslint-plugin-jsdoc');
const babelParser = require('@babel/eslint-parser');

module.exports = [
  {
    /* Ignores wants to be in its own block*/
    ignores: [
      '*.config.js',
      'coverage/',
      'docs/',
      'logs/',
      'node_modules/',
      'scripts/'
    ]
  },

  {
    languageOptions: {
      ecmaVersion: 6,
      parser: babelParser,
      parserOptions: {
        requireConfigFile: false,
        babelOptions: {
          babelrc: false,
          configFile: false
        }
      },
      globals: {
        ...globals.node,
        ...globals.jest,
        ...globals.jsdoc
      }
    },
    plugins: {
      jsdoc: jsdoc
    },

    rules: {
      'semi': 'off',
      'prefer-const': 'error',
      'no-unused-vars': 'off',
      'no-undef': 'error',
      //* ES6
      'arrow-spacing': 'error',
      'no-confusing-arrow': 'error',
      'no-duplicate-imports': 'error',
      'no-useless-catch': 'off',
      'no-var': 'error',
      'no-process-env': 'off',
      'no-process-exit': 'off',
      'object-shorthand': 'off',
      'prefer-const': 'error',
      'prefer-template': 'warn',
      'jsdoc/require-description': 'error',
      'jsdoc/check-values': 'error',
      'comma-dangle': [
        'error',
        {
          arrays: 'only-multiline',
          objects: 'only-multiline',
          imports: 'only-multiline',
          exports: 'only-multiline',
          functions: 'only-multiline'
        }
      ]
    }
  }
];
