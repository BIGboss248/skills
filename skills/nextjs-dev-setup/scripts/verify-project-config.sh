#!/usr/bin/env bash
set -e

# ==============================================================================
# Next.js Dev Setup & project.json Verification Script (Linux / macOS)
# ==============================================================================

BOLD="\033[1m"
RESET="\033[0m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
CYAN="\033[36m"
MAGENTA="\033[35m"

JSON_MODE=false
CUSTOM_CONFIG=""

for arg in "$@"; do
  if [ "$arg" == "--json" ]; then
    JSON_MODE=true
  else
    CUSTOM_CONFIG="$arg"
  fi
done

ROOT_DIR="$(pwd)"

resolve_config_path() {
  if [ -n "$CUSTOM_CONFIG" ] && [ -f "$CUSTOM_CONFIG" ]; then
    echo "$CUSTOM_CONFIG"
    return
  fi

  local candidates=(
    "docs/project.json"
    "docs/PROJECT.JSON"
    ".agents/project.json"
    ".agents/PROJECT.JSON"
  )

  for c in "${candidates[@]}"; do
    if [ -f "$c" ]; then
      echo "$c"
      return
    fi
  done

  echo "docs/project.json"
}

CONFIG_FILE="$(resolve_config_path)"
ERRORS=()
WARNINGS=()
PATH_CHECKS=()
AUTOMATION_CHECKS=()

FILE_EXISTS=false
IS_VALID_JSON=false

if [ -f "$CONFIG_FILE" ]; then
  FILE_EXISTS=true
  if command -v jq >/dev/null 2>&1; then
    if jq empty "$CONFIG_FILE" >/dev/null 2>&1; then
      IS_VALID_JSON=true
    fi
  elif command -v node >/dev/null 2>&1; then
    if node -e "JSON.parse(require('fs').readFileSync('$CONFIG_FILE', 'utf8'))" >/dev/null 2>&1; then
      IS_VALID_JSON=true
    fi
  else
    IS_VALID_JSON=true
  fi
else
  ERRORS+=("Configuration file not found at: $CONFIG_FILE")
fi

if [ "$FILE_EXISTS" = true ] && [ "$IS_VALID_JSON" = false ]; then
  ERRORS+=("Invalid JSON syntax in '$CONFIG_FILE'")
fi

# Schema validations using node or jq if available
if [ "$IS_VALID_JSON" = true ]; then
  if command -v node >/dev/null 2>&1; then
    SCHEMA_RES=$(node -e "
      const fs = require('fs');
      try {
        const data = JSON.parse(fs.readFileSync('$CONFIG_FILE', 'utf8'));
        const meta = data.project_context_and_metadata;
        if (!meta) {
          console.log('ERROR:Missing required top-level key: project_context_and_metadata');
          process.exit(0);
        }
        const reqStrings = ['package_manager', 'new_component_dir', 'style_file_dir', 'component_library', 'dictionaries_dir', 'dictionary_file_pattern'];
        for (const s of reqStrings) {
          if (!meta[s] || typeof meta[s] !== 'string' || !meta[s].trim()) {
            console.log('ERROR:Missing or empty required property: ' + s);
          }
        }
        const reqArrays = ['animation_library', 'testing_library'];
        for (const a of reqArrays) {
          if (!meta[a] || !Array.isArray(meta[a]) || meta[a].length === 0) {
            console.log('ERROR:Property ' + a + ' must be a non-empty array');
          }
        }
        if (!meta.supported_languages || !Array.isArray(meta.supported_languages) || meta.supported_languages.length === 0) {
          console.log('ERROR:Property supported_languages must contain at least one locale object');
        } else {
          meta.supported_languages.forEach((loc, idx) => {
            const reqF = ['language_code', 'country_code', 'currency_code', 'direction', 'native_name', 'calendar_type'];
            for (const f of reqF) {
              if (!loc[f] || !String(loc[f]).trim()) {
                console.log('ERROR:supported_languages[' + idx + '] missing field: ' + f);
              }
            }
            if (loc.direction && loc.direction !== 'ltr' && loc.direction !== 'rtl') {
              console.log('ERROR:supported_languages[' + idx + '].direction must be ltr or rtl');
            }
          });
        }
      } catch (e) {
        console.log('ERROR:' + e.message);
      }
    ")
    while IFS= read -r line; do
      if [[ "$line" =~ ^ERROR:(.*) ]]; then
        ERRORS+=("${BASH_REMATCH[1]}")
      fi
    done <<< "$SCHEMA_RES"
  fi
fi

# Filesystem path audits
check_path() {
  local prop="$1"
  local expected="$2"
  local type="$3"

  if [ -z "$expected" ]; then return; fi

  if [ "$type" == "file" ]; then
    if [ -f "$expected" ]; then
      PATH_CHECKS+=("OK:$prop:$expected:file")
    else
      PATH_CHECKS+=("MISSING:$prop:$expected:file")
      WARNINGS+=("Path '$expected' referenced by '$prop' was not found on disk.")
    fi
  else
    if [ -d "$expected" ]; then
      PATH_CHECKS+=("OK:$prop:$expected:dir")
    else
      PATH_CHECKS+=("MISSING:$prop:$expected:dir")
      WARNINGS+=("Directory '$expected' referenced by '$prop' does not exist.")
    fi
  fi
}

if [ "$IS_VALID_JSON" = true ] && command -v node >/dev/null 2>&1; then
  PATHS_DATA=$(node -e "
    const fs = require('fs');
    const meta = JSON.parse(fs.readFileSync('$CONFIG_FILE', 'utf8')).project_context_and_metadata || {};
    if (meta.style_file_dir) console.log('style_file_dir|' + meta.style_file_dir + '|file');
    if (meta.new_component_dir) console.log('new_component_dir|' + meta.new_component_dir + '|dir');
    if (meta.dictionaries_dir) {
      console.log('dictionaries_dir|' + meta.dictionaries_dir + '|dir');
      if (Array.isArray(meta.supported_languages) && meta.dictionary_file_pattern) {
        meta.supported_languages.forEach(loc => {
          if (loc.language_code) {
            const fn = meta.dictionary_file_pattern.replace(/\[locale\]/g, loc.language_code);
            console.log('dictionary:' + loc.language_code + '|' + meta.dictionaries_dir + '/' + fn + '|file');
          }
        });
      }
    }
  ")
  while IFS= read -r line; do
    if [ -n "$line" ]; then
      IFS='|' read -r p e t <<< "$line"
      check_path "$p" "$e" "$t"
    fi
  done <<< "$PATHS_DATA"
fi

# --- Automation Checks ---

# 1. Commitlint
if [ -f "commitlint.config.mjs" ] || [ -f "commitlint.config.js" ] || [ -f "commitlint.config.ts" ] || [ -f ".commitlintrc.json" ]; then
  AUTOMATION_CHECKS+=("OK:Commitlint Configuration:Found configuration enforcing Conventional Commits.")
else
  AUTOMATION_CHECKS+=("MISSING:Commitlint Configuration:Missing commitlint.config.mjs.")
fi

# 2. Husky
if [ -d ".husky" ]; then
  if [ -f ".husky/commit-msg" ] && [ -f ".husky/pre-push" ]; then
    AUTOMATION_CHECKS+=("OK:Husky Git Hooks:Configured with .husky/commit-msg and .husky/pre-push hooks.")
  else
    AUTOMATION_CHECKS+=("WARN:Husky Git Hooks:Husky initialized but missing commit-msg or pre-push hook.")
  fi
else
  AUTOMATION_CHECKS+=("MISSING:Husky Git Hooks:Missing .husky/ directory.")
fi

# 3. Release Please
if [ -f ".github/workflows/release-please.yml" ] || [ -f ".github/workflows/release.yml" ]; then
  WF=".github/workflows/release-please.yml"
  [ -f ".github/workflows/release.yml" ] && WF=".github/workflows/release.yml"
  CACHE_NOTE=""
  if grep -q "\.next/cache" "$WF" 2>/dev/null; then
    CACHE_NOTE=" [Next.js CI build cache enabled]"
  fi
  AUTOMATION_CHECKS+=("OK:Release Please CI/CD:Found GitHub Actions workflow '$WF'.$CACHE_NOTE")
else
  AUTOMATION_CHECKS+=("WARN:Release Please CI/CD:Missing .github/workflows/release-please.yml.")
fi

# 4. Jest & Playwright
if [ -f "jest.config.ts" ] || [ -f "jest.config.js" ] || [ -f "jest.config.mjs" ]; then
  AUTOMATION_CHECKS+=("OK:Jest Test Runner:Configured for unit & snapshot testing.")
else
  AUTOMATION_CHECKS+=("WARN:Jest Test Runner:Missing jest.config.ts.")
fi

if [ -f "playwright.config.ts" ] || [ -f "playwright.config.js" ] || [ -f "playwright.config.mjs" ]; then
  AUTOMATION_CHECKS+=("OK:Playwright Test Runner:Configured for E2E testing.")
else
  AUTOMATION_CHECKS+=("WARN:Playwright Test Runner:Missing playwright.config.ts.")
fi

# 5. MCP Integration
WS_MCP=""
for p in "mcp.json" ".agents/plugins/workspace-tools/mcp_config.json" ".vscode/mcp.json"; do
  if [ -f "$p" ]; then WS_MCP="$p"; break; fi
done

if [ -n "$WS_MCP" ]; then
  if grep -q "next-devtools" "$WS_MCP" 2>/dev/null && grep -q "playwright" "$WS_MCP" 2>/dev/null && grep -q "codebase-memory" "$WS_MCP" 2>/dev/null; then
    AUTOMATION_CHECKS+=("OK:Workspace MCP Server Integration:Found '$WS_MCP' with next-devtools, codebase-memory, and playwright.")
  else
    AUTOMATION_CHECKS+=("WARN:Workspace MCP Server Integration:'$WS_MCP' missing one or more required MCP servers.")
  fi
else
  AUTOMATION_CHECKS+=("WARN:Workspace MCP Server Integration:Missing workspace mcp.json.")
fi

# 6. .cbmignore
if [ -f ".cbmignore" ]; then
  if grep -q "\.agents" ".cbmignore" && grep -q "docs" ".cbmignore" && grep -q "\.next" ".cbmignore"; then
    AUTOMATION_CHECKS+=("OK:Codebase Memory Exclusions (.cbmignore):Found root '.cbmignore' with essential cache/doc exclusions.")
  else
    AUTOMATION_CHECKS+=("WARN:Codebase Memory Exclusions (.cbmignore):Missing key exclusions in .cbmignore.")
  fi
else
  AUTOMATION_CHECKS+=("WARN:Codebase Memory Exclusions (.cbmignore):Missing root '.cbmignore' file.")
fi

# 7. Docker
if [ -f "Dockerfile" ] && { [ -f "docker-compose.yml" ] || [ -f "compose.yaml" ]; } && [ -f ".dockerignore" ]; then
  AUTOMATION_CHECKS+=("OK:Docker Containerization:Configured production standalone Dockerfile, docker-compose.yml, and .dockerignore.")
else
  AUTOMATION_CHECKS+=("WARN:Docker Containerization:Missing one or more containerization files (Dockerfile, docker-compose.yml, .dockerignore).")
fi

# 8. @shadcn/lint
HAS_SHADCN_DEP=false
if [ -f "package.json" ] && grep -q '"@shadcn/lint"' package.json; then
  HAS_SHADCN_DEP=true
fi

HAS_SHADCN_CONFIG=false
for cfg in "eslint.config.mjs" "eslint.config.js" "eslint.config.ts" ".eslintrc.json"; do
  if [ -f "$cfg" ] && { grep -q "@shadcn/lint" "$cfg" || grep -q "shadcn" "$cfg"; }; then
    HAS_SHADCN_CONFIG=true
    break
  fi
done

if [ "$HAS_SHADCN_DEP" = true ] && [ "$HAS_SHADCN_CONFIG" = true ]; then
  AUTOMATION_CHECKS+=("OK:Agent-First Tailwind Linter (@shadcn/lint):Installed and registered with design system rules.")
elif [ "$HAS_SHADCN_DEP" = true ] || [ "$HAS_SHADCN_CONFIG" = true ]; then
  AUTOMATION_CHECKS+=("WARN:Agent-First Tailwind Linter (@shadcn/lint):Partially configured (missing package dependency or eslint config).")
else
  AUTOMATION_CHECKS+=("WARN:Agent-First Tailwind Linter (@shadcn/lint):Missing @shadcn/lint in package.json and ESLint config.")
fi

# 9. App Icons & PWA Web Manifest
APP_DIR="app"
[ -d "src/app" ] && APP_DIR="src/app"

FOUND_MANIFEST=""
for m in "$APP_DIR/manifest.ts" "$APP_DIR/manifest.js" "$APP_DIR/manifest.json" "$APP_DIR/manifest.webmanifest"; do
  if [ -f "$m" ]; then FOUND_MANIFEST="$m"; break; fi
done

HAS_FAVICON=false
[ -f "$APP_DIR/favicon.ico" ] || [ -f "public/favicon.ico" ] && HAS_FAVICON=true
HAS_ICON=false
for ic in "$APP_DIR/icon.png" "$APP_DIR/icon.ico" "$APP_DIR/icon.svg" "$APP_DIR/icon.tsx" "$APP_DIR/icon.js"; do
  if [ -f "$ic" ]; then HAS_ICON=true; break; fi
done
HAS_APPLE_ICON=false
for aic in "$APP_DIR/apple-icon.png" "$APP_DIR/apple-icon.jpg" "$APP_DIR/apple-icon.tsx" "$APP_DIR/apple-icon.js"; do
  if [ -f "$aic" ]; then HAS_APPLE_ICON=true; break; fi
done

if [ -n "$FOUND_MANIFEST" ] && { [ "$HAS_FAVICON" = true ] || [ "$HAS_ICON" = true ] || [ "$HAS_APPLE_ICON" = true ]; }; then
  AUTOMATION_CHECKS+=("OK:App Icons & PWA Web Manifest:Found '$FOUND_MANIFEST' and App Router icon file conventions.")
elif [ -n "$FOUND_MANIFEST" ]; then
  AUTOMATION_CHECKS+=("OK:App Icons & PWA Web Manifest:Found Web App Manifest '$FOUND_MANIFEST'.")
else
  AUTOMATION_CHECKS+=("WARN:App Icons & PWA Web Manifest:Missing Web App Manifest ($APP_DIR/manifest.ts) and App Router icon conventions.")
fi

# --- Output ---

if [ ${#ERRORS[@]} -eq 0 ]; then
  PASSED=true
else
  PASSED=false
fi

if [ "$JSON_MODE" = true ]; then
  echo "{\"passed\": $PASSED, \"config\": \"$CONFIG_FILE\", \"errors\": ${#ERRORS[@]}, \"warnings\": ${#WARNINGS[@]}}"
  if [ "$PASSED" = true ]; then exit 0; else exit 1; fi
fi

echo -e "\n${BOLD}${CYAN}=== Next.js Dev Setup & project.json Verification ===${RESET}\n"
echo -e "${BOLD}Configuration File:${RESET} $CONFIG_FILE"
echo -e "${BOLD}File Exists:${RESET} $([ "$FILE_EXISTS" = true ] && echo -e "${GREEN}Yes${RESET}" || echo -e "${RED}No${RESET}")"
echo -e "${BOLD}Valid JSON:${RESET} $([ "$IS_VALID_JSON" = true ] && echo -e "${GREEN}Yes${RESET}" || echo -e "${RED}No${RESET}")\n"

if [ ${#PATH_CHECKS[@]} -gt 0 ]; then
  echo -e "${BOLD}${MAGENTA}▶ Filesystem Structure & i18n Paths:${RESET}"
  for check in "${PATH_CHECKS[@]}"; do
    IFS=':' read -r st prop pth typ <<< "$check"
    if [ "$st" == "OK" ]; then
      echo -e "  ${GREEN}✓${RESET} ${CYAN}$prop${RESET}: $pth (${GREEN}Exists${RESET})"
    else
      echo -e "  ${YELLOW}✗${RESET} ${CYAN}$prop${RESET}: $pth (${YELLOW}Missing${RESET})"
    fi
  done
  echo ""
fi

if [ ${#AUTOMATION_CHECKS[@]} -gt 0 ]; then
  echo -e "${BOLD}${MAGENTA}▶ Git Hooks, Commit Standards & Release Automation:${RESET}"
  for check in "${AUTOMATION_CHECKS[@]}"; do
    IFS=':' read -r st name desc <<< "$check"
    if [ "$st" == "OK" ]; then
      echo -e "  ${GREEN}[OK]${RESET} ${BOLD}$name:${RESET} $desc"
    elif [ "$st" == "WARN" ]; then
      echo -e "  ${YELLOW}[WARN]${RESET} ${BOLD}$name:${RESET} $desc"
    else
      echo -e "  ${RED}[MISSING]${RESET} ${BOLD}$name:${RESET} $desc"
    fi
  done
  echo ""
fi

if [ ${#WARNINGS[@]} -gt 0 ]; then
  echo -e "${YELLOW}${BOLD}Warnings & Recommendations:${RESET}"
  for w in "${WARNINGS[@]}"; do
    echo -e "  ⚠️  $w"
  done
  echo ""
fi

if [ ${#ERRORS[@]} -gt 0 ]; then
  echo -e "${RED}${BOLD}Errors / Violations:${RESET}"
  for e in "${ERRORS[@]}"; do
    echo -e "  ✗ $e"
  done
  echo ""
fi

if [ "$PASSED" = true ]; then
  echo -e "${GREEN}${BOLD}✓ SUCCESS: project.json is valid and complete.${RESET}\n"
  exit 0
else
  echo -e "${RED}${BOLD}✗ FAILED: project.json has missing or invalid properties.${RESET}\n"
  exit 1
fi

