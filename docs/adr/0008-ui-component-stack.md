# ADR 0008: UI component stack: shadcn/ui, TanStack Table, Recharts

- Status: accepted
- Date: 2026-11-23

## Context
ADR-0001 chose React + Vite + TypeScript with TanStack Query, and left the component library, tables and charts open. The app needs:
- A component library that makes building quicker but follows our own design system (light and dark themes), not a vendor's look.
- Data tables: the transactions list (filter, search, edit category), the import review queue (ADR-0004), investment holdings later. Data volume is one household: tens of thousands of rows at most.
- Charts: spending trends (v1), net worth over time, allocation, retirement projection with a range band.
- Money shown correctly across currencies (ADR-0003), with no floating-point arithmetic (`CLAUDE.md`).

## Options considered
Component library:
1. MUI: pros: largest install base, common in enterprise. cons: built on Material Design, so our look means fighting its defaults; best data grid is paid (MUI X).
2. Ant Design: pros: rich free tables and forms for admin screens. cons: strong visual identity that is hard to override.
3. shadcn/ui (Radix primitives + Tailwind): pros: components are copied into the repo and owned; themed with semantic CSS variables, the same shape as our design tokens; fastest-growing option. cons: we maintain the copied code; Tailwind becomes a dependency.

Tables:
1. AG Grid Community: pros: well-known enterprise grid. cons: grouping, aggregation, Excel export and server-side rows are in the paid Enterprise tier ($999/developer); separate theming API to keep in sync with our tokens.
2. TanStack Table via shadcn's Data Table pattern: pros: headless, so it uses our tokens directly; grouping and aggregation are free; same family as TanStack Query. cons: filter, edit and resize UI is ours to build.

Charts:
1. TanStack Charts: pros: small, flexible grammar of graphics, can read shadcn's CSS variables. cons: 1.0 released October 2026; few examples.
2. AG Charts: pros: polished. cons: another vendor theming system; advanced types are paid.
3. shadcn charts (Recharts): pros: mature, many copy-ready examples, themed by shadcn's `--chart-N` variables out of the box. cons: larger bundle; unusual charts (range bands) need more fiddling.

## Decision
- **shadcn/ui** on its default Radix primitives, with **Tailwind CSS**. Pin versions when `apps/web` is initialised.
- **Tables:** shadcn `Table` + **TanStack Table** (shadcn's Data Table pattern); add **TanStack Virtual** for long lists.
- **Charts:** **shadcn charts (Recharts)**.
- **Server state:** TanStack Query (ADR-0001).
- **Wrapper rule:** screens use our own components (`DataTable`, `TrendChart`, `CategoryBars`, `AllocationBar`, `ProjectionChart`, `Money`), never TanStack Table or Recharts directly. This keeps a later swap (AG Grid, TanStack Charts) to one place.
- **Theming:** the design system's tokens are CSS variables using shadcn's semantic names (`--background`, `--primary`, `--chart-1` to `--chart-5`, …) plus Cocia-specific ones, with light and dark values.
- **Money in the UI:** amounts arrive from the API as integer minor units + ISO 4217 code; the browser does no currency conversion or arithmetic. One `Money` component formats with `Intl.NumberFormat`. Charts convert minor units to numbers only to plot them.

## Consequences
- We own the component code: upgrade by re-running the shadcn CLI and reviewing diffs, not `npm update`.
- Tailwind is required in `apps/web`.
- Recharts adds bundle size; acceptable for a signed-in app.
- Revisit AG Grid if spreadsheet-style bulk editing becomes a need; revisit TanStack Charts once it has matured.
- Still to decide (separate short ADRs or notes here): forms (shadcn assumes react-hook-form + zod), router (TanStack Router or React Router), and the OpenAPI client generator (Kiota/NSwag in `plan.md`, or Orval / Hey API, which generate TanStack Query hooks).
