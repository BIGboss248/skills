import React from "react";
import { cn } from "@/lib/utils";

/**
 * Props for ComponentNameSkeleton fallback.
 */
export interface ComponentNameSkeletonProps {
  /**
   * Optional custom CSS class name for outer wrapper styling.
   * @defaultValue undefined
   */
  className?: string;
}

/**
 * ComponentNameSkeleton Suspense Fallback.
 *
 * Mirrors exact layout geometry and bounding box dimensions of ComponentName
 * to prevent Cumulative Layout Shift (CLS) during streaming or hydration.
 *
 * @param props - Skeleton configuration properties.
 * @returns Skeleton JSX element with pulse animation.
 */
export function ComponentNameSkeleton({ className }: ComponentNameSkeletonProps) {
  return (
    <div
      aria-hidden="true"
      className={cn(
        "flex animate-pulse flex-col items-start gap-4 rounded-xl border border-border bg-card p-6 shadow-sm",
        className
      )}
    >
      <div className="h-6 w-48 rounded bg-muted" />
      <div className="h-4 w-full max-w-md rounded bg-muted/70" />
    </div>
  );
}
