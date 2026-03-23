# ClawTools

OpenClaw Installation, Configuration, and Management Suite

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Node.js Version](https://img.shields.io/badge/node-%3E%3D%2020.0.0-brightgreen)](package.json)

## Features

- **One-Click Installation** - Install OpenClaw with a single command
- **Multi-Version Support** - Choose from Stable, Beta, or Dev channels
- **Provider Management** - Configure API providers (OpenAI, Anthropic, MiniMax, Zhipu)
- **Diagnostics** - Run system checks and fix common issues
- **Backup & Restore** - Protect your OpenClaw configuration
- **Documentation Search** - Offline search through OpenClaw docs

## Supported Platforms

- Windows (PowerShell)
- Linux (Ubuntu, Debian, CentOS)
- macOS
- WSL (Windows Subsystem for Linux)
- Docker

## Quick Start

### Installation

```bash
# Linux/macOS/WSL
curl -fsSL https://raw.githubusercontent.com/norviglc-rgb/clawtools/main/scripts/install.sh | bash

# Windows (PowerShell)
iwr -useb https://raw.githubusercontent.com/norviglc-rgb/clawtools/main/scripts/install.ps1 | iex
```

### Usage

```bash
clawtools
```

## Requirements

- Node.js 20+ (will auto-install if missing)
- npm or pnpm

## Documentation

For full documentation, visit the [docs](./docs/) directory.

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Security

If you discover a security vulnerability, please see [SECURITY.md](SECURITY.md) for reporting guidelines.

## License

This project is licensed under the MIT License - see [LICENSE](LICENSE) for details.

## Related

- [OpenClaw](https://github.com/openclaw/openclaw) - The AI assistant this tool manages
