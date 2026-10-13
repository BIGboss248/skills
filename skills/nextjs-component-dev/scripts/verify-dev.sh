#!/usr/bin/env bash
set -e

if [ -z "$1" ]; then
    echo -e "\033[0;31m[FAIL] Usage: bash verify-dev.sh <ComponentPath> [ComponentName]\033[0m"
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

COMPONENT_FILE="$RESOLVED_DIR/${COMP_NAME}.tsx"
SKELETON_FILE="$RESOLVED_DIR/${COMP_NAME}Skeleton.tsx"
TEST_FILE="$RESOLVED_DIR/${COMP_NAME}.test.tsx"

if [ ! -f "$TEST_FILE" ]; then
    TEST_FILE="$RESOLVED_DIR/${COMP_NAME}.spec.tsx"
fi

MISSING=()
if [ ! -f "$COMPONENT_FILE" ]; then MISSING+=("${COMP_NAME}.tsx"); fi
if [ ! -f "$SKELETON_FILE" ]; then MISSING+=("${COMP_NAME}Skeleton.tsx"); fi
if [ ! -f "$TEST_FILE" ]; then MISSING+=("${COMP_NAME}.test.tsx"); fi

if [ ${#MISSING[@]} -gt 0 ]; then
    echo -e "\033[0;31m[FAIL] Missing dev companion files for $COMP_NAME in $RESOLVED_DIR:\033[0m"
    for m in "${MISSING[@]}"; do
        echo -e "\033[0;31m  - Missing: $m\033[0m"
    done
    exit 1
fi

echo -e "\033[0;32m[PASS] Files present: ${COMP_NAME}.tsx, ${COMP_NAME}Skeleton.tsx, $(basename "$TEST_FILE")\033[0m"

# Verify zero in-file i18n placeholders / mock translation dictionaries
if [ -f "$COMPONENT_FILE" ]; then
    if grep -qE "const\s+DEFAULT_CONTENT\s*=|const\s+DEFAULT_TRANSLATIONS\s*=" "$COMPONENT_FILE"; then
        echo -e "\033[0;31m[FAIL] In-file i18n placeholder dictionary detected in ${COMP_NAME}.tsx (e.g., DEFAULT_CONTENT). Extract all strings to messages/[locale].json and consume via next-intl.\033[0m"
        exit 1
    fi
fi

# Detect package manager
PKG_MANAGER="pnpm"
if [ -f "pnpm-lock.yaml" ]; then PKG_MANAGER="pnpm";
elif [ -f "bun.lockb" ]; then PKG_MANAGER="bun";
elif [ -f "package-lock.json" ]; then PKG_MANAGER="npm";
elif [ -f "yarn.lock" ]; then PKG_MANAGER="yarn";
fi

echo -e "\033[0;36m[INFO] Executing unit test suite via $PKG_MANAGER...\033[0m"
$PKG_MANAGER test -- "$TEST_FILE"

echo -e "\033[0;32m[SUCCESS] Dev verification passed for $COMP_NAME.\033[0m"
exit 0
