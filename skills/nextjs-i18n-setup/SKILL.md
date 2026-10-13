---
name: nextjs-i18n-setup
description: Bootstrap, configure, and verify next-intl App Router internationalization (proxy.ts/middleware.ts, next/root-params, [locale] layout, routing). Triggers on "/nextjs-i18n-setup", "setup i18n", "install next-intl", "configure next-intl", "add internationalization", "setup locale routing", "migrate to [locale]".
metadata:
  author: BIGboss248
  version: "1.1"
---

# Next.js i18n Setup (`nextjs-i18n-setup`)

Bootstrap and scaffold **`next-intl`** into an existing Next.js App Router project using modern **`next/root-params`**, dynamic segment `app/[locale]/`, and **Next.js 16+ (`proxy.ts`)** / **Next.js <=15 (`middleware.ts`)**.

> [!TIP]
> **Boilerplate & Templates:** Consult [`references/templates.md`](./references/templates.md) for full drop-in code templates when scaffolding files.
> **Fast Execution:** Delegate verification to a lightweight subagent (`Model: 'flash'`).

---

## 1. Architectural Rules & Requirements

1. **Metadata Contract:** Ensure `docs/project.json` contains:
   ```json
   "dictionaries_dir": "messages",
   "dictionary_file_pattern": "[locale].json"
   ```
2. **Next.js Version Interceptor:**
   - **Next.js 16+**: Use `proxy.ts` (or `src/proxy.ts`). Migrate and remove any legacy `middleware.ts`.
   - **Next.js <=15**: Use `middleware.ts` (or `src/middleware.ts`).
3. **Modern Root Params:** Use `next/root-params` (`await rootParams.locale()`) in `i18n/request.ts`. Deprecated `requestLocale` and `setRequestLocale()` are forbidden.
4. **Navigation:** Export `Link`, `redirect`, `usePathname`, `useRouter` from `i18n/navigation.ts` (pure TypeScript, zero JSX).
5. **Static Generation:** Root layout `app/[locale]/layout.tsx` MUST export `generateStaticParams()` returning `{ locale }` for all supported locales.

---

## 2. Setup Checklist

- [ ] **Step 0: Audit**: Check `docs/project.json` (`supported_languages`) and Next.js version in `package.json`.
- [ ] **Step 1: Install**: Run `<pkg_mgr> add next-intl` (`pnpm add next-intl`).
- [ ] **Step 2: Config Metadata**: Ensure `dictionaries_dir: "messages"` in `docs/project.json`.
- [ ] **Step 3: Routing**: Create `i18n/routing.ts` using `defineRouting` (see [templates](./references/templates.md#1-routing-configuration)).
- [ ] **Step 4: Request Handler**: Create `i18n/request.ts` using `next/root-params` (see [templates](./references/templates.md#2-request-configuration)).
- [ ] **Step 5: Navigation Helpers**: Create `i18n/navigation.ts` (see [templates](./references/templates.md#3-localized-navigation-utilities)).
- [ ] **Step 6: Next Plugin**: Wrap `next.config.ts` with `createNextIntlPlugin()` (see [templates](./references/templates.md#4-nextjs-plugin-configuration)).
- [ ] **Step 7: Interceptor**: Create `proxy.ts` (Next 16+) or `middleware.ts` (Next <=15) with asset filtering matcher (see [templates](./references/templates.md#5-request-interceptor)).
- [ ] **Step 8: Starter Dictionaries**: Ensure `messages/[locale].json` exists for all supported locales with matching baseline keys.
- [ ] **Step 9: Migrate Layout & Routes**: Move top-level routes to `app/[locale]/`. Configure dynamic `dir`, `lang`, `generateStaticParams`, and `<NextIntlClientProvider>` (see [templates](./references/templates.md#6-root-locale-layout)).
- [ ] **Step 10: Type Augmentation**: Declare `AppConfig.Messages` in `global.d.ts` (see [templates](./references/templates.md#7-typescript-type-augmentation)).
- [ ] **Step 11: Navigation Imports**: Update internal links across existing components to use `@/i18n/navigation`.
- [ ] **Step 12: Verification**: Run verification script and build:
  ```pwsh
  pwsh .agents/skills/nextjs-i18n-setup/scripts/verify-setup.ps1 -Quiet
  pnpm run build
  ```

---

## 3. Setup Execution Report Template

```markdown
## 🌐 Next.js i18n Setup Execution Report

| Step / Component   | Target File(s)               | Status                          | Notes                    |
| :----------------- | :--------------------------- | :------------------------------ | :----------------------- |
| **Package**        | `package.json` (`next-intl`) | `[IMPLEMENTED]` / `[UNTOUCHED]` | Installed runtime        |
| **Project Config** | `docs/project.json`          | `[IMPLEMENTED]` / `[UNTOUCHED]` | Configured messages dir  |
| **Routing**        | `i18n/routing.ts`            | `[IMPLEMENTED]` / `[UNTOUCHED]` | Locales & default        |
| **Request**        | `i18n/request.ts`            | `[IMPLEMENTED]` / `[UNTOUCHED]` | next/root-params         |
| **Navigation**     | `i18n/navigation.ts`         | `[IMPLEMENTED]` / `[UNTOUCHED]` | Pure TS helpers          |
| **Plugin**         | `next.config.ts`             | `[IMPLEMENTED]` / `[UNTOUCHED]` | withNextIntl wrapped     |
| **Interceptor**    | `proxy.ts` / `middleware.ts` | `[IMPLEMENTED]` / `[UNTOUCHED]` | Route matcher            |
| **Dictionaries**   | `messages/[locale].json`     | `[IMPLEMENTED]` / `[UNTOUCHED]` | Starter dictionaries     |
| **Layout**         | `app/[locale]/layout.tsx`    | `[IMPLEMENTED]` / `[UNTOUCHED]` | Static params & provider |
| **Types**          | `global.d.ts`                | `[IMPLEMENTED]` / `[UNTOUCHED]` | AppConfig augmentation   |
| **Verification**   | `verify-setup.ps1` & build   | `[PASSED]`                      | Clean build              |
```
