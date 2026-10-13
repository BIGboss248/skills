"use client";

import React from "react";
import {
  useSuspenseQuery,
  useMutation,
  useQueryClient,
} from "@tanstack/react-query";
import { cn } from "@/lib/utils";
import { productCache, type Product } from "./product-cache";

export interface ProductCardProps {
  id: string;
  onToggleFavorite: (id: string, nextStatus: boolean) => Promise<void>;
  className?: string;
}

export function ProductCard({
  id,
  onToggleFavorite,
  className = "",
}: ProductCardProps): React.JSX.Element {
  const queryClient = useQueryClient();
  const { data: product } = useSuspenseQuery(productCache.options(id));
  const queryKey = productCache.key(id);

  const mutation = useMutation({
    mutationFn: (nextStatus: boolean) => onToggleFavorite(id, nextStatus),
    onMutate: async (nextStatus) => {
      await queryClient.cancelQueries({ queryKey });
      const previous = queryClient.getQueryData<Product>(queryKey);
      if (previous) {
        queryClient.setQueryData<Product>(queryKey, {
          ...previous,
          isFavorite: nextStatus,
        });
      }
      return { previous };
    },
    onError: (_err, _vars, context) => {
      if (context?.previous) {
        queryClient.setQueryData(queryKey, context.previous);
      }
    },
  });

  return (
    <article
      className={cn(
        "flex flex-col gap-3 p-5 rounded-lg border border-border bg-card text-card-foreground shadow-xs",
        className,
      )}
    >
      <div className="flex items-center justify-between">
        <h3 className="text-lg font-semibold text-foreground">
          {product.name}
        </h3>
        <button
          type="button"
          aria-label={product.isFavorite ? "Remove favorite" : "Add favorite"}
          onClick={() => mutation.mutate(!product.isFavorite)}
          className="text-sm font-medium text-primary hover:underline ms-2"
        >
          {product.isFavorite ? "★ Favorited" : "☆ Favorite"}
        </button>
      </div>
      <p className="text-sm font-medium text-muted-foreground">
        ${product.price}
      </p>
    </article>
  );
}

export function ProductCardSkeleton(): React.JSX.Element {
  return (
    <div className="flex flex-col gap-3 p-5 rounded-lg border border-border bg-muted/40 animate-pulse">
      <div className="h-6 w-2/3 bg-muted rounded" />
      <div className="h-4 w-1/4 bg-muted rounded" />
    </div>
  );
}
