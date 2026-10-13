import React from "react";
import { getTranslations } from "next-intl/server";
import { cn } from "@/lib/utils";

/**
 * Props for the ComponentName component.
 */
export interface ComponentNameProps {
  /**
   * Optional custom CSS class name for outer wrapper styling.
   * @defaultValue undefined
   */
  className?: string;
  /**
   * The locale code for server-side translation resolution.
   * @defaultValue "en"
   */
  locale?: string;
}

/**
 * ComponentName React Server Component (RSC).
 *
 * Consumes localized strings from the dictionary via next-intl and applies
 * semantic OKLCH tokens with BiDi logical styling.
 *
 * @param props - Component configuration properties.
 * @returns Server-rendered JSX element.
 */
export async function ComponentName({
  className,
  locale = "en",
}: ComponentNameProps) {
  const t = await getTranslations({ locale, namespace: "ComponentName" });

  return (
    <section
      className={cn(
        "flex flex-col items-start gap-4 rounded-xl border border-border bg-card p-6 text-card-foreground shadow-sm",
        className
      )}
    >
      <h2 className="text-xl font-semibold tracking-tight text-foreground">
        {t("title")}
      </h2>
      <p className="text-sm leading-relaxed text-muted-foreground">
        {t("description")}
      </p>
    </section>
  );
}
