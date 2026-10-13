#!/usr/bin/env bash
set -euo pipefail

ROUTE_PATH="${1:-}"

if [ -z "$ROUTE_PATH" ]; then
  echo "❌ Error: Route path argument is required. Usage: verify-page.sh <path>"
  exit 1
fi

echo "🔍 Verifying Next.js Page at: $ROUTE_PATH"

PAGE_FILE="$ROUTE_PATH/page.tsx"
if [ ! -f "$PAGE_FILE" ]; then
  echo "❌ Missing required page file: $PAGE_FILE"
  exit 1
fi
echo "✅ Found page.tsx"

if grep -q "generateMetadata" "$PAGE_FILE"; then
  echo "✅ Exports generateMetadata"
else
  echo "⚠️ Warning: page.tsx does not export generateMetadata."
fi

LOADING_FILE="$ROUTE_PATH/loading.tsx"
if [ -f "$LOADING_FILE" ]; then
  echo "✅ Found loading.tsx skeleton fallback"
else
  echo "ℹ️ No loading.tsx found; assuming in-page component Suspense boundaries."
fi

echo "🎉 Page verification complete for: $ROUTE_PATH"
exit 0
