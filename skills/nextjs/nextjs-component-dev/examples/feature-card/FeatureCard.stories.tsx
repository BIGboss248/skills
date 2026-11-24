import type { Meta, StoryObj } from "@storybook/nextjs-vite";
import { NextIntlClientProvider } from "next-intl";
import { FeatureCard, FeatureCardSkeleton } from "./FeatureCard";

const messages = {
  en: {
    feature_card: {
      read_more: "Read More",
    },
  },
  fa: {
    feature_card: {
      read_more: "ادامه مطلب",
    },
  },
};

/**
 * Storybook CSF3 specification for the FeatureCard Server Component.
 */
const meta: Meta<typeof FeatureCard> = {
  title: "Features/FeatureCard",
  component: FeatureCard,
  tags: ["autodocs", "ai-generated"],
  parameters: {
    docs: {
      description: {
        component:
          "### FeatureCard\n\nCacheable React Server Component rendering localized feature highlights, responsive image assets, dictionary-backed translations, and JSON-LD structured data.",
      },
    },
  },
  decorators: [
    (Story, context) => {
      const locale = (context.args.locale as "en" | "fa") || "en";
      return (
        <NextIntlClientProvider locale={locale} messages={messages[locale]}>
          <Story />
        </NextIntlClientProvider>
      );
    },
  ],
  argTypes: {
    title: {
      control: "text",
      description: "Title of the feature card",
    },
    description: {
      control: "text",
      description: "Detailed body description",
    },
    imageUrl: {
      control: "text",
      description: "Card image source path",
    },
    href: {
      control: "text",
      description: "Navigation destination route",
    },
    locale: {
      control: "select",
      options: ["en", "fa"],
      description: "Language locale determining text direction and formatting",
    },
  },
  args: {
    title: "Production Next.js Architecture",
    description:
      "Engineered with React Server Components, OKLCH design tokens, and strict streaming boundaries.",
    imageUrl: "/images/feature.webp",
    href: "/features/architecture",
    locale: "en",
  },
};

export default meta;
type Story = StoryObj<typeof FeatureCard>;

export const Default: Story = {};

export const Light: Story = {
  parameters: {
    themes: { themeOverride: "light" },
    backgrounds: { default: "light" },
  },
  decorators: [
    (Story) => (
      <div className="light bg-background text-foreground p-8 rounded-xl border border-border shadow-xs flex flex-col items-center justify-center gap-3 min-w-[280px]">
        <span className="text-[11px] font-mono font-medium uppercase tracking-wider text-muted-foreground">
          Light Mode
        </span>
        <Story />
      </div>
    ),
  ],
};

export const Dark: Story = {
  parameters: {
    themes: { themeOverride: "dark" },
    backgrounds: { default: "dark" },
  },
  decorators: [
    (Story) => (
      <div className="dark bg-background text-foreground p-8 rounded-xl border border-border shadow-xs flex flex-col items-center justify-center gap-3 min-w-[280px]">
        <span className="text-[11px] font-mono font-medium uppercase tracking-wider text-muted-foreground">
          Dark Mode
        </span>
        <Story />
      </div>
    ),
  ],
};

export const SkeletonLight: Story = {
  parameters: {
    themes: { themeOverride: "light" },
    backgrounds: { default: "light" },
  },
  render: () => <FeatureCardSkeleton />,
  decorators: [
    (Story) => (
      <div className="light bg-background text-foreground p-8 rounded-xl border border-border shadow-xs flex flex-col items-center justify-center gap-3 min-w-[280px]">
        <span className="text-[11px] font-mono font-medium uppercase tracking-wider text-muted-foreground">
          Skeleton (Light)
        </span>
        <Story />
      </div>
    ),
  ],
};

export const SkeletonDark: Story = {
  parameters: {
    themes: { themeOverride: "dark" },
    backgrounds: { default: "dark" },
  },
  render: () => <FeatureCardSkeleton />,
  decorators: [
    (Story) => (
      <div className="dark bg-background text-foreground p-8 rounded-xl border border-border shadow-xs flex flex-col items-center justify-center gap-3 min-w-[280px]">
        <span className="text-[11px] font-mono font-medium uppercase tracking-wider text-muted-foreground">
          Skeleton (Dark)
        </span>
        <Story />
      </div>
    ),
  ],
};
