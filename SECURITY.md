# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 0.1.x   | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability within ClawTools, please follow these steps:

### For Security Researchers / Users

1. **Do NOT** create a public GitHub issue for security vulnerabilities
2. Send a detailed report to the maintainer via:
   - GitHub Security Advisories (preferred)
   - Or contact directly through GitHub profile

3. Include the following information in your report:
   - Type of vulnerability
   - Full paths of source file(s) related to the vulnerability
   - Location of the affected source code
   - Step-by-step instructions to reproduce the issue
   - Proof-of-concept or exploit code (if possible)
   - Impact assessment of the vulnerability

### What to Expect

- Acknowledgment of your report within 48 hours
- Regular updates on the progress
- Credit for the discovery (unless you prefer to remain anonymous)

### Scope

This security policy covers:
- ClawTools core functionality
- Installation scripts
- API key handling and storage
- Configuration management

### Out of Scope

- Social engineering attacks
- Physical security attacks
- Attacks against systems not running ClawTools
- Vulnerabilities in third-party dependencies (please report to upstream projects)

## Security Best Practices

When using ClawTools:

1. **API Keys**: Store API keys securely. ClawTools encrypts keys in local storage, but always use environment variables for production environments.

2. **Permissions**: Grant minimum necessary permissions to the user running ClawTools.

3. **Updates**: Keep ClawTools updated to receive security patches.

4. **Backups**: Regularly backup your OpenClaw configuration before making changes.

## Security Updates

Security updates will be released as patch versions (e.g., 0.1.1) and announced through:
- GitHub Releases
- Project README updates

Thank you for helping keep ClawTools and its users safe!
