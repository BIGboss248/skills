import { Suspense } from "react";
import {
  defaultShouldDehydrateQuery,
  dehydrate,
  HydrationBoundary,
  QueryClient,
} from "@tanstack/react-query";
import { ProductCard, ProductCardSkeleton } from "./ProductCard";
import { productCache } from "./product-cache";

// Replace with actual direct server/DB service function (never call relative fetch on server):
async function getProductFromDb(id: string) {
  return { id, name: "Ergonomic Chair", price: 299, isFavorite: false };
}

async function toggleFavoriteAction(id: string, nextStatus: boolean) {
  "use server";
  // Perform database write & call updateTag(productCache.tag(id))
}

interface ProductSectionProps {
  id: string;
}

export function ProductSection({ id }: ProductSectionProps): React.JSX.Element {
  return (
    <Suspense fallback={<ProductCardSkeleton />}>
      <ProductSectionData id={id} />
    </Suspense>
  );
}

async function ProductSectionData({
  id,
}: {
  id: string;
}): Promise<React.JSX.Element> {
  const queryClient = new QueryClient();

  // Non-blocking server prefetch (unawaited to allow route streaming)
  void queryClient.prefetchQuery({
    ...productCache.options(id),
    queryFn: () => getProductFromDb(id), // Direct DB call on server
  });

  return (
    <HydrationBoundary
      state={dehydrate(queryClient, {
        shouldDehydrateQuery: (query) =>
          defaultShouldDehydrateQuery(query) ||
          query.state.status === "pending",
      })}
    >
      <ProductCard id={id} onToggleFavorite={toggleFavoriteAction} />
    </HydrationBoundary>
  );
}
