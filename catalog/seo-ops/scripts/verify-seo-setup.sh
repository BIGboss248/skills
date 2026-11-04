#!/usr/bin/env bash
set -e

MODE="all"
AUTO_INSTALL=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -m|--mode) MODE="$2"; shift ;;
        -i|--install|--auto-install) AUTO_INSTALL=true ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

echo "=== SEO Operations Setup Verification ==="
echo "Verification Mode: $MODE"
if [ "$AUTO_INSTALL" = true ]; then
    echo "AutoInstall Flag: ENABLED"
fi

FAILURES=0
RESTART_REQUIRED=false

echo ""
echo "[1/3] Checking Node.js runtime..."
if command -v node >/dev/null 2>&1; then
    NODE_VERSION=$(node -v)
    NODE_MAJOR=$(echo "$NODE_VERSION" | sed 's/^v//' | cut -d'.' -f1)
    if [ "$NODE_MAJOR" -ge 22 ]; then
        echo "  [OK] Node.js version: $NODE_VERSION (>= 22)"
    else
        echo "  [FAIL] Node.js version $NODE_VERSION is below required v22+"
        FAILURES=$((FAILURES + 1))
    fi
else
    echo "  [FAIL] Node.js binary not found in PATH"
    FAILURES=$((FAILURES + 1))
fi

if [ "$MODE" = "mcp" ] || [ "$MODE" = "all" ]; then
    echo ""
    echo "[2/3] Checking SEO MCP / CLI configuration..."
    
    CLI_FOUND=false
    if npx -y seo --version >/dev/null 2>&1; then
        SEO_VERSION=$(npx -y seo --version 2>/dev/null || echo "installed")
        echo "  [OK] seo CLI available via npx: $SEO_VERSION"
        CLI_FOUND=true
    fi

    if [ "$CLI_FOUND" = false ]; then
        if [ "$AUTO_INSTALL" = true ]; then
            echo "  [INSTALL] Installing seo CLI globally..."
            npm install -g seo
            RESTART_REQUIRED=true
        else
            echo "  [WARN] seo CLI not detected. Run: npm install -g seo"
        fi
    fi

    MCP_CONFIG_FILE=".agents/mcp_config.json"
    MCP_CONFIGURED=false

    if [ -f "$MCP_CONFIG_FILE" ]; then
        if grep -q '"seo"' "$MCP_CONFIG_FILE"; then
            MCP_CONFIGURED=true
            echo "  [OK] SEO MCP server configured in $MCP_CONFIG_FILE"
        fi
    fi

    if [ "$MCP_CONFIGURED" = false ] && [ "$AUTO_INSTALL" = true ]; then
        echo "  [INSTALL] Adding seo MCP server entry to $MCP_CONFIG_FILE..."
        mkdir -p .agents
        if [ ! -f "$MCP_CONFIG_FILE" ]; then
            echo '{"mcpServers":{"seo":{"command":"npx","args":["-y","seo","mcp","serve"]}}}' > "$MCP_CONFIG_FILE"
        fi
        echo "  [OK] Successfully configured $MCP_CONFIG_FILE"
        RESTART_REQUIRED=true
    fi

    if npx -y seo mcp serve --test >/dev/null 2>&1; then
        echo "  [OK] SEO MCP daemon startup test passed"
    else
        echo "  [WARN] Could not test MCP daemon"
    fi
fi

if [ "$MODE" = "cicd" ] || [ "$MODE" = "all" ]; then
    echo ""
    echo "[3/3] Checking CI/CD and pre-push gates..."
    if [ -f ".github/workflows/seo-check.yml" ]; then
        echo "  [OK] CI/CD workflow found: .github/workflows/seo-check.yml"
    else
        echo "  [INFO] CI/CD workflow .github/workflows/seo-check.yml not created yet"
    fi

    if [ -f ".husky/pre-push" ]; then
        echo "  [OK] Husky pre-push hook found"
    else
        echo "  [INFO] Husky pre-push hook not configured"
    fi

    if [ -f "scripts/seo-pre-push.sh" ] || [ -f "scripts/seo-pre-push.ps1" ]; then
        echo "  [OK] SEO pre-push runner script found in scripts/"
    else
        echo "  [INFO] SEO pre-push runner script not found in scripts/ (see resources/templates/)"
    fi
fi

echo ""
echo "=== Verification Complete ==="
if [ "$RESTART_REQUIRED" = true ]; then
    echo ">> ACTION REQUIRED: The MCP server configuration was newly installed/updated. Please reload the IDE window or restart the agent session so Antigravity can connect to the new tools. <<"
fi
if [ "$FAILURES" -eq 0 ]; then
    echo "All prerequisite checks passed successfully."
    exit 0
else
    echo "Verification encountered $FAILURES failure(s)."
    exit 1
fi
