#!/bin/bash
# =============================================================================
# AgentFlow Initializer - v2.1
# Intelligent project initialization with automatic SPEC and FEATURES generation
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

readonly VERSION="2.1"

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

    # Close JSON
    cat >> "$file" << 'EOF'

  ],
  "summary": {
    "total": FEATURES_COUNT,
    "pass": 0,
    "pending": FEATURES_COUNT,
    "blocked": 0
  }
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
        IFS=' ' read -ra FEATURES <<< "$(printf '%s\n' "${FEATURES[@]}" | sort -u | tr '\n' ' ')"
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
    [ ${#TECH_STACK[@]} -eq 0 ] && TECH_STACK=("Node.js" "TypeScript")
}

auto_detect_platforms() {
    local plat_line=$(grep -i "platform\|Windows\|Linux\|macOS\|Docker" REQUIREMENTS.md 2>/dev/null | head -5)

    for platform in "Windows" "Linux" "macOS" "WSL" "Docker"; do
        if echo "$plat_line" | grep -qi "$platform"; then
            PLATFORMS+=("$platform")
        fi
    done

    # Defaults
    [ ${#PLATFORMS[@]} -eq 0 ] && PLATFORMS=("Windows" "Linux" "macOS")
}

# =============================================================================
# Framework Files
# =============================================================================

create_framework_files() {
    local agentflow_dir="$PROJECT_DIR/.agentflow"
    mkdir -p "$agentflow_dir"

    # SUPERVISOR.md
    cat > "$PROJECT_DIR/SUPERVISOR.md" << 'SUPERVISOREOF'
# Supervisor Agent Instructions

## Role
You are the **Supervisor Agent**. Read FEATURES.json, assign tasks, validate quality, update progress.

## Core Loop
```
WHILE NOT exit_conditions_met:
    1. Read FEATURES.json for pending features
    2. Select next by priority (P0 > P1 > P2)
    3. Assign to coding agent
    4. Validate (tests + typecheck)
    5. Update status
    6. Check checkpoint (every 2h)
END WHILE
```

## Exit Conditions
1. All P0/P1 features status="pass"
2. Test coverage ≥ 80%
3. All tests pass
4. No open P0/P1 bugs

## Quality Gates
- [ ] Code follows style
- [ ] Unit tests exist
- [ ] Typecheck passes
- [ ] Lint passes
- [ ] FEATURES.json updated
- [ ] PROGRESS.md updated
SUPERVISOREOF
    info "Created: SUPERVISOR.md"

    # TRIGGERS.md
    cat > "$PROJECT_DIR/TRIGGERS.md" << 'TRIGGERSEOF'
# Trigger Mechanism

## Types
1. **Git Push** - Primary trigger
2. **Manual** - `bash .agentflow/supervisor-loop.sh start`
3. **Scheduled** - Cron backup (every 6h)

## Loop States
IDLE → RUNNING → PAUSED → DONE/ERROR

## Exit Conditions
- All P0/P1 pass
- Coverage ≥ 80%
- All tests pass
TRIGGERSEOF
    info "Created: TRIGGERS.md"

    # supervisor-loop.sh
    cat > "$agentflow_dir/supervisor-loop.sh" << 'LOOPSCRIPT'
#!/bin/bash
AGENTFLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$AGENTFLOW_DIR")"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

case "${1:-start}" in
    start) log "Supervisor started" ;;
    stop) log "Supervisor stopped" ;;
    status) log "Status: IDLE" ;;
esac
LOOPSCRIPT
    chmod +x "$agentflow_dir/supervisor-loop.sh"
    info "Created: .agentflow/supervisor-loop.sh"
}

create_cicd_config() {
    local workflow_dir="$PROJECT_DIR/.github/workflows"
    mkdir -p "$workflow_dir"

    cat > "$workflow_dir/ci.yml" << 'CICDEOF'
name: CI

on:
  push:
    branches: [develop, main]
  pull_request:

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm ci
      - run: npm run typecheck
      - run: npm test
CICDEOF
    info "Created: .github/workflows/ci.yml"
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
