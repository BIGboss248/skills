#!/usr/bin/env bash
set -eo pipefail

PORT=3000
URL="http://127.0.0.1:${PORT}"
SPAWNED_SERVER=0
SERVER_PID=""

NODE_BIN=$(command -v node 2>/dev/null || command -v node.exe 2>/dev/null || echo "node")
NPX_BIN=$(command -v npx 2>/dev/null || command -v npx.cmd 2>/dev/null || echo "npx")
PNPM_BIN=$(command -v pnpm 2>/dev/null || command -v pnpm.cmd 2>/dev/null || echo "pnpm")

cleanup() {
  if [ "$SPAWNED_SERVER" -eq 1 ] && [ -n "$SERVER_PID" ]; then
    echo "[SEO Pre-Push] Shutting down spawned background dev server (PID: $SERVER_PID)..."
    kill "$SERVER_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

echo "[SEO Pre-Push] Probing for active dev server at $URL..."

# Check if server is already responding
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "$URL" 2>/dev/null || echo "000")
HTTP_CODE=$(echo "$HTTP_CODE" | tr -d '\r\n' | tail -c 3)

if [ "$HTTP_CODE" != "000" ] && [ -n "$HTTP_CODE" ]; then
  echo "[SEO Pre-Push] Detected running dev server with HTTP status $HTTP_CODE. Reusing existing instance."
else
  echo "[SEO Pre-Push] No active dev server detected. Starting dev server..."
  $PNPM_BIN run dev >/dev/null 2>&1 &
  SERVER_PID=$!
  SPAWNED_SERVER=1

  echo "[SEO Pre-Push] Waiting for dev server to become ready..."
  READY=0
  for i in $(seq 1 30); do
    CHECK_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 1 "$URL" 2>/dev/null || echo "000")
    CHECK_CODE=$(echo "$CHECK_CODE" | tr -d '\r\n' | tail -c 3)
    if [ "$CHECK_CODE" != "000" ] && [ -n "$CHECK_CODE" ]; then
      READY=1
      echo "[SEO Pre-Push] Dev server is ready with HTTP status $CHECK_CODE!"
      break
    fi
    sleep 1
  done

  if [ "$READY" -ne 1 ]; then
    echo "[SEO Pre-Push] Timed out waiting for dev server to start on port $PORT."
    exit 1
  fi
fi

echo "[SEO Pre-Push] Executing SEO technical audit against $URL..."
AUDIT_JSON=$($NPX_BIN -y seo report --url "$URL" --actions-only --json)

# Parse fixes count using node
FIXES_COUNT=$($NODE_BIN -e "
  try {
    const data = JSON.parse(process.argv[1]);
    const fixes = data?.findings?.counts?.fixes ?? 0;
    process.stdout.write(String(fixes));
  } catch (e) {
    process.stdout.write('0');
  }
" "$AUDIT_JSON")

if [ "$FIXES_COUNT" -gt 0 ]; then
  echo "[SEO Pre-Push] SEO quality gate failed! Found $FIXES_COUNT critical technical fix(es)."
  echo "$AUDIT_JSON"
  exit 1
fi

echo "[SEO Pre-Push] SEO quality gate passed with 0 critical findings."
exit 0
