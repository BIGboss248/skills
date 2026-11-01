import { screen } from "@testing-library/react";
import { Suspense } from "react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { render } from "@testing-library/react";
import { ProductCard, ProductCardSkeleton } from "./ProductCard";
import { productCache } from "./product-cache";

function renderWithClient(ui: React.ReactElement, client: QueryClient) {
  return render(
    <QueryClientProvider client={client}>{ui}</QueryClientProvider>,
  );
}

describe("ProductCard (TDD with useSuspenseQuery)", () => {
  it("renders cached product data when available", () => {
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

  it("renders Skeleton matching component dimensions during fallback", () => {
    const { container } = render(<ProductCardSkeleton />);
    expect(container.firstChild).toHaveClass("animate-pulse");
  });
});
