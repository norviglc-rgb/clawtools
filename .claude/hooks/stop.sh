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
        echo "  □ Does typecheck pass?"
        echo "  □ Is lint clean?"
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
