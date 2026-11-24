# Next.js 16 Route Handler Specification & Patterns

Complete architectural guide for implementing HTTP route handlers in Next.js 16 App Router (`app/api/**/route.ts`), adhering to Web Standards and Next.js 16 runtime conventions.

---

## 1. Asynchronous Request APIs (Next.js 15 & 16)

All dynamic request parameters and headers in Next.js 16 are asynchronous Promises:

### A. Dynamic Route Parameters (`context.params`)
Route segment parameters MUST be awaited before accessing properties:
```ts
// app/api/v1/teams/[teamId]/members/[memberId]/route.ts
import { NextRequest, NextResponse } from "next/server";

interface RouteContext {
  params: Promise<{
    teamId: string;
    memberId: string;
  }>;
}

export async function GET(request: NextRequest, context: RouteContext) {
  const { teamId, memberId } = await context.params;
  return NextResponse.json({ teamId, memberId });
}
```

### B. Headers, Cookies & Draft Mode
Accessing cookies or request headers via `next/headers` is asynchronous:
```ts
import { cookies, headers } from "next/headers";

export async function GET() {
  const cookieStore = await cookies();
  const token = cookieStore.get("session_token")?.value;

  const headerList = await headers();
  const userAgent = headerList.get("user-agent") || "unknown";

  return NextResponse.json({ authenticated: Boolean(token), userAgent });
}
```

---

## 2. Caching Mechanics in Next.js 16

In Next.js 15 and 16, **Route Handlers are uncached by default**. All HTTP methods (`GET`, `POST`, etc.) evaluate dynamically on every request.

### Explicit Caching with `"use cache"` & `cacheLife`
To cache `GET` route responses:
```ts
import { cacheLife, cacheTag } from "next/cache";

export async function GET() {
  "use cache";
  cacheLife("hours"); // presets: default, seconds, minutes, hours, days, weeks, max
  cacheTag("catalog-products");

  const products = await fetchProductCatalog();
  return Response.json(products);
}
```

### Static Prerendering via Route Segment Config
To force build-time static generation for completely static endpoints:
```ts
export const dynamic = "force-static";
export const revalidate = 86400; // Revalidate every 24 hours
```

---

## 3. Web Standards & `NextRequest` Extensions

Route Handlers support standard Web `Request` and `Response`, but `NextRequest` provides helpful utilities:

| Feature | NextRequest Helper | Standard Web API Equivalent |
| :--- | :--- | :--- |
| **Search Params** | `request.nextUrl.searchParams` | `new URL(request.url).searchParams` |
| **Incoming Cookies** | `request.cookies.get('token')` | Parsing `request.headers.get('cookie')` |
| **Client Abort Signal** | `request.signal` | Standard `AbortSignal` for canceling async DB queries |
| **Geolocation / IP** | `request.ip`, `request.geo` | Platform headers (`x-forwarded-for`) |

### Example: Using `request.signal` for Graceful Client Disconnects
```ts
export async function GET(request: NextRequest) {
  // Pass abort signal to db query or external fetch
  const data = await db.query("SELECT * FROM large_table", {
    signal: request.signal,
  });
  return NextResponse.json(data);
}
```

---

## 4. Streaming Responses & Server-Sent Events (SSE)

Next.js 16 natively supports Web Streams (`ReadableStream`) for real-time telemetry, AI chunking, or large exports:

```ts
export async function GET(request: NextRequest) {
  const encoder = new TextEncoder();

  const stream = new ReadableStream({
    async start(controller) {
      for (let i = 1; i <= 5; i++) {
        if (request.signal.aborted) break;
        controller.enqueue(encoder.encode(`data: ${JSON.stringify({ step: i })}\n\n`));
        await new Promise((resolve) => setTimeout(resolve, 500));
      }
      controller.close();
    },
  });

  return new Response(stream, {
    headers: {
      "Content-Type": "text/event-stream",
      "Cache-Control": "no-cache, no-transform",
      "Connection": "keep-alive",
    },
  });
}
```

---

## 5. FormData & File Uploads

Process binary uploads using standard Web `FormData`:
```ts
export async function POST(request: NextRequest) {
  const formData = await request.formData();
  const file = formData.get("avatar") as File | null;

  if (!file) {
    return NextResponse.json({ error: "File missing" }, { status: 400 });
  }

  const bytes = await file.arrayBuffer();
  const buffer = Buffer.from(bytes);
  // Persist buffer to S3 / disk ...

  return NextResponse.json({ filename: file.name, size: file.size });
}
```

---

## 6. Route Segment Config Options (Next.js 16)

Export configuration constants at the top of `route.ts`:
```ts
export const runtime = "nodejs"; // 'nodejs' | 'edge'
export const dynamic = "force-dynamic"; // 'auto' | 'force-dynamic' | 'error' | 'force-static'
export const maxDuration = 30; // Max execution timeout in seconds (Vercel / Serverless)
```

> [!WARNING] Route Colocation Rule
> A `route.ts` file **CANNOT** coexist at the same route path as a `page.tsx` file.
> - Invalid: `app/dashboard/route.ts` AND `app/dashboard/page.tsx`
> - Valid: `app/api/dashboard/route.ts` AND `app/dashboard/page.tsx`
