# Grilling Interview Reference Guide

This guide details the interview methodology, question structuring, and core inquiry areas for Next.js App Router planning.

---

## Grilling Methodology & The Frontier

The interview is structured as a **design tree** where high-level decisions branch into downstream technical requirements.

### The Questioning Protocol

1. **Work the Frontier in Rounds**: Group open decisions whose prerequisites are already met into a single round.
2. **Always Number and Recommend**: Number each question and provide a well-reasoned recommended answer based on Next.js best practices and detected project context.
3. **Wait for User Response**: Do not execute subsequent rounds or make assumptions until the user confirms or adjusts answers.
4. **Research Facts Yourself**: When a prerequisite depends on inspecting the codebase, run inspection commands or dispatch subagents rather than asking the user.

### Question Round Format

```markdown
❓ **Q1** - **<Question Title>**: <Clear question explanation and options>

➡️ **Recommended**: <Recommended choice with rationale>

---

❓ **Q2** - **<Question Title>**: <Clear question explanation and options>

➡️ **Recommended**: <Recommended choice with rationale>
```

---

## Mandatory Step 1 Grilling Sequence (Pages ➔ Sections ➔ Components)

> [!IMPORTANT]
> **Strict Hierarchy Rule**: For Step 1 (Design Website & User Experience), the agent must drill down sequentially through three progressive levels:
>
> 1. **Pages Grilling**: Drill down on what exact pages the web application needs (e.g. Home `/`, About `/about`, Projects `/projects`, Blog `/blog`, Lab `/lab`, Contact `/contact`, Dashboard `/dashboard`). Map all routes.
> 2. **Sections Grilling**: For each identified page, drill down on what specific content sections are required from top to bottom (e.g. For Home: SiteNavbar, Hero, Credentials, FeaturedProjects, InteractiveLabPreview, CTA, SiteFooter).
> 3. **Components Grilling**: For each section, drill down on what individual UI components are required to construct that section (e.g. Hero needs `HeroHeadline`, `AvailabilityBadge`, `PrimaryCTAButtons`, `HeroGraphic`).

---

## Core Areas of Inquiry

### 1. Page Inventory & Routes (Step 1 Core)

- What pages must exist in the application?
- Which pages belong in the primary navigation header vs footer or utility/detail routes?
- Which routes require dynamic parameters (e.g., `/projects/[slug]`, `/blog/[slug]`)?

### 2. Page Sections Breakdown (Step 1 Core)

- For every identified page, what specific content sections are needed from top to bottom?
- What is the primary purpose and narrative flow of each section?

### 3. Component Inventory & Roles (Step 1 Core)

- For every section, what specific UI components must be created or assembled?
- Which components are shared across multiple pages (`SiteNavbar`, `SiteFooter`, `Card`, `Badge`) vs. page-specific (`DoHProberConsole`, `ProjectFilterBar`)?

### 4. Product Purpose & Target Audience

- What core problem does the project solve?
- Who are the target users (technical literacy, geographic location, primary languages)?

### 5. Authentication & Authorization

- Is authentication required? (Public, Member, Admin)
- What provider is preferred (Better Auth, Clerk, Auth.js, Supabase Auth)?

### 6. Data Layer & Content Management

- How is data stored and queried (PostgreSQL, SQLite, Supabase, Redis)?
- What ORM or query tool is used (Drizzle, Prisma, Server Functions)?
- Is a CMS needed for content editing (in-repo Payload CMS, Headless CMS, local MDX)?

### 7. Internationalization (i18n) & Locales

- What languages must be supported (e.g., English `en`, Persian `fa`)?
- Are there RTL (Right-to-Left) requirements and specific typography pairings?
- Note: Dictionaries are always placed in `messages/` at the project root.

### 8. Visual Aesthetic, Design Tokens & Multi-Font Pairings

- What emotional tone and aesthetic is desired (e.g., clean dark mode, high-velocity engineering, minimalist typography)?
- Brand primary colors, contrast requirements, and radius tokens.
- **Harmonious Multi-Font Pairing**: Inquire whether to pair complementary typefaces across global styles (e.g. an expressive display/serif or geometric heading font paired with a clean neutral body sans) to give different sections distinct visual character rather than using a single monolithic font.

### 9. Deployment & Operations

- Target deployment platform (Docker on self-hosted VPS, Vercel, Cloudflare)?
- Health monitoring (`/api/health`), OpenTelemetry tracing, and CI/CD release automation requirements.
