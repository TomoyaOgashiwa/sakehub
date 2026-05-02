/** @type {import("eslint").Linter.Config} */
module.exports = {
  extends: ['./base.js', 'next/core-web-vitals', 'next/typescript'],
  rules: {
    'react/no-unescaped-entities': 'off',
  },
};
