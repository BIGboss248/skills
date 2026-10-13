import { cacheLife, cacheTag } from "next/cache";

export interface ProductItem {
  id: string;
  name: string;
  price: number;
}

export async function getCachedProducts(): Promise<ProductItem[]> {
  "use cache";
  cacheLife("hours");
  cacheTag("products-cache");

  // Simulated DB fetch
  return [
    { id: "1", name: "Premium Widget", price: 99 },
    { id: "2", name: "Standard Gadget", price: 49 },
  ];
}
