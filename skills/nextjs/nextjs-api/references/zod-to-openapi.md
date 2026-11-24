# Schema Validation & OpenAPI Registry with Zod

This guide details how to build type-safe, schema-driven Next.js Route Handlers and generate OpenAPI 3.1 specifications using [Zod](https://zod.dev/) and [`@asteasolutions/zod-to-openapi`](https://github.com/asteasolutions/zod-to-openapi).

---

## 1. Setup & Extension

Extend Zod with the OpenAPI method:

```ts
// lib/openapi.ts
import { extendZodWithOpenApi, OpenAPIRegistry, OpenApiGeneratorV31 } from "@asteasolutions/zod-to-openapi";
import { z } from "zod";

extendZodWithOpenApi(z);

export const registry = new OpenAPIRegistry();
```

---

## 2. Defining OpenAPI-Annotated Zod Schemas

```ts
export const ProductSchema = z
  .object({
    id: z.string().uuid().openapi({ description: "Unique UUID identifier", example: "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d" }),
    name: z.string().min(1).max(100).openapi({ description: "Product name", example: "Wireless Noise-Cancelling Headphones" }),
    price: z.number().positive().openapi({ description: "Price in USD", example: 199.99 }),
    inStock: z.boolean().default(true).openapi({ description: "Inventory availability status" }),
    createdAt: z.string().datetime().openapi({ description: "ISO 8601 timestamp" }),
  })
  .openapi("Product");

export const CreateProductSchema = ProductSchema.omit({
  id: true,
  createdAt: true,
}).openapi("CreateProductInput");
```

---

## 3. Registering Endpoints into the OpenAPI Registry

```ts
registry.registerPath({
  method: "post",
  path: "/api/v1/products",
  description: "Create a new product in the catalog.",
  summary: "Create product",
  request: {
    body: {
      content: {
        "application/json": {
          schema: CreateProductSchema,
        },
      },
    },
  },
  responses: {
    201: {
      description: "Product created successfully.",
      content: {
        "application/json": {
          schema: ProductSchema,
        },
      },
    },
    422: {
      description: "Validation error (RFC 9457 Problem Details).",
    },
  },
});
```

---

## 4. Generating the OpenAPI Document

```ts
export function getOpenApiDocumentation() {
  const generator = new OpenApiGeneratorV31(registry.definitions);
  return generator.generateDocument({
    openapi: "3.1.0",
    info: {
      version: "1.0.0",
      title: "Next.js Application API",
      description: "RESTful API routes conforming to OpenAPI 3.1 standards.",
    },
    servers: [{ url: "/" }],
  });
}
```
