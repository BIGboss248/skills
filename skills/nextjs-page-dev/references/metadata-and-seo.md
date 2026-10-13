# Next.js Page Metadata, SEO & JSON-LD Reference

This guide details type-safe dynamic metadata generation, OpenGraph/Twitter cards, and JSON-LD structured data for Next.js App Router pages.

---

## 1. Dynamic Metadata Generation (`generateMetadata`)

Use `generateMetadata` in `page.tsx` to construct localized, SEO-rich metadata.

### Standard Pattern

```typescript
import type { Metadata } from "next";
import { getTranslations } from "next-intl/server";
import { SITE_CONFIG } from "@/lib/site-config";
import { ROUTES } from "@/lib/routes";

interface PageProps {
  params: Promise<{ locale: string }>;
}

export async function generateMetadata(props: PageProps): Promise<Metadata> {
  const { locale } = await props.params;
  const t = await getTranslations({ locale, namespace: "AboutPage" });

  const pageTitle = `${t("meta.title")} | ${SITE_CONFIG.name}`;
  const pageDescription = t("meta.description");
  const canonicalUrl = `${SITE_CONFIG.baseUrl}/${locale}${ROUTES.about}`;

  return {
    title: pageTitle,
    description: pageDescription,
    alternates: {
      canonical: canonicalUrl,
      languages: {
        en: `${SITE_CONFIG.baseUrl}/en${ROUTES.about}`,
        fa: `${SITE_CONFIG.baseUrl}/fa${ROUTES.about}`,
      },
    },
    openGraph: {
      title: pageTitle,
      description: pageDescription,
      url: canonicalUrl,
      siteName: SITE_CONFIG.name,
      locale: locale === "fa" ? "fa_IR" : "en_US",
      type: "website",
      images: [
        {
          url: `${SITE_CONFIG.baseUrl}/og-about.png`,
          width: 1200,
          height: 630,
          alt: pageTitle,
        },
      ],
    },
    twitter: {
      card: "summary_large_image",
      title: pageTitle,
      description: pageDescription,
      creator: SITE_CONFIG.social.twitterHandle ?? undefined,
    },
  };
}
```

---

## 2. Structured Data (`JSON-LD` via `schema-dts`)

Embed search-engine readable JSON-LD using typed graphs in `page.tsx`:

```typescript
import type { WithContext, WebPage, ItemList } from "schema-dts";

export function getPageJsonLd(locale: string): WithContext<WebPage> {
  return {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "@id": `${SITE_CONFIG.baseUrl}/${locale}${ROUTES.about}/#webpage`,
    url: `${SITE_CONFIG.baseUrl}/${locale}${ROUTES.about}`,
    name: `${SITE_CONFIG.name} - About`,
    isPartOf: {
      "@type": "WebSite",
      "@id": `${SITE_CONFIG.baseUrl}/#website`,
      name: SITE_CONFIG.name,
      url: SITE_CONFIG.baseUrl,
    },
    inLanguage: locale,
  };
}

// In Page component JSX:
<script
  type="application/ld+json"
  dangerouslySetInnerHTML={{ __html: JSON.stringify(getPageJsonLd(locale)) }}
/>
```
