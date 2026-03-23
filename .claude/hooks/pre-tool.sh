#!/bin/bash
# PreToolUse Hook v3.0
# Block dangerous bash commands that target protected files
# =============================================================================

# Claude Code passes: TOOL NAME, TOOL INPUT (as JSON)
TOOL="$1"
ARGS="$2"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Protected patterns - files that should never be deleted
PROTECTED_PATTERNS=(
    "FEATURES\.json"
    "SPEC\.md"
    "PROGRESS\.md"
    "SUPERVISOR\.md"
    "TRIGGERS\.md"
    "\.git/"
    "AGENTS/"
    "CHECKPOINTS/"
)

# Dangerous command patterns
DANGEROUS_PATTERNS=(
    "rm\s+-rf"
    "del\s+/[fs]"
    "format\s+"
    "dd\s+if="
)

case "$TOOL" in
    "Bash")
        # Check for dangerous commands
        for pattern in "${DANGEROUS_PATTERNS[@]}"; do
            if echo "$ARGS" | grep -qiE "$pattern"; then
                # Check if targeting protected files
                for protected in "${PROTECTED_PATTERNS[@]}"; do
                    if echo "$ARGS" | grep -qiE "$protected"; then
                        echo "🚫 PRETOOL BLOCKED: Dangerous command targeting protected files"
                        echo ""
                        echo "Command: $ARGS"
                        echo "Target: Matched pattern '$protected'"
                        echo ""
                        echo "If you need to modify these files, use: Edit or Write tools"
                        echo "Or use explicit git commands: git rm, git checkout"
                        exit 1
                    fi
                done
            fi
        done

        # Block force push to main
        if echo "$ARGS" | grep -qiE "git\s+push.*--force.*main"; then
            echo "🚫 PRETOOL BLOCKED: Force push to main is not allowed"
            echo "Use a PR instead, or push to develop branch"
            exit 1
        fi
        ;;
esac

# Allow by default
exit 0
