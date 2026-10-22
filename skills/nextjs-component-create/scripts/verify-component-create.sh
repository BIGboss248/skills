#!/usr/bin/env bash
set -e

COMPONENT_PATH="$1"
COMPONENT_NAME="$2"
SKIP_TESTS=false

if [ "$3" == "--skip-tests" ] || [ "$2" == "--skip-tests" ]; then
  SKIP_TESTS=true
fi

if [ -z "$COMPONENT_PATH" ]; then
  echo "Usage: ./verify-component-create.sh <ComponentPath> [ComponentName] [--skip-tests]"
  exit 1
fi

if [ ! -e "$COMPONENT_PATH" ]; then
  echo -e "\033[31m[FAIL] Path not found: $COMPONENT_PATH\033[0m"
  exit 1
fi

if [ -d "$COMPONENT_PATH" ]; then
  RESOLVED_DIR="$COMPONENT_PATH"
  if [ -n "$COMPONENT_NAME" ] && [ "$COMPONENT_NAME" != "--skip-tests" ]; then
    COMP_NAME="$COMPONENT_NAME"
  else
    COMP_NAME=$(basename "$COMPONENT_PATH")
  fi
else
  RESOLVED_DIR=$(dirname "$COMPONENT_PATH")
  COMP_NAME=$(basename "$COMPONENT_PATH" | cut -f 1 -d '.')
fi

COMPONENT_FILE="$RESOLVED_DIR/$COMP_NAME.tsx"
SKELETON_FILE="$RESOLVED_DIR/${COMP_NAME}Skeleton.tsx"
INDEX_FILE="$RESOLVED_DIR/index.ts"
TEST_FILE="$RESOLVED_DIR/$COMP_NAME.test.tsx"
EDGE_TEST_FILE="$RESOLVED_DIR/$COMP_NAME.edge.test.tsx"

MISSING=()
[ ! -f "$COMPONENT_FILE" ] && MISSING+=("$COMP_NAME.tsx")
[ ! -f "$SKELETON_FILE" ] && MISSING+=("${COMP_NAME}Skeleton.tsx")
[ ! -f "$INDEX_FILE" ] && MISSING+=("index.ts")
[ ! -f "$TEST_FILE" ] && MISSING+=("$COMP_NAME.test.tsx")
[ ! -f "$EDGE_TEST_FILE" ] && MISSING+=("$COMP_NAME.edge.test.tsx")

if [ ${#MISSING[@]} -gt 0 ]; then
  echo -e "\033[31m[FAIL] Missing component artifacts for $COMP_NAME in $RESOLVED_DIR:\033[0m"
  for m in "${MISSING[@]}"; do
    echo -e "\033[31m  - Missing: $m\033[0m"
  done
  exit 1
fi

echo -e "\033[32m[PASS] All component files verified: $COMP_NAME.tsx, ${COMP_NAME}Skeleton.tsx, index.ts, $COMP_NAME.test.tsx, $COMP_NAME.edge.test.tsx\033[0m"

# Verify zero in-file mock dictionaries
if [ -f "$COMPONENT_FILE" ]; then
  if grep -q "const DEFAULT_CONTENT" "$COMPONENT_FILE" || grep -q "const DEFAULT_TRANSLATIONS" "$COMPONENT_FILE"; then
    echo -e "\033[31m[FAIL] In-file i18n placeholder dictionary detected in $COMP_NAME.tsx. Extract all strings to messages/[locale].json.\033[0m"
    exit 1
  fi
fi

# Detect package manager
PKG_MGR="pnpm"
[ -f "bun.lockb" ] && PKG_MGR="bun"
[ -f "package-lock.json" ] && PKG_MGR="npm"
[ -f "yarn.lock" ] && PKG_MGR="yarn"

if [ "$SKIP_TESTS" = false ]; then
  echo -e "\033[36m[INFO] Executing targeted unit & adversarial test suites via $PKG_MGR...\033[0m"
  $PKG_MGR test -- "$TEST_FILE" "$EDGE_TEST_FILE"
  if [ $? -ne 0 ]; then
    echo -e "\033[31m[FAIL] Unit/edge tests failed for $COMP_NAME.\033[0m"
    exit 1
  fi
  echo -e "\033[32m[SUCCESS] All unit and adversarial tests passed for $COMP_NAME.\033[0m"
fi

echo -e "\033[32m[SUCCESS] nextjs-component-create verification passed for $COMP_NAME.\033[0m"
exit 0

