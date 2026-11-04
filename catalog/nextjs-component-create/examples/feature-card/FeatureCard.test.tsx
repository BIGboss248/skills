import { render, screen } from "@testing-library/react";
import { FeatureCard, FeatureCardSkeleton } from "./FeatureCard";

describe("FeatureCard (TDD)", () => {
  const mockProps = {
    title: "Awesome Next.js Feature",
    description: "Build robust server components effortlessly.",
    imageUrl: "/images/feature.webp",
    href: "/features/nextjs",
    locale: "fa",
  };

  it("renders card title and description correctly", () => {
    render(<FeatureCard {...mockProps} />);
    expect(screen.getByRole("heading", { level: 2 })).toHaveTextContent(
      "Awesome Next.js Feature",
    );
    expect(
      screen.getByText("Build robust server components effortlessly."),
    ).toBeInTheDocument();
  });

  it("renders localized link attribute", () => {
    render(<FeatureCard {...mockProps} />);
    const link = screen.getByRole("link", { name: /read more/i });
    expect(link).toHaveAttribute("href", "/fa/features/nextjs");
  });

  it("renders Skeleton fallback matching layout", () => {
    const { container } = render(<FeatureCardSkeleton />);
    expect(container.firstChild).toHaveClass("animate-pulse");
  });
});
