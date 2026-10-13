import React from "react";
import Image from "next/image";
import { Link } from "@vercel/react-transition-progress";
import { Graph } from "schema-dts";
import { cn } from "@/lib/utils";

/**
 * Props for the FeatureCard component.
 */
export interface FeatureCardProps {
  /** Title of the feature card */
  title: string;
  /** Detailed description text */
  description: string;
  /** Image source URL relative or absolute */
  imageUrl: string;
  /** Navigation target path */
  href: string;
  /** Active user locale (e.g. 'fa' or 'en') */
  locale: string;
  /** Optional container class names @defaultValue `""` */
  className?: string;
}

/**
 * Renders a server-side cacheable feature card with responsive styling,
 * localized navigation, and schema.org structured data.
 *
 * @param props - Configuration properties for FeatureCard.
 * @returns A React Server Component rendering the localized feature card.
 */
export function FeatureCard({
  title,
  description,
  imageUrl,
  href,
  locale,
  className = "",
}: FeatureCardProps): React.JSX.Element {
  const localizedUrl = `/${locale}${href.startsWith("/") ? href : `/${href}`}`;

  const jsonLd: Graph = {
    "@context": "https://schema.org",
    "@graph": [
      {
        "@type": "WebPage",
        "@id": `${localizedUrl}#webpage`,
        url: localizedUrl,
        name: title,
        description: description,
      },
    ],
  };

  return (
    <>
      {/* TODO: Validate this JSON-LD schema on https://validator.schema.org/ */}
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
      <article
        className={cn(
          "flex flex-col gap-4 p-6 rounded-lg border border-border bg-card text-card-foreground shadow-xs transition-all hover:shadow-md",
          className,
        )}
      >
        <div className="relative w-full h-48 overflow-hidden rounded-md">
          <Image
            src={imageUrl}
            alt={title}
            fill
            className="object-cover"
            sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
          />
        </div>
        <h2 className="text-xl font-bold tracking-tight text-foreground">
          {title}
        </h2>
        <p className="text-sm text-muted-foreground leading-relaxed">
          {description}
        </p>
        <Link
          href={localizedUrl}
          className="inline-flex items-center gap-2 text-sm font-semibold text-primary hover:underline ms-auto"
        >
          Read More
        </Link>
      </article>
    </>
  );
}

/**
 * Skeleton fallback matching FeatureCard dimensions to prevent CLS.
 */
export function FeatureCardSkeleton(): React.JSX.Element {
  return (
    <div className="flex flex-col gap-4 p-6 rounded-lg border border-border bg-muted/40 animate-pulse">
      <div className="w-full h-48 bg-muted rounded-md" />
      <div className="h-6 w-3/4 bg-muted rounded" />
      <div className="h-4 w-full bg-muted rounded" />
      <div className="h-4 w-1/4 bg-muted rounded ms-auto" />
    </div>
  );
}
