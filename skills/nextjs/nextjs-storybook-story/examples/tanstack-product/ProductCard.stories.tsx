import type { Meta, StoryObj } from "@storybook/nextjs-vite";
import { fn } from "storybook/test";
import { ProductCard, ProductCardSkeleton } from "./ProductCard";

const meta: Meta<typeof ProductCard> = {
  title: "Shop/ProductCard",
  component: ProductCard,
  tags: ["autodocs", "ai-generated"],
  parameters: {
    docs: {
      description: {
        component:
          "### ProductCard\n\nClient component utilizing TanStack Query `useSuspenseQuery` and optimistic mutations with action spies.",
      },
    },
  },
  argTypes: {
    id: {
      control: "text",
      description: "Unique product identifier",
    },
    onToggleFavorite: {
      description: "Async favorite mutation callback spy",
    },
  },
  args: {
    id: "prod-1",
    onToggleFavorite: fn(),
  },
};

export default meta;
type Story = StoryObj<typeof ProductCard>;

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
  render: () => <ProductCardSkeleton />,
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
  render: () => <ProductCardSkeleton />,
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
