#!/usr/bin/env bash
set -u

usage() {
    cat <<'EOF'
Usage: bash verify-component-create.sh <TargetPath> [component|page] [--skip-storybook] [--skip-tests] [--help]

End-to-end verification for the Next.js creation pipeline.

Runs the phase gates in order: component infrastructure or page route files,
Storybook (components only), then QA suites (baseline + adversarial + Playwright,
or the page suite). Stops at the first failure.

Exit codes: 0 success, 1 gate failure, 2 usage error.
EOF
}

if [ $# -eq 0 ]; then
    usage
    exit 2
fi

COMPONENT_PATH=""
TARGET_KIND="component"
SKIP_STORYBOOK=0
SKIP_TESTS=0

for arg in "$@"; do
    case "$arg" in
        --help|-h) usage; exit 0 ;;
        --skip-storybook) SKIP_STORYBOOK=1 ;;
        --skip-tests) SKIP_TESTS=1 ;;
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
    run_gate "Phase 4 - QA suites ($QA_MODE)" \
        bash "$SKILLS_ROOT/nextjs-adversarial-qa/scripts/verify-qa.sh" "$COMPONENT_PATH" "$QA_MODE"
else
    echo "[SKIP] QA suite gate (--skip-tests)"
fi

echo "[SUCCESS] $TARGET_KIND creation verification passed for: $COMPONENT_PATH"
exit 0
