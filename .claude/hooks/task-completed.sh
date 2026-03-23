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
