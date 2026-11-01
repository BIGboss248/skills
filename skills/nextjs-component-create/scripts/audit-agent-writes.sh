#!/usr/bin/env bash
set -uo pipefail

# ==============================================================================
# Agent Write Audit (Linux / macOS)
# Classifies files changed since a git ref and fails when the phase touched a
# class it does not own. Pairs with nextjs-component-create Phase 6.
# ==============================================================================

SINCE="HEAD"
PHASE="all"
JSON_MODE=false

usage() {
  cat <<'EOF'
Usage: audit-agent-writes.sh [--since <ref>] [--phase <phase>] [--json]

Phases: baseline | page | implementation | adversarial | final | all
Exit codes: 0 pass, 1 violation, 2 usage/git error.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --since) SINCE="${2:-}"; shift 2 ;;
    --phase) PHASE="${2:-}"; shift 2 ;;
    --json) JSON_MODE=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

case "$PHASE" in
  baseline|page|implementation|adversarial|final|all) ;;
  *) echo "Invalid phase: $PHASE" >&2; exit 2 ;;
esac

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "[FAIL] Not a git repository." >&2
  exit 2
fi

if ! TRACKED=$(git diff --name-only "$SINCE" 2>/dev/null); then
  echo "[FAIL] git diff failed for ref '$SINCE'." >&2
  exit 2
fi

UNTRACKED=$(git ls-files --others --exclude-standard 2>/dev/null || true)

CHANGES=$(printf '%s\n%s\n' "$TRACKED" "$UNTRACKED" | sed '/^[[:space:]]*$/d' | sort -u)

if [ -z "$CHANGES" ]; then
  if [ "$JSON_MODE" = true ]; then
    echo "{\"since\":\"$SINCE\",\"phase\":\"$PHASE\",\"result\":\"pass\",\"changed\":0,\"violations\":[]}"
  else
    echo "[PASS] No changes since '$SINCE' for phase '$PHASE'."
  fi
  exit 0
fi

classify() {
  local p="$1"
  case "$p" in
    */package.json|package.json) echo "config"; return ;;
    *pnpm-lock.yaml|*package-lock.json|*yarn.lock|*bun.lockb) echo "config"; return ;;
    *jest.config.*|*jest.setup.*|*playwright.config.*|*next.config.*|*tsconfig*.json|*eslint.config.*|*vitest.config.*) echo "config"; return ;;
    */test-plan.md|test-plan.md) echo "test-plan"; return ;;
    *.edge.test.ts|*.edge.test.tsx|*.edge.test.js|*.edge.test.jsx) echo "test-edge"; return ;;
    *.test.ts|*.test.tsx|*.test.js|*.test.jsx) echo "test-baseline"; return ;;
    */tests/e2e/pages/*) echo "test-e2e-page"; return ;;
    */tests/e2e/components/*) echo "test-e2e-component"; return ;;
    */tests/e2e/*) echo "test-e2e-other"; return ;;
    */docs/plan/*|docs/plan/*) echo "plan"; return ;;
    */docs/design/*|docs/design/*) echo "design"; return ;;
    */app/*|app/*|*/components/*|components/*|*/lib/*|lib/*|*/hooks/*|hooks/*|*/messages/*|messages/*|*/i18n/*|i18n/*) echo "impl"; return ;;
    *) echo "other"; return ;;
  esac
}

allowed_for_phase() {
  case "$1" in
    baseline) echo "test-baseline test-plan" ;;
    page) echo "test-e2e-page test-plan" ;;
    implementation) echo "impl" ;;
    adversarial) echo "test-edge test-e2e-component" ;;
    final) echo "plan design" ;;
    *) echo "impl test-baseline test-edge test-e2e-page test-e2e-component test-plan plan design other" ;;
  esac
}

ALLOWED=$(allowed_for_phase "$PHASE")
VIOLATIONS=()
ROWS=()

while IFS= read -r file; do
  [ -z "$file" ] && continue
  cls=$(classify "$file")
  ok=false
  for a in $ALLOWED; do
    [ "$cls" = "$a" ] && ok=true
  done
  [ "$cls" = "config" ] && ok=false
  ROWS+=("$ok|$cls|$file")
  [ "$ok" = false ] && VIOLATIONS+=("$file|$cls")
done <<< "$CHANGES"

if [ "$JSON_MODE" = true ]; then
  RESULT="pass"
  [ ${#VIOLATIONS[@]} -gt 0 ] && RESULT="violation"
  printf '{"since":"%s","phase":"%s","result":"%s","changed":%d,"violations":[' "$SINCE" "$PHASE" "$RESULT" "$(printf '%s\n' "$CHANGES" | wc -l | tr -d ' ')"
  first=true
  for v in "${VIOLATIONS[@]}"; do
    [ "$first" = true ] || printf ','
    first=false
    printf '{"path":"%s","class":"%s"}' "${v%%|*}" "${v##*|}"
  done
  printf ']}\n'
  [ "$RESULT" = "pass" ] && exit 0 || exit 1
fi

echo ""
echo "=== Agent Write Audit ==="
echo "Since  : $SINCE"
echo "Phase  : $PHASE"
echo "Allowed: $ALLOWED"
echo ""

for row in "${ROWS[@]}"; do
  ok="${row%%|*}"
  rest="${row#*|}"
  cls="${rest%%|*}"
  file="${rest#*|}"
  if [ "$ok" = true ]; then
    printf '  [OK]   %-18s %s\n' "$cls" "$file"
  else
    printf '  [DENY] %-18s %s\n' "$cls" "$file"
  fi
done

echo ""
if [ ${#VIOLATIONS[@]} -eq 0 ]; then
  echo "[PASS] All changed files match phase '$PHASE'."
  exit 0
fi

echo "[FAIL] ${#VIOLATIONS[@]} path(s) outside phase '$PHASE' boundary:"
for v in "${VIOLATIONS[@]}"; do
  echo "  - ${v%%|*} (${v##*|})"
done
exit 1
