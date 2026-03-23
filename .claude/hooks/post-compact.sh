#!/bin/bash
# PostCompact Hook v3.0
# Verify critical context was preserved after compaction
# =============================================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Post-Compact Verification"
echo "═══════════════════════════════════════════════════════════"

# Check if hints file was used
if [ -f "$PROJECT_DIR/.agentflow/.compact_hints" ]; then
    echo ""
    echo "✓ Context preservation hints were available during compaction"

    # Verify FEATURES.json still accessible
    if [ -f "$PROJECT_DIR/FEATURES.json" ]; then
        IN_PROGRESS=$(jq '[.features[] | select(.status == "in_progress")] | length' "$PROJECT_DIR/FEATURES.json" 2>/dev/null || echo "?")
        echo "✓ FEATURES.json intact (in_progress: $IN_PROGRESS)"
    else
        echo "⚠️  WARNING: FEATURES.json not found after compaction"
    fi

    # Verify SPEC.md still accessible
    if [ -f "$PROJECT_DIR/SPEC.md" ]; then
        echo "✓ SPEC.md intact"
    else
        echo "⚠️  WARNING: SPEC.md not found after compaction"
    fi
fi

echo ""
echo "If context feels incomplete, use /compact to re-summarize"
echo "═══════════════════════════════════════════════════════════"
