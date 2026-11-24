import Image from "next/image";
import { cn } from "@/lib/utils";

/**
 * Props for the ThemeHeroBackdrop component.
 */
export interface ThemeHeroBackdropProps {
  /** Daylight plate, shown in the light theme. */
  lightSrc: string;
  /** Night plate of the same scene, shown in the dark theme. */
  darkSrc: string;
  /** Wrapper height on small screens. @defaultValue `"min-h-[520px]"` */
  minHeightClassName?: string;
  /** Focal point on small screens. @defaultValue `"object-top"` */
  objectPositionClassName?: string;
  /** Focal point from `lg` up. @defaultValue `"lg:object-[55%_center]"` */
  objectPositionClassNameLg?: string;
  /** Wrapper class names. @defaultValue `""` */
  className?: string;
}

/**
 * Renders the two theme plates for a hero section. Both plates ship in the
 * HTML inside one positioned box; the `.dark` class on `<html>` decides which
 * one is visible, so no React state or hydration gate is involved.
 *
 * Only the light plate gets `priority`. Marking both emits two preload links
 * that compete for the LCP slot.
 *
 * @param props - Plate sources and framing overrides.
 * @returns A React Server Component holding the decorative hero artwork.
 */
export function ThemeHeroBackdrop({
  lightSrc,
  darkSrc,
  minHeightClassName = "min-h-[520px]",
  objectPositionClassName = "object-top",
  objectPositionClassNameLg = "lg:object-[55%_center]",
  className = "",
}: ThemeHeroBackdropProps): React.JSX.Element {
  const plateClassName = cn(
    "object-cover",
    objectPositionClassName,
    objectPositionClassNameLg,
  );

  return (
    <div
      aria-hidden
      className={cn(
        "pointer-events-none absolute inset-0 -z-10 overflow-hidden",
        minHeightClassName,
        className,
      )}
    >
      <Image
        src={lightSrc}
        alt=""
        fill
        priority
        sizes="100vw"
        className={cn(plateClassName, "dark:hidden")}
      />
      <Image
        src={darkSrc}
        alt=""
        fill
        loading="lazy"
        fetchPriority="low"
        sizes="100vw"
        className={cn(plateClassName, "hidden dark:block")}
      />
    </div>
  );
}
