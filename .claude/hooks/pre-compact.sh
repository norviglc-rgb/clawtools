#!/bin/bash
# PreCompact Hook v3.0
# Prepare essential context for preservation during compaction
# =============================================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPACT_HINTS_FILE="$PROJECT_DIR/.agentflow/.compact_hints"

echo "Preparing context for compaction..."

# Generate hints for what to preserve
cat > "$COMPACT_HINTS_FILE" << 'HINTSEOF'
CONTEXT PRESERVATION HINTS:

1. CURRENT TASK:
   - Read FEATURES.json for in_progress task
   - Read current file being edited

2. RECENT CHANGES:
   - git diff --cached
   - git status

3. ACTIVE REFERENCES:
   - Any functions/classes being modified
   - Any documentation being updated

4. QUALITY GATES (must maintain):
   - typecheck must pass
   - lint must pass

5. BLOCKERS:
   - Any open issues requiring resolution
HINTSEOF

echo "  ✓ Hints written to .agentflow/.compact_hints"
echo "  ✓ Essential context flagged for preservation"
exit 0
