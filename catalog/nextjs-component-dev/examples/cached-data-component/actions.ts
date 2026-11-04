"use server";

import { updateTag } from "next/cache";

export async function mutateProductPrice(productId: string, newPrice: number) {
  // 1. Perform database mutation
  // await db.products.update({ where: { id: productId }, data: { price: newPrice } });

  // 2. Immediate read-your-own-writes invalidation for user
  updateTag("products-cache");

  return { success: true };
}
