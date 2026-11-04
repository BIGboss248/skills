# Next.js Page Static Params & i18n Reference

This guide details route parameter handling, multi-locale static generation, and internationalization in Next.js App Router pages.

---

## 1. Static Pre-Rendering (`generateStaticParams`)

When a route is nested under dynamic segments (e.g. `app/[locale]/...` or dynamic slugs `[slug]`), Next.js can pre-render all static variants at build time.

### Multi-Locale Static Params Rule (Autofix Rule 26)

If `docs/project.json` defines multiple locales in `supported_languages` and a page is nested under `[locale]`:

- The page (or parent route segment) MUST export `generateStaticParams()`.
- Return an array of param objects: `[{ locale: 'en' }, { locale: 'fa' }, ...]`.

```typescript
import { routing } from "@/i18n/routing";

export function generateStaticParams() {
  return routing.locales.map((locale) => ({ locale }));
}
```

For nested dynamic parameters (e.g. `app/[locale]/(routes)/projects/[slug]/page.tsx`):

```typescript
export async function generateStaticParams() {
  const paths: Array<{ locale: string; slug: string }> = [];
  const slugs = await getProjectSlugs();

  for (const locale of routing.locales) {
    for (const slug of slugs) {
      paths.push({ locale, slug });
    }
  }

  return paths;
}
```

---

## 2. Next.js 15+ / 16+ Async Route Params Contract

In Next.js 15+ and 16+, `params` and `searchParams` passed to pages and layouts are **Promises** and must be `await`ed before accessing their properties.

```typescript
interface PageProps {
  params: Promise<{
    locale: string;
    slug?: string;
  }>;
  searchParams?: Promise<{ [key: string]: string | string[] | undefined }>;
}

export default async function Page(props: PageProps) {
  const { locale, slug } = await props.params;
  const searchParams = await props.searchParams;
  // ...
}
```

---

## 3. Server-Side Translations in Pages (`getTranslations`)

RSC page components fetch dictionary namespaces via `getTranslations`:

```typescript
import { getTranslations, setRequestLocale } from "next-intl/server";

export default async function Page(props: PageProps) {
  const { locale } = await props.params;

  // Enable static rendering
  setRequestLocale(locale);

  const t = await getTranslations({ locale, namespace: "HomePage" });

  return (
    <main>
      <h1>{t("title")}</h1>
      <p>{t("description")}</p>
    </main>
  );
}
```
