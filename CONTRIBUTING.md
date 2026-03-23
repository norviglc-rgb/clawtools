# Contributing to ClawTools

Thank you for your interest in contributing to ClawTools!

## Code of Conduct

This project adheres to a code of conduct that all contributors are expected to follow. Please be respectful and constructive in all interactions.

## How Can I Contribute?

### Reporting Bugs

Before creating a bug report:
- Check the [issue tracker](https://github.com/norviglc-rgb/clawtools/issues) to avoid duplicates
- Verify the bug exists in the latest version
- Collect information about your environment (OS, Node.js version, etc.)

When filing a bug report, include:
- A clear, descriptive title
- Steps to reproduce the issue
- Expected vs actual behavior
- Relevant logs or error messages
- Your environment details

### Suggesting Features

Feature suggestions are welcome! Please:
- Search existing issues before creating a new one
- Provide a clear use case and expected behavior
- Explain why this feature would benefit users

### Pull Requests

1. **Fork the Repository**
   ```bash
   git clone https://github.com/norviglc-rgb/clawtools.git
   cd clawtools
   ```

2. **Create a Feature Branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

3. **Set Up Development Environment**
   ```bash
   npm install
   npm run build
   ```

4. **Make Your Changes**
   - Follow existing code style
   - Write clear, descriptive commit messages
   - Add tests if applicable
   - Update documentation as needed

5. **Test Your Changes**
   ```bash
   npm run typecheck
   npm start
   ```

6. **Commit and Push**
   ```bash
   git add .
   git commit -m "Add: descriptive commit message"
   git push origin feature/your-feature-name
   ```

7. **Open a Pull Request**
   - Fill out the PR template
   - Link related issues
   - Wait for review

## Development Setup

### Prerequisites

- Node.js 20+
- npm or pnpm

### Project Structure

```
clawtools/
├── cli/           # TUI interface
│   └── screens/   # UI screens
├── core/          # Business logic
├── config/        # Configuration presets
├── db/            # Database layer
├── i18n/          # Internationalization
└── scripts/       # Installation scripts
```

### Coding Standards

- Use TypeScript for all new code
- Follow existing code formatting
- Write self-documenting code with clear variable/function names
- Add JSDoc comments for public APIs
- Keep functions small and focused

### Testing

Run the test suite:
```bash
npm run test
```

### Commit Message Format

```
type(scope): description

Types:
- Add: New feature
- Fix: Bug fix
- Update: Update existing feature
- Refactor: Code refactoring
- Docs: Documentation changes
- Style: Formatting, no code change
- Test: Adding tests
- Chore: Maintenance tasks
```

Examples:
```
Add(config): Add MiniMax provider support
Fix(installer): Handle missing Node.js gracefully
Docs(readme): Update installation instructions
```

## Branching Strategy

- `main` - Stable release branch
- `develop` - Development branch (if needed)
- `feature/*` - New feature branches
- `fix/*` - Bug fix branches

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

## Questions?

Feel free to:
- Open an issue for questions
- Check existing discussions
- Contact the maintainer

Thank you for contributing to ClawTools!
