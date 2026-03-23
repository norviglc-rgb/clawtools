# ClawTools

OpenClaw 安装、配置与管理套件

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Node.js Version](https://img.shields.io/badge/node-%3E%3D%2020.0.0-brightgreen)](package.json)

## 功能特性

- **一键安装** - 一条命令安装 OpenClaw
- **多版本支持** - 可选择 Stable（稳定版）、Beta（测试版）或 Dev（开发版）通道
- **Provider 管理** - 配置 API 提供商（OpenAI、Anthropic、MiniMax、智谱）
- **系统诊断** - 运行系统检查并修复常见问题
- **备份与恢复** - 保护您的 OpenClaw 配置
- **文档搜索** - 离线搜索 OpenClaw 文档

## 支持的平台

- Windows (PowerShell)
- Linux (Ubuntu、Debian、CentOS)
- macOS
- WSL (Windows Subsystem for Linux)
- Docker

## 快速开始

### 安装

```bash
# Linux/macOS/WSL
curl -fsSL https://raw.githubusercontent.com/norviglc-rgb/clawtools/main/scripts/install.sh | bash

# Windows (PowerShell)
iwr -useb https://raw.githubusercontent.com/norviglc-rgb/clawtools/main/scripts/install.ps1 | iex
```

### 使用

```bash
clawtools
```

## 系统要求

- Node.js 20+（如未安装会自动安装）
- npm 或 pnpm

## 文档

更多文档请访问 [docs](./docs/) 目录。

## 参与贡献

欢迎贡献！请参阅 [CONTRIBUTING.md](CONTRIBUTING.md) 了解贡献指南。

## 安全

如果您发现安全漏洞，请参阅 [SECURITY.md](SECURITY.md) 了解报告指南。

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE)。

## 相关项目

- [OpenClaw](https://github.com/openclaw/openclaw) - 本工具管理的 AI 助手
