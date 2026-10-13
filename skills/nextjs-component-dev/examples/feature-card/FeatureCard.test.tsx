import { render, screen } from "@testing-library/react";
import { NextIntlClientProvider } from "next-intl";
import { FeatureCard, FeatureCardSkeleton } from "./FeatureCard";

describe("FeatureCard (TDD)", () => {
  const mockMessages = {
    feature_card: {
      read_more: "ادامه مطلب",
    },
  };

  const mockProps = {
    title: "Awesome Next.js Feature",
    description: "Build robust server components effortlessly.",
    imageUrl: "/images/feature.webp",
    href: "/features/nextjs",
    locale: "fa",
  };

  it("renders card title and description correctly", async () => {
    // Note: For RSC components in unit tests, render the resolved JSX wrapped in NextIntlClientProvider
    const jsx = await FeatureCard(mockProps);
    render(
      <NextIntlClientProvider locale="fa" messages={mockMessages}>
        {jsx}
      </NextIntlClientProvider>,
    );

    expect(screen.getByRole("heading", { level: 2 })).toHaveTextContent(
      "Awesome Next.js Feature",
    );
    expect(
      screen.getByText("Build robust server components effortlessly."),
    ).toBeInTheDocument();
  });

  it("renders localized link attribute and dictionary text", async () => {
    const jsx = await FeatureCard(mockProps);
    render(
      <NextIntlClientProvider locale="fa" messages={mockMessages}>
        {jsx}
      </NextIntlClientProvider>,
    );

    const link = screen.getByRole("link", { name: /ادامه مطلب/i });
    expect(link).toHaveAttribute("href", "/fa/features/nextjs");
  });

  it("renders Skeleton fallback matching layout", () => {
    const { container } = render(<FeatureCardSkeleton />);
    expect(container.firstChild).toHaveClass("animate-pulse");
  });
});
