#!/bin/bash
# =============================================================================
# AgentFlow Initializer - v1.0
# A reusable framework for initializing long-running agent development projects
# Based on Anthropic's "Effective Harnesses for Long-Running Agents"
#
# This script creates the complete infrastructure for automated agent development:
# 1. Project scaffolding
# 2. Supervisor Agent instructions (with loop & exit conditions)
# 3. Trigger mechanism design
# 4. CI/CD configuration
# =============================================================================

set -e

# =============================================================================
# Configuration
# =============================================================================

readonly SCRIPT_VERSION="1.0"
readonly AGENTFLOW_VERSION="1.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# =============================================================================
# Helper Functions
# =============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${BLUE}[${timestamp}]${NC} [${level}] $message"
}

log_info()    { log "${CYAN}INFO${NC}" "$@"; }
log_success() { log "${GREEN}SUCCESS${NC}" "$@"; }
log_warning() { log "${YELLOW}WARNING${NC}" "$@"; }
log_error()   { log "${RED}ERROR${NC}" "$@"; }

section() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  $1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 is not installed"
        return 1
    fi
    return 0
}

create_directory() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        log_info "Created: $dir"
    fi
}

# =============================================================================
# Main
# =============================================================================

main() {
    local project_dir="${1:-.}"

    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}"                                                                  "  AgentFlow Initializer v${SCRIPT_VERSION}"
    echo -e "${CYAN}║${NC}"                                          "Reusable Framework for Long-Running Agents"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Step 1: Check prerequisites
    section "Step 1: Checking Prerequisites"
    check_prerequisites

    # Step 2: Create directory structure
    section "Step 2: Creating Directory Structure"
    create_directory_structure "$project_dir"

    # Step 3: Create Git infrastructure
    section "Step 3: Initializing Git"
    init_git "$project_dir"

    # Step 4: Create core artifacts
    section "Step 4: Creating Core Artifacts"
    create_artifacts "$project_dir"

    # Step 5: Create Supervisor Agent instructions
    section "Step 5: Creating Supervisor Agent Instructions"
    create_supervisor_instructions "$project_dir"

    # Step 6: Create trigger mechanism
    section "Step 6: Creating Trigger Mechanism"
    create_trigger_mechanism "$project_dir"

    # Step 7: Create CI/CD configuration
    section "Step 7: Creating CI/CD Configuration"
    create_cicd_config "$project_dir"

    # Step 8: Create checkpoint
    section "Step 8: Creating Initial Checkpoint"
    create_checkpoint "$project_dir"

    # Step 9: Initial commit
    section "Step 9: Creating Initial Commit"
    create_initial_commit "$project_dir"

    # Summary
    print_summary "$project_dir"
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
        log_error "Missing prerequisites"
        exit 1
    fi

    log_success "All prerequisites met"
}

create_directory_structure() {
    local base="$1"
    local dirs=(
        "$base/.github/workflows"
        "$base/.agentflow"
        "$base/CHECKPOINTS"
        "$base/TESTS/unit"
        "$base/TESTS/e2e"
    )

    for dir in "${dirs[@]}"; do
        create_directory "$dir"
    done

    log_success "Directory structure created"
}

init_git() {
    local base="$1"
    cd "$base"

    if [ ! -d ".git" ]; then
        log_info "Initializing git repository..."
        git init
        git checkout -b develop 2>/dev/null || git branch -M develop
        log_success "Git repository initialized"
    else
        log_info "Git repository already exists"
    fi
}

create_artifacts() {
    local base="$1"
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    # Create SPEC.md
    create_spec_md "$base" "$timestamp"

    # Create FEATURES.json
    create_features_json "$base" "$timestamp"

    # Create PROGRESS.md
    create_progress_md "$base" "$timestamp"

    # Create README if not exists
    if [ ! -f "$base/README.md" ]; then
        create_readme "$base"
    fi

    log_success "Core artifacts created"
}

create_spec_md() {
    local base="$1"
    local timestamp="$2"
    local spec_file="$base/SPEC.md"

    if [ -f "$spec_file" ]; then
        log_info "SPEC.md already exists, skipping"
        return
    fi

    cat > "$spec_file" << SPECEOF
# Project Specification

## Metadata
- **Project Name**: $(basename "$base")
- **Version**: 0.1.0
- **Created**: ${timestamp}
- **Last Updated**: ${timestamp}

## 1. Project Overview
[Describe the project purpose and goals]

## 2. Technical Stack
[List the technical stack]

## 3. Architecture
[Describe the system architecture]

## 4. Functionality
[Describe core functionality]

## 5. Quality Standards
- Test coverage ≥ 80%
- All public APIs have TypeScript types
- Pass linting
- All commits pass typecheck

## 6. Exit Criteria
Project is complete when:
1. All P0/P1 features have status="pass" in FEATURES.json
2. Test coverage ≥ 80%
3. All tests pass
4. No open P0/P1 bugs

## 7. Supervisor Loop
See SUPERVISOR.md for the agent execution loop.
SPECEOF

    log_info "Created: SPEC.md"
}

create_features_json() {
    local base="$1"
    local timestamp="$2"
    local features_file="$base/FEATURES.json"

    if [ -f "$features_file" ]; then
        log_info "FEATURES.json already exists, skipping"
        return
    fi

    cat > "$features_file" << FEATURESEOF
{
  "version": "0.1.0",
  "created": "${timestamp}",
  "updated": "${timestamp}",
  "features": [],
  "summary": {
    "total": 0,
    "pass": 0,
    "pending": 0,
    "blocked": 0
  },
  "_template": {
    "feature": {
      "id": "unique-id",
      "name": "Feature name",
      "module": "path/to/module",
      "status": "pending",
      "priority": "P0|P1|P2",
      "tests": [],
      "assigned_to": null,
      "notes": ""
    }
  }
}
FEATURESEOF

    log_info "Created: FEATURES.json"
}

create_progress_md() {
    local base="$1"
    local timestamp="$2"
    local progress_file="$base/PROGRESS.md"

    if [ -f "$progress_file" ]; then
        log_info "PROGRESS.md already exists, skipping"
        return
    fi

    cat > "$progress_file" << PROGRESSEOF
# Development Progress

## Project Info
- **Project**: $(basename "$base")
- **Init Date**: ${timestamp}
- **Current Phase**: Init

## Phases
### Phase 0: Initialization
- [x] Run init.sh - ${timestamp}
- [x] Create artifacts
- [x] Setup CI/CD

### Phase 1: Development
- [ ] [In progress]

### Phase 2: Testing
- [ ]

### Phase 3: Release
- [ ]

## Sprint
**Current Sprint**: Sprint 1
**Goal**: Complete core functionality
**Status**: Not started

## Log

### ${timestamp} - Initialization
| Time | Action | Agent |
|------|--------|-------|
| ${timestamp} | Project initialized | init.sh |

## Blockers
None

## Pending Reviews
None

## Checkpoints
| ID | Date | Status | Summary |
|----|------|--------|---------|
| CP-000 | ${timestamp} | Init | Project initialized |

## Statistics
- **Total Features**: 0
- **Completed**: 0
- **In Progress**: 0
- **Pending**: 0
- **Completion**: 0%

---
*Auto-maintained by AgentFlow Framework*
PROGRESSEOF

    log_info "Created: PROGRESS.md"
}

create_readme() {
    local base="$1"

    cat > "$base/README.md" << READMEEOF
# $(basename "$base")

## Project Status
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

## Overview
[Describe the project]

## Quick Start
\`\`\`bash
# Development
npm install
npm run dev

# Build
npm run build

# Test
npm test
\`\`\`

## Documentation
- [SPEC.md](./SPEC.md) - Project specification
- [FEATURES.json](./FEATURES.json) - Feature tracking
- [SUPERVISOR.md](./SUPERVISOR.md) - Agent instructions

## License
MIT
READMEEOF

    log_info "Created: README.md"
}

# =============================================================================
# Supervisor Agent Instructions
# =============================================================================

create_supervisor_instructions() {
    local base="$1"
    local supervisor_file="$base/SUPERVISOR.md"

    cat > "$supervisor_file" << 'SUPERVISOREOF'
# Supervisor Agent Instructions

## Role
You are the **Supervisor Agent** for this project. Your role is to orchestrate the development process by:
1. Reading FEATURES.json to find next task
2. Assigning tasks to coding agents
3. Validating quality (run tests)
4. Updating FEATURES.json status
5. Updating PROGRESS.md
6. Creating checkpoints periodically

## Core Loop

```
WHILE NOT exit_conditions_met:
    1. Read FEATURES.json for pending features
    2. Select next feature by priority (P0 > P1 > P2)
    3. Assign to available coding agent
    4. Wait for agent to complete
    5. Validate quality:
       - Run tests
       - Run typecheck
       - Check lint
    6. IF validation passes:
          - Update FEATURES.json status to "pass"
          - Create git commit
          - Update PROGRESS.md
       ELSE:
          - Update FEATURES.json status to "fail"
          - Record error in PROGRESS.md
          - Assign fix to agent
    7. Check checkpoint timer (every 2 hours)
    8. Check for self-correction needs
END WHILE
```

## Exit Conditions

The loop exits when ALL conditions are met:

```yaml
exit_conditions:
  development_complete:
    description: "All P0/P1 features are pass"
    check: "jq '.features[] | select(.priority | IN(\"P0\",\"P1\")) | select(.status != \"pass\")' FEATURES.json | jq -s length | [ $value -eq 0 ]"

  tests_complete:
    description: "All tests pass with ≥80% coverage"
    check: "npm test && npm run coverage | grep -E 'All files.*[8-9][0-9]%|100%'"

  no_blocking_bugs:
    description: "No open P0/P1 bugs"
    check: "jq '.features[] | select(.status == \"bug\" and .priority | IN(\"P0\",\"P1\"))' FEATURES.json | jq -s length | [ $value -eq 0 ]"
```

## Task Assignment Protocol

When assigning a task to a coding agent:

1. **Check dependencies**: Ensure prerequisite features are "pass"
2. **Provide context**: Share SPEC.md and relevant module code
3. **Set expectations**: Clear output format and test requirements
4. **Set deadline**: Soft deadline of 4 hours for P0, 8 hours for P1

### Assignment Message Template

```
Task: {feature_name}
Feature ID: {feature_id}
Module: {module_path}
Priority: {P0|P1|P2}
Dependencies: {list of dependent feature IDs}

Requirements:
1. Implement feature according to SPEC.md
2. Write unit tests in {test_path}
3. Ensure typecheck passes
4. Ensure lint passes

Output:
1. Updated code in {module_path}
2. Tests in {test_path}
3. Update FEATURES.json status
4. Update PROGRESS.md with progress

Exit: When tests pass and FEATURES.json is updated
```

## Self-Correction Triggers

Automatically trigger self-correction when:

| Trigger | Condition | Action |
|---------|-----------|--------|
| Stuck feature | Feature pending > 48 hours | Reassign or break into smaller tasks |
| Repeated failures | Same feature fails 3x | Review design, potentially revise SPEC.md |
| Quality degradation | Pass rate < 80% over 24h | Pause, review, adjust approach |
| Scope creep | > 30% new features added | Review with human before proceeding |
| Test coverage drop | Coverage < 80% | Prioritize test writing |

## Quality Gates

Before marking a feature as "pass":

- [ ] Code follows project style
- [ ] Unit tests exist and pass
- [ ] Typecheck passes
- [ ] Lint passes
- [ ] FEATURES.json updated
- [ ] PROGRESS.md updated
- [ ] Git commit created

## Checkpoint Protocol

Create a checkpoint every:
- 2 hours of development
- After completing a feature
- Before starting a major new section
- When self-correction is triggered

### Checkpoint Format

\`\`\`json
{
  "id": "CP-{NNN}",
  "timestamp": "{ISO8601}",
  "phase": "{current_phase}",
  "features": {
    "total": {n},
    "pass": {n},
    "pending": {n},
    "blocked": {n}
  },
  "git": {
    "branch": "{branch}",
    "commit": "{hash}",
    "message": "{last_commit_message}"
  },
  "health": {
    "test_coverage": {n},
    "lint_errors": {n},
    "type_errors": {n}
  }
}
\`\`\`

## Progress Reporting

After each feature completion, update PROGRESS.md:

```
### {YYYY-MM-DD HH:MM} - Feature Completion
| Time | Action | Agent | Result |
|------|--------|-------|--------|
| {time} | {feature_name} | {agent_name} | {pass|fail} |
```

## Human Intervention Points

Request human intervention when:
1. Exit conditions are met (for final approval)
2. Self-correction fails 3 times
3. New features requested outside original scope
4. Significant architectural changes needed
5. Blockers that require external decisions

## Artifact Locations

- SPEC.md - Project specification (read only during execution)
- FEATURES.json - Task queue and status (read/write)
- PROGRESS.md - Human-readable progress log (append only)
- CHECKPOINTS/ - Periodic snapshots (create only)

## Supervisor Agent Commands

| Command | Action |
|---------|--------|
| `supervisor:start` | Begin the supervisor loop |
| `supervisor:status` | Print current progress |
| `supervisor:checkpoint` | Create checkpoint now |
| `supervisor:fix {feature_id}` | Reassign feature for fixing |
| `supervisor:pause` | Pause development |
| `supervisor:resume` | Resume development |
| `supervisor:exit` | Check exit conditions |

---
*Generated by AgentFlow Initializer v1.0*
SUPERVISOREOF

    log_info "Created: SUPERVISOR.md"
}

# =============================================================================
# Trigger Mechanism
# =============================================================================

create_trigger_mechanism() {
    local base="$1"
    local triggers_file="$base/TRIGGERS.md"
    local hooks_dir="$base/.git/hooks"

    # Create triggers documentation
    cat > "$triggers_file" << 'TRIGGERSEOF'
# Trigger Mechanism

This document describes how the AgentFlow framework is triggered and executed.

## Trigger Types

### 1. Git Push Trigger (Primary)
Automatically triggers on push to specific branches.

**Setup**: `.github/workflows/ci.yml` handles this.

**Behavior**:
- On push to `develop`: Run tests, if pass → trigger Supervisor
- On push to `main`: Run full CI, create release
- On PR: Run tests, post results as status check

### 2. Manual Trigger
Human can manually trigger the Supervisor.

```bash
# Start supervisor
bash .agentflow/supervisor-loop.sh start

# Stop supervisor
bash .agentflow/supervisor-loop.sh stop

# Check status
bash .agentflow/supervisor-loop.sh status
```

### 3. Scheduled Trigger (Backup)
Cron job as backup to ensure development continues.

**Schedule**: Every 6 hours (if no recent activity)

## Agent Execution Flow

```
┌─────────────────────────────────────────────────────────────┐
│                     Git Push                                │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│              GitHub Actions (CI/CD)                          │
│  1. Checkout code                                           │
│  2. Install dependencies                                    │
│  3. Run tests                                              │
│  4. Run typecheck                                          │
│  5. Check coverage                                         │
└─────────────────────────┬───────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────┐
│           Test Results                                      │
│  ┌─────────────────┐    ┌─────────────────┐                 │
│  │    ALL PASS     │    │    ANY FAIL     │                 │
│  └────────┬────────┘    └────────┬────────┘                 │
│           │                      │                         │
│           ▼                      ▼                         │
│  ┌─────────────────┐    ┌─────────────────┐               │
│  │ Trigger Agent   │    │ Post Results    │               │
│  │ Development     │    │ Fix Required    │               │
│  └─────────────────┘    └─────────────────┘               │
└─────────────────────────────────────────────────────────────┘
```

## Loop Control

The main loop is controlled by `.agentflow/supervisor-loop.sh`:

### Loop States

| State | Description |
|-------|-------------|
| `IDLE` | Waiting for trigger |
| `RUNNING` | Supervisor active |
| `PAUSED` | Manually paused |
| `DONE` | Exit conditions met |
| `ERROR` | Unrecoverable error |

### State Transitions

```
IDLE ──(push/start)──> RUNNING
RUNNING ──(pause)──> PAUSED
PAUSED ──(resume)──> RUNNING
RUNNING ──(exit conditions)──> DONE
RUNNING ──(error)──> ERROR
ERROR ──(fix)──> RUNNING
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `AGENTFLOW_MODE` | `auto` | `auto` or `manual` |
| `AGENTFLOW_INTERVAL` | `3600` | Loop check interval (seconds) |
| `AGENTFLOW_MAX_HOURS` | `48` | Max hours per feature |
| `AGENTFLOW_CHECKPOINT_Hours` | `2` | Hours between checkpoints |

## Monitoring

Monitor the loop via:

1. **PROGRESS.md** - Human-readable progress
2. **FEATURES.json** - Machine-readable status
3. **Git log** - Agent commits with messages
4. **GitHub Actions** - CI/CD results

## Alert Conditions

The loop pauses and alerts human when:

- Test coverage drops below 70%
- Same feature fails 3 times
- No progress for 24 hours
- Blocked features > 5

## External Integrations

### GitHub Issues Integration
When a feature fails 3 times, automatically create GitHub issue:

```json
{
  "title": "[Agent] Feature {id} repeatedly failing",
  "body": "Feature has failed 3 times. Requires human review.",
  "labels": ["bug", "agent-blocked"]
}
```

---
*Generated by AgentFlow Initializer v1.0*
TRIGGERSEOF

    # Create supervisor loop script
    create_supervisor_loop_script "$base"

    log_success "Created: TRIGGERS.md and supervisor-loop.sh"
}

create_supervisor_loop_script() {
    local base="$1"
    local script_dir="$base/.agentflow"
    create_directory "$script_dir"

    cat > "$script_dir/supervisor-loop.sh" << 'LOOPSCRIPT'
#!/bin/bash
# =============================================================================
# AgentFlow Supervisor Loop
# This script manages the supervisor agent execution
# =============================================================================

set -e

AGENTFLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$AGENTFLOW_DIR")"
STATE_FILE="$AGENTFLOW_DIR/.state"
LOG_FILE="$AGENTFLOW_DIR/supervisor.log"
PID_FILE="$AGENTFLOW_DIR/.pid"

source "$AGENTFLOW_DIR/common.sh" 2>/dev/null || true

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

get_state() {
    cat "$STATE_FILE" 2>/dev/null || echo "IDLE"
}

set_state() {
    echo "$1" > "$STATE_FILE"
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

start_loop() {
    if is_running; then
        log "Supervisor already running (PID: $(cat $PID_FILE))"
        return 1
    fi

    log "Starting supervisor loop..."
    set_state "RUNNING"

    (
        while [ "$(get_state)" = "RUNNING" ]; do
            # Check exit conditions
            if check_exit_conditions; then
                log "Exit conditions met!"
                set_state "DONE"
                exit 0
            fi

            # Find and assign next task
            assign_next_task

            # Sleep before next iteration
            sleep 60
        done
    ) &

    echo $! > "$PID_FILE"
    log "Supervisor started (PID: $(cat $PID_FILE))"
}

stop_loop() {
    if ! is_running; then
        log "Supervisor not running"
        return 1
    fi

    log "Stopping supervisor..."
    local pid=$(cat "$PID_FILE")
    kill "$pid" 2>/dev/null || true
    rm -f "$PID_FILE"
    set_state "IDLE"
    log "Supervisor stopped"
}

status_loop() {
    if is_running; then
        log "Supervisor RUNNING (PID: $(cat $PID_FILE))"
    else
        log "Supervisor IDLE"
    fi
    log "Last state: $(get_state)"
}

check_exit_conditions() {
    # Check if all P0/P1 features are pass
    local pending=$(jq '[.features[] | select(.priority | IN("P0","P1")) | select(.status != "pass")] | length' "$PROJECT_DIR/FEATURES.json")

    if [ "$pending" -eq 0 ]; then
        return 0
    fi
    return 1
}

assign_next_task() {
    # Find highest priority pending feature
    local feature=$(jq '[.features[] | select(.status == "pending")] | sort_by(.priority) | .[0]' "$PROJECT_DIR/FEATURES.json")

    if [ -z "$feature" ] || [ "$feature" = "null" ]; then
        log "No pending features"
        return 1
    fi

    local id=$(echo "$feature" | jq -r '.id')
    local name=$(echo "$feature" | jq -r '.name')

    log "Assigning task: $id - $name"

    # Update assigned_to
    jq ".features[] | select(.id == \"$id\") | .assigned_to = \"supervisor\"" \
        "$PROJECT_DIR/FEATURES.json" > /tmp/features.json && \
        mv /tmp/features.json "$PROJECT_DIR/FEATURES.json"

    # Update PROGRESS.md
    echo "| $(date '+%H:%M') | $name | Supervisor | Assigned |" >> "$PROJECT_DIR/PROGRESS.md"

    return 0
}

case "${1:-start}" in
    start)   start_loop ;;
    stop)    stop_loop ;;
    status)  status_loop ;;
    *)       echo "Usage: $0 {start|stop|status}" ;;
esac
LOOPSCRIPT

    chmod +x "$script_dir/supervisor-loop.sh"

    # Create common.sh
    cat > "$script_dir/common.sh" << 'COMMONSEOF'
# AgentFlow Common Utilities

AGENTFLOW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$AGENTFLOW_DIR")"

log_info()    { echo "[INFO] $*"; }
log_success() { echo "[SUCCESS] $*"; }
log_warning() { echo "[WARNING] $*"; }
log_error()   { echo "[ERROR] $*" >&2; }
COMMONSEOF

    log_info "Created: .agentflow/supervisor-loop.sh"
}

# =============================================================================
# CI/CD Configuration
# =============================================================================

create_cicd_config() {
    local base="$1"
    local workflow_dir="$base/.github/workflows"

    create_directory "$workflow_dir"

    # Main CI workflow
    cat > "$workflow_dir/ci.yml" << 'CICDEOF'
name: CI/CD

on:
  push:
    branches: [develop, main]
  pull_request:
    branches: [develop, main]

jobs:
  # =============================================================================
  # Quality Checks (Always Run)
  # =============================================================================
  quality:
    name: Quality Checks
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: TypeScript type check
        run: npm run typecheck

      - name: ESLint
        run: npm run lint

      - name: Unit tests
        run: npm test

  # =============================================================================
  # Test Coverage
  # =============================================================================
  coverage:
    name: Test Coverage
    runs-on: ubuntu-latest
    needs: quality

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run tests with coverage
        run: npm run test:coverage

      - name: Check coverage threshold
        run: |
          COVERAGE=$(cat coverage/coverage-summary.json | jq '.total.lines.pct')
          echo "Coverage: $COVERAGE%"
          if (( $(echo "$COVERAGE < 80" | bc -l) )); then
            echo "Coverage below 80%, failing"
            exit 1
          fi

  # =============================================================================
  # Trigger Agent Development (On push to develop)
  # =============================================================================
  trigger-agent:
    name: Trigger Agent Development
    runs-on: ubuntu-latest
    needs: [quality, coverage]
    if: github.ref == 'refs/heads/develop' && github.event_name == 'push'

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Read FEATURES.json
        id: features
        run: |
          echo "pending_features=$(jq '[.features[] | select(.status == "pending")] | length' FEATURES.json)" >> $GITHUB_OUTPUT
          echo "total_features=$(jq '.features | length' FEATURES.json)" >> $GITHUB_OUTPUT

      - name: Decision结点
        run: |
          echo "Pending features: ${{ steps.features.outputs.pending_features }}"
          echo "Total features: ${{ steps.features.outputs.total_features }}"
          # If all features are done, skip agent trigger
          if [ "${{ steps.features.outputs.pending_features }}" -eq 0 ]; then
            echo "All features complete, skipping agent trigger"
            echo "all_done=true" >> $GITHUB_OUTPUT
          else
            echo "all_done=false" >> $GITHUB_OUTPUT
          fi

      - name: Trigger Supervisor Agent
        if: steps.features.outputs.all_done != 'true'
        run: |
          echo "Triggering Supervisor Agent..."
          # In a real implementation, this would trigger the supervisor
          # For now, we document the mechanism
          echo "Supervisor would be triggered here"

  # =============================================================================
  # Release (On push to main)
  # =============================================================================
  release:
    name: Release
    runs-on: ubuntu-latest
    needs: [quality, coverage]
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
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

  # =============================================================================
  # Update Progress (Always on push)
  # =============================================================================
  update-progress:
    name: Update Progress
    runs-on: ubuntu-latest
    if: always() && github.ref == 'refs/heads/develop'

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Update PROGRESS.md
        run: |
          echo "### ${{ github.sha }}" >> PROGRESS.md
          echo "| $(date) | GitHub Actions | Push: ${{ github.event_name }} |" >> PROGRESS.md

      - name: Commit update
        run: |
          git config user.name "GitHub Actions"
          git config user.email "actions@github.com"
          git add PROGRESS.md
          git diff --cached --quiet || git commit -m "docs: update progress [skip ci]"
          git push
CICDEOF

    log_info "Created: .github/workflows/ci.yml"
}

# =============================================================================
# Checkpoint
# =============================================================================

create_checkpoint() {
    local base="$1"
    create_directory "$base/CHECKPOINTS"

    local checkpoint_file="$base/CHECKPOINTS/CP-000-$(date +%Y%m%d-%H%M%S).json"
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    cat > "$checkpoint_file" << EOF
{
  "id": "CP-000",
  "timestamp": "${timestamp}",
  "phase": "initialization",
  "status": "complete",
  "init_version": "${AGENTFLOW_VERSION}",
  "features": {
    "total": 0,
    "pass": 0,
    "pending": 0,
    "blocked": 0
  },
  "git": {
    "branch": "develop",
    "commit": "$(git rev-parse HEAD 2>/dev/null || echo 'initial')",
    "message": "Initial commit"
  },
  "health": {
    "test_coverage": 0,
    "lint_errors": 0,
    "type_errors": 0
  },
  "artifacts": [
    "SPEC.md",
    "FEATURES.json",
    "PROGRESS.md",
    "SUPERVISOR.md",
    "TRIGGERS.md"
  ]
}
EOF

    log_success "Created checkpoint: $(basename $checkpoint_file)"
}

# =============================================================================
# Initial Commit
# =============================================================================

create_initial_commit() {
    cd "$base"

    # Create .gitignore if not exists
    if [ ! -f ".gitignore" ]; then
        cat > .gitignore << 'GITIGNORE'
node_modules/
bin/
dist/
*.log
.env
.env.local
.DS_Store
*.db
*.db-wal
*.db-shm
.clawtools/
.agentflow/
coverage/
GITIGNORE
    fi

    git add -A

    if git diff --cached --quiet; then
        log_info "No changes to commit"
        return
    fi

    git commit -m "$(cat <<'EOF'
feat: Initialize AgentFlow project

This commit initializes the project with the AgentFlow framework for
long-running agent development.

Created artifacts:
- SPEC.md: Project specification
- FEATURES.json: Feature tracking
- PROGRESS.md: Progress logging
- SUPERVISOR.md: Agent instructions with loop
- TRIGGERS.md: Trigger mechanism
- .github/workflows/ci.yml: CI/CD pipeline

Based on Anthropic's "Effective Harnesses for Long-Running Agents"

Co-Authored-By: AgentFlow Initializer v1.0
EOF
)"

    log_success "Initial commit: $(git log --oneline -1)"
}

# =============================================================================
# Summary
# =============================================================================

print_summary() {
    local base="$1"
    local rel_base=$(basename "$base")

    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}"                            "  Initialization Complete!"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Project:${NC} $rel_base"
    echo -e "${CYAN}Location:${NC} $(cd "$base" && pwd)"
    echo ""
    echo -e "${CYAN}Created Artifacts:${NC}"
    echo -e "  ├── ${GREEN}SPEC.md${NC}              - Project specification"
    echo -e "  ├── ${GREEN}FEATURES.json${NC}         - Feature tracking"
    echo -e "  ├── ${GREEN}PROGRESS.md${NC}           - Progress logging"
    echo -e "  ├── ${GREEN}SUPERVISOR.md${NC}         - Agent instructions (with loop)"
    echo -e "  ├── ${GREEN}TRIGGERS.md${NC}           - Trigger mechanism"
    echo -e "  ├── ${GREEN}.agentflow/${NC}           - Supervisor loop script"
    echo -e "  └── ${GREEN}.github/workflows/ci.yml${NC} - CI/CD configuration"
    echo ""
    echo -e "${CYAN}Next Steps:${NC}"
    echo -e "  1. Review SPEC.md and adjust project details"
    echo -e "  2. Add features to FEATURES.json"
    echo -e "  3. Start supervisor: ${YELLOW}bash .agentflow/supervisor-loop.sh start${NC}"
    echo -e "  4. Or use GitHub Actions: push to develop branch"
    echo ""
    echo -e "${CYAN}Exit Conditions:${NC}"
    echo -e "  • All P0/P1 features status='pass'"
    echo -e "  • Test coverage ≥ 80%"
    echo -e "  • All tests pass"
    echo -e "  • No open P0/P1 bugs"
    echo ""
}

# Run
main "${@}"
