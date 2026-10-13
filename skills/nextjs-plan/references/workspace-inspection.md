# Workspace Inspection Reference Guide

This guide details the automated, zero-interruption inspection protocol to extract project facts and architecture before initiating user interviews.

---

## Zero-Interruption Rule

> [!IMPORTANT]
> **Inspect first, ask later.** Never ask the user for configuration details, dependencies, or architectural choices that can be determined directly from workspace files.

---

## Inspection Checklist & Discovery Matrix

### 1. Package Manager & Tooling

- **`package.json` inspection**:
  - Check `packageManager` field (e.g. `pnpm@...`, `bun@...`, `yarn@...`).
  - Check lockfiles: `pnpm-lock.yaml` (`pnpm`), `bun.lockb` / `bun.lock` (`bun`), `yarn.lock` (`yarn`), `package-lock.json` (`npm`).
  - Scan `dependencies` and `devDependencies` for:
    - `next` (determine App Router vs Pages Router, check Next.js 15+ vs 16+).
    - `react` / `react-dom` (check React 19 / React Compiler support).
    - `typescript` (verify `.ts` / `.tsx` extension usage).

### 2. Directory Layout & Routing Architecture

- **Root routing directory**:
  - `src/app/` vs `app/` (sets base directory for routing and layouts).
- **Component directories**:
  - Check `app/components`, `src/app/components`, `src/components`, or `components`.
- **Static & public assets**:
  - Check `public/` directory for brand logos, favicons, OG images, fonts.

### 3. Styling & Design Token System

- **Global CSS file**:
  - Locate `app/globals.css`, `src/app/globals.css`, `app/global.css`, or `src/styles/globals.css`.
- **CSS / Tailwind config**:
  - Inspect `tailwind.config.ts` / `tailwind.config.js` or Tailwind CSS v4 `@import "tailwindcss";` / `@theme` blocks.
  - Check for semantic token classes (e.g. `--background`, `--foreground`, `--primary`, `--border`, OKLCH tokens).

### 4. UI Primitives, Animation & Icon Libraries

- **UI primitives**:
  - `components.json` (shadcn/ui configuration).
  - `@radix-ui/*`, `@headlessui/react`, `@base-ui-components/react`.
- **Animation tools**:
  - `gsap`, `@gsap/react`, `framer-motion`, `motion`.
- **Icon packages**:
  - `lucide-react`, `react-icons`, `@heroicons/react`, `@tabler/icons-react`.

### 5. Internationalization & Localization (i18n)

- **`next-intl` configuration**:
  - Check for `next-intl` in `package.json`.
  - Check root dictionary directory: `messages/` (e.g., `messages/en.json`, `messages/fa.json`). Note: Never assume `app/dictionaries`.
  - Check dynamic locale routing segment: `app/[locale]/` or `src/app/[locale]/`.
  - Check middleware/proxy routing: `proxy.ts` (Next.js 16+), `middleware.ts` (Next.js 15-), or `i18n/routing.ts`.

### 6. Existing Routes & API Handlers

- **Pages**:
  - Scan all `page.tsx` files to construct existing information architecture.
- **API handlers & Server Functions**:
  - Scan all `route.ts` files under `app/api/` or `src/app/api/`.
  - Check for server actions or server functions with `'use server'`.

### 7. Testing Suites, Containers & Tooling

- **Testing**:
  - `jest.config.*`, `playwright.config.*`, `vitest.config.*`.
- **Docker & Containerization**:
  - `Dockerfile`, `docker-compose.yml`, `.dockerignore` (standalone production setup).
- **Documentation & Agent Rules**:
  - `AGENTS.md`, `CONTEXT.md`, `README.md`, `docs/`.
