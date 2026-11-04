#!/usr/bin/env bash
set -u

usage() {
    cat <<'EOF'
Usage: bash verify-component-create.sh <TargetPath> [component|page] [--tier fast|full] [--skip-storybook] [--skip-tests] [--help]

End-to-end verification for the Next.js creation pipeline.

Runs the phase gates in order: component infrastructure or page route files,
Storybook (components only), then QA suites (baseline + adversarial, or the page
suite). Stops at the first failure.

  TargetPath         Component file (components/home/hero.tsx) or route
                     directory (app/[locale]/about). Components are flat files
                     inside their page or layout-region folder.

  --tier fast|full   Default: fast. 'fast' runs Jest only and defers Playwright
                     to the pre-push gate; 'full' runs every gate and belongs to
                     pre-push, CI, or an explicit user request.

Exit codes: 0 success, 1 gate failure, 2 usage error.
EOF
}

if [ $# -eq 0 ]; then
    usage
    exit 2
fi

COMPONENT_PATH=""
TARGET_KIND="component"
TIER="fast"
SKIP_STORYBOOK=0
SKIP_TESTS=0

for arg in "$@"; do
    case "$arg" in
        --help|-h) usage; exit 0 ;;
        --skip-storybook) SKIP_STORYBOOK=1 ;;
        --skip-tests) SKIP_TESTS=1 ;;
        --tier) ;;
        --tier=fast) TIER="fast" ;;
        --tier=full) TIER="full" ;;
        fast|full) TIER="$arg" ;;
        component|page) TARGET_KIND="$arg" ;;
        *) if [ -z "$COMPONENT_PATH" ]; then COMPONENT_PATH="$arg"; fi ;;
    esac
done

if [ -z "$COMPONENT_PATH" ]; then
    usage
    exit 2
fi

if [ ! -e "$COMPONENT_PATH" ]; then
    echo "[FAIL] Path not found: $COMPONENT_PATH"
    exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

run_gate() {
    local label="$1"
    shift
    echo "[GATE] $label"
    "$@"
    local code=$?
    if [ $code -ne 0 ]; then
        echo "[FAIL] Gate failed: $label"
        exit $code
    fi
    echo "[PASS] Gate passed: $label"
}

if [ "$TARGET_KIND" = "page" ]; then
    run_gate "Phase 2 - page infrastructure, metadata, and i18n" \
        bash "$SKILLS_ROOT/nextjs-page-dev/scripts/verify-page.sh" "$COMPONENT_PATH"
else
    run_gate "Phase 2 - dev companions and i18n" \
        bash "$SKILLS_ROOT/nextjs-component-dev/scripts/verify-dev.sh" "$COMPONENT_PATH"
fi

if [ "$TARGET_KIND" = "page" ]; then
    echo "[SKIP] Storybook gate (not applicable to pages)"
elif [ "$SKIP_STORYBOOK" -eq 0 ]; then
    run_gate "Phase 3 - Storybook smoke and build" \
        bash "$SKILLS_ROOT/nextjs-storybook-story/scripts/verify-storybook.sh" "$COMPONENT_PATH"
else
    echo "[SKIP] Storybook gate (--skip-storybook)"
fi

if [ "$SKIP_TESTS" -eq 0 ]; then
    QA_MODE="all"
    [ "$TARGET_KIND" = "page" ] && QA_MODE="page"
    run_gate "Phase 4 - QA suites ($QA_MODE, tier $TIER)" \
        bash "$SKILLS_ROOT/nextjs-adversarial-qa/scripts/verify-qa.sh" "$COMPONENT_PATH" "$QA_MODE" "$TIER"
else
    echo "[SKIP] QA suite gate (--skip-tests)"
fi

if [ "$TIER" != "full" ]; then
    echo "[DEFERRED] Expensive tier not executed. It runs at 'git push' through .husky/pre-push:"
    echo "  - full Jest project, Playwright component + page E2E, production build, Storybook build"
    echo "  Explicit re-run: bash verify-component-create.sh $COMPONENT_PATH $TARGET_KIND --tier full"
    echo "[DEFERRED] A deferred suite is not a passing suite."
fi

echo "[SUCCESS] $TARGET_KIND creation verification passed for: $COMPONENT_PATH (tier: $TIER)"
exit 0
