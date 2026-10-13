# Project Specifications Schema Reference (`docs/project.json`)

This reference documents the canonical JSON schema and field constraints for `docs/project.json`.

---

## Canonical Schema Definition

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "NextJSProjectMetadata",
  "type": "object",
  "required": ["project_context_and_metadata"],
  "properties": {
    "project_context_and_metadata": {
      "type": "object",
      "required": [
        "package_manager",
        "new_component_dir",
        "style_file_dir",
        "component_library",
        "animation_library",
        "testing_library",
        "supported_languages",
        "dictionaries_dir",
        "dictionary_file_pattern"
      ],
      "properties": {
        "package_manager": {
          "type": "string",
          "enum": ["pnpm", "bun", "yarn", "npm"],
          "description": "Active package manager for executing scripts and installs."
        },
        "new_component_dir": {
          "type": "string",
          "description": "Standard directory where custom React UI components are created."
        },
        "style_file_dir": {
          "type": "string",
          "description": "Path to the primary global stylesheet containing CSS variables/tokens."
        },
        "component_library": {
          "type": "string",
          "description": "Primary UI component primitive library (e.g. shadcn/ui, Radix UI)."
        },
        "animation_library": {
          "type": "array",
          "items": { "type": "string" },
          "description": "List of installed animation and motion libraries."
        },
        "testing_library": {
          "type": "array",
          "items": { "type": "string" },
          "description": "Installed testing frameworks and assertion suites."
        },
        "supported_languages": {
          "type": "array",
          "items": {
            "type": "object",
            "required": [
              "language_code",
              "country_code",
              "currency_code",
              "direction",
              "native_name",
              "calendar_type"
            ],
            "properties": {
              "language_code": { "type": "string", "example": "en" },
              "country_code": { "type": "string", "example": "US" },
              "currency_code": { "type": "string", "example": "USD" },
              "direction": { "type": "string", "enum": ["ltr", "rtl"] },
              "native_name": { "type": "string", "example": "English" },
              "calendar_type": { "type": "string", "example": "gregorian" }
            }
          }
        },
        "dictionaries_dir": {
          "type": "string",
          "const": "messages",
          "description": "Root directory for next-intl dictionary files (always 'messages')."
        },
        "dictionary_file_pattern": {
          "type": "string",
          "const": "[locale].json",
          "description": "Filename pattern for translation JSON files."
        }
      }
    }
  }
}
```

---

## Field Descriptions & Guidelines

1. **`package_manager`**: Use `pnpm` (standard for monorepos and deterministic caching) or detected manager from lockfiles.
2. **`new_component_dir`**: Standard component path (typically `app/components` or `src/components`).
3. **`style_file_dir`**: Primary global CSS token file (typically `app/globals.css`).
4. **`dictionaries_dir`**: Must strictly be `messages` at the project root per `next-intl` standards (e.g., `messages/en.json`, `messages/fa.json`).
