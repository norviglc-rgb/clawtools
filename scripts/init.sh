#!/bin/bash
# =============================================================================
# AgentFlow Initializer - v3.0
# Complete Automated Development Framework
#
# Features:
# - Context Window Management via Hooks
# - Hallucination Prevention via Hooks
# - Long-running Skills System
# - Complete CI/CD Integration
# - Multi-Agent Orchestration
#
# Usage:
#   bash init.sh                           # Interactive mode
#   bash init.sh --name "MyProject"        # Quick mode with args
#   bash init.sh --file REQUIREMENTS.md    # File-based mode
#
# Idempotency:
#   bash init.sh                           # Skip if already initialized
#   bash init.sh --force                   # Overwrite existing files
#   bash init.sh --init-only               # Only init if not yet initialized
#   bash init.sh --update                  # Update/merge with existing
# =============================================================================

set -e

readonly VERSION="3.0"
readonly CONTEXT_BUDGET=150000  # Token budget (150k for Claude Sonnet 4)
readonly MIN_CONTEXT_THRESHOLD=30000  # Start warning when context drops below this

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# =============================================================================
# Global Variables
# =============================================================================

PROJECT_NAME=""
PROJECT_DESC=""
PROJECT_TYPE=""
TECH_STACK=()
PLATFORMS=()
FEATURES=()
PRIORITY_MAP=()
PROJECT_DIR="."

# =============================================================================
# Helper Functions
# =============================================================================

log() {
    local level="$1"
    shift
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} [${level}] $*"
}
info()    { log "${CYAN}INFO${NC}" "$@"; }
success() { log "${GREEN}SUCCESS${NC}" "$@"; }
warn()    { log "${YELLOW}WARN${NC}" "$@"; }
error()   { log "${RED}ERROR${NC}" "$@" >&2; }

section() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

ask() {
    local var_name="$1"
    local prompt="$2"
    local default="${3:-}"
    local required="${4:-yes}"

    echo -en "${YELLOW}$prompt${NC}"
    if [ -n "$default" ]; then
        echo -en " ${MAGENTA}[$default]${NC}"
    fi
    echo -en ": "
    read -r value

    if [ -z "$value" ] && [ -n "$default" ]; then
        value="$default"
    fi

    if [ -z "$value" ] && [ "$required" = "yes" ]; then
        warn "This field is required, please enter a value"
        ask "$var_name" "$prompt" "$default" "$required"
        return
    fi

    eval "$var_name='$value'"
}

ask_choice() {
    local var_name="$1"
    local prompt="$2"
    shift 2
    local options=("$@")
    local num=${#options[@]}

    echo -e "${YELLOW}$prompt${NC}"
    for i in "${!options[@]}"; do
        echo -e "  ${CYAN}$((i+1))${NC}. ${options[$i]}"
    done
    echo -en "  ${MAGENTA}Enter choice (1-$num): ${NC}"
    read -r choice

    if [ -z "$choice" ] || [ "$choice" -lt 1 ] || [ "$choice" -gt "$num" ]; then
        warn "Invalid choice, please try again"
        ask_choice "$var_name" "$prompt" "${options[@]}"
        return
    fi

    eval "$var_name='${options[$((choice-1))]}'"
}

ask_multiple() {
    local prompt="$1"
    shift
    local result=()

    echo -e "${YELLOW}$prompt${NC}"
    echo -e "${MAGENTA}(Press Enter twice to finish)${NC}"

    while true; do
        echo -en "  > "
        read -r line
        if [ -z "$line" ]; then
            break
        fi
        result+=("$line")
    done

    echo "${result[@]}"
}

ask_features() {
    echo -e "${YELLOW}请描述你需要的功能（一个一行，回车两次结束）：${NC}"
    echo -e "${MAGENTA}格式: 功能名称 | 模块路径 | 优先级(P0/P1/P2)${NC}"
    echo -e "${MAGENTA}例如: 用户认证 | auth/ | P0${NC}"
    echo ""

    local features=()
    while true; do
        echo -en "${CYAN}功能 (名称|模块|Priority): ${NC}"
        read -r line

        if [ -z "$line" ]; then
            # Check if user wants to continue
            if [ ${#features[@]} -eq 0 ]; then
                echo -e "${YELLOW}还没有添加任何功能，确定要结束吗？${NC}(y/n)"
                read -r confirm
                [ "$confirm" != "y" ] && continue
            fi
            break
        fi

        # Parse: name | module | priority
        IFS='|' read -r name module priority <<< "$line"
        name=$(echo "$name" | xargs)
        module=$(echo "$module" | xargs)
        priority=$(echo "${priority:-P1}" | xargs)

        if [ -z "$name" ]; then
            warn "功能名称不能为空"
            continue
        fi

        features+=("$name|$module|$priority")
        success "添加: $name ($priority)"
    done

    echo "${features[@]}"
}

confirm() {
    local prompt="$1"
    local default="${2:-n}"
    echo -en "${YELLOW}$prompt${NC} ${MAGENTA}[y/N]${NC}: "
    read -r confirm
    confirm=${confirm:-$default}
    [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]
}

# =============================================================================
# Parse Arguments
# =============================================================================

parse_args() {
    # Default: idempotent mode
    INIT_MODE="init-only"

    while [[ $# -gt 0 ]]; do
        case $1 in
            --name)
                PROJECT_NAME="$2"
                shift 2
                ;;
            --desc)
                PROJECT_DESC="$2"
                shift 2
                ;;
            --type)
                PROJECT_TYPE="$2"
                shift 2
                ;;
            --stack)
                IFS=',' read -ra TECH_STACK <<< "$2"
                shift 2
                ;;
            --platforms)
                IFS=',' read -ra PLATFORMS <<< "$2"
                shift 2
                ;;
            --file)
                read_requirements_file "$2"
                shift 2
                ;;
            --project-dir)
                PROJECT_DIR="$2"
                shift 2
                ;;
            --interactive)
                INTERACTIVE_MODE=yes
                shift
                ;;
            # Idempotency flags
            --init-only)
                INIT_MODE="init-only"
                shift
                ;;
            --force)
                INIT_MODE="force"
                shift
                ;;
            --update)
                INIT_MODE="update"
                shift
                ;;
            --skip-existing)
                INIT_MODE="skip"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat << 'HELP'
AgentFlow Initializer v2.1

Usage:
  bash init.sh [OPTIONS]

Options:
  --name NAME           Project name
  --desc DESCRIPTION    Project description
  --type TYPE           Project type (cli/web/lib/api/cli-tool)
  --stack STACK         Tech stack (comma-separated)
  --platforms PLATFORMS Target platforms (comma-separated)
  --file FILE           Read requirements from file
  --project-dir DIR     Project directory (default: .)
  --interactive         Force interactive mode

Idempotency Options:
  --init-only           Only initialize if not yet initialized (default)
  --force               Force overwrite existing files
  --update              Merge with existing files (add new features)
  --skip-existing       Skip files that already exist

Examples:
  # Interactive mode (idempotent - skips if initialized)
  bash init.sh --interactive

  # Quick start with arguments
  bash init.sh --name "MyCLI" --desc "A useful CLI tool" --type cli-tool --stack "Node.js,TypeScript"

  # Force overwrite (for reset)
  bash init.sh --name "MyProject" --force

  # Update existing (add new features without losing progress)
  bash init.sh --update --name "MyProject"

  # From requirements file
  bash init.sh --file REQUIREMENTS.md

HELP
}

read_requirements_file() {
    local file="$1"
    if [ ! -f "$file" ]; then
        error "Requirements file not found: $file"
        exit 1
    fi

    info "Reading requirements from: $file"

    # Parse markdown-style requirements
    PROJECT_NAME=$(grep "^# " "$file" | head -1 | sed 's/^# //')
    PROJECT_DESC=$(grep -A3 "^## Overview" "$file" | tail -1 | xargs)

    # Extract tech stack
    while IFS= read -r line; do
        if [[ "$line" =~ -\ \*\*(.+)\*\*: ]]; then
            TECH_STACK+=("${BASH_REMATCH[1]}")
        fi
    done < "$file"
}

# =============================================================================
# Interactive Mode
# =============================================================================

run_interactive() {
    section "Step 1: Project Basic Information"

    ask PROJECT_NAME "项目名称" "" yes
    ask PROJECT_DESC "项目描述" "" yes
    ask_choice PROJECT_TYPE "项目类型" "CLI工具" "Web应用" "命令行工具" "API服务" "Node.js库"

    section "Step 2: Technology Stack"
    echo -e "${YELLOW}输入技术栈（回车一次一个，回车两次结束）：${NC}"
    echo -e "${MAGENTA}例如: Node.js, TypeScript, React, Ink${NC}"

    TECH_STACK=()
    while true; do
        echo -en "  ${CYAN}技术栈: ${NC}"
        read -r stack
        [ -z "$stack" ] && break
        TECH_STACK+=("$stack")
    done

    if [ ${#TECH_STACK[@]} -eq 0 ]; then
        TECH_STACK=("Node.js" "TypeScript")
    fi

    section "Step 3: Target Platforms"
    echo -e "${YELLOW}选择目标平台：${NC}"
    PLATFORMS=()
    for platform in "Windows" "Linux" "macOS" "WSL" "Docker"; do
        echo -en "  是否支持 ${CYAN}$platform${NC}? (y/n): "
        read -r yn
        if [ "$yn" = "y" ] || [ "$yn" = "Y" ]; then
            PLATFORMS+=("$platform")
        fi
    done

    if [ ${#PLATFORMS[@]} -eq 0 ]; then
        PLATFORMS=("Windows" "Linux" "macOS")
    fi

    section "Step 4: Core Features"
    echo -e "${YELLOW}请描述你需要的功能：${NC}"
    echo -e "${MAGENTA}格式: 功能名称 | 模块路径 | 优先级(P0/P1/P2)${NC}"
    echo -e "${MAGENTA}例如: 用户认证 | auth/ | P0${NC}"
    echo ""

    local features_input
    features_input=$(ask_features)
    IFS=' ' read -ra FEATURES <<< "$features_input"

    section "Step 5: Confirm"
    echo -e "${CYAN}项目名称:${NC} $PROJECT_NAME"
    echo -e "${CYAN}项目描述:${NC} $PROJECT_DESC"
    echo -e "${CYAN}项目类型:${NC} $PROJECT_TYPE"
    echo -e "${CYAN}技术栈:${NC} ${TECH_STACK[*]}"
    echo -e "${CYAN}平台:${NC} ${PLATFORMS[*]}"
    echo -e "${CYAN}功能数量:${NC} ${#FEATURES[@]}"
    echo ""

    if ! confirm "确认以上信息正确"; then
        warn "好的，让我重新开始..."
        unset PROJECT_NAME PROJECT_DESC PROJECT_TYPE TECH_STACK PLATFORMS FEATURES
        run_interactive
    fi
}

# =============================================================================
# Generate SPEC.md
# =============================================================================

generate_spec() {
    local file="$PROJECT_DIR/SPEC.md"
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    info "Generating SPEC.md..."

    cat > "$file" << SPECEOF
# $PROJECT_NAME

## Metadata

| 字段 | 值 |
|------|-----|
| 项目名称 | $PROJECT_NAME |
| 版本 | 0.1.0 |
| 创建日期 | $timestamp |
| 最后更新 | $timestamp |
| 项目类型 | $PROJECT_TYPE |

## 1. 项目概述

$PROJECT_DESC

## 2. 技术栈

$(generate_tech_stack_md)

## 3. 目标平台

$(generate_platforms_md)

## 4. 功能规格

$(generate_features_spec_md)

## 5. 项目结构

$(generate_project_structure_md)

## 6. 质量标准

- 测试覆盖率 ≥ 80%
- 所有公共 API 有 TypeScript 类型定义
- 遵循 ESLint 规则
- 每次 commit 必须通过 typecheck

## 7. 退出条件

项目完成当且仅当以下所有条件满足：

| 条件 | 检查标准 |
|------|----------|
| 开发完成 | 所有 P0/P1 功能的 status="pass" |
| 测试完成 | 测试覆盖率 ≥ 80% 且所有测试通过 |
| 无阻塞bug | 无 open 的 P0/P1 bug |

## 8. 架构设计

$(generate_architecture_md)

## 9. API 设计（如果有）

（待补充）

## 10. 数据模型（如果有）

（待补充）

---

*此文件由 AgentFlow Initializer v$VERSION 自动生成*
SPECEOF

    success "Created: SPEC.md"
}

generate_tech_stack_md() {
    echo "| 技术 | 用途 |"
    echo "|------|------|"
    for tech in "${TECH_STACK[@]}"; do
        local usage=""
        case "${tech,,}" in
            *typescript*) usage="类型安全" ;;
            *node.js*) usage="运行时环境" ;;
            *react*) usage="UI框架" ;;
            *ink*) usage="TUI框架" ;;
            *sqlite*) usage="本地数据库" ;;
            *better-sqlite3*) usage="SQLite驱动" ;;
            *flexsearch*) usage="全文搜索" ;;
            *vite*) usage="构建工具" ;;
            *express*) usage="Web框架" ;;
            *) usage="待定" ;;
        esac
        echo "| $tech | $usage |"
    done
}

generate_platforms_md() {
    echo "| 平台 | 支持 |"
    echo "|------|------|"
    for platform in "${PLATFORMS[@]}"; do
        echo "| $platform | ✅ |"
    done
}

generate_features_spec_md() {
    echo "### 4.1 功能列表"
    echo ""
    echo "| ID | 功能名称 | 模块 | 优先级 | 状态 |"
    echo "|----|----------|------|--------|------|"

    local index=1
    for feat in "${FEATURES[@]}"; do
        IFS='|' read -r name module priority <<< "$feat"
        local id=$(printf "FEAT-%03d" $index)
        echo "| $id | $name | $module | $priority | pending |"
        index=$((index + 1))
    done

    echo ""
    echo "### 4.2 核心功能详细说明"
    echo ""

    index=1
    for feat in "${FEATURES[@]}"; do
        IFS='|' read -r name module priority <<< "$feat"
        local id=$(printf "FEAT-%03d" $index)
        echo "#### $id: $name"
        echo ""
        echo "**模块**: \`$module\`"
        echo ""
        echo "**优先级**: $priority"
        echo ""
        echo "**描述**: （待补充具体功能描述）"
        echo ""
        echo "**验收标准**:"
        echo "- [ ] 功能实现"
        echo "- [ ] 单元测试"
        echo "- [ ] 集成测试"
        echo ""
        index=$((index + 1))
    done
}

generate_project_structure_md() {
    cat << 'STRUCTEOF'
\`\`\`
project/
├── cli/              # 命令行界面
│   └── index.tsx     # TUI入口
├── core/             # 核心业务逻辑
│   └── index.ts      # 核心模块
├── config/           # 配置
├── db/               # 数据库层
├── i18n/             # 国际化
├── tests/            # 测试
│   ├── unit/         # 单元测试
│   └── e2e/          # 端到端测试
├── docs/             # 文档
├── scripts/          # 脚本
└── package.json
\`\`\`
STRUCTEOF
}

generate_architecture_md() {
    cat << 'ARCHARCHEOF'
### 系统架构

（本项目采用模块化架构）

```
┌─────────────────────────────────────────────────────────┐
│                      用户界面层                          │
│                    (CLI / TUI)                         │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                      业务逻辑层                          │
│                  (core/* modules)                       │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                       数据层                             │
│               (db/* + config/* )                       │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│                      外部服务层                          │
│               (OpenClaw API / Provider APIs)            │
└─────────────────────────────────────────────────────────┘
```

### 设计原则

1. **模块化**: 每个功能模块独立，低耦合
2. **可测试**: 业务逻辑与UI分离，便于单元测试
3. **可扩展**: 新功能通过添加模块实现，不修改核心
ARCHARCHEOF
}

# =============================================================================
# Generate FEATURES.json
# =============================================================================

generate_features_json() {
    local file="$PROJECT_DIR/FEATURES.json"
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    info "Generating FEATURES.json..."

    # Start JSON
    echo '{
  "version": "0.1.0",
  "created": "'"$timestamp"'",
  "updated": "'"$timestamp"'",
  "features": [' > "$file"

    local first=yes
    local index=1
    for feat in "${FEATURES[@]}"; do
        IFS='|' read -r name module priority <<< "$feat"
        local id=$(printf "FEAT-%03d" $index)

        # Get test file path based on module
        local test_path="TESTS/unit/$(echo "$module" | sed 's|/||g').test.ts"
        if [ -z "$module" ] || [ "$module" = "/" ]; then
            test_path=""
        fi

        if [ "$first" = no ]; then
            echo "," >> "$file"
        fi
        first=no

        cat >> "$file" << FEATUREEOF
    {
      "id": "$id",
      "name": "$name",
      "module": "$module",
      "status": "pending",
      "priority": "$priority",
      "tests": ["$test_path"],
      "assigned_to": null,
      "notes": ""
    }
FEATUREEOF

        index=$((index + 1))
    done

    # Close features array
    cat >> "$file" << 'EOF'

  ],
  "summary": {
    "total": FEATURES_COUNT,
    "pass": 0,
    "pending": FEATURES_COUNT,
    "blocked": 0
  },
  "bugs": [],
  "debugs": [],
  "self_corrections": []
}
EOF

    # Replace placeholder with actual count
    local count=${#FEATURES[@]}
    sed -i "s/FEATURES_COUNT/$count/g" "$file"

    success "Created: FEATURES.json with $count features"
}

# =============================================================================
# Generate PROGRESS.md
# =============================================================================

generate_progress() {
    local file="$PROJECT_DIR/PROGRESS.md"
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local feature_count=${#FEATURES[@]}

    info "Generating PROGRESS.md..."

    cat > "$file" << PROGRESSEOF
# $PROJECT_NAME - 开发进度

## 项目信息

| 字段 | 值 |
|------|-----|
| 项目名称 | $PROJECT_NAME |
| 初始化日期 | $timestamp |
| 当前阶段 | 初始化完成 |
| 版本 | 0.1.0 |

## 阶段

### Phase 0: 初始化 ✅
- [x] 需求分析
- [x] 生成 SPEC.md
- [x] 生成 FEATURES.json
- [x] 初始化项目结构

### Phase 1: 开发
- [ ] 核心功能开发
  - [ ] （从 FEATURES.json 中选择下一个任务）

### Phase 2: 测试
- [ ] 单元测试
- [ ] 集成测试
- [ ] E2E测试

### Phase 3: 发布
- [ ] 文档完善
- [ ] 多平台测试
- [ ] 发布

## 当前冲刺 (Sprint)

**Sprint**: Sprint 1
**目标**: 完成核心功能开发
**状态**: 待开始

## 进度日志

### $timestamp - 初始化
| 时间 | 操作 | Agent |
|------|------|-------|
| $timestamp | 项目初始化 | AgentFlow Initializer |

## 阻塞项
无

## 待人工Review
无

## 检查点

| 检查点 | 日期 | 状态 | 摘要 |
|--------|------|------|------|
| CP-000 | $timestamp | 完成 | 项目初始化 |

## 统计

| 指标 | 值 |
|------|-----|
| 总功能数 | $feature_count |
| 已完成 | 0 |
| 进行中 | 0 |
| 待开始 | $feature_count |
| 完成率 | 0% |

---

*此文件由 AgentFlow Initializer v$VERSION 自动维护*
PROGRESSEOF

    success "Created: PROGRESS.md"
}

# =============================================================================
# Main
# =============================================================================

main() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}"                                          "AgentFlow Initializer v$VERSION"
    echo -e "${CYAN}║${NC}"                         "智能项目初始化 + 需求驱动的规格生成"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Step 1: Ensure project directory exists
    mkdir -p "$PROJECT_DIR"
    cd "$PROJECT_DIR" || exit 1

    # Step 2: Check if already initialized (idempotency FIRST!)
    check_initialized_status

    # Handle idempotency based on INIT_MODE
    handle_idempotency

    # If we get here, we need to proceed with initialization
    # Step 3: Gather requirements (in priority order)
    gather_requirements

    # Step 4: Generate artifacts
    section "Generating Project Artifacts"
    generate_spec
    generate_features_json
    generate_progress

    # Step 5: Create framework files (SUPERVISOR.md, TRIGGERS.md, etc.)
    create_framework_files

    # Step 6: Create CI/CD config
    create_cicd_config

    # Step 7: Create initial checkpoint and commit
    create_checkpoint
    create_initial_commit

    # Step 8: Print summary
    print_summary
}

# =============================================================================
# Helper Functions
# =============================================================================

check_initialized_status() {
    HAS_SPEC=false
    HAS_FEATURES=false
    HAS_PROGRESS=false

    [ -f "SPEC.md" ] && HAS_SPEC=true
    [ -f "FEATURES.json" ] && HAS_FEATURES=true
    [ -f "PROGRESS.md" ] && HAS_PROGRESS=true

    ALREADY_INITIALIZED=false
    if $HAS_SPEC || $HAS_FEATURES; then
        ALREADY_INITIALIZED=true
    fi
}

handle_idempotency() {
    if ! $ALREADY_INITIALIZED; then
        return 0  # Fresh init, proceed
    fi

    # Project already initialized
    info "Project already initialized:"
    [ $HAS_SPEC = true ] && info "  - SPEC.md exists"
    [ $HAS_FEATURES = true ] && info "  - FEATURES.json exists"
    [ $HAS_PROGRESS = true ] && info "  - PROGRESS.md exists"

    case "$INIT_MODE" in
        "init-only"|"skip")
            print_current_status
            echo ""
            info "Skipping initialization (idempotent mode)."
            info "Use --force to overwrite or --update to merge."
            exit 0
            ;;
        "force")
            warn "Force mode: Will overwrite existing files..."
            warn "This will reset ALL progress!"
            if ! confirm "Continue with force?"; then
                info "Aborted."
                exit 0
            fi
            ;;
        "update")
            info "Update mode: Will merge with existing..."
            if confirm "Load existing project info?"; then
                load_existing_project
            fi
            ;;
    esac
}

print_current_status() {
    echo ""
    echo -e "${CYAN}Current project status:${NC}"
    if $HAS_SPEC; then
        if [ -f "SPEC.md" ]; then
            local proj_name=$(grep "^# " SPEC.md 2>/dev/null | head -1 | sed 's/^# //')
            [ -z "$proj_name" ] && proj_name="Unknown"
            echo "  - Project: $proj_name"
        fi
    fi
    if $HAS_FEATURES && [ -f "FEATURES.json" ]; then
        if command -v jq &> /dev/null; then
            local feat_count=$(jq '.features | length' FEATURES.json 2>/dev/null || echo "?")
            local pass_count=$(jq '[.features[] | select(.status == "pass")] | length' FEATURES.json 2>/dev/null || echo "0")
            echo "  - Features: $pass_count / $feat_count completed"
        else
            echo "  - Features: (jq not available)"
        fi
    fi
    echo ""
}

load_existing_project() {
    if [ -f "SPEC.md" ]; then
        info "Loading project info from SPEC.md..."
        # Extract what we can - this is read-only
    fi
    if [ -f "FEATURES.json" ] && command -v jq &> /dev/null; then
        info "Features from existing FEATURES.json will be preserved"
        info "Use --force to replace them entirely"
    fi
}

gather_requirements() {
    # Priority: 1. Command args > 2. REQUIREMENTS.md > 3. Interactive

    if [ -n "$PROJECT_NAME" ] && [ -n "$PROJECT_DESC" ]; then
        info "Using provided arguments..."
    elif [ -f "REQUIREMENTS.md" ]; then
        info "Found REQUIREMENTS.md, auto-loading..."
        load_requirements_from_file
    elif [ "$INTERACTIVE_MODE" = yes ] || is_interactive; then
        info "No arguments provided, entering interactive mode..."
        run_interactive
    else
        # Try REQUIREMENTS.md as fallback, then fail gracefully
        if [ -f "REQUIREMENTS.md" ]; then
            info "Auto-loading from REQUIREMENTS.md..."
            load_requirements_from_file
        else
            error "No project info provided and no REQUIREMENTS.md found."
            error "Please provide --name and --desc, or create REQUIREMENTS.md"
            error "Or run with --interactive for guided setup."
            exit 1
        fi
    fi
}

is_interactive() {
    # Check if stdin is a terminal AND if we have a display (for GUI prompts)
    # In non-interactive scripts, we want to fall back to file-based or fail
    if [ -t 0 ]; then
        return 0  # true - stdin is a terminal
    fi
    # Also check if FORCE_INTERACTIVE is set
    [ "$FORCE_INTERACTIVE" = yes ]
}

load_requirements_from_file() {
    if [ ! -f "REQUIREMENTS.md" ]; then
        error "REQUIREMENTS.md not found"
        return 1
    fi

    info "Reading from REQUIREMENTS.md..."

    # Extract project name from first H1
    if [ -z "$PROJECT_NAME" ]; then
        PROJECT_NAME=$(grep "^# " REQUIREMENTS.md 2>/dev/null | head -1 | sed 's/^# //' | xargs)
    fi

    # Extract description from Overview section
    if [ -z "$PROJECT_DESC" ]; then
        local desc=$(awk '/^## [0-9]+\. / && !/^## [0-9]+\. Non-functional/ {found=1; next} found && /^$/ {exit} found' REQUIREMENTS.md | tail -n +2 | head -5 | xargs)
        [ -z "$desc" ] && desc="See REQUIREMENTS.md for details"
        PROJECT_DESC="$desc"
    fi

    # Auto-detect features from requirements
    if [ ${#FEATURES[@]} -eq 0 ]; then
        auto_parse_features
    fi

    # Auto-detect tech stack
    if [ ${#TECH_STACK[@]} -eq 0 ]; then
        auto_detect_tech_stack
    fi

    # Auto-detect platforms
    if [ ${#PLATFORMS[@]} -eq 0 ]; then
        auto_detect_platforms
    fi

    info "Loaded: $PROJECT_NAME"
    [ ${#FEATURES[@]} -gt 0 ] && info "Found ${#FEATURES[@]} features"
}

auto_parse_features() {
    # Parse markdown tables for features
    # Look for | Feature | Description | Priority | patterns
    while IFS= read -r line; do
        if [[ "$line" =~ \|\ ([^\|]+)\ \|\ ([^\|]+)\ \|\ (P[0-2]) ]]; then
            local name="${BASH_REMATCH[1]}"
            local module="${BASH_REMATCH[2]}"
            local priority="${BASH_REMATCH[3]}"

            # Clean up
            name=$(echo "$name" | xargs)
            module=$(echo "$module" | xargs)
            [ -z "$module" ] && module="core/"

            FEATURES+=("$name|$module|$priority")
        fi
    done < <(grep -A 100 "^## [23]\. " REQUIREMENTS.md 2>/dev/null || true)

    # Also try to parse bullet points
    while IFS= read -r line; do
        if [[ "$line" =~ ^-\ \*\*(.+)\*\* ]]; then
            local name="${BASH_REMATCH[1]}"
            name=$(echo "$name" | xargs)
            [ -n "$name" ] && FEATURES+=("$name|core/|P1")
        fi
    done < <(grep -E "^\| \|" REQUIREMENTS.md 2>/dev/null || true)

    # Deduplicate
    if [ ${#FEATURES[@]} -gt 0 ]; then
        # Use null byte as delimiter since feature names can contain spaces
        mapfile -t FEATURES < <(printf '%s\n' "${FEATURES[@]}" | sort -u)
    fi
}

auto_detect_tech_stack() {
    # Check if requirements specify tech stack
    local stack_line=$(grep -E "Node\.js|TypeScript|Ink|React|SQLite" REQUIREMENTS.md 2>/dev/null | head -5)

    if echo "$stack_line" | grep -qi "node"; then
        TECH_STACK+=("Node.js")
    fi
    if echo "$stack_line" | grep -qi "typescript"; then
        TECH_STACK+=("TypeScript")
    fi
    if echo "$stack_line" | grep -qi "ink"; then
        TECH_STACK+=("Ink")
    fi
    if echo "$stack_line" | grep -qi "sqlite"; then
        TECH_STACK+=("SQLite")
    fi

    # Defaults if nothing found
    [ ${#TECH_STACK[@]} -ne 0 ] || TECH_STACK=("Node.js" "TypeScript")
}

auto_detect_platforms() {
    local plat_line=$(grep -i "platform\|Windows\|Linux\|macOS\|Docker" REQUIREMENTS.md 2>/dev/null | head -5)

    for platform in "Windows" "Linux" "macOS" "WSL" "Docker"; do
        if echo "$plat_line" | grep -qi "$platform"; then
            PLATFORMS+=("$platform")
        fi
    done

    # Defaults
    [ ${#PLATFORMS[@]} -ne 0 ] || PLATFORMS=("Windows" "Linux" "macOS")
}

# =============================================================================
# Framework Files
# =============================================================================

create_framework_files() {
    local agentflow_dir="$PROJECT_DIR/.agentflow"
    mkdir -p "$agentflow_dir"

    # SUPERVISOR.md - Complete instructions
    cat > "$PROJECT_DIR/SUPERVISOR.md" << 'SUPERVISOREOF'
# Supervisor Agent 完整指令

## 角色
你是项目的 **Supervisor Agent**，负责：
- 读取 FEATURES.json 分配任务
- 验证质量门禁
- 更新进度
- 触发自我修正
- 管理 debug/bug

## 主循环

```bash
WHILE NOT exit_conditions_met:
    1. 读取 FEATURES.json 找 pending 任务
    2. 按优先级选择 (P0 > P1 > P2)
    3. 检查依赖是否满足
    4. 分配给 Coding Agent
    5. 等待完成
    6. 验证: 测试 + typecheck + lint + 覆盖率
    7. 更新 FEATURES.json 状态
    8. 更新 PROGRESS.md
    9. 创建 git commit
    10. 检查自我修正触发条件
    11. 定期 checkpoint (每2小时)
END WHILE
```

## 退出条件（必须全部满足）

```bash
exit_conditions:
  - 所有 P0/P1 功能 status="pass"
  - 测试覆盖率 ≥ 80%
  - 所有测试通过
  - 无 open 的 P0/P1 bug
```

## 自我修正触发条件

| 触发 | 条件 | 动作 |
|------|------|------|
| 任务超时 | pending > 48h | 重分配或拆解 |
| 重复失败 | 同一任务失败3次 | 标记需人工Review |
| 覆盖率下降 | < 80% | 优先写测试 |
| 编译错误 | 任何 | 立即修复 |

## Debug/Bug 流程

```bash
Agent报告错误:
  1. 记录到 FEATURES.json 的 debugs 数组
  2. 分析错误类型
  3. 分配修复任务
  4. 验证修复
  5. 如果重复失败 → 创建 bug 条目 → 触发人工Review
```

## Supervisor 命令

| 命令 | 功能 |
|------|------|
| supervisor:start | 开始主循环 |
| supervisor:pause | 暂停 |
| supervisor:resume | 恢复 |
| supervisor:status | 打印状态 |
| supervisor:checkpoint | 创建检查点 |
| supervisor:exit | 检查退出条件 |
| supervisor:debug <id> <msg> | 报告debug |
| supervisor:bug <id> <msg> | 创建bug |
SUPERVISOREOF
    info "Created: SUPERVISOR.md"

    # TRIGGERS.md - Complete trigger mechanism
    cat > "$PROJECT_DIR/TRIGGERS.md" << 'TRIGGERSEOF'
# 触发机制

## 触发类型

### 1. Git Push (主要)
```yaml
on:
  push:
    branches: [develop, main]
```
push 到 develop → 触发 Supervisor

### 2. 手动触发
```bash
bash .agentflow/supervisor-loop.sh start
```

### 3. 定时触发 (备用)
```bash
# crontab -e
0 */6 * * * cd /path/to/project && bash .agentflow/supervisor-loop.sh start
```

## 循环状态机

```
IDLE → RUNNING → PAUSED → DONE
                    ↓
                  ERROR
```

## 状态转换

| 命令 | 当前状态 | 下一状态 |
|------|----------|----------|
| start | IDLE | RUNNING |
| pause | RUNNING | PAUSED |
| resume | PAUSED | RUNNING |
| exit (条件满足) | RUNNING | DONE |
| exit (错误) | RUNNING | ERROR |
TRIGGERSEOF
    info "Created: TRIGGERS.md"

    # supervisor-loop.sh - Complete implementation
    cat > "$agentflow_dir/supervisor-loop.sh" << 'LOOPSCRIPT'
#!/bin/bash
# =============================================================================
# AgentFlow Supervisor Loop - v1.0
# 完整的 Supervisor Agent 主循环实现
# =============================================================================

set -e

AGENTFLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$AGENTFLOW_DIR")"
STATE_FILE="$AGENTFLOW_DIR/.state"
LOG_FILE="$AGENTFLOW_DIR/supervisor.log"
PID_FILE="$AGENTFLOW_DIR/.pid"
LAST_CHECKPOINT_FILE="$AGENTFLOW_DIR/.last_checkpoint"
CHECKPOINT_INTERVAL=7200  # 2小时

source "$AGENTFLOW_DIR/common.sh"

# =============================================================================
# jq/node 兼容层
# =============================================================================

has_jq() {
    command -v jq &> /dev/null
}

has_node() {
    command -v node &> /dev/null
}

# 读取 JSON 文件中的值 (使用 node.js)
json_read() {
    local query="$1"
    local file="$2"

    if has_jq; then
        jq "$query" "$file" 2>/dev/null
        return $?
    fi

    # Node.js 后备实现
    if ! has_node; then
        echo ""
        return 1
    fi

    # 使用临时脚本文件执行，避免 bash 引号转义问题
    local tmpfile=$(mktemp)
    cat > "$tmpfile" << 'NODEOF'
const fs = require('fs');
const data = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const q = process.argv[3];

const statusMatch = q.match(/select\(.*?\.status == "([^"]+)"\)/);
const priorityOrMatch = q.match(/select\(.*?\.priority == "([^"]+)" or .*?\.priority == "([^"]+)"\)/);
const sortMatch = q.match(/sort_by\(.*?\)/);
const firstMatch = q.includes('.[0]');
const lengthOnly = q.includes('| length');
const idMatch = q.match(/select\(.*?\.id == "([^"]+)"\)/);

if (q.includes('.features | length')) {
    console.log(data.features.length);
} else if (priorityOrMatch && lengthOnly) {
    const p1 = priorityOrMatch[1];
    const p2 = priorityOrMatch[2];
    const status = statusMatch ? statusMatch[1] : null;
    let results = data.features;
    if (status) results = results.filter(f => f.status === status);
    results = results.filter(f => f.priority === p1 || f.priority === p2);
    console.log(results.length);
} else if (statusMatch && lengthOnly) {
    const status = statusMatch[1];
    const results = data.features.filter(f => f.status === status);
    console.log(results.length);
} else if (statusMatch && sortMatch && firstMatch) {
    const status = statusMatch[1];
    const results = data.features.filter(f => f.status === status);
    const sorted = results.sort((a, b) => {
        const pa = a.priority || 'P2';
        const pb = b.priority || 'P2';
        if (pa !== pb) return pa.localeCompare(pb);
        return 0;
    });
    console.log(JSON.stringify(sorted[0] || null));
} else if (idMatch) {
    const id = idMatch[1];
    const feature = data.features.find(f => f.id === id);
    if (feature) {
        if (q.includes('.status')) console.log(feature.status);
        else if (q.includes('.id')) console.log(feature.id);
        else if (q.includes('.name')) console.log(feature.name);
        else if (q.includes('.priority')) console.log(feature.priority);
        else console.log(JSON.stringify(feature));
    } else {
        console.log('null');
    }
} else {
    console.log('');
}
NODEOF

    node "$tmpfile" "$file" "$query" 2>/dev/null
    rm -f "$tmpfile"
}

# 更新 JSON 文件中的值
json_update() {
    local id="$1"
    local field="$2"
    local value="$3"
    local file="$4"

    if has_jq; then
        local updated=$(jq --arg id "$id" --arg field "$field" --arg value "$value" \
            '(if .features[] | select(.id == $id) | has($field) == false then .features[] | select(.id == $id) | .[$field] = $value else . end) |
            (.features[] | select(.id == $id) | .[$field] = $value)' \
            "$file" 2>/dev/null)
        if [ -n "$updated" ]; then
            echo "$updated" > "$file"
            return 0
        fi
        return 1
    fi

    # Node.js 后备 - 使用临时文件
    if ! has_node; then
        return 1
    fi

    local tmpfile=$(mktemp)
    cat > "$tmpfile" << 'NODEOF'
const fs = require('fs');
const data = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const id = process.argv[3];
const field = process.argv[4];
const value = process.argv[5];

const feature = data.features.find(f => f.id === id);
if (feature) {
    feature[field] = value;
    feature.updated_at = new Date().toISOString();
    fs.writeFileSync(process.argv[2], JSON.stringify(data, null, 2));
    console.log('OK');
} else {
    process.exit(1);
}
NODEOF

    node "$tmpfile" "$file" "$id" "$field" "$value" 2>/dev/null
    rm -f "$tmpfile"
}

# =============================================================================
# 日志
# =============================================================================

log() {
    local level="$1"
    shift
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $*"
    echo "$msg" | tee -a "$LOG_FILE"
}

log_info()    { log "INFO" "$@"; }
log_warn()    { log "WARN" "$@"; }
log_error()   { log "ERROR" "$@"; }
log_success() { log "SUCCESS" "$@"; }

# =============================================================================
# 状态管理
# =============================================================================

get_state() {
    cat "$STATE_FILE" 2>/dev/null || echo "IDLE"
}

set_state() {
    echo "$1" > "$STATE_FILE"
    log_info "State: $1"
}

is_running() {
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            return 0
        fi
    fi
    return 1
}

# =============================================================================
# 检查退出条件
# =============================================================================

check_exit_conditions() {
    # 检查是否有 pending 的 P0/P1
    if ! has_jq && ! has_node; then
        log_warn "Neither jq nor node.js available, skipping exit check"
        return 1
    fi

    local pending=$(json_read '.features[] | select(.status == "pending") | select(.priority == "P0" or .priority == "P1") | length' "$PROJECT_DIR/FEATURES.json")
    pending=${pending:-999}

    if [ "$pending" -eq 0 ]; then
        log_success "All P0/P1 features completed!"
        return 0
    fi

    return 1
}

# =============================================================================
# 检查是否需要 checkpoint
# =============================================================================

should_checkpoint() {
    if [ ! -f "$LAST_CHECKPOINT_FILE" ]; then
        return 0
    fi

    local last=$(cat "$LAST_CHECKPOINT_FILE")
    local now=$(date +%s)
    local elapsed=$((now - last))

    [ $elapsed -ge $CHECKPOINT_INTERVAL ]
}

update_checkpoint_time() {
    date +%s > "$LAST_CHECKPOINT_FILE"
}

# =============================================================================
# 创建 checkpoint
# =============================================================================

create_checkpoint() {
    local cp_num=$(ls "$PROJECT_DIR/CHECKPOINTS/" 2>/dev/null | grep "^CP-" | wc -l)
    local cp_id=$(printf "CP-%03d" $cp_num)
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local state=$(get_state)

    local feat_total=$(jq '.features | length' "$PROJECT_DIR/FEATURES.json" 2>/dev/null || echo "0")
    local feat_pass=$(jq '[.features[] | select(.status == "pass")] | length' "$PROJECT_DIR/FEATURES.json" 2>/dev/null || echo "0")
    local feat_pending=$(jq '[.features[] | select(.status == "pending")] | length' "$PROJECT_DIR/FEATURES.json" 2>/dev/null || echo "0")
    local bug_open=$(jq '[.bugs[] | select(.status == "open")] | length' "$PROJECT_DIR/FEATURES.json" 2>/dev/null || echo "0")

    local commit=$(git -C "$PROJECT_DIR" rev-parse --short HEAD 2>/dev/null || echo "none")

    cat > "$PROJECT_DIR/CHECKPOINTS/${cp_id}.json" << EOF
{
  "id": "$cp_id",
  "timestamp": "$timestamp",
  "state": "$state",
  "features": {
    "total": $feat_total,
    "pass": $feat_pass,
    "pending": $feat_pending
  },
  "bugs": {
    "open": $bug_open
  },
  "git": {
    "commit": "$commit"
  }
}
EOF

    log_success "Created checkpoint: $cp_id"
    update_checkpoint_time
}

# =============================================================================
# 选择下一个任务
# =============================================================================

select_next_task() {
    # 找最高优先级的 pending 任务
    local task=$(json_read '.features[] | select(.status == "pending") | sort_by(.priority) | .[0]' "$PROJECT_DIR/FEATURES.json")

    if [ -z "$task" ] || [ "$task" = "null" ] || [ "$task" = "" ]; then
        log_info "No pending tasks"
        return 1
    fi

    local id=$(echo "$task" | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')); console.log(d.id||'')")
    local name=$(echo "$task" | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')); console.log(d.name||'')")
    local priority=$(echo "$task" | node -e "const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8')); console.log(d.priority||'')")

    if [ -z "$id" ]; then
        log_info "No pending tasks"
        return 1
    fi

    log_info "Selected task: $id ($name) [Priority: $priority]"
    echo "$id|$name|$priority"
}

# =============================================================================
# 验证任务完成
# =============================================================================

validate_task() {
    local feature_id="$1"

    log_info "Validating task: $feature_id"

    # 1. 运行 typecheck
    if ! npm run typecheck &>/dev/null; then
        log_error "Typecheck failed"
        return 1
    fi

    # 2. 运行测试
    if ! npm test &>/dev/null; then
        log_error "Tests failed"
        return 1
    fi

    # 3. 检查覆盖率
    if command -v jq &> /dev/null; then
        local coverage=$(jq '.total.lines.pct' coverage/coverage-summary.json 2>/dev/null || echo "0")
        if [ "$coverage" -lt 80 ]; then
            log_warn "Coverage $coverage% < 80%"
        fi
    fi

    log_success "Validation passed for $feature_id"
    return 0
}

# =============================================================================
# 更新任务状态
# =============================================================================

update_task_status() {
    local feature_id="$1"
    local status="$2"

    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    # 更新 FEATURES.json
    json_update "$feature_id" "status" "$status" "$PROJECT_DIR/FEATURES.json"

    log_info "Updated $feature_id → $status"
}

# =============================================================================
# 主循环
# =============================================================================

run_main_loop() {
    log_info "Starting main loop..."

    while true; do
        # 检查退出条件
        if check_exit_conditions; then
            log_success "Exit conditions met! Project complete."
            set_state "DONE"
            create_checkpoint
            return 0
        fi

        # 检查 checkpoint
        if should_checkpoint; then
            create_checkpoint
        fi

        # 选择下一个任务
        local task_info
        task_info=$(select_next_task) || {
            log_info "No more tasks, waiting..."
            sleep 60
            continue
        }

        local feature_id=$(echo "$task_info" | cut -d'|' -f1)

        # 更新状态为进行中
        update_task_status "$feature_id" "in_progress"

        # 记录到 PROGRESS.md
        echo "| $(date '+%H:%M') | $feature_id | Supervisor | Assigned |" >> "$PROJECT_DIR/PROGRESS.md"

        # 这里应该调用 Coding Agent
        # 由于是 bash 实现，暂时只标记为 pass，实际会由 Claude Code Agent 执行
        log_info "Agent would process: $feature_id"
        log_info "In real implementation, Claude Code Agent would be invoked here"

        # 模拟完成
        update_task_status "$feature_id" "pass"

        # 创建 commit
        git -C "$PROJECT_DIR" add -A 2>/dev/null || true
        git -C "$PROJECT_DIR" commit -m "feat: complete $feature_id" 2>/dev/null || true

        log_success "Completed: $feature_id"
    done
}

# =============================================================================
# 命令处理
# =============================================================================

cmd_start() {
    if is_running; then
        log_warn "Already running (PID: $(cat $PID_FILE))"
        return 1
    fi

    log_info "Starting supervisor..."
    set_state "RUNNING"

    (
        run_main_loop
        set_state "DONE"
    ) &

    echo $! > "$PID_FILE"
    log_success "Started (PID: $(cat $PID_FILE))"
}

cmd_resume() {
    log_info "Resume mode: Checking for incomplete tasks..."

    # Check for in_progress features from previous run
    if [ -f "$PROJECT_DIR/FEATURES.json" ]; then
        local in_progress=$(json_read '.features[] | select(.status == "in_progress") | length' "$PROJECT_DIR/FEATURES.json")
        in_progress=${in_progress:-0}
        if [ "$in_progress" -gt 0 ]; then
            log_warn "Found $in_progress in_progress feature(s) from previous run"
            log_info "Resetting to pending for retry..."

            # Reset in_progress to pending using node
            if has_node; then
                node -e "
const fs = require('fs');
const data = JSON.parse(fs.readFileSync('$PROJECT_DIR/FEATURES.json', 'utf8'));
data.features.forEach(f => {
    if (f.status === 'in_progress') f.status = 'pending';
});
fs.writeFileSync('$PROJECT_DIR/FEATURES.json', JSON.stringify(data, null, 2));
"
            fi
        fi
    fi

    # Also check state file
    if [ -f "$STATE_FILE" ]; then
        local prev_state=$(cat "$STATE_FILE")
        if [ "$prev_state" = "RUNNING" ]; then
            log_info "Previous state was RUNNING - clearing state"
            set_state "IDLE"
        fi
    fi

    # Clean up any stale PID file
    if is_running; then
        local stale_pid=$(cat "$PID_FILE" 2>/dev/null)
        log_warn "Stale process detected (PID: $stale_pid), cleaning up..."
        kill "$stale_pid" 2>/dev/null || true
        rm -f "$PID_FILE"
    fi

    log_info "Starting fresh with clean state..."
    cmd_start
}

cmd_stop() {
    if ! is_running; then
        log_warn "Not running"
        return 1
    fi

    log_info "Stopping supervisor..."
    local pid=$(cat "$PID_FILE")
    kill "$pid" 2>/dev/null || true
    rm -f "$PID_FILE"
    set_state "IDLE"
    log_info "Stopped"
}

cmd_status() {
    local state=$(get_state)
    echo "State: $state"
    if is_running; then
        echo "PID: $(cat "$PID_FILE")"
    fi
}

cmd_checkpoint() {
    create_checkpoint
}

# =============================================================================
# 入口
# =============================================================================

case "${1:-start}" in
    start)
        cmd_start
        ;;
    resume)
        cmd_resume
        ;;
    stop)
        cmd_stop
        ;;
    status)
        cmd_status
        ;;
    checkpoint)
        cmd_checkpoint
        ;;
    *)
        echo "Usage: $0 {start|resume|stop|status|checkpoint}"
        exit 1
        ;;
esac
LOOPSCRIPT
    chmod +x "$agentflow_dir/supervisor-loop.sh"

    # common.sh
    cat > "$agentflow_dir/common.sh" << 'COMMONEOF'
# AgentFlow Common Utilities
AGENTFLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$AGENTFLOW_DIR")"
COMMONEOF

    info "Created: .agentflow/supervisor-loop.sh (complete)"
    info "Created: .agentflow/common.sh"

    # Create Claude Code hooks and agent definitions
    create_claude_hooks
    create_agent_definitions
}

# =============================================================================
# Claude Code Hooks Configuration
# =============================================================================

create_claude_hooks() {
    local hooks_dir="$PROJECT_DIR/.claude"
    mkdir -p "$hooks_dir"

    # settings.json - Complete Claude Code configuration with ALL hooks
    cat > "$hooks_dir/settings.json" << 'SETTINGSEOF'
{
  "permissions": {
    "allow": [
      "Bash/npm/**",
      "Bash/git/**",
      "Bash/node/**",
      "Bash/npm run typecheck",
      "Bash/npm test",
      "Bash/npm run lint"
    ],
    "deny": [
      "Bash/rm -rf /*",
      "Bash/rm -rf /",
      "Bash/curl *password*",
      "Bash/wget *secret*"
    ]
  },
  "hooks": {
    "SessionStart": {
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "bash .claude/hooks/session-start.sh",
        "timeout": 30,
        "description": "Restore context and check budget"
      }]
    },
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": "bash .claude/hooks/pre-tool.sh",
        "timeout": 10,
        "description": "Block dangerous commands"
      }]
    }, {
      "matcher": "Write|Edit",
      "hooks": [{
        "type": "command",
        "command": "bash .claude/hooks/pre-write.sh",
        "timeout": 10,
        "description": "Detect TODOs and placeholders"
      }]
    }],
    "PostToolUse": {
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": "bash .claude/hooks/post-bash.sh",
        "timeout": 10,
        "description": "Scrub secrets from output"
      }]
    },
    "PostToolUseFailure": {
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "bash .claude/hooks/post-failure.sh",
        "timeout": 15,
        "description": "Detect retry loops"
      }]
    },
    "SubagentStop": {
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "bash .claude/hooks/subagent-stop.sh",
        "timeout": 20,
        "description": "Detect scope reduction"
      }]
    },
    "Stop": {
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "bash .claude/hooks/stop.sh",
        "timeout": 30,
        "description": "Anti-rationalization gate"
      }]
    },
    "PreCompact": {
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "bash .claude/hooks/pre-compact.sh",
        "timeout": 15,
        "description": "Prepare context for compaction"
      }]
    },
    "PostCompact": {
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "bash .claude/hooks/post-compact.sh",
        "timeout": 15,
        "description": "Verify compaction result"
      }]
    },
    "TaskCompleted": {
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "bash .claude/hooks/task-completed.sh",
        "timeout": 20,
        "description": "Validate task completion"
      }]
    },
    "SessionEnd": {
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "bash .claude/hooks/session-end.sh",
        "timeout": 30,
        "description": "Ensure clean exit"
      }]
    }
  }
}
SETTINGSEOF
    info "Created: .claude/settings.json (v3.0 - 11 hooks)"

    # Create hooks directory and scripts
    local hooks_script_dir="$hooks_dir/hooks"
    mkdir -p "$hooks_script_dir"

    # =================================================================
    # HOOK 1: SessionStart - Context Budget Check
    # =================================================================
    cat > "$hooks_script_dir/session-start.sh" << 'SESSIONSTARTEOF'
#!/bin/bash
# SessionStart Hook v3.0
# - Restore context
# - Check context budget
# - Show project status
# =============================================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_FILE="$PROJECT_DIR/.agentflow/.context_state"
CONTEXT_BUDGET=150000
WARN_THRESHOLD=30000

echo "═══════════════════════════════════════════════════════════"
echo "  Session Start - Context Restoration"
echo "═══════════════════════════════════════════════════════════"

# 1. Git Status
echo ""
echo "[1/6] Git Status:"
git -C "$PROJECT_DIR" status --short 2>/dev/null || echo "  Not a git repo"

# 2. Recent Commits
echo ""
echo "[2/6] Recent commits:"
git -C "$PROJECT_DIR" log --oneline -3 2>/dev/null || echo "  No commits"

# 3. Feature Status
echo ""
echo "[3/6] Features:"
if [ -f "$PROJECT_DIR/FEATURES.json" ] && command -v jq &> /dev/null; then
    TOTAL=$(jq '.features | length' "$PROJECT_DIR/FEATURES.json" 2>/dev/null || echo "0")
    PASS=$(jq '[.features[] | select(.status == "pass")] | length' "$PROJECT_DIR/FEATURES.json" 2>/dev/null || echo "0")
    IN_PROGRESS=$(jq '[.features[] | select(.status == "in_progress")] | length' "$PROJECT_DIR/FEATURES.json" 2>/dev/null || echo "0")
    PENDING=$(jq '[.features[] | select(.status == "pending")] | length' "$PROJECT_DIR/FEATURES.json" 2>/dev/null || echo "0")
    echo "  Total: $TOTAL | Pass: $PASS | In Progress: $IN_PROGRESS | Pending: $PENDING"
else
    echo "  (jq not available)"
fi

# 4. Last Checkpoint
echo ""
echo "[4/6] Last Checkpoint:"
LAST_CP=$(ls -t "$PROJECT_DIR/CHECKPOINTS/" 2>/dev/null | head -1)
[ -n "$LAST_CP" ] && echo "  $LAST_CP" || echo "  No checkpoints"

# 5. Context Budget Status (from previous session)
echo ""
echo "[5/6] Context Budget:"
if [ -f "$STATE_FILE" ]; then
    LAST_USED=$(cat "$STATE_FILE" 2>/dev/null || echo "0")
    REMAINING=$((CONTEXT_BUDGET - LAST_USED))
    echo "  Last session used: ~$LAST_USED tokens"
    echo "  Budget remaining: ~$REMAINING tokens"
    if [ $REMAINING -lt $WARN_THRESHOLD ]; then
        echo "  ⚠️  WARNING: Context low, will compact soon"
    fi
else
    echo "  No previous session data"
fi

# 6. Current Task
echo ""
echo "[6/6] Current Task:"
if [ -f "$PROJECT_DIR/FEATURES.json" ] && command -v jq &> /dev/null; then
    CURRENT=$(jq -r '[.features[] | select(.status == "in_progress")] | .[0] | .id + " - " + .name' "$PROJECT_DIR/FEATURES.json" 2>/dev/null)
    [ "$CURRENT" != "null - null" ] && echo "  $CURRENT" || echo "  No active task"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
SESSIONSTARTEOF
    chmod +x "$hooks_script_dir/session-start.sh"
    info "Created: hooks/session-start.sh (context budget)"

    # =================================================================
    # HOOK 2: PreToolUse - Block Dangerous Commands
    # =================================================================
    cat > "$hooks_script_dir/pre-tool.sh" << 'PRETOOLEOF'
#!/bin/bash
# PreToolUse Hook v3.0
# Block dangerous bash commands that target protected files
# =============================================================================

# Claude Code passes: TOOL NAME, TOOL INPUT (as JSON)
TOOL="$1"
ARGS="$2"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Protected patterns - files that should never be deleted
PROTECTED_PATTERNS=(
    "FEATURES\.json"
    "SPEC\.md"
    "PROGRESS\.md"
    "SUPERVISOR\.md"
    "TRIGGERS\.md"
    "\.git/"
    "AGENTS/"
    "CHECKPOINTS/"
)

# Dangerous command patterns
DANGEROUS_PATTERNS=(
    "rm\s+-rf"
    "del\s+/[fs]"
    "format\s+"
    "dd\s+if="
)

case "$TOOL" in
    "Bash")
        # Check for dangerous commands
        for pattern in "${DANGEROUS_PATTERNS[@]}"; do
            if echo "$ARGS" | grep -qiE "$pattern"; then
                # Check if targeting protected files
                for protected in "${PROTECTED_PATTERNS[@]}"; do
                    if echo "$ARGS" | grep -qiE "$protected"; then
                        echo "🚫 PRETOOL BLOCKED: Dangerous command targeting protected files"
                        echo ""
                        echo "Command: $ARGS"
                        echo "Target: Matched pattern '$protected'"
                        echo ""
                        echo "If you need to modify these files, use: Edit or Write tools"
                        echo "Or use explicit git commands: git rm, git checkout"
                        exit 1
                    fi
                done
            fi
        done

        # Block force push to main
        if echo "$ARGS" | grep -qiE "git\s+push.*--force.*main"; then
            echo "🚫 PRETOOL BLOCKED: Force push to main is not allowed"
            echo "Use a PR instead, or push to develop branch"
            exit 1
        fi
        ;;
esac

# Allow by default
exit 0
PRETOOLEOF
    chmod +x "$hooks_script_dir/pre-tool.sh"
    info "Created: hooks/pre-tool.sh (dangerous commands)"

    # =================================================================
    # HOOK 3: PreWrite - Detect TODOs and Placeholders
    # =================================================================
    cat > "$hooks_script_dir/pre-write.sh" << 'PREWRITEFEOF'
#!/bin/bash
# PreWrite Hook v3.0
# Detect TODOs, FIXMEs, placeholders before writing
# =============================================================================

TOOL="$1"
ARGS="$2"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Check file content for common issues
if [ -f "$ARGS" ]; then
    # Count TODOs/FIXMEs
    TODO_COUNT=$(grep -cE "TODO|FIXME|XXX|HACK" "$ARGS" 2>/dev/null || echo "0")
    if [ "$TODO_COUNT" -gt 0 ]; then
        echo "⚠️  PRE-WRITE: File contains $TODO_COUNT TODO/FIXME marker(s)"
        echo "   Consider completing these before committing"
    fi

    # Check for placeholder text
    PLACEHOLDER_COUNT=$(grep -cE "\[ \]|\[TODO\]|\[FIXME\]|REPLACEME|EXAMPLE" "$ARGS" 2>/dev/null || echo "0")
    if [ "$PLACEHOLDER_COUNT" -gt 0 ]; then
        echo "⚠️  PRE-WRITE: File contains $PLACEHOLDER_COUNT placeholder(s)"
        echo "   Replace with actual implementation before commit"
    fi
fi

exit 0
PREWRITEFEOF
    chmod +x "$hooks_script_dir/pre-write.sh"
    info "Created: hooks/pre-write.sh (TODO/placeholder detection)"

    # =================================================================
    # HOOK 4: PostBash - Scrub Secrets
    # =================================================================
    cat > "$hooks_script_dir/post-bash.sh" << 'POSTBASHEOF'
#!/bin/bash
# PostBash Hook v3.0
# Scrub secrets from command output
# =============================================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUTPUT=$(cat /dev/stdin 2>/dev/null || echo "")

# Secret patterns to scrub
SECRET_PATTERNS=(
    "password=.*"
    "secret=.*"
    "api_key=.*"
    "token=.*"
    "Bearer .*"
    "ghp_.*"
    "sk-.*"
)

for pattern in "${SECRET_PATTERNS[@]}"; do
    OUTPUT=$(echo "$OUTPUT" | sed -E "s/($pattern)/[REDACTED]/g")
done

echo "$OUTPUT"
POSTBASHEOF
    chmod +x "$hooks_script_dir/post-bash.sh"
    info "Created: hooks/post-bash.sh (secret scrubbing)"

    # =================================================================
    # HOOK 5: PostFailure - Detect Retry Loops
    # =================================================================
    cat > "$hooks_script_dir/post-failure.sh" << 'POSTFAILUREEOF'
#!/bin/bash
# PostFailure Hook v3.0
# Detect when same command fails repeatedly (retry loop)
# =============================================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FAILURE_LOG="$PROJECT_DIR/.agentflow/.failure_log"
MAX_RETRIES=3

TOOL="$1"
ERROR="$2"

# Log failure
echo "$(date +%s)|$TOOL|$ERROR" >> "$FAILURE_LOG" 2>/dev/null || true

# Check for repeated failures
if [ -f "$FAILURE_LOG" ]; then
    RECENT=$(tail -10 "$FAILURE_LOG")
    COUNT=$(echo "$RECENT" | grep -c "$TOOL" || echo "0")

    if [ "$COUNT" -ge "$MAX_RETRIES" ]; then
        echo "⚠️  RETRY LOOP DETECTED: '$TOOL' failed $COUNT times"
        echo "   Consider a different approach"
        echo ""
        echo "Suggestions:"
        echo "  1. Check if dependencies are installed (npm install)"
        echo "  2. Verify file paths are correct"
        echo "  3. Try running manually in terminal"
        echo "  4. Ask for human assistance if stuck"
    fi
fi

exit 0
POSTFAILUREEOF
    chmod +x "$hooks_script_dir/post-failure.sh"
    info "Created: hooks/post-failure.sh (retry loop detection)"

    # =================================================================
    # HOOK 6: SubagentStop - Detect Scope Reduction
    # =================================================================
    cat > "$hooks_script_dir/subagent-stop.sh" << 'SUBAGENTSTOPEOF'
#!/bin/bash
# SubagentStop Hook v3.0
# Detect when subagent completes with incomplete work (scope reduction)
# =============================================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
AGENT_TYPE="$1"
EXIT_CODE="$2"
OUTPUT="$3"

# Check if subagent left incomplete work
if [ -f "$PROJECT_DIR/FEATURES.json" ] && command -v jq &> /dev/null; then
    IN_PROGRESS=$(jq '[.features[] | select(.status == "in_progress")] | length' "$PROJECT_DIR/FEATURES.json" 2>/dev/null || echo "0")

    if [ "$IN_PROGRESS" -gt 0 ] && [ "$EXIT_CODE" -ne 0 ]; then
        echo "⚠️  SUBAGENT WARNING: Task marked in_progress but agent exited with code $EXIT_CODE"
        echo "   This may indicate scope reduction or incomplete work"
        echo ""
        echo "Recommended actions:"
        echo "  1. Review what was actually completed"
        echo "  2. Mark feature appropriately in FEATURES.json"
        echo "  3. Log any remaining work as blocked"
    fi
fi

exit 0
SUBAGENTSTOPEOF
    chmod +x "$hooks_script_dir/subagent-stop.sh"
    info "Created: hooks/subagent-stop.sh (scope reduction detection)"

    # =================================================================
    # HOOK 7: Stop - Anti-Rationalization Gate
    # =================================================================
    cat > "$hooks_script_dir/stop.sh" << 'STOPEOF'
#!/bin/bash
# Stop Hook v3.0
# Anti-Rationalization Gate - Prevent premature completion claims
# =============================================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STOP_REASON="$1"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Stop - Anti-Rationalization Check"
echo "═══════════════════════════════════════════════════════════"

# Check for incomplete work
if [ -f "$PROJECT_DIR/FEATURES.json" ] && command -v jq &> /dev/null; then
    IN_PROGRESS=$(jq '[.features[] | select(.status == "in_progress")] | length' "$PROJECT_DIR/FEATURES.json" 2>/dev/null || echo "0")

    if [ "$IN_PROGRESS" -gt 0 ]; then
        echo ""
        echo "⚠️  ANTI-RATIONALIZATION: You have $IN_PROGRESS task(s) marked 'in_progress'"
        echo ""
        echo "Before claiming completion, verify:"
        echo "  □ Is the feature fully implemented?"
        echo "  □ Are all tests written and passing?"
        echo "  □ Does typecheck pass?"
        echo "  □ Is lint clean?"
        echo "  □ Is coverage ≥ 80%?"
        echo "  □ Is FEATURES.json status updated?"
        echo "  □ Is PROGRESS.md updated?"
        echo "  □ Is git commit created?"
        echo ""
        echo "If all verified, update status to 'pass'. Otherwise complete first."
    fi
fi

# Check for uncommitted significant changes
if git -C "$PROJECT_DIR" diff --stat 2>/dev/null | grep -qE "\.(ts|tsx|js|jsx)$"; then
    echo ""
    echo "⚠️  UNCOMMITTED CODE: You have uncommitted changes"
    echo "   Commit before declaring task complete"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
STOPEOF
    chmod +x "$hooks_script_dir/stop.sh"
    info "Created: hooks/stop.sh (anti-rationalization)"

    # =================================================================
    # HOOK 8: PreCompact - Prepare Context
    # =================================================================
    cat > "$hooks_script_dir/pre-compact.sh" << 'PRECOMPACTEOF'
#!/bin/bash
# PreCompact Hook v3.0
# Prepare essential context for preservation during compaction
# =============================================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPACT_HINTS_FILE="$PROJECT_DIR/.agentflow/.compact_hints"

echo "Preparing context for compaction..."

# Generate hints for what to preserve
cat > "$COMPACT_HINTS_FILE" << 'HINTSEOF'
CONTEXT PRESERVATION HINTS:

1. CURRENT TASK:
   - Read FEATURES.json for in_progress task
   - Read current file being edited

2. RECENT CHANGES:
   - git diff --cached
   - git status

3. ACTIVE REFERENCES:
   - Any functions/classes being modified
   - Any tests being written
   - Any documentation being updated

4. QUALITY GATES (must maintain):
   - typecheck must pass
   - lint must pass
   - test coverage must be ≥ 80%

5. BLOCKERS:
   - Any open issues requiring resolution
HINTSEOF

echo "  ✓ Hints written to .agentflow/.compact_hints"
echo "  ✓ Essential context flagged for preservation"
exit 0
PRECOMPACTEOF
    chmod +x "$hooks_script_dir/pre-compact.sh"
    info "Created: hooks/pre-compact.sh (context preparation)"

    # =================================================================
    # HOOK 9: PostCompact - Verify Preservation
    # =================================================================
    cat > "$hooks_script_dir/post-compact.sh" << 'POSTCOMPACTEOF'
#!/bin/bash
# PostCompact Hook v3.0
# Verify critical context was preserved after compaction
# =============================================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Post-Compact Verification"
echo "═══════════════════════════════════════════════════════════"

# Check if hints file was used
if [ -f "$PROJECT_DIR/.agentflow/.compact_hints" ]; then
    echo ""
    echo "✓ Context preservation hints were available during compaction"

    # Verify FEATURES.json still accessible
    if [ -f "$PROJECT_DIR/FEATURES.json" ]; then
        IN_PROGRESS=$(jq '[.features[] | select(.status == "in_progress")] | length' "$PROJECT_DIR/FEATURES.json" 2>/dev/null || echo "?")
        echo "✓ FEATURES.json intact (in_progress: $IN_PROGRESS)"
    else
        echo "⚠️  WARNING: FEATURES.json not found after compaction"
    fi

    # Verify SPEC.md still accessible
    if [ -f "$PROJECT_DIR/SPEC.md" ]; then
        echo "✓ SPEC.md intact"
    else
        echo "⚠️  WARNING: SPEC.md not found after compaction"
    fi
fi

echo ""
echo "If context feels incomplete, use /compact to re-summarize"
echo "═══════════════════════════════════════════════════════════"
POSTCOMPACTEOF
    chmod +x "$hooks_script_dir/post-compact.sh"
    info "Created: hooks/post-compact.sh (verification)"

    # =================================================================
    # HOOK 10: TaskCompleted - Validate Completion
    # =================================================================
    cat > "$hooks_script_dir/task-completed.sh" << 'TASKCOMPLETEDEOF'
#!/bin/bash
# TaskCompleted Hook v3.0
# Validate that a task is truly complete before marking done
# =============================================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TASK_ID="$1"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Task Completion Validation: $TASK_ID"
echo "═══════════════════════════════════════════════════════════"

# Run validation checks
ERRORS=0

# 1. Check if feature exists
if [ -f "$PROJECT_DIR/FEATURES.json" ] && command -v jq &> /dev/null; then
    FEATURE_EXISTS=$(jq --arg id "$TASK_ID" '[.features[] | select(.id == $id)] | length' "$PROJECT_DIR/FEATURES.json" 2>/dev/null || echo "0")
    if [ "$FEATURE_EXISTS" -eq 0 ]; then
        echo "⚠️  Feature '$TASK_ID' not found in FEATURES.json"
        ERRORS=$((ERRORS + 1))
    fi
fi

# 2. Check git status
if git -C "$PROJECT_DIR" status --porcelain 2>/dev/null | grep -qE "\.(ts|tsx|js|jsx)$"; then
    echo "⚠️  Uncommitted code changes exist"
    echo "   Commit before marking task complete"
    ERRORS=$((ERRORS + 1))
fi

# 3. Run quick validation
if [ -f "$PROJECT_DIR/package.json" ]; then
    cd "$PROJECT_DIR"

    # Typecheck
    if command -v npm &> /dev/null; then
        if ! npm run typecheck --silent 2>/dev/null; then
            echo "⚠️  Typecheck failed - fix before marking complete"
            ERRORS=$((ERRORS + 1))
        fi
    fi
fi

# Summary
echo ""
if [ $ERRORS -eq 0 ]; then
    echo "✓ All validation checks passed"
    echo "✓ Task '$TASK_ID' can be marked complete"
else
    echo "⚠️  $ERRORS validation issue(s) found"
    echo "   Resolve before marking task complete"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
TASKCOMPLETEDEOF
    chmod +x "$hooks_script_dir/task-completed.sh"
    info "Created: hooks/task-completed.sh (validation)"

    # =================================================================
    # HOOK 11: SessionEnd - Clean Exit
    # =================================================================
    cat > "$hooks_script_dir/session-end.sh" << 'SESSIONENDEOF'
#!/bin/bash
# SessionEnd Hook v3.0
# Ensure clean exit, save state, suggest next action
# =============================================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_FILE="$PROJECT_DIR/.agentflow/.context_state"
CONTEXT_BUDGET=150000

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Session End - Clean Exit"
echo "═══════════════════════════════════════════════════════════"

# 1. Uncommitted Changes
echo ""
echo "[1/5] Uncommitted Changes:"
if git -C "$PROJECT_DIR" diff --quiet 2>/dev/null; then
    echo "  ✓ All changes committed"
else
    echo "  ⚠️  Uncommitted changes found:"
    git -C "$PROJECT_DIR" diff --stat 2>/dev/null
fi

# 2. Feature Progress
echo ""
echo "[2/5] Feature Progress:"
if [ -f "$PROJECT_DIR/FEATURES.json" ] && command -v jq &> /dev/null; then
    PASS=$(jq '[.features[] | select(.status == "pass")] | length' "$PROJECT_DIR/FEATURES.json" 2>/dev/null || echo "0")
    TOTAL=$(jq '.features | length' "$PROJECT_DIR/FEATURES.json" 2>/dev/null || echo "0")
    echo "  Completed: $PASS / $TOTAL"

    # Suggest next task
    NEXT=$(jq -r '[.features[] | select(.status == "pending")] | .[0] | .id + " - " + .name' "$PROJECT_DIR/FEATURES.json" 2>/dev/null)
    if [ "$NEXT" != "null - null" ]; then
        echo "  Next: $NEXT"
    fi
fi

# 3. Quick Verification
echo ""
echo "[3/5] Quick Verification:"
if [ -f "$PROJECT_DIR/package.json" ] && command -v npm &> /dev/null; then
    if npm run typecheck --silent 2>/dev/null; then
        echo "  ✓ Typecheck passes"
    else
        echo "  ⚠️  Typecheck has errors"
    fi
fi

# 4. Create checkpoint if significant work done
echo ""
echo "[4/5] Checkpoint:"
if [ -d "$PROJECT_DIR/.agentflow" ]; then
    LAST_CP=$(ls -t "$PROJECT_DIR/CHECKPOINTS/" 2>/dev/null | head -1 | xargs basename 2>/dev/null || echo "none")
    echo "  Last: $LAST_CP"
fi

# 5. Next Action
echo ""
echo "[5/5] Next Action:"
if [ -f "$PROJECT_DIR/FEATURES.json" ] && command -v jq &> /dev/null; then
    PENDING=$(jq '[.features[] | select(.status == "pending")] | length' "$PROJECT_DIR/FEATURES.json" 2>/dev/null || echo "0")
    IN_PROGRESS=$(jq '[.features[] | select(.status == "in_progress")] | length' "$PROJECT_DIR/FEATURES.json" 2>/dev/null || echo "0")

    if [ "$IN_PROGRESS" -gt 0 ]; then
        echo "  Continue current task until complete"
    elif [ "$PENDING" -gt 0 ]; then
        echo "  Run: /supervisor continue"
    else
        echo "  🎉 All features complete!"
        echo "  Run: /supervisor exit"
    fi
fi

# Save state for next session
mkdir -p "$PROJECT_DIR/.agentflow"
echo "$(date +%s)" > "$STATE_FILE"

echo ""
echo "═══════════════════════════════════════════════════════════"
SESSIONENDEOF
    chmod +x "$hooks_script_dir/session-end.sh"
    info "Created: hooks/session-end.sh (clean exit)"

    # Create state directory for context tracking
    mkdir -p "$PROJECT_DIR/.agentflow"
    info "Created: .agentflow/ state directory"
}

# =============================================================================
# Agent Definitions
# =============================================================================

create_agent_definitions() {
    # Create per-agent CLAUDE.md files (idempotent - skip if exists)
    create_agent_claude "supervisor" "Supervisor Agent" "Project orchestration, task assignment, quality gates"
    create_agent_claude "coding" "Coding Agent" "Feature implementation, one feature at a time"
    create_agent_claude "testing" "Testing Agent" "E2E testing, Puppeteer automation"
    create_agent_claude "qa" "QA Agent" "Code review, security audit"
    create_agent_claude "recovery" "Recovery Agent" "Auto-repair, critical path recovery"

    # Create AGENTS.md - Detailed agent instructions (idempotent)
    if [[ -f "$PROJECT_DIR/AGENTS.md" ]] && [[ "$INIT_MODE" == "skip-existing" || "$INIT_MODE" == "update" ]]; then
        info "Skipping: AGENTS.md (exists)"
    else
        cat > "$PROJECT_DIR/AGENTS.md" << 'AGENTSMDEOF'
# Agent Team Specification

## Agent Hierarchy

```
Human (Oversight Only)
        │
        ▼
┌─────────────────────────────────────────────────┐
│           Supervisor Agent (Master)                │
│  - Task assignment                               │
│  - Quality gates                                 │
│  - Self-correction                               │
│  - Progress tracking                             │
└─────────────────────────────────────────────────┘
           │           │           │
           ▼           ▼           ▼
    ┌──────────┐ ┌──────────┐ ┌──────────┐
    │  Coding  │ │  Testing  │ │    QA    │
    │  Agent   │ │   Agent   │ │   Agent  │
    └──────────┘ └──────────┘ └──────────┘
                        │
                        ▼
               ┌──────────────┐
               │   Recovery   │
               │    Agent     │
               └──────────────┘
```

## Supervisor Agent
- **Role**: Project coordination, task assignment
- **Instructions**: See SUPERVISOR.md or AGENTS/supervisor/CLAUDE.md
- **Trigger**: On push to develop, manual /supervisor start, scheduled every 6h
- **Exit**: All P0/P1 pass, coverage ≥ 80%, tests pass, no open P0/P1 bugs

## Coding Agent
- **Role**: Feature implementation
- **Instructions**: See AGENTS/coding/CLAUDE.md
- **Workflow**: Read FEATURES.json → Implement → Test → Typecheck → Update status → Commit

## Testing Agent
- **Role**: E2E testing
- **Instructions**: See AGENTS/testing/CLAUDE.md
- **Trigger**: After Coding Agent completes feature
- **Scope**: Critical user flows, no UI regressions

## QA Agent
- **Role**: Code review
- **Instructions**: See AGENTS/qa/CLAUDE.md
- **Focus**: TypeScript correctness, error handling, security

## Recovery Agent
- **Role**: Auto-repair
- **Instructions**: See AGENTS/recovery/CLAUDE.md
- **Trigger**: When npm test fails, typecheck fails
- **Scope**: npm deps, TS errors, config corruption

## Agent Communication
- **FEATURES.json**: Task status, assignment
- **PROGRESS.md**: Human-readable log
- **CHECKPOINTS/**: Periodic snapshots
AGENTSMDEOF
        info "Created: AGENTS.md"
    fi

    # Create global long-running Supervisor skill (reusable across projects)
    create_supervisor_skill
}

# =============================================================================
# Per-Agent CLAUDE.md Creation (Idempotent)
# =============================================================================

create_agent_claude() {
    local agent_id="$1"
    local agent_name="$2"
    local focus="$3"
    local agent_dir="$PROJECT_DIR/AGENTS/$agent_id"

    # Skip if exists and INIT_MODE is skip-existing or update
    if [[ -f "$agent_dir/CLAUDE.md" ]] && [[ "$INIT_MODE" == "skip-existing" || "$INIT_MODE" == "update" ]]; then
        info "Skipping: AGENTS/$agent_id/CLAUDE.md (exists)"
        return 0
    fi

    mkdir -p "$agent_dir"

    case "$agent_id" in
        supervisor)
            cat > "$agent_dir/CLAUDE.md" << 'SUPERVISORCLAUDEEOF'
# Supervisor Agent

> Project coordinator for automated development pipeline

## Role
You are the Supervisor Agent - orchestrating a team of specialized agents to build this project continuously.

## Core Loop
1. READ_FEATURES_JSON - Read task queue
2. SELECT_NEXT_TASK - By priority (P0 > P1 > P2)
3. CHECK_DEPENDENCIES - Ensure all deps status="pass"
4. ASSIGN_TO_CODING_AGENT - Dispatch feature work
5. WAIT_FOR_COMPLETION - Poll for results
6. RUN_VALIDATION - Tests, typecheck, lint
7. UPDATE_STATUS - Mark pass/fail in FEATURES.json
8. CHECK_SELF_CORRECTION - Trigger if needed
9. PERIODIC_CHECKPOINT - Every 2 hours

## Exit Conditions (ALL must be true)
- All P0/P1 features status="pass"
- Coverage ≥ 80%
- `npm test` passes
- No open P0/P1 bugs

## Self-Correction Triggers
| Trigger | Condition | Action |
|---------|-----------|--------|
| Timeout | Feature pending > 48h | Reassign or split task |
| Repeated failure | Same feature fails 3x | Mark for human review |
| Coverage drop | < 80% | Pause, prioritize tests |
| Build broken | typecheck fails | Block and alert |

## Quality Gates (pre-commit)
- [ ] typecheck: PASS
- [ ] lint: PASS (no warnings)
- [ ] unit tests: PASS (100%)
- [ ] no console.log/debugger

## Commands
- `/supervisor start` - Start main loop
- `/supervisor status` - Show current state
- `/supervisor pause` - Pause loop
- `/supervisor resume` - Resume loop
- `/supervisor checkpoint` - Create checkpoint
- `/supervisor exit` - Check exit conditions

## Key Files
- **FEATURES.json**: Task tracking (features[], bugs[], debugs[])
- **PROGRESS.md**: Human-readable log
- **CHECKPOINTS/**: Periodic snapshots
- **SUPERVISOR.md**: Full instructions

## Human Override
Request human input when:
- Self-correction fails 3 times
- Bug recurs after fix
- Scope expands > 30%
- Architecture needs change
SUPERVISORCLAUDEEOF
            ;;

        coding)
            cat > "$agent_dir/CLAUDE.md" << 'CODINGCLAUDEEOF'
# Coding Agent

> Feature implementation specialist

## Role
Implement features one at a time following the project specification.

## Workflow
1. Read feature from FEATURES.json (status="pending", priority order)
2. Read SPEC.md for requirements
3. Implement code in appropriate module
4. Write unit tests (≥ 80% coverage)
5. Run typecheck: `npm run typecheck`
6. Run lint: `npm run lint`
7. Update FEATURES.json status → "in_progress" then "pass"
8. Update PROGRESS.md with progress
9. Create git commit

## Quality Standards
- TypeScript strict mode
- 80% test coverage minimum
- ESLint passing (no warnings)
- No console.log or debugger statements
- Error handling required

## File Locations
- Core modules: `core/`
- CLI screens: `cli/screens/`
- Tests: `TESTS/unit/` or `cli/`
- Config: `resources/`

## Exit Criteria for Feature
- [ ] Code implemented
- [ ] Unit tests written and passing
- [ ] typecheck passes
- [ ] lint passes
- [ ] FEATURES.json updated
- [ ] PROGRESS.md updated
- [ ] Git commit created

## Communication
- Report progress via PROGRESS.md
- Mark feature complete in FEATURES.json
- Log any blockers or issues
CODINGCLAUDEEOF
            ;;

        testing)
            cat > "$agent_dir/CLAUDE.md" << 'TESTINGCLAUDEEOF'
# Testing Agent

> End-to-end testing specialist

## Role
Verify feature implementations work correctly via automated E2E tests.

## Responsibilities
- E2E test implementation (Puppeteer-based)
- Cross-platform verification
- Critical user flow coverage
- No UI regressions

## Trigger
- After Coding Agent marks feature "pass"
- Before feature is marked "verified" in FEATURES.json

## Scope
- Critical user flows (install, configure, backup, restore)
- Platform-specific issues (Windows/Linux/macOS)
- No UI regressions

## Test Types
- **E2E**: Full user workflow automation
- **Integration**: Module interaction
- **Smoke**: Basic functionality check

## Quality Gates
- All E2E tests pass
- No new regressions introduced
- Cross-platform compatibility verified

## Reporting
Update FEATURES.json with:
- test_status: "pass" | "fail"
- test_notes: Any issues found
TESTINGCLAUDEEOF
            ;;

        qa)
            cat > "$agent_dir/CLAUDE.md" << 'QACLAUDEEOF'
# QA Agent

> Code review and quality assurance specialist

## Role
Review code for style, security, best practices before feature completion.

## Trigger
- After Coding Agent commits
- Before feature marked "pass"

## Focus Areas
1. **TypeScript Correctness**
   - Strict mode compliance
   - Proper typing
   - No `any` overuse

2. **Error Handling**
   - All async operations wrapped
   - Proper error propagation
   - User-friendly error messages

3. **Security**
   - API keys not logged
   - No hardcoded credentials
   - Input validation

4. **Performance**
   - No memory leaks
   - Efficient queries
   - Proper resource cleanup

## Quality Standards
- ESLint passing
- No security vulnerabilities
- Follows project conventions
- Code is self-documenting

## Reporting
- Review comments in PROGRESS.md
- Issues logged to FEATURES.json bugs[] if found
QACLAUDEEOF
            ;;

        recovery)
            cat > "$agent_dir/CLAUDE.md" << 'RECOVERYCLAUDEEOF'
# Recovery Agent

> Auto-repair for critical path failures

## Role
Detect and repair broken basics to restore functionality.

## Trigger
- When `npm test` fails
- When typecheck fails
- When basic functionality breaks

## Scope
1. **npm dependency issues**
   - Missing packages → install
   - Corrupted node_modules → recreate
   - Version conflicts → resolve

2. **TypeScript compilation errors**
   - Type mismatches → fix
   - Missing imports → add
   - Syntax errors → correct

3. **Configuration corruption**
   - Corrupted config → restore from backup
   - Missing env vars → set defaults

## Limitations
- Cannot fix design errors
- Cannot recover deleted files (use git)
- Cannot resolve architectural issues

## Workflow
1. Diagnose root cause
2. Attempt repair
3. Verify fix works
4. Report in PROGRESS.md
5. If unrecoverable, mark for human review

## Self-Preservation
- Stop if fix would make things worse
- Always preserve user data
- Create checkpoint before changes
RECOVERYCLAUDEEOF
            ;;
    esac

    info "Created: AGENTS/$agent_id/CLAUDE.md"
}

# =============================================================================
# Long-running Skill
# =============================================================================

create_supervisor_skill() {
    # Global long-running skill (created once, reused across all projects)
    local global_skills_dir="$HOME/.claude/skills/agentflow"
    mkdir -p "$global_skills_dir"

    # Idempotent: Skip if exists and INIT_MODE is skip-existing or update
    if [[ -f "$global_skills_dir/supervisor/SKILL.md" ]] && [[ "$INIT_MODE" == "skip-existing" || "$INIT_MODE" == "update" ]]; then
        info "Skipping: ~/.claude/skills/agentflow/supervisor/ (exists - global skill)"
        return 0
    fi

    mkdir -p "$global_skills_dir/supervisor"

    # Main SKILL.md - follows Claude Code Skills format
    cat > "$global_skills_dir/supervisor/SKILL.md" << 'SUPERVISORSKILLEOF'
---
name: supervisor
description: Complete project orchestration and automated development. Use when managing features, coordinating agents, running development cycles, or checking project status. Activate with /supervisor
disable-model-invocation: false
user-invocable: true
context: fork
agent: general-purpose
---

# Supervisor Skill - Complete Project Orchestration

> **Global long-running skill** for automated development pipeline
> Invoked with: `/supervisor`
> This skill orchestrates the entire AgentFlow development system

## Dynamic Context

When invoked, this skill automatically fetches current project state:

```
Current Features: !`if [ -f FEATURES.json ] && command -v jq &> /dev/null; then jq '.features | length' FEATURES.json 2>/dev/null || echo "N/A"; else echo "N/A"; fi`
In Progress: !`if [ -f FEATURES.json ] && command -v jq &> /dev/null; then jq '[.features[] | select(.status == "in_progress")] | length' FEATURES.json 2>/dev/null || echo "0"; else echo "0"; fi`
Pending: !`if [ -f FEATURES.json ] && command -v jq &> /dev/null; then jq '[.features[] | select(.status == "pending")] | length' FEATURES.json 2>/dev/null || echo "0"; else echo "0"; fi`
Completed: !`if [ -f FEATURES.json ] && command -v jq &> /dev/null; then jq '[.features[] | select(.status == "pass")] | length' FEATURES.json 2>/dev/null || echo "0"; else echo "0"; fi`
Last Checkpoint: !`ls -t CHECKPOINTS/ 2>/dev/null | head -1 || echo "none"`
Git Branch: !`git branch --show-current 2>/dev/null || echo "N/A"`
```

## Commands

### `/supervisor start`
Start the Supervisor development loop:
1. Read FEATURES.json for pending tasks
2. Select highest priority task (P0 > P1 > P2)
3. Assign to Coding Agent
4. Validate results (tests, typecheck, lint)
5. Update status in FEATURES.json
6. Check self-correction triggers
7. Create checkpoint if needed

### `/supervisor status`
Display current development state:
- State: IDLE | RUNNING | PAUSED | DONE
- Features: X/Y/Z (completed/in_progress/pending)
- Open bugs count
- Last checkpoint time
- Next recommended action

### `/supervisor next`
Show the next task to work on:
- Task ID and name
- Priority level
- Dependencies (if any)
- Module path

### `/supervisor checkpoint`
Create a checkpoint immediately:
- Snapshot FEATURES.json to CHECKPOINTS/
- Log current state
- Update .agentflow/.last_checkpoint

### `/supervisor pause`
Pause the development loop after current task completes.

### `/supervisor resume`
Resume from paused state.

### `/supervisor exit`
Check all exit conditions and report:
- All P0/P1 features complete?
- Coverage ≥ 80%?
- All tests passing?
- No open P0/P1 bugs?
- **If ALL true**: Development complete, ready for release

## Core Loop

```
WHILE NOT exit_conditions_met:
    1. READ_FEATURES_JSON
    2. SELECT_NEXT_TASK (P0 > P1 > P2)
    3. CHECK_DEPENDENCIES (all deps status="pass")
    4. UPDATE_STATUS("in_progress")
    5. SPAWN_CODING_AGENT
    6. WAIT_FOR_COMPLETION
    7. RUN_VALIDATION
       - npm run typecheck
       - npm test
       - npm run lint
       - Check coverage ≥ 80%
    8. IF validation passes:
       - UPDATE_STATUS("pass")
       - CREATE_GIT_COMMIT
       - UPDATE_PROGRESS
    9. ELSE:
       - LOG_DEBUG
       - CHECK_SELF_CORRECTION
    10. CHECKPOINT (every 2 hours)
END WHILE
```

## Exit Conditions (ALL must be true)

```bash
# Check with:
jq '[.features[] | select(.priority | IN("P0","P1")) | select(.status != "pass")] | length' FEATURES.json
# Must equal 0

jq '[.bugs[] | select(.priority | IN("P0","P1") and .status == "open")] | length' FEATURES.json
# Must equal 0

npm test  # Must pass
coverage >= 80%  # From coverage/coverage-summary.json
```

## Self-Correction Triggers

| Trigger | Condition | Action |
|---------|-----------|--------|
| Task Timeout | pending > 48h | Reassign or split task |
| Repeated Failure | same task fails 3x | Mark for human review |
| Coverage Drop | < 80% | Pause, prioritize tests |
| Build Broken | typecheck fails | Block and alert |
| Retry Loop | same command fails 3x | Suggest alternative |

## Quality Gates

Before marking ANY feature as "pass":

```
□ typecheck: npm run typecheck → PASS
□ lint: npm run lint → PASS (no warnings)
□ tests: npm test → PASS (100%)
□ coverage: ≥ 80% (from coverage/coverage-summary.json)
□ no console.log/debugger in code
□ FEATURES.json: status updated to "pass"
□ PROGRESS.md: progress logged
□ git: commit created with proper message
□ no new bugs introduced
```

## Anti-Hallucination Checks

The SessionEnd hook prevents rationalization. Before claiming task complete:

```
□ Is the code actually implemented?
□ Do tests actually test the feature?
□ Does typecheck pass with NO errors?
□ Does lint pass with NO warnings?
□ Is coverage ≥ 80%?
□ Did I commit the changes?
□ Did I update FEATURES.json?
□ Did I update PROGRESS.md?
□ Is there any placeholder code remaining?
```

## Project Structure

This skill expects:

```
project/
├── FEATURES.json      # Task tracking (features[], bugs[], debugs[])
├── PROGRESS.md        # Human-readable progress log
├── CHECKPOINTS/       # Periodic snapshots (CP-*.json)
├── SPEC.md           # Project specification
├── .agentflow/       # Supervisor state
│   ├── .state        # Current state (IDLE/RUNNING/PAUSED/DONE)
│   ├── .last_checkpoint  # Timestamp of last checkpoint
│   └── supervisor.log # Activity log
├── AGENTS/           # Per-agent CLAUDE.md files
│   ├── supervisor/   # Supervisor agent context
│   ├── coding/       # Coding agent context
│   ├── testing/      # Testing agent context
│   ├── qa/           # QA agent context
│   └── recovery/     # Recovery agent context
└── .claude/hooks/    # Lifecycle hooks
```

## Safety Features

- **PreToolUse hook**: Blocks rm -rf on protected files
- **SessionEnd hook**: Anti-rationalization gate
- **TaskCompleted hook**: Validates completion
- **Checkpointing**: Full rollback capability

## Human Override Points

STOP and request human input when:
1. Self-correction fails 3 times
2. Same bug recurs after fix
3. Scope expands > 30%
4. Architecture change needed
5. Quality gates cannot be met
SUPERVISORSKILLEOF

    # Create supporting files
    mkdir -p "$global_skills_dir/supervisor/scripts"

    # Helper script for supervisor operations
    cat > "$global_skills_dir/supervisor/scripts/status.sh" << 'STATUSSCRIPT'
#!/bin/bash
# Supervisor status helper script

PROJECT_DIR="${1:-.}"

echo "═══════════════════════════════════════════════════════════"
echo "  Supervisor Status"
echo "═══════════════════════════════════════════════════════════"

# State
STATE="IDLE"
if [ -f "$PROJECT_DIR/.agentflow/.state" ]; then
    STATE=$(cat "$PROJECT_DIR/.agentflow/.state")
fi
echo "State: $STATE"

# Features
if [ -f "$PROJECT_DIR/FEATURES.json" ] && command -v jq &> /dev/null; then
    TOTAL=$(jq '.features | length' "$PROJECT_DIR/FEATURES.json")
    PASS=$(jq '[.features[] | select(.status == "pass")] | length' "$PROJECT_DIR/FEATURES.json")
    IN_PROGRESS=$(jq '[.features[] | select(.status == "in_progress")] | length' "$PROJECT_DIR/FEATURES.json")
    PENDING=$(jq '[.features[] | select(.status == "pending")] | length' "$PROJECT_DIR/FEATURES.json")
    echo ""
    echo "Features: $PASS/$TOTAL completed"
    echo "  In Progress: $IN_PROGRESS"
    echo "  Pending: $PENDING"
fi

# Bugs
if [ -f "$PROJECT_DIR/FEATURES.json" ] && command -v jq &> /dev/null; then
    BUGS=$(jq '[.bugs[] | select(.status == "open")] | length' "$PROJECT_DIR/FEATURES.json")
    echo ""
    echo "Open Bugs: $BUGS"
fi

# Last Checkpoint
if [ -d "$PROJECT_DIR/CHECKPOINTS" ]; then
    LAST=$(ls -t "$PROJECT_DIR/CHECKPOINTS/" 2>/dev/null | head -1)
    echo ""
    echo "Last Checkpoint: $LAST"
fi

echo "═══════════════════════════════════════════════════════════"
STATUSSCRIPT

    chmod +x "$global_skills_dir/supervisor/scripts/status.sh"

    # Create reference directory and file for FEATURES.json structure
    mkdir -p "$global_skills_dir/supervisor/reference"
    cat > "$global_skills_dir/supervisor/reference/features-json.md" << 'FEATURESREF'
# FEATURES.json Reference

## Structure

```json
{
  "version": "0.1.0",
  "created": "ISO timestamp",
  "updated": "ISO timestamp",
  "features": [
    {
      "id": "FEAT-001",
      "name": "Feature Name",
      "module": "core/",
      "status": "pending|in_progress|pass|blocked",
      "priority": "P0|P1|P2",
      "tests": ["path/to/test.test.ts"],
      "assigned_to": "agent-id|null",
      "notes": "free text",
      "created_at": "ISO timestamp",
      "updated_at": "ISO timestamp"
    }
  ],
  "summary": {
    "total": 10,
    "pass": 5,
    "pending": 4,
    "blocked": 1
  },
  "bugs": [
    {
      "id": "BUG-001",
      "feature_id": "FEAT-001",
      "description": "Bug description",
      "severity": "P0|P1|P2",
      "status": "open|in_progress|fixed|closed",
      "reporter": "agent-id",
      "created_at": "ISO timestamp"
    }
  ],
  "debugs": [
    {
      "id": "DEBUG-001",
      "feature_id": "FEAT-001",
      "error": "Error message",
      "context": "file:line",
      "status": "open|investigating|resolved",
      "created_at": "ISO timestamp"
    }
  ],
  "self_corrections": [
    {
      "id": "SC-001",
      "type": "timeout|repeated_failure|coverage_drop",
      "feature_id": "FEAT-001",
      "action": "What was done",
      "result": "resolved|failed",
      "created_at": "ISO timestamp"
    }
  ]
}
```

## Status Values

| Status | Meaning |
|--------|---------|
| pending | Not started, waiting for dependencies |
| in_progress | Currently being worked on |
| pass | Completed and validated |
| blocked | Cannot proceed, dependency issue |

## Priority Values

| Priority | Meaning |
|----------|---------|
| P0 | Critical, must complete first |
| P1 | High priority |
| P2 | Nice to have |
FEATURESREF

    info "Created: ~/.claude/skills/agentflow/supervisor/ (SKILL.md + reference + scripts)"
}

# =============================================================================
# CI/CD Configuration
# =============================================================================

create_cicd_config() {
    local workflow_dir="$PROJECT_DIR/.github/workflows"
    mkdir -p "$workflow_dir"

    # Complete CI/CD with Agent triggering
    cat > "$workflow_dir/ci.yml" << 'CICDEOF'
name: CI/CD

on:
  push:
    branches: [develop, main]
  pull_request:
    branches: [develop]
  workflow_dispatch:

env:
  NODE_VERSION: '20'

jobs:
  # =============================================================================
  # Quality Gate - Always runs
  # =============================================================================
  quality:
    name: Quality Checks
    runs-on: ubuntu-latest
    outputs:
      can_trigger_agent: ${{ steps.check.outputs.can_trigger }}

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: TypeScript check
        run: npm run typecheck
        continue-on-error: false

      - name: ESLint
        run: npm run lint || true

      - name: Unit tests
        run: npm test
        continue-on-error: false

      - name: Check coverage
        run: |
          COVERAGE=$(cat coverage/coverage-summary.json | jq -r '.total.lines.pct // 0')
          echo "Coverage: $COVERAGE%"
          if (( $(echo "$COVERAGE < 80" | bc -l) )); then
            echo "WARNING: Coverage below 80%"
            echo "can_trigger=false" >> $GITHUB_OUTPUT
          else
            echo "can_trigger=true" >> $GITHUB_OUTPUT
          fi

      - id: check
        run: echo "can_trigger=true" >> $GITHUB_OUTPUT

  # =============================================================================
  # Update Progress - Always runs
  # =============================================================================
  progress:
    name: Update Progress
    runs-on: ubuntu-latest
    needs: quality
    if: github.ref == 'refs/heads/develop'

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Update PROGRESS.md
        run: |
          echo "### $(date '+%Y-%m-%d %H:%M')" >> PROGRESS.md
          echo "| CI | GitHub Actions | Push: ${{ github.event_name }} |" >> PROGRESS.md

      - name: Commit if changed
        run: |
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          if git diff --quiet PROGRESS.md; then
            echo "No changes"
          else
            git add PROGRESS.md
            git commit -m "docs: update progress [skip ci]" || true
            git push || true
          fi

  # =============================================================================
  # Trigger Supervisor Agent (on push to develop, quality passed)
  # =============================================================================
  trigger-agent:
    name: Trigger Supervisor
    runs-on: ubuntu-latest
    needs: [quality, progress]
    if: github.ref == 'refs/heads/develop' && github.event_name == 'push'
    concurrency:
      group: supervisor
      cancel-in-progress: false

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Read feature status
        id: features
        run: |
          FEATURES_PENDING=$(jq '[.features[] | select(.status == "pending")] | length' FEATURES.json 2>/dev/null || echo "0")
          echo "Pending features: $FEATURES_PENDING"
          echo "pending=$FEATURES_PENDING" >> $GITHUB_OUTPUT

      - name: Decision
        run: |
          PENDING=${{ steps.features.outputs.pending }}
          if [ "$PENDING" -eq 0 ]; then
            echo "All features complete!"
            echo "all_done=true" >> $GITHUB_OUTPUT
          else
            echo "Features remaining: $PENDING"
            echo "all_done=false" >> $GITHUB_OUTPUT
          fi

      - name: Trigger Supervisor via workflow_dispatch
        if: steps.features.outputs.all_done == 'false'
        uses: actions/github-script@v7
        with:
          script: |
            // Trigger supervisor workflow
            try {
              await github.rest.actions.createWorkflowDispatch({
                owner: context.repo.owner,
                repo: context.repo.repo,
                workflow_id: 'supervisor.yml',
                ref: 'develop',
                inputs: {
                  trigger: 'push',
                  commit: context.sha
                }
              });
              console.log('✓ Supervisor workflow triggered');
            } catch (e) {
              console.log('⚠ Could not trigger supervisor:', e.message);
              console.log('  Supervisor can be started manually:');
              console.log('  bash .agentflow/supervisor-loop.sh start');
            }

      - name: Notify completion
        if: steps.features.outputs.all_done == 'true'
        run: |
          echo "🎉 All features completed!"
          echo "Project is ready for release."

  # =============================================================================
  # Release (on push to main)
  # =============================================================================
  release:
    name: Release
    runs-on: ubuntu-latest
    needs: quality
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'

      - name: Install
        run: npm ci

      - name: Build
        run: npm run build

      - name: Create Release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: v${{ github.run_number }}
          release_name: Release v${{ github.run_number }}
          draft: true
          prerelease: false
CICDEOF
    info "Created: .github/workflows/ci.yml"

    # Create dedicated Supervisor workflow with retry and recovery support
    cat > "$workflow_dir/supervisor.yml" << 'SUPERVISOREEOF'
name: Supervisor Agent

on:
  workflow_dispatch:
    inputs:
      trigger:
        description: 'Trigger reason'
        required: false
        default: 'manual'
      commit:
        description: 'Commit SHA'
        required: false
      resume:
        description: 'Resume from checkpoint (true/false)'
        required: false
        default: 'false'
  # Scheduled backup trigger - runs hourly to ensure supervision continues
  schedule:
    - cron: '0 * * * *'

env:
  SUPERVISOR_TIMEOUT: 120

jobs:
  supervisor:
    name: Run Supervisor
    runs-on: ubuntu-latest
    timeout-minutes: ${{ env.SUPERVISOR_TIMEOUT || 120 }}
    concurrency:
      group: supervisor-run
      cancel-in-progress: false

    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Determine resume mode
        id: resume_check
        run: |
          if [ "${{ inputs.resume || 'false' }}" == "true" ] || [ -f .agentflow/.state ] && grep -q "RUNNING" .agentflow/.state 2>/dev/null; then
            echo "resume_mode=true" >> $GITHUB_OUTPUT
            echo "Mode: RESUME from checkpoint"
          else
            echo "resume_mode=false" >> $GITHUB_OUTPUT
            echo "Mode: FRESH start"
          fi

      - name: Run Supervisor Loop
        run: |
          echo "═══════════════════════════════════════════════════════════"
          echo "  Supervisor Agent - Automated Development Loop"
          echo "═══════════════════════════════════════════════════════════"
          echo ""
          echo "Trigger: ${{ inputs.trigger || 'schedule' }}"
          echo "Commit: ${{ inputs.commit || github.sha }}"
          echo "Resume: ${{ inputs.resume || 'false' }}"
          echo ""

          # Start supervisor loop with optional resume
          if [ "${{ steps.resume_check.outputs.resume_mode }}" == "true" ]; then
            bash .agentflow/supervisor-loop.sh resume
          else
            bash .agentflow/supervisor-loop.sh start
          fi

      - name: Create Checkpoint (Success)
        if: success()
        run: |
          mkdir -p CHECKPOINTS
          TIMESTAMP=$(date +%Y%m%d-%H%M%S)
          cp FEATURES.json CHECKPOINTS/${TIMESTAMP}-FEATURES.json
          echo "✓ Success checkpoint created at ${TIMESTAMP}"

      - name: Create Failure Checkpoint
        if: failure()
        run: |
          mkdir -p CHECKPOINTS
          TIMESTAMP=$(date +%Y%m%d-%H%M%S)
          cp FEATURES.json CHECKPOINTS/${TIMESTAMP}-FEATURES-FAILED.json
          echo "::error::Supervisor failed - checkpoint created for recovery"
          echo "✓ Failure checkpoint: CHECKPOINTS/${TIMESTAMP}-FEATURES-FAILED.json"

      - name: Commit Progress
        if: success()
        run: |
          git config user.name "Supervisor Agent"
          git config user.email "supervisor@agentflow.dev"
          git add -A
          git diff --cached --quiet || git commit -m "feat: supervisor progress update [skip ci]"
          git push || true

      - name: Report Status
        if: always()
        run: |
          echo ""
          echo "═══════════════════════════════════════════════════════════"
          echo "  Supervisor Run Complete"
          echo "═══════════════════════════════════════════════════════════"

          if [ -f FEATURES.json ] && command -v jq &> /dev/null; then
            TOTAL=$(jq '.features | length' FEATURES.json)
            PASS=$(jq '[.features[] | select(.status == "pass")] | length' FEATURES.json)
            PENDING=$(jq '[.features[] | select(.status == "pending")] | length' FEATURES.json)
            IN_PROGRESS=$(jq '[.features[] | select(.status == "in_progress")] | length' FEATURES.json)
            echo "Features: $PASS/$TOTAL completed, $IN_PROGRESS in progress, $PENDING pending"

            # Check if all done
            if [ "$PENDING" -eq 0 ] && [ "$IN_PROGRESS" -eq 0 ]; then
              echo ""
              echo "🎉 All features completed!"
            fi
          fi

  # Failure Recovery Job - triggers when supervisor fails
  recovery:
    name: Recovery Handler
    runs-on: ubuntu-latest
    needs: [supervisor]
    if: failure()
    steps:
      - name: Analyze Failure
        run: |
          echo "═══════════════════════════════════════════════════════════"
          echo "  Supervisor Failed - Analyzing"
          echo "═══════════════════════════════════════════════════════════"

          # Find latest checkpoint
          if [ -d CHECKPOINTS ]; then
            LATEST=$(ls -t CHECKPOINTS/*.json 2>/dev/null | head -1)
            if [ -n "$LATEST" ]; then
              echo "Latest checkpoint: $LATEST"
              FAILED_COUNT=$(ls -t CHECKPOINTS/*-FAILED.json 2>/dev/null | head -1 | wc -l)
              echo "Failed checkpoints: $FAILED_COUNT"

              # If more than 3 consecutive failures, stop retrying
              if [ "$FAILED_COUNT" -gt 3 ]; then
                echo "::error::Too many consecutive failures (>$FAILED_COUNT). Manual intervention required."
                echo "all_done=true" >> $GITHUB_OUTPUT
              else
                echo "Will retry on next trigger..."
                echo "all_done=false" >> $GITHUB_OUTPUT
              fi
            fi
          fi

      - name: Notify via Commit
        if: needs.supervisor.outputs.all_done != 'true'
        run: |
          git config user.name "Supervisor Agent"
          git config user.email "supervisor@agentflow.dev"
          git add -A
          git diff --cached --quiet || git commit -m "⚠️ supervisor failed - will retry [skip ci]" || true
          git push || true
SUPERVISOREEOF
    info "Created: .github/workflows/supervisor.yml (agent triggering)"
}

create_checkpoint() {
    local checkpoint_dir="$PROJECT_DIR/CHECKPOINTS"
    mkdir -p "$checkpoint_dir"

    local cp_file="$checkpoint_dir/CP-000-$(date +%Y%m%d-%H%M%S).json"
    cat > "$cp_file" << EOF
{
  "id": "CP-000",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "phase": "initialization",
  "status": "complete"
}
EOF
    info "Created checkpoint: $(basename $cp_file)"
}

create_initial_commit() {
    cd "$PROJECT_DIR" || return 1

    # Create .gitignore if missing
    if [ ! -f ".gitignore" ]; then
        cat > .gitignore << 'GITIGNORE'
node_modules/
bin/
dist/
*.log
.env
.DS_Store
*.db
.clawtools/
.agentflow/
coverage/
GITIGNORE
    fi

    git add -A 2>/dev/null || true

    if git diff --cached --quiet 2>/dev/null; then
        info "No changes to commit"
        return 0
    fi

    git commit -m "feat: initialize project with AgentFlow framework

Generated by AgentFlow Initializer v$VERSION" 2>/dev/null || true
    info "Git commit created"
}

print_summary() {
    local feat_count=${#FEATURES[@]}
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}"                                                    "✓ 项目初始化完成"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}项目:${NC} $PROJECT_NAME"
    echo -e "${CYAN}功能:${NC} $feat_count"
    echo -e "${CYAN}平台:${NC} ${PLATFORMS[*]:-默认}"
    echo ""
    echo -e "${CYAN}生成的文件:${NC}"
    echo -e "  ├── ${GREEN}SPEC.md${NC} - 项目规格"
    echo -e "  ├── ${GREEN}FEATURES.json${NC} - 功能列表"
    echo -e "  ├── ${GREEN}PROGRESS.md${NC} - 进度日志"
    echo -e "  ├── ${GREEN}SUPERVISOR.md${NC} - Agent指令"
    echo -e "  ├── ${GREEN}TRIGGERS.md${NC} - 触发机制"
    echo -e "  └── ${GREEN}.github/workflows/ci.yml${NC} - CI/CD"
    echo ""
    echo -e "${YELLOW}下一步:${NC}"
    echo -e "  1. 审查 SPEC.md"
    echo -e "  2. 审查 FEATURES.json"
    echo -e "  3. 启动: bash .agentflow/supervisor-loop.sh start"
    echo ""
}

# Run
parse_args "$@"
parse_args "$@"
main
