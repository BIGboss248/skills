# Code Examples & Provider Patterns for `nextjs-i18n-usage`

### 1. Dictionary Architecture (`messages/en.json` & `messages/fa.json`)

#### `messages/en.json`:
```json
{
  "common": {
    "brand": "Portfolio",
    "switch_language": "Change Language",
    "theme_toggle": "Toggle Theme"
  },
  "navigation": {
    "home": "Home",
    "about": "About",
    "projects": "Projects",
    "contact": "Contact"
  },
  "components": {
    "ContactForm": {
      "name_label": "Your Name",
      "name_placeholder": "Jane Doe",
      "email_label": "Email Address",
      "email_placeholder": "jane@example.com",
      "message_label": "Message",
      "success_message": "Message sent successfully!"
    }
  },
  "metadata": {
    "title": "Portfolio | Full-Stack Architect",
    "description": "Portfolio and engineering lab."
  }
}
```

---

### 2. Server Component (RSC) Pattern

```tsx
import React from "react";
import { getTranslations } from "next-intl/server";
import { Link } from "@/i18n/navigation";

export async function HeroSection(): Promise<React.JSX.Element> {
  const t = await getTranslations("home.hero");

  return (
    <section className="py-16 text-center">
      <h1 className="text-4xl font-bold text-foreground sm:text-6xl">{t("title")}</h1>
      <p className="mt-4 text-lg text-muted-foreground">{t("description")}</p>
      <div className="mt-8 flex justify-center gap-4">
        <Link href="/projects" className="bg-primary text-primary-foreground px-4 py-2 rounded-md">
          {t("cta_projects")}
        </Link>
      </div>
    </section>
  );
}
```

---

### 3. Client Component Pattern (with `t.rich`)

```tsx
"use client";

import React, { useState } from "react";
import { useTranslations } from "next-intl";
import { Link } from "@/i18n/navigation";

export function ContactForm(): React.JSX.Element {
  const t = useTranslations("components.ContactForm");
  const [submitted, setSubmitted] = useState(false);

  if (submitted) return <p className="text-success">{t("success_message")}</p>;

  return (
    <form onSubmit={(e) => { e.preventDefault(); setSubmitted(true); }} className="flex flex-col gap-4">
      <label className="text-sm font-medium">{t("name_label")}</label>
      <input placeholder={t("name_placeholder")} className="border border-border bg-background p-2 rounded-md" required />
      <button type="submit" className="bg-primary text-primary-foreground py-2 rounded-md">
        {t("message_label")}
      </button>
    </form>
  );
}
```

---

### 4. Language Switcher Component

```tsx
"use client";

import React, { useTransition } from "react";
import { useLocale, useTranslations } from "next-intl";
import { usePathname, useRouter } from "@/i18n/navigation";
import { routing, type Locale } from "@/i18n/routing";

export function LanguageSwitcher(): React.JSX.Element {
  const t = useTranslations("common");
  const locale = useLocale();
  const router = useRouter();
  const pathname = usePathname();
  const [isPending, startTransition] = useTransition();

  function onSelectChange(nextLocale: Locale) {
    startTransition(() => {
      router.replace(pathname, { locale: nextLocale });
    });
  }

  return (
    <select
      defaultValue={locale}
      disabled={isPending}
      onChange={(e) => onSelectChange(e.target.value as Locale)}
      className="border border-border bg-background px-2.5 py-1.5 rounded-md text-xs font-medium"
      aria-label={t("switch_language")}
    >
      {routing.locales.map((cur) => (
        <option key={cur} value={cur}>
          {cur === "en" ? "English" : cur === "fa" ? "فارسی" : cur.toUpperCase()}
        </option>
      ))}
    </select>
  );
}
```

---

### 5. Storybook Configuration (`.storybook/preview.tsx` & Stories)

```tsx
// .storybook/preview.tsx
import React from "react";
import type { Preview } from "@storybook/react";
import { NextIntlClientProvider } from "next-intl";
import enMessages from "../messages/en.json";

const preview: Preview = {
  decorators: [
    (Story, context) => (
      <NextIntlClientProvider locale={context.globals.locale || "en"} messages={enMessages}>
        <Story />
      </NextIntlClientProvider>
    ),
  ],
};

export default preview;
```

---

### 6. Unit Test Harness Setup (Jest / Vitest)

```tsx
import React from "react";
import { render, RenderOptions } from "@testing-library/react";
import { NextIntlClientProvider } from "next-intl";
import enMessages from "@/messages/en.json";

export function renderWithIntl(
  ui: React.ReactElement,
  { locale = "en", messages = enMessages, ...renderOptions }: { locale?: string; messages?: Record<string, any> } & RenderOptions = {}
) {
  return render(
    <NextIntlClientProvider locale={locale} messages={messages}>
      {ui}
    </NextIntlClientProvider>,
    renderOptions
  );
}
```

