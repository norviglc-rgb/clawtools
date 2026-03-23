#!/bin/bash
# PostBash Hook v3.0
# Scrub secrets from command output
# =============================================================================

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUTPUT=$(cat /dev/stdin 2>/dev/null || echo "")

# Secret patterns to scrub
SECRET_PATTERNS=(
    "password=.*"
    "secret=.*"
    "api_key=.*"
    "token=.*"
    "Bearer .*"
    "ghp_.*"
    "sk-.*"
)

for pattern in "${SECRET_PATTERNS[@]}"; do
    OUTPUT=$(echo "$OUTPUT" | sed -E "s/($pattern)/[REDACTED]/g")
done

echo "$OUTPUT"
