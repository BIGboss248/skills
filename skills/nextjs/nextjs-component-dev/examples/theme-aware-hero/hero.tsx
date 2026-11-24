import { getTranslations } from "next-intl/server";
import { ThemeHeroBackdrop } from "./theme_hero_backdrop";

/**
 * Props for the Hero section.
 */
export interface HeroProps {
  /** Active locale, as passed by the page segment. */
  locale: string;
}

/**
 * Hero section using the day/night plate concept: one composition rendered
 * twice, swapped by the `.dark` class, never by React state.
 *
 * The copy sits on a token-based gradient so contrast holds over both plates.
 * Every string comes from the dictionary; nothing is inlined.
 *
 * @param props - Active locale.
 * @returns A React Server Component rendering the hero section.
 */
export async function Hero({ locale }: HeroProps): Promise<React.JSX.Element> {
  const t = await getTranslations({ locale, namespace: "home.hero" });

  return (
    <section className="relative isolate flex min-h-[560px] items-end overflow-hidden bg-background">
      <ThemeHeroBackdrop
        lightSrc="/images/hero_day.webp"
        darkSrc="/images/hero_night.webp"
      />

      <div
        aria-hidden
        className="absolute inset-0 -z-10 bg-gradient-to-t from-background via-background/70 to-transparent"
      />

      <div className="relative mx-auto flex w-full max-w-6xl flex-col gap-6 px-6 pb-16 pt-32">
        <h1 className="max-w-2xl text-balance text-4xl font-bold tracking-tight text-foreground sm:text-5xl">
          {t("title")}
        </h1>
        <p className="max-w-xl text-pretty text-base leading-relaxed text-muted-foreground">
          {t("subtitle")}
        </p>
        <div className="flex flex-wrap items-center gap-3">
          <a
            href={t("primary_href")}
            className="inline-flex min-h-11 items-center rounded-md bg-primary px-5 text-sm font-semibold text-primary-foreground transition-colors hover:bg-primary/90"
          >
            {t("primary_cta")}
          </a>
          <a
            href={t("secondary_href")}
            className="inline-flex min-h-11 items-center rounded-md border border-border px-5 text-sm font-semibold text-foreground transition-colors hover:bg-muted"
          >
            {t("secondary_cta")}
          </a>
        </div>
      </div>
    </section>
  );
}
