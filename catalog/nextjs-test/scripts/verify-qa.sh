#!/usr/bin/env bash
set -u

usage() {
    cat <<'EOF'
Usage: bash verify-qa.sh <TargetPath> [Mode] [--tier fast|full] [--no-run] [--help]

Verifies Next.js test artifacts and runs the targeted QA suites.

  TargetPath   Component file (components/home/hero.tsx) or route directory
               (app/[locale]/about). Components are flat files; a surface
               folder (components/home) needs an explicit component name.
  Mode         baseline | adversarial | page | all | audit   (default: all)
  --tier       fast | full (default: fast). 'fast' runs Jest only and defers
               Playwright to the pre-push gate; 'full' runs everything and is
               reserved for pre-push, CI, or an explicit user request.
  --no-run     Audit files only; do not execute test runners.
  --help       Show this help.

Exit codes: 0 success, 1 verification failure, 2 usage error.
EOF
}

if [ $# -eq 0 ]; then
    usage
    exit 2
fi

TARGET_PATH=""
MODE="all"
TIER="fast"
NO_RUN=0

for arg in "$@"; do
    case "$arg" in
        --help|-h) usage; exit 0 ;;
        --no-run) NO_RUN=1 ;;
        --tier) ;;
        --tier=fast) TIER="fast" ;;
        --tier=full) TIER="full" ;;
        fast|full) TIER="$arg" ;;
        baseline|adversarial|page|all|audit) MODE="$arg" ;;
        *) if [ -z "$TARGET_PATH" ]; then TARGET_PATH="$arg"; fi ;;
    esac
done

if [ -z "$TARGET_PATH" ]; then
    usage
    exit 2
fi

if [ ! -e "$TARGET_PATH" ]; then
    echo "[FAIL] Target not found: $TARGET_PATH"
    exit 2
fi

if [ -d "$TARGET_PATH" ]; then
    RESOLVED_DIR="$(cd "$TARGET_PATH" && pwd)"
    COMP_NAME="$(basename "$RESOLVED_DIR")"
else
    RESOLVED_DIR="$(cd "$(dirname "$TARGET_PATH")" && pwd)"
    FILE_NAME="$(basename "$TARGET_PATH")"
    COMP_NAME="${FILE_NAME%.*}"
fi

BASELINE_FILE="$RESOLVED_DIR/${COMP_NAME}.test.tsx"
EDGE_FILE="$RESOLVED_DIR/${COMP_NAME}.edge.test.tsx"
JEST_FILES=()
E2E_FILES=()
MISSING=()

case "$MODE" in
    baseline)
        if [ -f "$BASELINE_FILE" ]; then JEST_FILES+=("$BASELINE_FILE"); else MISSING+=("${COMP_NAME}.test.tsx"); fi
        ;;
    adversarial)
        if [ -f "$EDGE_FILE" ]; then JEST_FILES+=("$EDGE_FILE"); else MISSING+=("${COMP_NAME}.edge.test.tsx"); fi
        ;;
    page)
        if [ ! -f "$RESOLVED_DIR/page.tsx" ]; then MISSING+=("page.tsx"); fi
        LEAF="$(basename "$RESOLVED_DIR")"
        if [ -d "tests/e2e/pages" ]; then
            while IFS= read -r spec; do E2E_FILES+=("$spec"); done < <(find "tests/e2e/pages" -type f -name "*${LEAF}*.spec.ts" 2>/dev/null)
            if [ ${#E2E_FILES[@]} -eq 0 ]; then MISSING+=("tests/e2e/pages/*${LEAF}*.spec.ts"); fi
        else
            MISSING+=("tests/e2e/pages/")
        fi
        ;;
    all)
        if [ -f "$BASELINE_FILE" ]; then JEST_FILES+=("$BASELINE_FILE"); else MISSING+=("${COMP_NAME}.test.tsx"); fi
        if [ -f "$EDGE_FILE" ]; then JEST_FILES+=("$EDGE_FILE"); else MISSING+=("${COMP_NAME}.edge.test.tsx"); fi
        ;;
    audit)
        [ -f "$BASELINE_FILE" ] && JEST_FILES+=("$BASELINE_FILE")
        [ -f "$EDGE_FILE" ] && JEST_FILES+=("$EDGE_FILE")
        if [ ${#JEST_FILES[@]} -eq 0 ]; then MISSING+=("${COMP_NAME}.test.tsx or ${COMP_NAME}.edge.test.tsx"); fi
        ;;
    *)
        echo "[FAIL] Unknown mode: $MODE"
        exit 2
        ;;
esac

if [ ${#MISSING[@]} -gt 0 ]; then
    echo "[FAIL] Missing required QA artifacts for '$COMP_NAME' in $RESOLVED_DIR:"
    for m in "${MISSING[@]}"; do echo "  - Missing: $m"; done
    exit 1
fi

FORBIDDEN='^[[:space:]]*(it|test|describe)\.(only|skip|fixme)[[:space:]]*\('
PLACEHOLDER='expect\([[:space:]]*(true|1)[[:space:]]*\)\.toBe\([[:space:]]*(true|1)[[:space:]]*\)'

for file in "${JEST_FILES[@]}" "${E2E_FILES[@]}"; do
    if grep -qE "$FORBIDDEN" "$file"; then
        echo "[FAIL] Forbidden focused/skipped test in $(basename "$file")"
        exit 1
    fi
    if grep -qE "$PLACEHOLDER" "$file"; then
        echo "[FAIL] Placeholder assertion detected in $(basename "$file")"
        exit 1
    fi
    case "$file" in
        *.edge.test.tsx)
            CASES="$(grep -cE '^[[:space:]]*(it|test)[[:space:]]*\(' "$file" || true)"
            if [ "$CASES" -lt 6 ]; then
                echo "[FAIL] Edge suite has $CASES cases; minimum is 6."
                exit 1
            fi
            ;;
    esac
    echo "[PASS] Audited $(basename "$file")"
done

if [ "$NO_RUN" -eq 1 ]; then
    echo "[SUCCESS] Audit complete (--no-run)."
    exit 0
fi

PKG_MANAGER="pnpm"
if [ -f "pnpm-lock.yaml" ]; then PKG_MANAGER="pnpm"
elif [ -f "bun.lockb" ]; then PKG_MANAGER="bun"
elif [ -f "package-lock.json" ]; then PKG_MANAGER="npm"
elif [ -f "yarn.lock" ]; then PKG_MANAGER="yarn"
fi

for file in "${JEST_FILES[@]}"; do
    echo "[INFO] Running Jest: $file"
    if [ "$PKG_MANAGER" = "bun" ]; then bun test "$file"; else "$PKG_MANAGER" test -- "$file"; fi
    if [ $? -ne 0 ]; then
        echo "[FAIL] Jest suite failed: $(basename "$file")"
        exit 1
    fi
done

if [ ${#E2E_FILES[@]} -gt 0 ] && [ "$TIER" != "full" ]; then
    echo "[DEFERRED] Playwright suites are expensive and run pre-push:"
    for file in "${E2E_FILES[@]}"; do echo "  - $file"; done
    echo "  Run now only on explicit request: $PKG_MANAGER run test:e2e <file>  (or --tier full)"
    echo "[DEFERRED] A deferred suite is not a passing suite."
else
    for file in "${E2E_FILES[@]}"; do
        echo "[INFO] Running Playwright: $file"
        if [ "$PKG_MANAGER" = "bun" ]; then bun run test:e2e "$file"
        elif [ "$PKG_MANAGER" = "npm" ]; then npm run test:e2e -- "$file"
        else "$PKG_MANAGER" run test:e2e -- "$file"; fi
        if [ $? -ne 0 ]; then
            echo "[FAIL] Playwright suite failed: $(basename "$file")"
            exit 1
        fi
    done
fi

echo "[SUCCESS] QA verification passed for '$COMP_NAME' (mode: $MODE, tier: $TIER)."
exit 0
