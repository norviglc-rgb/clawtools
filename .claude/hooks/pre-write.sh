#!/bin/bash
# PreWrite Hook v3.0
# Detect TODOs, FIXMEs, placeholders before writing
# =============================================================================

TOOL="$1"
ARGS="$2"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Check file content for common issues
if [ -f "$ARGS" ]; then
    # Count TODOs/FIXMEs
    TODO_COUNT=$(grep -cE "TODO|FIXME|XXX|HACK" "$ARGS" 2>/dev/null || echo "0")
    if [ "$TODO_COUNT" -gt 0 ]; then
        echo "⚠️  PRE-WRITE: File contains $TODO_COUNT TODO/FIXME marker(s)"
        echo "   Consider completing these before committing"
    fi

    # Check for placeholder text
    PLACEHOLDER_COUNT=$(grep -cE "\[ \]|\[TODO\]|\[FIXME\]|REPLACEME|EXAMPLE" "$ARGS" 2>/dev/null || echo "0")
    if [ "$PLACEHOLDER_COUNT" -gt 0 ]; then
        echo "⚠️  PRE-WRITE: File contains $PLACEHOLDER_COUNT placeholder(s)"
        echo "   Replace with actual implementation before commit"
    fi
fi

exit 0
