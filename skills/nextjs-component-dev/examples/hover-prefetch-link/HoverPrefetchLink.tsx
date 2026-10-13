"use client";

import * as React from "react";
import { Link } from "@/components/Link";

interface HoverPrefetchLinkProps extends React.ComponentProps<typeof Link> {
  href: string;
  children: React.ReactNode;
}

/**
 * Optimized Link component that only triggers route prefetching upon mouse hover / focus,
 * preventing viewport network saturation on virtualized lists or long scroll feeds.
 */
export function HoverPrefetchLink({
  href,
  children,
  onMouseEnter,
  ...props
}: HoverPrefetchLinkProps) {
  const [active, setActive] = React.useState(false);

  return (
    <Link
      href={href}
      prefetch={active ? null : false}
      onMouseEnter={(e) => {
        setActive(true);
        if (onMouseEnter) onMouseEnter(e);
      }}
      {...props}
    >
      {children}
    </Link>
  );
}
