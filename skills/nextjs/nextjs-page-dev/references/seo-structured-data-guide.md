# SEO, Metadata & Structured Data Guide

Engineering reference for implementing dynamic metadata, OpenGraph cards, canonical URLs, and type-safe JSON-LD structured data via `schema-dts`.

> [!NOTE]
> **Local Next.js Documentation Reference:**
> Consult `node_modules/next/dist/docs/01-app/02-guides/seo/` and `node_modules/next/dist/docs/01-app/04-api-reference/02-functions/generate-metadata.md`.

---

## 1. Dynamic Metadata & OpenGraph (`generateMetadata`)

Export `generateMetadata()` in `page.tsx` to dynamically construct SEO meta tags based on route parameters and dictionary messages:

```tsx
import type { Metadata, ResolvingMetadata } from "next";
import { getTranslations } from "next-intl/server";
import { SITE_CONFIG } from "@/lib/site-config";

interface Props {
  params: Promise<{ locale: string; slug?: string }>;
  searchParams: Promise<{ [key: string]: string | string[] | undefined }>;
}

export async function generateMetadata(
  { params, searchParams }: Props,
  parent: ResolvingMetadata
): Promise<Metadata> {
  const { locale } = await params;
  const t = await getTranslations({ locale, namespace: "about" });

  const canonicalUrl = `${SITE_CONFIG.url}/${locale}/about`;

  return {
    title: t("meta.title"),
    description: t("meta.description"),
    alternates: {
      canonical: canonicalUrl,
      languages: {
        en: `${SITE_CONFIG.url}/en/about`,
        fa: `${SITE_CONFIG.url}/fa/about`,
      },
    },
    openGraph: {
      title: t("meta.title"),
      description: t("meta.description"),
      url: canonicalUrl,
      siteName: SITE_CONFIG.name,
      locale: locale,
      type: "website",
    },
    twitter: {
      card: "summary_large_image",
      title: t("meta.title"),
      description: t("meta.description"),
    },
  };
}
```

---

## 2. Type-Safe Structured Data (`schema-dts`)

Use the `schema-dts` package for compile-time validation and autocompletion of Google Search Schema markup.

### A. Component Pattern (`JsonLd.tsx`)

```tsx
import type { Thing, WithContext } from "schema-dts";

interface JsonLdProps<T extends Thing> {
  schema: WithContext<T>;
}

export function JsonLd<T extends Thing>({ schema }: JsonLdProps<T>) {
  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{
        __html: JSON.stringify(schema).replace(/</g, "\\u003c"),
      }}
    />
  );
}
```

### B. Common Schemas

#### WebPage / AboutPage Schema:
```tsx
import type { AboutPage, WithContext } from "schema-dts";

const aboutSchema: WithContext<AboutPage> = {
  "@context": "https://schema.org",
  "@type": "AboutPage",
  name: t("meta.title"),
  description: t("meta.description"),
  url: `${SITE_CONFIG.url}/${locale}/about`,
  publisher: {
    "@type": "Organization",
    name: SITE_CONFIG.name,
    url: SITE_CONFIG.url,
  },
};
```

#### Product Schema:
```tsx
import type { Product, WithContext } from "schema-dts";

const productSchema: WithContext<Product> = {
  "@context": "https://schema.org",
  "@type": "Product",
  name: product.name,
  description: product.description,
  image: product.imageUrl,
  offers: {
    "@type": "Offer",
    price: product.price,
    priceCurrency: "USD",
    availability: "https://schema.org/InStock",
  },
};
```
