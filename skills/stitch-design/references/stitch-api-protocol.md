# Google Stitch API Protocol & Tool Contracts

This reference details the Google Stitch (`StitchMCP`) tool calling standards, single-project persistence protocol, and asset download conventions.

---

## 1. Single Project Container Invariant

Every repository MUST maintain exactly **one shared Google Stitch project container** across all screens and components:

1. **Check `docs/project.json`**: Inspect for `"stitch": { "project_id": "..." }`.
2. **Reuse Existing Project**: If present, reuse `stitch.project_id` directly for all operations. Do not call `create_project`.
3. **Create & Persist (Only if Absent)**:
   - Check `list_projects` on `StitchMCP`.
   - If missing, call `create_project` with `title: "[Project Name] Design System & Components"`.
   - Immediately write `stitch.project_id` and `stitch.project_name` to `docs/project.json`.

---

## 2. StitchMCP Tool Calling Sequence

### Step 1: Seed Design Tokens
- Provide canonical design system tokens to Stitch via `upload_design_md` or `create_design_system_from_design_md`.

### Step 2: Generate Primary Screen (`generate_screen_from_text`)
- **Parameters**:
  - `projectId`: Canonical project ID.
  - `prompt`: Detailed prompt synthesizing component purpose, visual hierarchy, and color tokens.
  - `deviceType`: `"DESKTOP"` (or `"MOBILE"` / `"TABLET"`).
- Extract `screenId`, `resourceName`, `screenshot.downloadUrl`, and `htmlCode.downloadUrl`.

### Step 3: Generate Visual Variant (`generate_variants`)
- Call `generate_variants` on the primary screen ID to produce 1 layout/density variant.
- Extract variant `screenshot.downloadUrl` and `htmlCode.downloadUrl`.

---

## 3. Binary Asset Download Protocol

> [!CAUTION]
> NEVER use `read_url_content` for binary image downloads or raw HTML exports. Always use PowerShell `Invoke-WebRequest -Uri <url> -OutFile <path>` in discrete single operations. Signed download URLs expire quickly; download immediately upon receiving the response.

```powershell
powershell -Command "Invoke-WebRequest -Uri '<screenshot.downloadUrl>' -OutFile 'docs/design/components/[page]/[component]/stitch/screen.jpg'"
powershell -Command "Invoke-WebRequest -Uri '<htmlCode.downloadUrl>' -OutFile 'docs/design/components/[page]/[component]/stitch/screen.html'"
powershell -Command "Invoke-WebRequest -Uri '<variant.screenshot.downloadUrl>' -OutFile 'docs/design/components/[page]/[component]/stitch/variant-1.jpg'"
powershell -Command "Invoke-WebRequest -Uri '<variant.htmlCode.downloadUrl>' -OutFile 'docs/design/components/[page]/[component]/stitch/variant-1.html'"
```

