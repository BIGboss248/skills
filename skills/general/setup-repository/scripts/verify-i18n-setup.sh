#!/usr/bin/env bash
# Verifies the next-intl App Router setup produced by feature F11.
# Usage: bash verify-i18n-setup.sh [repo-root] [--quiet]

set -uo pipefail

root="$(pwd)"
quiet=false
for argument in "$@"; do
  case "$argument" in
    --quiet) quiet=true ;;
    *) root="$argument" ;;
  esac
done

errors=0

log() { [ "$quiet" = true ] || printf '  [PASS] %s\n' "$1"; }
fail() { printf '  [FAIL] %s\n' "$1"; errors=$((errors + 1)); }
check() { if [ "$1" -eq 0 ]; then log "$2"; else fail "$2"; fi; }

find_first() {
  for relative in "$@"; do
    if [ -f "$root/$relative" ]; then
      printf '%s' "$root/$relative"
      return 0
    fi
  done
  return 1
}

[ "$quiet" = true ] || printf '=== Verifying Next.js i18n setup (F11) ===\n'

package_json="$root/package.json"
[ -f "$package_json" ] && grep -q '"[[:space:]]*next-intl"' "$package_json"
check $? "next-intl is declared in package.json"

routing="$(find_first i18n/routing.ts src/i18n/routing.ts)"
check $? "routing.ts exists (i18n/ or src/i18n/)"
request="$(find_first i18n/request.ts src/i18n/request.ts)"
check $? "request.ts exists (i18n/ or src/i18n/)"
navigation="$(find_first i18n/navigation.ts src/i18n/navigation.ts)"
check $? "navigation.ts exists (i18n/ or src/i18n/)"

if [ -n "$request" ]; then
  grep -q 'next/root-params' "$request"
  check $? "request.ts reads the locale from next/root-params"
  if grep -qE 'requestLocale|setRequestLocale' "$request"; then
    fail "request.ts does not use the deprecated requestLocale / setRequestLocale()"
  else
    log "request.ts does not use the deprecated requestLocale / setRequestLocale()"
  fi
fi

proxy="$(find_first proxy.ts src/proxy.ts)"
proxy_status=$?
middleware="$(find_first middleware.ts src/middleware.ts)"
middleware_status=$?
if [ "$proxy_status" -eq 0 ] || [ "$middleware_status" -eq 0 ]; then
  log "request interceptor exists (proxy.ts or middleware.ts)"
else
  fail "request interceptor exists (proxy.ts or middleware.ts)"
fi
if [ "$proxy_status" -eq 0 ] && [ "$middleware_status" -eq 0 ]; then
  fail "only one interceptor exists (proxy.ts XOR middleware.ts)"
else
  log "only one interceptor exists (proxy.ts XOR middleware.ts)"
fi

next_major=0
if [ -f "$package_json" ]; then
  next_version=$(grep -oE '"next"[[:space:]]*:[[:space:]]*"[^"]+"' "$package_json" | head -n1)
  if [[ "$next_version" =~ ([0-9]+) ]]; then next_major="${BASH_REMATCH[1]}"; fi
fi
if [ "$next_major" -ge 16 ]; then
  check "$proxy_status" "Next.js $next_major requires proxy.ts"
elif [ "$next_major" -gt 0 ]; then
  check "$middleware_status" "Next.js $next_major requires middleware.ts"
fi

next_config="$(find_first next.config.ts next.config.mjs next.config.js next.config.cjs)"
if [ -n "$next_config" ] && grep -q 'createNextIntlPlugin' "$next_config"; then
  log "next.config wraps the config with createNextIntlPlugin()"
else
  fail "next.config wraps the config with createNextIntlPlugin()"
fi

layout="$(find_first 'app/[locale]/layout.tsx' 'src/app/[locale]/layout.tsx')"
if [ -n "$layout" ] && grep -q 'generateStaticParams' "$layout"; then
  log "app/[locale]/layout.tsx exports generateStaticParams()"
else
  fail "app/[locale]/layout.tsx exports generateStaticParams()"
fi
if [ -n "$layout" ] && grep -q 'NextIntlClientProvider' "$layout"; then
  log "locale layout renders NextIntlClientProvider"
else
  fail "locale layout renders NextIntlClientProvider"
fi

root_layout="$(find_first app/layout.tsx src/app/layout.tsx)"
if [ -n "$root_layout" ] && [ -n "$layout" ] && grep -q '<html' "$root_layout"; then
  fail "root layout does not render a second <html> element"
else
  log "root layout does not render a second <html> element"
fi

global_types="$(find_first global.d.ts src/global.d.ts types/global.d.ts src/types/global.d.ts)"
if [ -n "$global_types" ] && grep -q 'AppConfig' "$global_types" && grep -q 'Messages' "$global_types"; then
  log "global.d.ts augments AppConfig.Messages"
else
  fail "global.d.ts augments AppConfig.Messages"
fi

dictionaries="$root/messages"
[ -d "$dictionaries" ] || dictionaries="$root/src/messages"
if [ -d "$dictionaries" ]; then
  log "messages/ dictionary directory exists"
else
  fail "messages/ dictionary directory exists"
fi

locales=()
if [ -n "$routing" ]; then
  locale_line=$(grep -oE 'locales[[:space:]]*:[[:space:]]*\[[^]]*\]' "$routing" | head -n1)
  if [ -n "$locale_line" ]; then
    raw="${locale_line#*[}"
    raw="${raw%]*}"
    IFS=',' read -r -a parts <<< "$raw"
    for part in "${parts[@]}"; do
      cleaned=$(printf '%s' "$part" | sed -e 's/["'"'"']//g' -e 's/[[:space:]]//g')
      [ -n "$cleaned" ] && locales+=("$cleaned")
    done
  fi
fi
if [ "${#locales[@]}" -gt 0 ]; then
  log "routing.ts declares at least one locale"
else
  fail "routing.ts declares at least one locale"
fi

dictionary_files=()
for locale in "${locales[@]}"; do
  if [ -f "$dictionaries/$locale.json" ]; then
    log "dictionary messages/$locale.json exists"
    dictionary_files+=("$dictionaries/$locale.json")
  else
    fail "dictionary messages/$locale.json exists"
  fi
done

if [ "${#dictionary_files[@]}" -gt 0 ]; then
  if ! command -v node >/dev/null 2>&1; then
    fail "node is available for dictionary key parity"
  else
    parity_output=$(node - "${dictionary_files[@]}" <<'NODE'
const fs = require("fs");
const flatten = (node, prefix = "", out = []) => {
  if (node && typeof node === "object" && !Array.isArray(node)) {
    for (const [key, value] of Object.entries(node)) {
      const child = prefix ? `${prefix}.${key}` : key;
      out.push(child);
      flatten(value, child, out);
    }
  }
  return out;
};
const [baseline, ...files] = process.argv.slice(2);
const base = new Set(flatten(JSON.parse(fs.readFileSync(baseline, "utf8"))));
let failed = false;
for (const file of files) {
  const keys = new Set(flatten(JSON.parse(fs.readFileSync(file, "utf8"))));
  const missing = [...base].filter((key) => !keys.has(key));
  const extra = [...keys].filter((key) => !base.has(key));
  if (missing.length || extra.length) {
    failed = true;
    console.log(`  [FAIL] dictionary keys match baseline in ${file}`);
    missing.forEach((key) => console.log(`         missing key: ${key}`));
    extra.forEach((key) => console.log(`         unexpected key: ${key}`));
  } else {
    console.log(`  [PASS] dictionary keys match baseline in ${file}`);
  }
}
process.exit(failed ? 1 : 0);
NODE
)
    parity_status=$?
    if [ "$parity_status" -ne 0 ]; then
      errors=$((errors + 1))
      printf '%s\n' "$parity_output" | grep -E '\[FAIL\]|missing key|unexpected key' || true
    else
      [ "$quiet" = true ] || printf '%s\n' "$parity_output"
    fi
  fi
fi

project_json="$root/docs/project.json"
if [ -f "$project_json" ] && grep -q '"dictionaries_dir"' "$project_json" && grep -q '"dictionary_file_pattern"' "$project_json"; then
  log "docs/project.json records dictionaries_dir and dictionary_file_pattern"
else
  fail "docs/project.json records dictionaries_dir and dictionary_file_pattern"
fi

if [ "$errors" -gt 0 ]; then
  printf 'i18n-setup: FAIL (%s error(s))\n' "$errors"
  exit 1
fi

printf 'i18n-setup: PASS\n'
exit 0
