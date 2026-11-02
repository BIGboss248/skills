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
ALL_FEATURES=false
SELECTION_PATH=".agents/nextjs-setup-features.json"

while [ $# -gt 0 ]; do
  case "$1" in
    --json) JSON_MODE=true ;;
    --all) ALL_FEATURES=true ;;
    --selection)
      shift
      if [ $# -gt 0 ]; then SELECTION_PATH="$1"; fi
      ;;
    *) CUSTOM_CONFIG="$1" ;;
  esac
  shift
done

ROOT_DIR="$(pwd)"

# Feature selection (.agents/nextjs-setup-features.json, fallback docs/project.json)
SELECTION_FILE=""
if [ "$ALL_FEATURES" = false ]; then
  for candidate in "$SELECTION_PATH" "docs/project.json"; do
    if [ -f "$candidate" ]; then
      SELECTION_FILE="$candidate"
      break
    fi
  done
fi

ENABLED_FEATURES=""
if [ -n "$SELECTION_FILE" ] && command -v node >/dev/null 2>&1; then
  ENABLED_FEATURES=$(node -e '
    const fs = require("fs");
    try {
      let data = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
      data = data.nextjs_setup_features || data;
      if (Array.isArray(data.enabled)) console.log(data.enabled.join(" "));
    } catch (error) {
      /* unreadable selection: audit every feature */
    }
  ' "$SELECTION_FILE")
fi

feature_enabled() {
  [ -z "$ENABLED_FEATURES" ] && return 0
  case " $ENABLED_FEATURES " in
    *" $1 "*) return 0 ;;
    *) return 1 ;;
  esac
}

check_feature() {
  case "$1" in
    "Commitlint Configuration"|"Husky Git Hooks"|"Release Please CI/CD"|"GitHub Triage Infrastructure") echo "N12" ;;
    "Jest Test Runner") echo "N5" ;;
    "Playwright Test Runner") echo "N6" ;;
    "Workspace MCP Server Integration"|"Antigravity Global MCP Integration"|"Codebase Memory Exclusions (.cbmignore)") echo "N10" ;;
    "Docker Containerization") echo "N11" ;;
    "Agent-First Tailwind Linter (@shadcn/lint)") echo "N8" ;;
    "App Icons & PWA Web Manifest") echo "N3" ;;
    "Next.js Internationalization (next-intl)") echo "N4" ;;
    "Next.js Core Dependency (next@latest)"|"Agent Instructions & Docs Notice"*) echo "N2" ;;
    "Agent Roster & Permission Boundaries") echo "N9" ;;
    *) echo "" ;;
  esac
}

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
  if feature_enabled N1; then
    ERRORS+=("Configuration file not found at: $CONFIG_FILE")
  fi
fi

if [ "$FILE_EXISTS" = true ] && [ "$IS_VALID_JSON" = false ] && feature_enabled N1; then
  ERRORS+=("Invalid JSON syntax in '$CONFIG_FILE'")
fi

# Schema validations using node or jq if available
if [ "$IS_VALID_JSON" = true ] && feature_enabled N1; then
  if command -v node >/dev/null 2>&1; then
    DICT_REQUIRED=false
    feature_enabled N4 && DICT_REQUIRED=true
    SCHEMA_RES=$(DICT_REQUIRED="$DICT_REQUIRED" node -e "
      const fs = require('fs');
      try {
        const data = JSON.parse(fs.readFileSync('$CONFIG_FILE', 'utf8'));
        const meta = data.project_context_and_metadata;
        if (!meta) {
          console.log('ERROR:Missing required top-level key: project_context_and_metadata');
          process.exit(0);
        }
        const reqStrings = ['package_manager', 'new_component_dir', 'style_file_dir', 'component_library'];
        if (process.env.DICT_REQUIRED === 'true') {
          reqStrings.push('dictionaries_dir', 'dictionary_file_pattern');
        }
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

if [ "$IS_VALID_JSON" = true ] && feature_enabled N1 && command -v node >/dev/null 2>&1; then
  DICT_REQUIRED=false
  feature_enabled N4 && DICT_REQUIRED=true
  PATHS_DATA=$(DICT_REQUIRED="$DICT_REQUIRED" node -e "
    const fs = require('fs');
    const meta = JSON.parse(fs.readFileSync('$CONFIG_FILE', 'utf8')).project_context_and_metadata || {};
    if (meta.style_file_dir) console.log('style_file_dir|' + meta.style_file_dir + '|file');
    if (meta.new_component_dir) console.log('new_component_dir|' + meta.new_component_dir + '|dir');
    if (process.env.DICT_REQUIRED === 'true' && meta.dictionaries_dir) {
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

# 10. Next.js Internationalization (next-intl)
HAS_INTL_DEP=false
if [ -f "package.json" ] && grep -q '"next-intl"' package.json; then
  HAS_INTL_DEP=true
fi

HAS_ROUTING=false
[ -f "i18n/routing.ts" ] || [ -f "src/i18n/routing.ts" ] && HAS_ROUTING=true

HAS_REQUEST=false
[ -f "i18n/request.ts" ] || [ -f "src/i18n/request.ts" ] && HAS_REQUEST=true

HAS_NAVIGATION=false
[ -f "i18n/navigation.ts" ] || [ -f "src/i18n/navigation.ts" ] && HAS_NAVIGATION=true

HAS_INTERCEPTOR=false
[ -f "proxy.ts" ] || [ -f "src/proxy.ts" ] || [ -f "middleware.ts" ] || [ -f "src/middleware.ts" ] && HAS_INTERCEPTOR=true

HAS_INTL_PLUGIN=false
for nc in "next.config.ts" "next.config.js" "next.config.mjs"; do
  if [ -f "$nc" ] && { grep -q "next-intl" "$nc" || grep -q "withNextIntl" "$nc"; }; then
    HAS_INTL_PLUGIN=true
    break
  fi
done

MISSING_INTL=()
[ "$HAS_INTL_DEP" = false ] && MISSING_INTL+=("package next-intl")
[ "$HAS_ROUTING" = false ] && MISSING_INTL+=("i18n/routing.ts")
[ "$HAS_REQUEST" = false ] && MISSING_INTL+=("i18n/request.ts")
[ "$HAS_NAVIGATION" = false ] && MISSING_INTL+=("i18n/navigation.ts")
[ "$HAS_INTERCEPTOR" = false ] && MISSING_INTL+=("proxy.ts/middleware.ts")
[ "$HAS_INTL_PLUGIN" = false ] && MISSING_INTL+=("next.config wrapper")

if [ ${#MISSING_INTL[@]} -eq 0 ]; then
  AUTOMATION_CHECKS+=("OK:Next.js Internationalization (next-intl):Configured next-intl, routing, request, navigation, interceptor, and next.config plugin.")
else
  AUTOMATION_CHECKS+=("WARN:Next.js Internationalization (next-intl):Incomplete next-intl setup. Missing: $(IFS=', '; echo "${MISSING_INTL[*]}")")
fi

# 11. GitHub Triage Infrastructure (.github/ISSUE_TEMPLATE)
if [ -f ".github/ISSUE_TEMPLATE/bug_report.yml" ] && [ -f ".github/ISSUE_TEMPLATE/config.yml" ]; then
  AUTOMATION_CHECKS+=("OK:GitHub Triage Infrastructure:Found .github/ISSUE_TEMPLATE/bug_report.yml and config.yml for github-triage.")
else
  AUTOMATION_CHECKS+=("WARN:GitHub Triage Infrastructure:Missing .github/ISSUE_TEMPLATE/bug_report.yml or config.yml. Run scripts/init_triage_infra.ps1.")
fi

# 12. Agent Rules & Next.js Local Docs Notice (AGENTS.md / agent.md)
FOUND_AGENT_MD=""
for am in "AGENTS.md" "agents.md" "AGENT.md" "agent.md"; do
  if [ -f "$am" ]; then FOUND_AGENT_MD="$am"; break; fi
done

if [ -n "$FOUND_AGENT_MD" ]; then
  if grep -qi "outdated" "$FOUND_AGENT_MD" && grep -qiE "node_modules[\\/]next[\\/]dist[\\/]docs" "$FOUND_AGENT_MD"; then
    AUTOMATION_CHECKS+=("OK:Agent Instructions & Docs Notice ($FOUND_AGENT_MD):Found '$FOUND_AGENT_MD' with outdated context notice and node_modules/next/dist/docs mandate.")
  else
    AUTOMATION_CHECKS+=("WARN:Agent Instructions & Docs Notice ($FOUND_AGENT_MD):Missing outdated context notice or node_modules/next/dist/docs search mandate.")
  fi
else
  AUTOMATION_CHECKS+=("WARN:Agent Instructions & Docs Notice (AGENTS.md):Missing AGENTS.md / agent.md file.")
fi

# 13. Next.js Core Dependency (next@latest)
if [ -f "package.json" ] && grep -q '"next"' package.json; then
  AUTOMATION_CHECKS+=("OK:Next.js Core Dependency (next@latest):Found 'next' dependency in package.json (always target latest).")
else
  AUTOMATION_CHECKS+=("WARN:Next.js Core Dependency (next@latest):Missing 'next' dependency in package.json. Run '<pkg_mgr> add next@latest'.")
fi

# 14. Agent Roster & Permission Boundaries (.opencode/agents)
AGENT_MISSING=()
AGENT_INVALID=()
check_agent() {
  local name="$1"; local file="$2"; local mode="$3"; local needles="$4"
  if [ ! -f "$file" ]; then
    AGENT_MISSING+=("$file")
    return
  fi
  local problems=""
  grep -Eq "^mode:[[:space:]]*${mode}[[:space:]]*$" "$file" || problems="$problems mode must be '$mode';"
  grep -Eq '\{\{[A-Z_]+\}\}' "$file" && problems="$problems unreplaced {{TOKEN}} placeholder;"
  IFS='|' read -ra NEEDLES <<< "$needles"
  for needle in "${NEEDLES[@]}"; do
    grep -Fq "$needle" "$file" || problems="$problems missing '$needle';"
  done
  [ -n "$problems" ] && AGENT_INVALID+=("$file:$problems")
  return 0
}

check_agent "nextjs-dev" ".opencode/agents/nextjs-dev.md" "subagent" "*.test.tsx|task: deny"
check_agent "nextjs-test-author" ".opencode/agents/nextjs-test-author.md" "subagent" "edit:|task: deny"
check_agent "nextjs-qa-auditor" ".opencode/agents/nextjs-qa-auditor.md" "subagent" "edge.test.tsx|task: deny"
check_agent "nextjs-orchestrator" ".opencode/agents/nextjs-orchestrator.md" "primary" "nextjs-dev|nextjs-test-author|nextjs-qa-auditor"

COMMANDS_MISSING=()
for cmd in ".opencode/commands/create-nextjs-component.md" ".opencode/commands/create-nextjs-page.md"; do
  [ -f "$cmd" ] || COMMANDS_MISSING+=("$cmd")
done

if [ ${#AGENT_MISSING[@]} -eq 0 ] && [ ${#AGENT_INVALID[@]} -eq 0 ] && [ -f ".agents/rules/agent-boundaries.md" ] && [ ${#COMMANDS_MISSING[@]} -eq 0 ]; then
  AUTOMATION_CHECKS+=("OK:Agent Roster & Permission Boundaries:Found 4 agents in .opencode/agents with enforced write boundaries, .agents/rules/agent-boundaries.md, and both command shortcuts.")
else
  if feature_enabled N9; then
    if [ ${#AGENT_MISSING[@]} -gt 0 ]; then
      ERRORS+=("Missing agent file(s): ${AGENT_MISSING[*]}. Enable N9 (agent roster) or remove it from the selection.")
    fi
    if [ ${#AGENT_INVALID[@]} -gt 0 ]; then
      ERRORS+=("Invalid agent configuration - ${AGENT_INVALID[*]}")
    fi
    [ -f ".agents/rules/agent-boundaries.md" ] || ERRORS+=("Missing .agents/rules/agent-boundaries.md.")
    if [ ${#COMMANDS_MISSING[@]} -gt 0 ]; then
      WARNINGS+=("Missing command shortcut(s): ${COMMANDS_MISSING[*]}.")
    fi
  fi
  AUTOMATION_CHECKS+=("MISS:Agent Roster & Permission Boundaries:Agent roster incomplete or invalid.")
fi

# --- Output ---

VISIBLE_CHECKS=()
SKIPPED_CHECKS=()
for check in "${AUTOMATION_CHECKS[@]}"; do
  IFS=':' read -r st name desc <<< "$check"
  feat=$(check_feature "$name")
  if [ -n "$feat" ] && ! feature_enabled "$feat"; then
    SKIPPED_CHECKS+=("$name ($feat)")
  else
    VISIBLE_CHECKS+=("$check")
  fi
done

if [ ${#ERRORS[@]} -eq 0 ]; then
  PASSED=true
else
  PASSED=false
fi

if [ "$JSON_MODE" = true ]; then
  echo "{\"passed\": $PASSED, \"config\": \"$CONFIG_FILE\", \"selection\": \"${SELECTION_FILE:-none}\", \"enabledFeatures\": \"$ENABLED_FEATURES\", \"errors\": ${#ERRORS[@]}, \"warnings\": ${#WARNINGS[@]}, \"skippedChecks\": ${#SKIPPED_CHECKS[@]}}"
  if [ "$PASSED" = true ]; then exit 0; else exit 1; fi
fi

echo -e "\n${BOLD}${CYAN}=== Next.js Dev Setup & project.json Verification ===${RESET}\n"
echo -e "${BOLD}Configuration File:${RESET} $CONFIG_FILE"
echo -e "${BOLD}File Exists:${RESET} $([ "$FILE_EXISTS" = true ] && echo -e "${GREEN}Yes${RESET}" || echo -e "${RED}No${RESET}")"
echo -e "${BOLD}Valid JSON:${RESET} $([ "$IS_VALID_JSON" = true ] && echo -e "${GREEN}Yes${RESET}" || echo -e "${RED}No${RESET}")"
if [ -n "$SELECTION_FILE" ]; then
  echo -e "${BOLD}Feature Selection:${RESET} $SELECTION_FILE"
  echo -e "${BOLD}Enabled Features:${RESET} ${ENABLED_FEATURES:-all (selection has no enabled list)}"
elif [ "$ALL_FEATURES" = true ]; then
  echo -e "${BOLD}Feature Selection:${RESET} disabled (--all); auditing every feature"
else
  echo -e "${BOLD}Feature Selection:${RESET} not found; auditing every feature"
fi
echo ""

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

if [ ${#VISIBLE_CHECKS[@]} -gt 0 ]; then
  echo -e "${BOLD}${MAGENTA}▶ Feature Audits:${RESET}"
  for check in "${VISIBLE_CHECKS[@]}"; do
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

if [ ${#SKIPPED_CHECKS[@]} -gt 0 ]; then
  echo -e "${BOLD}${YELLOW}▶ Not checked (feature disabled in this setup):${RESET}"
  for skipped in "${SKIPPED_CHECKS[@]}"; do
    echo -e "  [SKIP] $skipped"
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
