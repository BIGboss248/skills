import { render, screen } from "@testing-library/react";
import { NextIntlClientProvider } from "next-intl";
import { FeatureCard, FeatureCardSkeleton } from "./FeatureCard";

describe("FeatureCard (baseline)", () => {
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

  it("renders the card title and description", async () => {
    // Synchronous RSC: await the component, then render the resolved JSX.
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

  it("renders the localized link and dictionary text", async () => {
    const jsx = await FeatureCard(mockProps);
    render(
      <NextIntlClientProvider locale="fa" messages={mockMessages}>
        {jsx}
      </NextIntlClientProvider>,
    );

    const link = screen.getByRole("link", { name: /ادامه مطلب/i });
    expect(link).toHaveAttribute("href", "/fa/features/nextjs");
  });

  it("renders the skeleton with matching layout", () => {
    const { container } = render(<FeatureCardSkeleton />);

    expect(container.firstChild).toHaveClass("animate-pulse");
  });
});
