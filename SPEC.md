# ClawTools 项目规格说明书

## 1. 项目概述

**项目名称**: ClawTools
**版本**: 0.1.0
**创建日期**: $(date +%Y-%m-%d)
**最后更新**: $(date +%Y-%m-%d)

## 2. 目标

为 [OpenClaw](https://github.com/openclaw/openclaw) 提供跨平台管理套件，实现：
- 一键安装
- 配置管理
- 诊断与排错
- 备份与恢复
- 文档搜索

## 3. 技术栈

- **运行时**: Node.js 20+
- **语言**: TypeScript
- **TUI框架**: Ink (React-based)
- **数据库**: SQLite (better-sqlite3)
- **搜索**: FlexSearch
- **构建**: tsc

## 4. 功能模块

### 4.1 安装模块 (installer)
- Node.js 环境检测
- OpenClaw 一键安装 (npm/script/docker)
- 版本选择 (stable/beta/dev)
- 卸载功能

### 4.2 检测模块 (detector)
- 平台检测
- Node.js 版本检测
- OpenClaw 安装状态检测
- 防火墙检测
- 公网IP检测
- 端口检测

### 4.3 配置模块 (configurator)
- Provider 预设配置
- API Key 加密存储
- 配置文件读写
- 默认配置模板

### 4.4 诊断模块 (doctor)
- 系统健康检查
- openclaw doctor 集成
- 问题报告生成

### 4.5 备份模块 (backup)
- 配置文件备份
- 可选 workspace/skills/plugins 备份
- 备份恢复
- 迁移导出

### 4.6 搜索模块 (search)
- OpenClaw 文档 clone
- FlexSearch 全文索引
- 离线搜索

### 4.7 数据库模块 (db)
- SQLite 存储
- Provider 配置持久化
- 备份历史记录

### 4.8 国际化 (i18n)
- 多语言框架
- 中文 (zh-CN) - 默认
- 英文 (en)

## 5. 支持平台

- Windows (PowerShell)
- Linux (Ubuntu, Debian, CentOS)
- macOS
- WSL
- Docker

## 6. 项目结构

```
clawtools/
├── cli/              # TUI 界面
│   ├── App.tsx       # 主应用
│   ├── index.tsx     # 入口
│   └── screens/      # 各功能界面
├── core/             # 核心业务逻辑
│   ├── detector.ts   # 环境检测
│   ├── installer.ts  # 安装管理
│   ├── configurator.ts # 配置管理
│   ├── doctor.ts     # 诊断
│   ├── backup.ts     # 备份
│   └── search.ts     # 搜索
├── config/           # 配置预设
├── db/               # 数据库层
├── i18n/             # 国际化
├── scripts/          # 安装脚本
│   ├── init.sh      # 初始化脚本
│   ├── install.sh    # Linux/macOS 安装
│   └── install.ps1   # Windows 安装
├── bin/              # 编译输出
├── TESTS/            # 测试
└── CHECKPOINTS/      # 检查点快照
```

## 7. 质量标准

- 测试覆盖率 ≥ 80%
- 所有公共 API 有 TypeScript 类型定义
- 遵循 ESLint 规则
- 每次 commit 必须通过 typecheck

## 8. 发布要求

- [ ] 所有 P0 功能实现并测试通过
- [ ] 文档完整
- [ ] 在 Windows/Linux/macOS 上测试通过
