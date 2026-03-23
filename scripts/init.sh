#!/bin/bash
# =============================================================================
# AgentFlow Initializer - v2.0
# Intelligent project initialization with automatic SPEC and FEATURES generation
#
# Usage:
#   bash init.sh                           # Interactive mode
#   bash init.sh --name "MyProject"        # Quick mode with args
#   bash init.sh --file REQUIREMENTS.md    # File-based mode
# =============================================================================

set -e

readonly VERSION="2.0"

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
AgentFlow Initializer v2.0

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
  --help, -h            Show this help

Examples:
  # Interactive mode
  bash init.sh --interactive

  # Quick start with arguments
  bash init.sh --name "MyCLI" --desc "A useful CLI tool" --type cli-tool --stack "Node.js,TypeScript"

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
    echo '```'"
echo 'project/'
echo '├── cli/              # 命令行界面'
echo '│   └── index.tsx     # TUI入口'
echo '├── core/             # 核心业务逻辑'
echo '│   └── index.ts      # 核心模块'
echo '├── config/           # 配置'
echo '├── db/               # 数据库层'
echo '├── i18n/             # 国际化'
echo '├── tests/            # 测试'
echo '│   ├── unit/         # 单元测试'
echo '│   └── e2e/          # 端到端测试'
echo '├── docs/             # 文档'
echo '├── scripts/          # 脚本'
echo '└── package.json'
echo '```'
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
    }FEATUREEOF

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

    # Check if we have all required info
    if [ -z "$PROJECT_NAME" ] || [ -z "$PROJECT_DESC" ]; then
        if [ "$INTERACTIVE_MODE" = yes ] || [ -t 0 ]; then
            run_interactive
        else
            error "Missing required arguments. Use --interactive or provide --name and --desc"
            error "Or run without arguments for interactive mode"
            exit 1
        fi
    fi

    # Ensure project directory exists
    mkdir -p "$PROJECT_DIR"

    cd "$PROJECT_DIR" || exit 1

    # Check if already initialized
    if [ -f "SPEC.md" ] && [ -f "FEATURES.json" ]; then
        warn "Project already initialized (SPEC.md and FEATURES.json exist)"
        if confirm "覆盖现有文件?"; then
            info "Overwriting existing files..."
        else
            info "Keeping existing files, skipping generation"
            return
        fi
    fi

    section "Generating Project Artifacts"

    generate_spec
    generate_features_json
    generate_progress

    section "Project Created"

    echo -e "${GREEN}✓ 项目初始化完成！${NC}"
    echo ""
    echo -e "${CYAN}项目名称:${NC} $PROJECT_NAME"
    echo -e "${CYAN}功能数量:${NC} ${#FEATURES[@]}"
    echo -e "${CYAN}技术栈:${NC} ${TECH_STACK[*]:-默认}"
    echo ""
    echo -e "${CYAN}生成的文件:${NC}"
    echo -e "  ├── ${GREEN}SPEC.md${NC} - 项目规格说明书"
    echo -e "  ├── ${GREEN}FEATURES.json${NC} - 功能追踪列表"
    echo -e "  └── ${GREEN}PROGRESS.md${NC} - 进度日志"
    echo ""
    echo -e "${YELLOW}下一步:${NC}"
    echo -e "  1. 审查 SPEC.md 确认项目目标"
    echo -e "  2. 审查 FEATURES.json 确认功能范围"
    echo -e "  3. 启动开发: bash .agentflow/supervisor-loop.sh start"
    echo ""
}

# Run
parse_args "$@"
main
