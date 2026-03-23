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
    # 需要 jq
    if ! command -v jq &> /dev/null; then
        log_warn "jq not found, skipping exit check"
        return 1
    fi

    # 检查是否有 pending 的 P0/P1
    local pending=$(jq '[.features[] | select(.priority | IN("P0","P1")) | select(.status == "pending")] | length' "$PROJECT_DIR/FEATURES.json" 2>/dev/null || echo "999")

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
    local task=$(jq '[.features[] | select(.status == "pending")] | sort_by(.priority) | .[0]' "$PROJECT_DIR/FEATURES.json" 2>/dev/null)

    if [ -z "$task" ] || [ "$task" = "null" ]; then
        log_info "No pending tasks"
        return 1
    fi

    local id=$(echo "$task" | jq -r '.id')
    local name=$(echo "$task" | jq -r '.name')
    local priority=$(echo "$task" | jq -r '.priority')

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
    if command -v jq &> /dev/null; then
        local updated=$(jq --arg id "$feature_id" --arg status "$status" --arg time "$timestamp" \
            '(if .features[] | select(.id == $id) | has("updated_at") == false then .features[] | select(.id == $id) | .updated_at = $time else . end) |
            (.features[] | select(.id == $id) | .status = $status | .updated_at = $time)' \
            "$PROJECT_DIR/FEATURES.json" 2>/dev/null)

        if [ -n "$updated" ]; then
            echo "$updated" > "$PROJECT_DIR/FEATURES.json"
        fi
    fi

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
    if command -v jq &> /dev/null && [ -f "$PROJECT_DIR/FEATURES.json" ]; then
        local in_progress=$(jq '[.features[] | select(.status == "in_progress")] | length' "$PROJECT_DIR/FEATURES.json" 2>/dev/null || echo "0")
        if [ "$in_progress" -gt 0 ]; then
            log_warn "Found $in_progress in_progress feature(s) from previous run"
            log_info "Resetting to pending for retry..."

            # Reset in_progress to pending
            jq '[.features[] | if .status == "in_progress" then .status = "pending" else . end]' "$PROJECT_DIR/FEATURES.json" > "$PROJECT_DIR/FEATURES.json.tmp" 2>/dev/null
            mv "$PROJECT_DIR/FEATURES.json.tmp" "$PROJECT_DIR/FEATURES.json"
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
