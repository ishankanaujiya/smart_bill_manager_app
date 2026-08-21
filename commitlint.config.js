module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      [
        'feat',     // A new feature
        'fix',      // A bug fix
        'docs',     // Documentation changes
        'style',    // Code style changes (formatting, semicolons, etc.)
        'refactor', // Code refactoring (no feature or bug fix)
        'perf',     // Performance improvements
        'test',     // Adding or updating tests
        'build',    // Build system or external dependency changes
        'ci',       // CI/CD configuration changes
        'chore',    // Maintenance tasks
        'revert',   // Reverting a previous commit
      ],
    ],
    'subject-case': [2, 'never', ['upper-case']],
    'subject-max-length': [2, 'always', 72],
    'body-max-line-length': [2, 'always', 100],
  },
};
