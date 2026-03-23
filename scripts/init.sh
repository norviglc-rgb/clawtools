#!/bin/bash
# =============================================================================
# ClawTools Initialization Script
# Created by: Initializer Agent (based on Anthropic Harness Framework)
# Purpose: Establish development environment foundation for long-running agents
# =============================================================================

set -e

# Configuration
PROJECT_NAME="clawtools"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GIT_REPO="https://github.com/norviglc-rgb/clawtools.git"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# Helper Functions
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 is not installed"
        return 1
    fi
    return 0
}

# =============================================================================
# Main Initialization Steps
# =============================================================================

main() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║         ClawTools Initialization (AgentFlow v1.0)         ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""

    # Step 1: Check prerequisites
    log_info "Step 1/8: Checking prerequisites..."
    check_prerequisites

    # Step 2: Create directory structure
    log_info "Step 2/8: Creating directory structure..."
    create_directory_structure

    # Step 3: Initialize or update git repository
    log_info "Step 3/8: Initializing Git repository..."
    init_git

    # Step 4: Create SPEC.md if not exists
    log_info "Step 4/8: Creating project specification..."
    create_spec

    # Step 5: Create FEATURES.json
    log_info "Step 5/8: Creating feature tracking list..."
    create_features

    # Step 6: Create PROGRESS.md
    log_info "Step 6/8: Creating progress tracking..."
    create_progress

    # Step 7: Create checkpoint directory
    log_info "Step 7/8: Setting up checkpoints..."
    setup_checkpoints

    # Step 8: Initial commit
    log_info "Step 8/8: Creating initial commit..."
    initial_commit

    # Final summary
    print_summary
}

# =============================================================================
# Step Implementations
# =============================================================================

check_prerequisites() {
    local missing=0

    check_command git || missing=1
    check_command node || missing=1
    check_command npm || missing=1

    if [ $missing -eq 1 ]; then
        log_error "Missing prerequisites. Please install them first."
        exit 1
    fi

    log_success "All prerequisites met"
}

create_directory_structure() {
    local dirs=(
        "$PROJECT_DIR/cli/screens"
        "$PROJECT_DIR/core"
        "$PROJECT_DIR/config"
        "$PROJECT_DIR/db"
        "$PROJECT_DIR/i18n"
        "$PROJECT_DIR/docs"
        "$PROJECT_DIR/scripts"
        "$PROJECT_DIR/bin"
        "$PROJECT_DIR/TESTS/unit"
        "$PROJECT_DIR/TESTS/e2e"
        "$PROJECT_DIR/CHECKPOINTS"
    )

    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            log_info "Created: $dir"
        fi
    done

    log_success "Directory structure created"
}

init_git() {
    cd "$PROJECT_DIR"

    if [ ! -d ".git" ]; then
        log_info "Initializing new git repository..."
        git init

        # Set default branch
        git checkout -b develop 2>/dev/null || git branch -M develop

        log_success "Git repository initialized"
    else
        log_info "Git repository already exists"
    fi

    # Configure git if needed
    if [ ! -f ".gitignore" ]; then
        cat > .gitignore << 'EOF'
node_modules/
bin/
dist/
*.log
.env
.DS_Store
*.db
.clawtools/
EOF
        log_info "Created .gitignore"
    fi
}

create_spec() {
    local spec_file="$PROJECT_DIR/SPEC.md"

    if [ -f "$spec_file" ]; then
        log_info "SPEC.md already exists, skipping"
        return
    fi

    cat > "$spec_file" << 'EOF'
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
EOF

    log_success "SPEC.md created"
}

create_features() {
    local features_file="$PROJECT_DIR/FEATURES.json"

    if [ -f "$features_file" ]; then
        log_info "FEATURES.json already exists, skipping"
        return
    fi

    cat > "$features_file" << 'EOF'
{
  "version": "0.1.0",
  "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "updated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "features": [
    {
      "id": "core-001",
      "name": "项目初始化",
      "module": "core/init",
      "status": "pass",
      "priority": "P0",
      "tests": [],
      "notes": "初始化完成"
    },
    {
      "id": "det-001",
      "name": "平台检测",
      "module": "core/detector",
      "status": "pending",
      "priority": "P0",
      "tests": ["TESTS/unit/detector.test.ts"],
      "assigned_to": null
    },
    {
      "id": "det-002",
      "name": "Node.js版本检测",
      "module": "core/detector",
      "status": "pending",
      "priority": "P0",
      "tests": ["TESTS/unit/detector.test.ts"],
      "assigned_to": null
    },
    {
      "id": "det-003",
      "name": "OpenClaw安装状态检测",
      "module": "core/detector",
      "status": "pending",
      "priority": "P0",
      "tests": ["TESTS/unit/detector.test.ts"],
      "assigned_to": null
    },
    {
      "id": "det-004",
      "name": "防火墙检测",
      "module": "core/detector",
      "status": "pending",
      "priority": "P1",
      "tests": ["TESTS/unit/detector.test.ts"],
      "assigned_to": null
    },
    {
      "id": "det-005",
      "name": "端口检测",
      "module": "core/detector",
      "status": "pending",
      "priority": "P1",
      "tests": ["TESTS/unit/detector.test.ts"],
      "assigned_to": null
    },
    {
      "id": "inst-001",
      "name": "OpenClaw安装(stable)",
      "module": "core/installer",
      "status": "pending",
      "priority": "P0",
      "tests": ["TESTS/unit/installer.test.ts"],
      "assigned_to": null
    },
    {
      "id": "inst-002",
      "name": "OpenClaw安装(beta/dev)",
      "module": "core/installer",
      "status": "pending",
      "priority": "P1",
      "tests": ["TESTS/unit/installer.test.ts"],
      "assigned_to": null
    },
    {
      "id": "inst-003",
      "name": "OpenClaw卸载",
      "module": "core/installer",
      "status": "pending",
      "priority": "P1",
      "tests": [],
      "assigned_to": null
    },
    {
      "id": "cfg-001",
      "name": "Provider预设配置",
      "module": "config/providers",
      "status": "pending",
      "priority": "P0",
      "tests": ["TESTS/unit/configurator.test.ts"],
      "assigned_to": null
    },
    {
      "id": "cfg-002",
      "name": "API Key加密存储",
      "module": "core/configurator",
      "status": "pending",
      "priority": "P0",
      "tests": ["TESTS/unit/configurator.test.ts"],
      "assigned_to": null
    },
    {
      "id": "cfg-003",
      "name": "配置文件读写",
      "module": "core/configurator",
      "status": "pending",
      "priority": "P0",
      "tests": ["TESTS/unit/configurator.test.ts"],
      "assigned_to": null
    },
    {
      "id": "doc-001",
      "name": "系统诊断",
      "module": "core/doctor",
      "status": "pending",
      "priority": "P0",
      "tests": ["TESTS/unit/doctor.test.ts"],
      "assigned_to": null
    },
    {
      "id": "doc-002",
      "name": "openclaw doctor集成",
      "module": "core/doctor",
      "status": "pending",
      "priority": "P1",
      "tests": [],
      "assigned_to": null
    },
    {
      "id": "bak-001",
      "name": "配置文件备份",
      "module": "core/backup",
      "status": "pending",
      "priority": "P0",
      "tests": ["TESTS/unit/backup.test.ts"],
      "assigned_to": null
    },
    {
      "id": "bak-002",
      "name": "备份恢复",
      "module": "core/backup",
      "status": "pending",
      "priority": "P0",
      "tests": ["TESTS/unit/backup.test.ts"],
      "assigned_to": null
    },
    {
      "id": "bak-003",
      "name": "迁移导出",
      "module": "core/backup",
      "status": "pending",
      "priority": "P2",
      "tests": [],
      "assigned_to": null
    },
    {
      "id": "sea-001",
      "name": "文档clone",
      "module": "core/search",
      "status": "pending",
      "priority": "P1",
      "tests": [],
      "assigned_to": null
    },
    {
      "id": "sea-002",
      "name": "全文索引和搜索",
      "module": "core/search",
      "status": "pending",
      "priority": "P1",
      "tests": ["TESTS/unit/search.test.ts"],
      "assigned_to": null
    },
    {
      "id": "tui-001",
      "name": "主菜单界面",
      "module": "cli/App",
      "status": "pending",
      "priority": "P0",
      "tests": [],
      "assigned_to": null
    },
    {
      "id": "tui-002",
      "name": "安装界面",
      "module": "cli/screens/install",
      "status": "pending",
      "priority": "P0",
      "tests": [],
      "assigned_to": null
    },
    {
      "id": "tui-003",
      "name": "配置界面",
      "module": "cli/screens/config",
      "status": "pending",
      "priority": "P0",
      "tests": [],
      "assigned_to": null
    },
    {
      "id": "tui-004",
      "name": "诊断界面",
      "module": "cli/screens/doctor",
      "status": "pending",
      "priority": "P0",
      "tests": [],
      "assigned_to": null
    },
    {
      "id": "tui-005",
      "name": "备份界面",
      "module": "cli/screens/backup",
      "status": "pending",
      "priority": "P1",
      "tests": [],
      "assigned_to": null
    },
    {
      "id": "tui-006",
      "name": "搜索界面",
      "module": "cli/screens/search",
      "status": "pending",
      "priority": "P1",
      "tests": [],
      "assigned_to": null
    },
    {
      "id": "db-001",
      "name": "SQLite数据库初始化",
      "module": "db",
      "status": "pending",
      "priority": "P0",
      "tests": [],
      "assigned_to": null
    },
    {
      "id": "i18n-001",
      "name": "国际化框架",
      "module": "i18n",
      "status": "pass",
      "priority": "P0",
      "tests": [],
      "notes": "框架已创建"
    },
    {
      "id": "i18n-002",
      "name": "中文翻译",
      "module": "i18n",
      "status": "pass",
      "priority": "P0",
      "tests": [],
      "notes": "中文为默认语言"
    },
    {
      "id": "i18n-003",
      "name": "英文翻译",
      "module": "i18n",
      "status": "pending",
      "priority": "P1",
      "tests": [],
      "assigned_to": null
    }
  ],
  "summary": {
    "total": 27,
    "pass": 3,
    "pending": 24,
    "blocked": 0
  }
}
EOF

    log_success "FEATURES.json created"
}

create_progress() {
    local progress_file="$PROJECT_DIR/PROGRESS.md"

    if [ -f "$progress_file" ]; then
        log_info "PROGRESS.md already exists, skipping"
        return
    fi

    cat > "$progress_file" << EOF
# ClawTools 开发进度

## 项目信息
- **项目名称**: ClawTools
- **版本**: 0.1.0
- **初始化日期**: $(date +%Y-%m-%d)
- **当前阶段**: 初始化完成

## 阶段

### Phase 0: 初始化
- [x] 初始化脚本执行 - $(date +%Y-%m-%d)
- [x] 目录结构创建
- [x] Git 仓库初始化
- [x] SPEC.md 创建
- [x] FEATURES.json 创建
- [x] PROGRESS.md 创建
- [x] CHECKPOINTS 目录创建

### Phase 1: 核心模块开发
- [ ] 核心模块实现
  - [ ] detector 模块
  - [ ] installer 模块
  - [ ] configurator 模块
  - [ ] doctor 模块
  - [ ] backup 模块
  - [ ] search 模块

### Phase 2: TUI 界面开发
- [ ] 主菜单
- [ ] 安装界面
- [ ] 配置界面
- [ ] 诊断界面
- [ ] 备份界面
- [ ] 搜索界面

### Phase 3: 测试
- [ ] 单元测试
- [ ] 集成测试
- [ ] E2E 测试

### Phase 4: 发布准备
- [ ] 文档完善
- [ ] 多平台测试
- [ ] 发布

## 当前冲刺 (Sprint)

### Sprint 1: 核心逻辑
**目标**: 完成核心业务逻辑模块
**时间**: $(date +%Y-%m-%d) - $(date -d "+7 days" +%Y-%m-%d)
**状态**: 待开始

## 进度日志

### $(date +%Y-%m-%d) - 初始化
| 时间 | 操作 | Agent |
|------|------|-------|
| $(date +%H:%M) | 执行 init.sh | Initializer Agent |

## 阻塞项
无

## 待人工Review
无

## 检查点

| 检查点 | 日期 | 状态 | 快照 |
|--------|------|------|------|
| CP-001 | $(date +%Y-%m-%d) | 完成 | 初始化完成 |

## 统计

- **总功能数**: 27
- **已完成**: 3
- **进行中**: 0
- **待开始**: 24
- **完成率**: 11%

---

*此文件由 AgentFlow 框架自动维护*
EOF

    log_success "PROGRESS.md created"
}

setup_checkpoints() {
    mkdir -p "$PROJECT_DIR/CHECKPOINTS"

    # Create first checkpoint
    local checkpoint_file="$PROJECT_DIR/CHECKPOINTS/CP-001-$(date +%Y%m%d).json"

    cat > "$checkpoint_file" << EOF
{
  "id": "CP-001",
  "date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "phase": "initialization",
  "status": "complete",
  "features": {
    "total": 27,
    "pass": 3,
    "pending": 24
  },
  "git": {
    "branch": "develop",
    "commit": "$(git rev-parse HEAD 2>/dev/null || echo 'initial')",
    "message": "Initial commit: Project initialization"
  },
  "artifacts": {
    "spec": "SPEC.md",
    "features": "FEATURES.json",
    "progress": "PROGRESS.md"
  }
}
EOF

    log_success "Checkpoints directory created"
}

initial_commit() {
    cd "$PROJECT_DIR"

    # Add all files
    git add -A

    # Check if there are changes to commit
    if git diff --cached --quiet; then
        log_info "No changes to commit"
        return
    fi

    # Create initial commit
    git commit -m "$(cat <<'EOF'
feat: 初始化 ClawTools 项目

初始化完成，基于 AgentFlow 方法论：
- 创建项目目录结构
- 初始化 Git 仓库
- 创建 SPEC.md 项目规格
- 创建 FEATURES.json 功能列表
- 创建 PROGRESS.md 进度追踪
- 设置 CHECKPOINTS 检查点目录

Co-Authored-By: Initializer Agent <noreply@clawtools.local>
EOF
)"

    log_success "Initial commit created"
    git log --oneline -1
}

# =============================================================================
# Summary
# =============================================================================

print_summary() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    初始化完成                                ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "项目结构:"
    echo "  $PROJECT_DIR"
    echo ""
    echo "创建的文件:"
    echo "  ├── SPEC.md          # 项目规格"
    echo "  ├── FEATURES.json    # 功能列表"
    echo "  ├── PROGRESS.md      # 进度追踪"
    echo "  └── CHECKPOINTS/    # 检查点"
    echo ""
    echo "下一步:"
    echo "  1. 审查 SPEC.md 确认项目目标"
    echo "  2. 审查 FEATURES.json 确认功能范围"
    echo "  3. 启动 Agent Teams 开始开发"
    echo ""
    echo "启动开发命令:"
    echo "  cd $PROJECT_DIR"
    echo "  npm install"
    echo "  npm run build"
    echo ""
}

# Run main
main "$@"
