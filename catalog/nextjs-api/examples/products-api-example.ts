import { z } from "zod";
import { registry } from "@/lib/openapi";
import { NextRequest, NextResponse } from "next/server";
import { createProblemResponse, handleValidationError } from "@/lib/api/problem-details";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

// 1. Define Entity Schemas with OpenAPI annotations
export const ProductSchema = z
  .object({
    id: z.string().uuid().openapi({ description: "Unique product identifier", example: "550e8400-e29b-41d4-a716-446655440000" }),
    title: z.string().min(2).max(120).openapi({ description: "Product title", example: "Mechanical Keyboard" }),
    price: z.number().positive().openapi({ description: "Price in USD", example: 129.99 }),
    inStock: z.boolean().default(true).openapi({ description: "Stock status" }),
  })
  .openapi("Product");

export const CreateProductInput = ProductSchema.omit({ id: true }).openapi("CreateProductInput");

// 2. Register Route with OpenAPI Registry
registry.registerPath({
  method: "get",
  path: "/api/v1/products",
  summary: "List all products",
  responses: {
    200: {
      description: "List of products",
      content: {
        "application/json": {
          schema: z.array(ProductSchema),
        },
      },
    },
  },
});

registry.registerPath({
  method: "post",
  path: "/api/v1/products",
  summary: "Create product",
  request: {
    body: {
      content: {
        "application/json": { schema: CreateProductInput },
      },
    },
  },
  responses: {
    201: {
      description: "Created product",
      content: {
        "application/json": { schema: ProductSchema },
      },
    },
    422: {
      description: "Validation error (RFC 9457 Problem Details)",
    },
  },
});

// 3. Collection Route Handlers (app/api/v1/products/route.ts)
export async function POST(request: NextRequest) {
  try {
    let body: unknown;
    try {
      body = await request.json();
    } catch {
      return createProblemResponse({
        title: "Bad Request",
        status: 400,
        detail: "Malformed JSON payload.",
        instance: request.nextUrl.pathname,
      });
    }

    const result = CreateProductInput.safeParse(body);
    if (!result.success) {
      return handleValidationError(result.error, request.nextUrl.pathname);
    }

    const newProduct = {
      id: crypto.randomUUID(),
      ...result.data,
    };

    return NextResponse.json(newProduct, {
      status: 201,
      headers: {
        Location: `/api/v1/products/${newProduct.id}`,
      },
    });
  } catch (err) {
    return createProblemResponse({
      title: "Internal Server Error",
      status: 500,
      detail: "Unexpected error during product creation.",
    });
  }
}

// 4. Dynamic Segment Handler (app/api/v1/products/[id]/route.ts)
interface RouteContext {
  params: Promise<{ id: string }>;
}

export async function GET(request: NextRequest, context: RouteContext) {
  const { id } = await context.params;

  // Query database using request.signal for abort support
  const product = null;

  if (!product) {
    return createProblemResponse({
      title: "Not Found",
      status: 404,
      detail: `Product '${id}' not found.`,
      instance: request.nextUrl.pathname,
    });
  }

  return NextResponse.json(product);
}
