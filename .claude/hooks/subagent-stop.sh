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
