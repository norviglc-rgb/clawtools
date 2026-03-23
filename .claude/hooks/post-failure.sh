#!/bin/bash
# PostFailure Hook v3.0
# Detect when same command fails repeatedly (retry loop)
# =============================================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FAILURE_LOG="$PROJECT_DIR/.agentflow/.failure_log"
MAX_RETRIES=3

TOOL="$1"
ERROR="$2"

# Log failure
echo "$(date +%s)|$TOOL|$ERROR" >> "$FAILURE_LOG" 2>/dev/null || true

# Check for repeated failures
if [ -f "$FAILURE_LOG" ]; then
    RECENT=$(tail -10 "$FAILURE_LOG")
    COUNT=$(echo "$RECENT" | grep -c "$TOOL" || echo "0")

    if [ "$COUNT" -ge "$MAX_RETRIES" ]; then
        echo "⚠️  RETRY LOOP DETECTED: '$TOOL' failed $COUNT times"
        echo "   Consider a different approach"
        echo ""
        echo "Suggestions:"
        echo "  1. Check if dependencies are installed (npm install)"
        echo "  2. Verify file paths are correct"
        echo "  3. Try running manually in terminal"
        echo "  4. Ask for human assistance if stuck"
    fi
fi

exit 0
