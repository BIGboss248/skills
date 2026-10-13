# Model Context Protocol (MCP) Configuration Guide

The Model Context Protocol (MCP) connects Antigravity to external tool providers, databases, web services, and APIs.

---

## 1. Configuration File Locations

- **Workspace Scope**: `<workspace_root>/.agents/mcp_config.json` (recommended for project-specific tools).
- **Global Scope**: `~/.gemini/config/mcp_config.json` (active across all sessions and workspaces).
- **Plugin Scope**: `.agents/plugins/<plugin_name>/mcp_config.json` (active when the plugin is loaded).

---

## 2. Configuration Schema & Transports

The top-level configuration object must contain the `mcpServers` map:

```json
{
  "mcpServers": {
    "<server-name>": {
      ...
    }
  }
}
```

### Transport 1: Local `stdio` Transport

Spawns a local executable process and communicates over standard input/output.

```json
{
  "mcpServers": {
    "sqlite-server": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-sqlite",
        "./data/database.db"
      ],
      "env": {
        "SQLITE_READONLY": "true"
      },
      "cwd": "${workspaceFolder}"
    }
  }
}
```

| Property  | Type     | Required | Description                                                                           |
| :-------- | :------- | :------- | :------------------------------------------------------------------------------------ |
| `command` | string   | Yes      | The executable binary to spawn (`node`, `npx`, `python`, `uvx`, or full binary path). |
| `args`    | string[] | No       | Array of arguments passed to the command.                                             |
| `env`     | object   | No       | Custom environment variables injected into the process.                               |
| `cwd`     | string   | No       | Working directory for the server process.                                             |

---

### Transport 2: Remote SSE / Streamable HTTP Transport

Connects to a remote server over HTTP using Server-Sent Events (SSE) or Streamable HTTP.

> [!IMPORTANT]
> **Use `serverUrl` exclusively**: Always specify `serverUrl`. Legacy properties such as `url` or `httpUrl` are deprecated and not supported in Antigravity.

```json
{
  "mcpServers": {
    "remote-api-server": {
      "serverUrl": "https://mcp.internal.company.com/sse",
      "headers": {
        "Authorization": "Bearer YOUR_ACCESS_TOKEN",
        "X-Custom-Header": "production"
      }
    }
  }
}
```

---

## 3. Authentication Mechanisms

### Option A: Google Application Default Credentials (ADC)

For connecting to Google Cloud services or internal Google APIs:

```json
{
  "mcpServers": {
    "google-cloud-mcp": {
      "serverUrl": "https://cloud-mcp.googleapis.com/sse",
      "authProviderType": "google_credentials"
    }
  }
}
```

Requires local ADC login via Google Cloud CLI:

```bash
gcloud auth application-default login
gcloud auth application-default set-quota-project YOUR_PROJECT_ID
```

### Option B: OAuth 2.0 (Dynamic Client Registration & Manual)

If the server supports OAuth Dynamic Client Registration (DCR), specify only the `serverUrl`:

```json
{
  "mcpServers": {
    "oauth-service": {
      "serverUrl": "https://api.example.com/mcp/"
    }
  }
}
```

If manual client credentials are required:

```json
{
  "mcpServers": {
    "oauth-service": {
      "serverUrl": "https://api.example.com/mcp/",
      "oauth": {
        "clientId": "YOUR_CLIENT_ID",
        "clientSecret": "YOUR_CLIENT_SECRET"
      }
    }
  }
}
```

> [!NOTE]
> The redirect URI registered with your OAuth provider must be:
> `https://antigravity.google/oauth-callback`
> In Antigravity IDE, authenticate via **Settings (Ctrl+,) > Customizations > Authenticate**.

---

## 4. Operational Controls & Tool Filtering

You can disable servers or withhold dangerous tools without deleting the configuration:

```json
{
  "mcpServers": {
    "database-tools": {
      "command": "python",
      "args": ["-m", "db_mcp_server"],
      "disabled": false,
      "disabledTools": ["drop_table", "truncate_table", "delete_records"]
    },
    "experimental-service": {
      "serverUrl": "https://staging.mcp.example.com/",
      "disabled": true
    }
  }
}
```

- **`disabled`** (boolean): Set to `true` to pause the server entirely.
- **`disabledTools`** (string[]): List of tool names to withhold from the model prompt.

---

## 5. Ready-to-Use Popular Server Recipes

### GitHub MCP

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_xxxxxxxxxxxx"
      }
    }
  }
}
```

### PostgreSQL MCP

```json
{
  "mcpServers": {
    "postgres": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-postgres",
        "postgresql://user:password@localhost:5432/mydb"
      ]
    }
  }
}
```

### Filesystem MCP (Restricted scope)

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "./safe-directory"
      ]
    }
  }
}
```
