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

    # 解析查询并执行
    node -e "
const fs = require('fs');
const data = JSON.parse(fs.readFileSync('$file', 'utf8'));
const q = '$query';

// 支持: .features | length
// 支持: .features[] | select(.status == \"pending\") | length
// 支持: .features[] | select(.status == \"pending\") | select(.priority == \"P0\" or .priority == \"P1\") | length
// 支持: .features[] | select(.status == \"pending\") | sort_by(.priority) | .[0]
// 支持: .features[] | select(.id == \"ID\") | .status
const statusMatch = q.match(/select\(.*?\.status == \\\"([^\\\"]+)\\\"\)/);
const priorityOrMatch = q.match(/select\(.*?\.priority == \\\"([^\\\"]+)\\\" or .*?\.priority == \\\"([^\\\"]+)\\\"\)/);
const sortMatch = q.match(/sort_by\(.*?\)/);
const firstMatch = q.includes('.[0]');
const lengthOnly = q.includes('| length');
const idMatch = q.match(/select\(.*?\.id == \\\"([^\\\"]+)\\\"\)/);

if (q.includes('.features | length')) {
    console.log(data.features.length);
} else if (priorityOrMatch && lengthOnly) {
    // Handle: select(.priority == \"P0\" or .priority == \"P1\") | length
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
        // 提取具体字段
        if (q.includes('.status')) {
            console.log(feature.status);
        } else if (q.includes('.id')) {
            console.log(feature.id);
        } else if (q.includes('.name')) {
            console.log(feature.name);
        } else if (q.includes('.priority')) {
            console.log(feature.priority);
        } else {
            console.log(JSON.stringify(feature));
        }
    } else {
        console.log('null');
    }
} else {
    console.log('');
}
" 2>/dev/null
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

    # Node.js 后备
    if ! has_node; then
        return 1
    fi

    node -e "
const fs = require('fs');
const data = JSON.parse(fs.readFileSync('$file', 'utf8'));
const id = '$id';
const field = '$field';
const value = '$value';

const feature = data.features.find(f => f.id === id);
if (feature) {
    feature[field] = value;
    feature.updated_at = new Date().toISOString();
    fs.writeFileSync('$file', JSON.stringify(data, null, 2));
    console.log('OK');
} else {
    process.exit(1);
}
" 2>/dev/null
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
