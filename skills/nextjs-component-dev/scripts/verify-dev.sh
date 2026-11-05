#!/usr/bin/env bash
set -e

SKELETON_MODE="auto"

# Usage: bash verify-dev.sh <ComponentPath> [ComponentName] [auto|required|not-required]
#        bash verify-dev.sh <ComponentPath> --skeleton=required
if [ -z "$1" ]; then
    echo -e "\033[0;31m[FAIL] Usage: bash verify-dev.sh <ComponentPath> [ComponentName] [auto|required|not-required]\033[0m"
    exit 1
fi

TARGET_PATH="$1"
CUSTOM_NAME="$2"

case "$CUSTOM_NAME" in
    --skeleton=*) SKELETON_MODE="${CUSTOM_NAME#--skeleton=}"; CUSTOM_NAME="" ;;
esac

if [ -n "$3" ]; then
    SKELETON_MODE="$3"
fi
case "$SKELETON_MODE" in
    --skeleton=*) SKELETON_MODE="${SKELETON_MODE#--skeleton=}" ;;
esac

case "$SKELETON_MODE" in
    auto|required|not-required) ;;
    *)
        echo -e "\033[0;31m[FAIL] Invalid skeleton mode '$SKELETON_MODE'. Use auto, required, or not-required.\033[0m"
        exit 1
        ;;
esac

if [ ! -e "$TARGET_PATH" ]; then
    echo -e "\033[0;31m[FAIL] Path not found: $TARGET_PATH\033[0m"
    exit 1
fi

if [ -d "$TARGET_PATH" ]; then
    RESOLVED_DIR="$(cd "$TARGET_PATH" && pwd)"
    if [ -z "$CUSTOM_NAME" ]; then
        echo -e "\033[0;31m[FAIL] '$RESOLVED_DIR' is a surface folder (page or layout region), not a component folder.\033[0m"
        echo -e "\033[0;31m       Components are flat files: <new_component_dir>/<surface>/<component_name>.tsx\033[0m"
        echo -e "\033[0;31m       Re-run with the component file path, or pass the component name as the second argument.\033[0m"
        exit 1
    fi
    COMP_NAME="$CUSTOM_NAME"
else
    RESOLVED_DIR="$(cd "$(dirname "$TARGET_PATH")" && pwd)"
    FILE_NAME="$(basename "$TARGET_PATH")"
    COMP_NAME="${FILE_NAME%.*}"
    COMP_NAME="$(echo "$COMP_NAME" | sed -E 's/\.edge\.test$//; s/\.test$//; s/\.stories$//; s/_skeleton$//')"
fi

COMPONENT_FILE="$RESOLVED_DIR/${COMP_NAME}.tsx"

# --- Skeleton decision gate (SKILL.md §1.2) --------------------------------------
# A skeleton is a streaming fallback, not a mandatory companion. Only components that
# can suspend, lazy-load, or wait on I/O need one; static components must not ship one.
suspends_or_lazy_loads() {
    local path="$1"
    [ -f "$path" ] || return 1
    if grep -qE 'next/dynamic|(^|[^[:alnum:]_])dynamic\(|useSuspenseQuery|ssr:[[:space:]]*false' "$path"; then
        return 0
    fi
    # Await inside a client component is usually an event handler, not a suspend point.
    if grep -qE "^[[:space:]]*(\"use client\"|'use client')" "$path"; then
        return 1
    fi
    if grep -qE '(^|[^[:alnum:]_])await([^[:alnum:]_]|$)' "$path"; then
        return 0
    fi
    if grep -qE 'cookies\(\)|headers\(\)|connection\(\)|noStore\(\)' "$path"; then
        return 0
    fi
    return 1
}

case "$SKELETON_MODE" in
    required) SKELETON_REQUIRED=1 ;;
    not-required) SKELETON_REQUIRED=0 ;;
    *)
        if suspends_or_lazy_loads "$COMPONENT_FILE"; then SKELETON_REQUIRED=1; else SKELETON_REQUIRED=0; fi
        ;;
esac

# Flat companion convention: <component_name>_skeleton.tsx. Legacy '<Name>Skeleton.tsx' is tolerated with a rename warning.
SKELETON_FILE="$RESOLVED_DIR/${COMP_NAME}_skeleton.tsx"
LEGACY_SKELETON=0
if [ ! -f "$SKELETON_FILE" ]; then
    LEGACY_FILE="$RESOLVED_DIR/${COMP_NAME}Skeleton.tsx"
    if [ -f "$LEGACY_FILE" ]; then
        SKELETON_FILE="$LEGACY_FILE"
        LEGACY_SKELETON=1
    fi
fi

TEST_FILE="$RESOLVED_DIR/${COMP_NAME}.test.tsx"

if [ ! -f "$TEST_FILE" ]; then
    TEST_FILE="$RESOLVED_DIR/${COMP_NAME}.spec.tsx"
fi

MISSING=()
if [ ! -f "$COMPONENT_FILE" ]; then MISSING+=("${COMP_NAME}.tsx"); fi
if [ "$SKELETON_REQUIRED" -eq 1 ] && [ ! -f "$SKELETON_FILE" ]; then MISSING+=("${COMP_NAME}_skeleton.tsx"); fi

if [ ${#MISSING[@]} -gt 0 ]; then
    echo -e "\033[0;31m[FAIL] Missing dev companion files for $COMP_NAME in $RESOLVED_DIR:\033[0m"
    for m in "${MISSING[@]}"; do
        echo -e "\033[0;31m  - Missing: $m\033[0m"
    done
    exit 1
fi

PRESENT="${COMP_NAME}.tsx"
if [ -f "$SKELETON_FILE" ]; then PRESENT="$PRESENT, $(basename "$SKELETON_FILE")"; fi
echo -e "\033[0;32m[PASS] Files present: $PRESENT\033[0m"

if [ "$LEGACY_SKELETON" -eq 1 ]; then
    echo -e "\033[0;33m[WARN] Legacy skeleton name found. Rename '${COMP_NAME}Skeleton.tsx' to '${COMP_NAME}_skeleton.tsx' (flat snake_case convention).\033[0m"
fi

if [ "$SKELETON_REQUIRED" -eq 0 ]; then
    if [ -f "$SKELETON_FILE" ]; then
        echo -e "\033[0;33m[WARN] Static component carries a skeleton ('$(basename "$SKELETON_FILE")'). It can never paint, so it is dead code that will drift from the real layout. Delete it unless the component gains await / a data hook / next/dynamic.\033[0m"
    else
        echo -e "\033[0;32m[PASS] Skeleton not required: static component (no suspend/lazy/await trigger detected).\033[0m"
    fi
else
    echo -e "\033[0;36m[INFO] Skeleton required: component can suspend, lazy-load, or wait on I/O.\033[0m"

    # Skeleton-first streaming: an orphan skeleton (no Suspense/dynamic/loading.tsx import) is a failed deliverable.
    SKELETON_REF="${COMP_NAME}_skeleton"
    SKELETON_LEAF="$(basename "$SKELETON_FILE")"
    WIRED=0
    for SCAN_PATH in app src "$RESOLVED_DIR"; do
        [ -d "$SCAN_PATH" ] || continue
        if grep -rlF --include='*.tsx' --exclude="$SKELETON_LEAF" --exclude='*.test.tsx' --exclude='*.edge.test.tsx' --exclude='*.stories.tsx' --exclude-dir=node_modules --exclude-dir=.next --exclude-dir=.git --exclude-dir=dist --exclude-dir=build --exclude-dir=coverage "$SKELETON_REF" "$SCAN_PATH" >/dev/null 2>&1; then
            WIRED=1
            break
        fi
    done

    if [ "$WIRED" -eq 0 ]; then
        echo -e "\033[0;33m[WARN] Orphan skeleton: '$SKELETON_LEAF' is not imported by any <Suspense fallback>, next/dynamic loading, or loading.tsx. Wire it so the skeleton renders first while the component streams.\033[0m"
    else
        echo -e "\033[0;32m[PASS] Skeleton is wired into a streaming boundary.\033[0m"
    fi
fi

# Test authoring is owned exclusively by the nextjs-test skill (separate step).
# If tests already exist, run only those files read-only for feedback; never author one here.
if [ -f "$TEST_FILE" ]; then
    echo -e "\033[0;32m[PASS] Existing suite found: $(basename "$TEST_FILE") (run read-only for feedback).\033[0m"
fi
echo -e "\033[0;36m[INFO] Test authoring is owned by nextjs-test (separate step). Use nextjs-test/scripts/verify-qa.sh for the test gate.\033[0m"

# Verify zero in-file i18n placeholders / mock translation dictionaries
if [ -f "$COMPONENT_FILE" ]; then
    if grep -qE "const\s+DEFAULT_CONTENT\s*=|const\s+DEFAULT_TRANSLATIONS\s*=" "$COMPONENT_FILE"; then
        echo -e "\033[0;31m[FAIL] In-file i18n placeholder dictionary detected in ${COMP_NAME}.tsx (e.g., DEFAULT_CONTENT). Extract all strings to messages/[locale].json and consume via next-intl.\033[0m"
        exit 1
    fi
fi

echo -e "\033[0;32m[SUCCESS] Dev verification passed for $COMP_NAME.\033[0m"
exit 0
