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
