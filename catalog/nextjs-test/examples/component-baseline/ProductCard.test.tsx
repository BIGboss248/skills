import { render, screen } from "@testing-library/react";
import { Suspense } from "react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { ProductCard, ProductCardSkeleton } from "./ProductCard";
import { productCache } from "./product-cache";

/**
 * Renders a query-driven component with a seeded client.
 *
 * @param ui - Component tree under test.
 * @param client - Query client with pre-populated cache.
 */
function renderWithClient(ui: React.ReactElement, client: QueryClient) {
  return render(
    <QueryClientProvider client={client}>{ui}</QueryClientProvider>,
  );
}

describe("ProductCard (baseline, useSuspenseQuery)", () => {
  it("renders cached product data", () => {
    const testClient = new QueryClient({
      defaultOptions: { queries: { retry: false, gcTime: Infinity } },
    });

    testClient.setQueryData(productCache.key("prod-1"), {
      id: "prod-1",
      name: "Ergonomic Chair",
      price: 299,
      isFavorite: false,
    });

    renderWithClient(
      <Suspense fallback={<ProductCardSkeleton />}>
        <ProductCard id="prod-1" onToggleFavorite={jest.fn()} />
      </Suspense>,
      testClient,
    );

    expect(screen.getByRole("heading", { level: 3 })).toHaveTextContent(
      "Ergonomic Chair",
    );
    expect(screen.getByText("$299")).toBeInTheDocument();
  });

  it("renders the skeleton matching component dimensions", () => {
    const { container } = render(<ProductCardSkeleton />);

    expect(container.firstChild).toHaveClass("animate-pulse");
  });
});
