#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
    echo -e "\033[0;31m[FAIL] Usage: bash verify-storybook.sh <ComponentPath> [ComponentName]\033[0m"
    exit 1
fi

TARGET_PATH="$1"
CUSTOM_NAME="$2"

if [ ! -e "$TARGET_PATH" ]; then
    echo -e "\033[0;31m[FAIL] Path not found: $TARGET_PATH\033[0m"
    exit 1
fi

if [ -d "$TARGET_PATH" ]; then
    RESOLVED_DIR="$(cd "$TARGET_PATH" && pwd)"
    if [ -n "$CUSTOM_NAME" ]; then
        COMP_NAME="$CUSTOM_NAME"
    else
        COMP_NAME="$(basename "$RESOLVED_DIR")"
    fi
else
    RESOLVED_DIR="$(cd "$(dirname "$TARGET_PATH")" && pwd)"
    FILE_NAME="$(basename "$TARGET_PATH")"
    COMP_NAME="${FILE_NAME%.*}"
fi

STORY_FILE="$RESOLVED_DIR/${COMP_NAME}.stories.tsx"

if [ ! -f "$STORY_FILE" ]; then
    echo -e "\033[0;31m[FAIL] Missing Storybook story file: ${COMP_NAME}.stories.tsx in $RESOLVED_DIR\033[0m"
    exit 1
fi

echo -e "\033[0;32m[PASS] Story file present: ${COMP_NAME}.stories.tsx\033[0m"

# Detect package manager
PKG_MANAGER="pnpm"
if [ -f "pnpm-lock.yaml" ]; then PKG_MANAGER="pnpm";
elif [ -f "bun.lockb" ]; then PKG_MANAGER="bun";
elif [ -f "package-lock.json" ]; then PKG_MANAGER="npm";
elif [ -f "yarn.lock" ]; then PKG_MANAGER="yarn";
fi

echo -e "\033[0;36m[INFO] Executing Storybook smoke & indexing check via $PKG_MANAGER...\033[0m"

HAS_SMOKE_SCRIPT=false
if [ -f "package.json" ]; then
    if grep -q '"storybook:smoke"' package.json; then
        HAS_SMOKE_SCRIPT=true
    fi
fi

if [ "$HAS_SMOKE_SCRIPT" = true ]; then
    $PKG_MANAGER run storybook:smoke
else
    $PKG_MANAGER exec storybook dev --smoke-test
fi

echo -e "\033[0;32m[SUCCESS] Storybook verification passed for $COMP_NAME.\033[0m"
exit 0

