# Next.js Docs Search Reference (`codebase-memory`)

Instructions for querying local Next.js distribution documentation in `node_modules/next/dist/docs/` using the `codebase-memory` MCP server.

---

## Codebase Memory MCP Search Protocol

Query `node_modules/next/dist/docs/` before authoring components to retrieve exact API signatures, directives, and component props.

### 1. Keyword & API Search (`search_code`)

```json
{
  "ServerName": "codebase-memory",
  "ToolName": "search_code",
  "Arguments": {
    "project": "<project-id>",
    "query": "<API, prop, directive, or keyword>",
    "file_pattern": "*docs*"
  }
}
```

### 2. Concept & Header Discovery (`search_graph`)

```json
{
  "ServerName": "codebase-memory",
  "ToolName": "search_graph",
  "Arguments": {
    "project": "<project-id>",
    "query": "<topic or feature name>"
  }
}
```

### 3. Targeted Snippet Retrieval (`get_code_snippet`)

```json
{
  "ServerName": "codebase-memory",
  "ToolName": "get_code_snippet",
  "Arguments": {
    "project": "<project-id>",
    "qualified_name": "<doc-node-symbol>"
  }
}
```
