"use client";

import React from "react";
import { useLinkStatus } from "next/link";
import { Loader2 } from "lucide-react";
import { cn } from "@/lib/utils";

/**
 * Props for the LinkStatusContent component.
 */
export interface LinkStatusContentProps {
  /**
   * The default text label displayed when the link is idle.
   */
  label: string;
  /**
   * Optional loading text displayed while the link transition is pending.
   * If omitted, the default label remains visible alongside the spinner.
   * @defaultValue undefined
   */
  loadingLabel?: string;
  /**
   * Optional icon to display alongside the label in the idle state.
   * @defaultValue undefined
   */
  icon?: React.ReactNode;
  /**
   * Optional custom CSS class name for the wrapper span.
   * @defaultValue undefined
   */
  className?: string;
}

/**
 * Contextual loading indicator for Next.js App Router `<Link>` components.
 *
 * Must be rendered as a child of a `<Link>` component. Reads `useLinkStatus()`
 * to determine if this specific link transition is pending, rendering an inline
 * spinner and accessible pending attributes.
 *
 * @param props - Component configuration properties.
 * @returns An inline element reflecting the current link transition status.
 */
export function LinkStatusContent({
  label,
  loadingLabel,
  icon,
  className,
}: LinkStatusContentProps) {
  const { pending } = useLinkStatus();

  return (
    <span
      aria-busy={pending}
      className={cn(
        "inline-flex items-center justify-center gap-2 transition-opacity",
        pending && "pointer-events-none cursor-wait opacity-75",
        className
      )}
    >
      {pending ? (
        <Loader2 className="h-4 w-4 animate-spin text-muted-foreground" aria-hidden="true" />
      ) : (
        icon
      )}
      <span>{pending && loadingLabel ? loadingLabel : label}</span>
    </span>
  );
}
