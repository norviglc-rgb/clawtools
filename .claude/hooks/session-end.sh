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
