import { queryOptions } from "@tanstack/react-query";

export interface Product {
  id: string;
  name: string;
  price: number;
  isFavorite: boolean;
}

export const productCache = {
  key: (id: string) => ["product", id] as const,
  tag: (id: string) => `product:${id}`,
  options: (id: string) =>
    queryOptions({
      queryKey: productCache.key(id),
      queryFn: async (): Promise<Product> => {
        const res = await fetch(`/api/products/${id}`);
        if (!res.ok) throw new Error("Failed to fetch product");
        return res.json();
      },
      staleTime: 30_000,
    }),
};

