# Cocia

Calm, factual money. Cocia is a private finance app for one household: spending, investments, estate and planning in one place. The interface should feel like a well-kept ledger, not a trading screen. It's quiet by default, precise with numbers, and loud only when something needs the user to act.

This file is the brand book. Tokens are in `tokens.json`. In the codebase this system lives in `docs/design-system/` and is the source of truth; the web app is built with shadcn/ui, Tailwind, TanStack Table and Recharts (ADR-0008).

## Principles

1. **Numbers first.** Figures are the content. Give them the largest type, tabular digits and room to breathe. Chrome stays neutral.
2. **Colour means something.** Teal = brand, action and gains. Red = losses and shortfalls. Orange = needs your action. Everything else is ink and grey. Never use colour as decoration.
3. **Tell me what to do.** Every screen leads with what changed or what needs attention, then the detail.
4. **Honest about uncertainty.** Converted amounts show they're converted, rates show their age, synced data shows when it last synced, estimates say they're estimates.
5. **Private by default.** "Hide amounts" is always one click away. Real financial data never appears in examples, screenshots or tests; use synthetic data.

## Voice and copy

- Plain, short, specific. Sentence case everywhere ("Link bank account", not "Link Bank Account").
- Name the thing and the action: "Bank link expires in 5 days · Re-link", not "Warning: authentication issue".
- No alarm words (urgent, critical, danger) and no exclamation marks. Orange plus a clear action is enough.
- Buttons are verbs: Link, Import, Review, Categorise, Save scenario.
- Empty states say what will appear and how to get it: "No transactions yet. Link a bank account or import a CSV/OFX file."
- Dates: "21 Nov" in lists, "21 November 2026" in headings, relative time for sync status ("Synced 2 h ago").
- Spelling: UK English (categorise, colour) in UI copy.

## Money and numbers

These rules apply everywhere, including tables, charts and tooltips. In code, one `Money` component implements them; screens never format amounts by hand.

**Format: US style for every currency.** Comma thousands separator, dot decimal: `$1,234.56`, `R 18,400.00`, `€950.00`. Always two decimals in lists and tables; whole units are allowed for large headline figures and chart axes (`$4.25M`, `$412K` on axes only).

**Symbols:**

| Currency | Shown as | Example |
|---|---|---|
| USD | `$` | `$1,240.50` |
| HKD | `HK$` | `HK$9,680.00` |
| ZAR | `R` + space | `R 18,400.00` |
| EUR | `€` | `€950.00` |
| GBP | `£` | `£730.00` |

USD is the only currency shown with a bare `$`. HKD always carries `HK$`, so the two can't be confused. Any future dollar currency gets its prefix too (A$, C$). Where a table mixes currencies, add a currency column or code (`USD`, `HKD`) rather than relying on the symbol.

**Signs.** Negatives use a true minus sign (U+2212) before the symbol: `−$1,240.50`. Gains that are shown as a change get an explicit plus: `+$38,200`, `+9.8%`. Never use brackets for negatives.

**Colour of amounts:**
- `negative` (red): losses and shortfalls only. That means negative returns, negative cash flow, overspent budgets and overdrawn balances.
- `positive` (teal): gains, positive returns and positive cash flow, shown as a change.
- Ordinary expenses are **not** red. A transaction list shows `−$385.00` in `foreground`; otherwise every list is a wall of red.
- Colour is never the only signal: the sign is always there.

**Original vs reporting currency (ADR-0003).**
- A single item (transaction, account balance, holding) shows its **original currency**.
- Anything combined (totals, net worth, budgets, charts, cash flow) shows **USD**, labelled once per card or chart ("in USD").
- Where an original amount isn't USD, its USD value can appear underneath in `muted-foreground` with an approximate sign: `HK$9,680.00` / `≈ $1,241.03`.
- A converted figure carries the rate's age somewhere on the same card: "Rates as of 14:00". This is a rule from ADR-0007.

**Digits.** Always tabular (`font-variant-numeric: tabular-nums`) so columns line up. Right-align amounts in tables.

## People and accounts

The app shows accounts belonging to several people in one household. Every list, table and chart can be filtered by **person** and by **account**.

- Each person has a person chip: initials in a `radius-full` circle plus their name. Each account always shows its owner.
- The global filter sits in the page header: "Everyone ▾" and "All accounts ▾". The current filter is always visible, so totals are never ambiguous.
- Totals respect the filter and say so: "Net worth · Everyone" or "Net worth · Sam".
- Use colour for people only as a secondary cue. Names and initials carry the meaning.

## Colour

Teal is the brand. The rest of the palette is warm neutral, with two signal hues.

| Role | Token | Use |
|---|---|---|
| Ground | `background` | Page behind cards |
| Surface | `card`, `popover` | Cards, tables, menus |
| Ink | `foreground`, `muted-foreground` | Text, figures, labels |
| Brand / action | `primary`, `accent` | Primary buttons, links, selected states |
| Gain | `positive` | Gains, shown as a change |
| Loss | `negative` | Losses and shortfalls |
| Needs action | `attention`, `attention-surface`, `attention-strong` | Items the user must act on |
| Destructive | `destructive` | Delete, disconnect |
| Structure | `border`, `input`, `ring`, `track` | Dividers, control borders, focus, empty bars |
| Navigation | `sidebar-*` | The dark sidebar in both themes |
| Charts | `chart-1` … `chart-5`, `chart-grid` | Data series and gridlines |

- One `primary` button per view. Everything else is secondary or ghost.
- Orange (`attention`) and red (`negative`) never stand in for each other. Orange asks you to do something; red reports a number that went the wrong way.
- Cards are separated by `border`, not shadows. Shadows (`shadow-popover`) are for floating layers only.
- **Dark mode** follows the device setting, with a manual override in Settings. Every token has a light and a dark value. Never hard-code a colour.
- Contrast: text pairs meet 4.5:1 and control borders, focus rings and chart series meet 3:1 in both themes.

## Typography

- **Inter** for all UI text. **Space Grotesk** for page titles and headline figures. Both are Google Fonts.
- Display styles (`page-title`, `figure-lg`, `figure-md`) are for one or two things per screen: the page title and the key figures. Text styles cover everything else.
- `label` (12px/500) is the smallest size. Use it only for column headers and form labels.
- Never use bold body text for emphasis inside sentences. Use structure instead.

## Layout

- **Desktop:** a fixed 232px dark sidebar plus content with 32px top and 40px side padding. Content is a stack of sections 24px apart; cards sit in responsive grids with 16px gaps.
- **Page header:** title (with date or context above it in `caption`) on the left; filters (person, account, period) and actions on the right. One primary action at most.
- **Phone:** the sidebar becomes a 5-tab bottom bar (Overview, Spending, Invest, Estate, Plan). Cards stack in one column and tables scroll horizontally inside their card.
- **Cards:** `card` fill, 1px `border`, `radius-lg`, `space-5` padding, with a title in the `title` style.
- Touch targets are at least 44px. Inputs and buttons are 40–44px tall.

## Iconography

- **Lucide** icons, the shadcn default. Outline style, 24px grid, drawn at 18px in navigation and 16px inline.
- Stroke 1.75–2, `currentColor`.
- Icons support labels; they never replace them, except in compact toolbars, where they need an `aria-label` and a tooltip.
- No emoji in the UI.

## Charts

- Charts are wrapped in app components (`TrendChart`, `CategoryBars`, `AllocationBar`, `ProjectionChart`) built on shadcn charts (Recharts). Screens never use Recharts directly.
- Series colours go in order `chart-1` … `chart-5`. "Other" always uses `chart-5`. Comparison or target lines are dashed.
- Gridlines use `chart-grid`, horizontal only. No chart borders and no 3D. Axis text is `caption` in `muted-foreground`.
- Combined values are in USD (see Money). Say so in the chart's subtitle.
- Tooltips use the `popover` surface and format amounts with the Money rules.
- Label series directly or with a legend. Colour alone never identifies a series.
- Every chart has a text alternative: a one-line summary for screen readers ("Net worth rose $412K over 12 months").

## Motion

- Quick and functional. 150ms for hover and press, 200ms for popovers and menus, 250ms for chart transitions. Ease-out.
- Respect `prefers-reduced-motion`: no chart animation and instant transitions.

## Accessibility

- Use real elements: `button`, `a`, `label` + `input`, `table`. Use shadcn's Radix primitives for menus, dialogs and tabs so keyboard handling and ARIA come built in.
- A visible focus ring (`ring`, 2px, offset 2px) on every interactive element.
- Contrast as in Colour, in both themes.
- Amounts are read in full by screen readers: "minus 1,240 dollars 50 cents", not just a red colour.

## Logo

The mark is the **Ring**: an open C with a dot in its gap. It reads as a coin, a progress ring and a C for Cocia. The files are in the Logos asset group (`docs/design-system/logo/` in the repo).

| File | Use |
|---|---|
| `cocia-mark.svg` | The mark on light grounds: `primary` ring with a `chart-2` dot. |
| `cocia-mark-dark.svg` | The mark on dark grounds and in the sidebar: `sidebar-primary` ring with a light-teal dot. |
| `cocia-app-icon.svg` | App icon, favicon and home-screen icon: a white ring in a `primary` tile with `radius-lg` corners. |

- **Lockup:** the mark followed by the word **Cocia** in Space Grotesk 600 and `foreground` (white in the sidebar). The mark's height is 1.4 × the word's font size, with a gap of 0.35 × the mark's height. The word is live text, not part of an image.
- **Clear space:** keep at least half the mark's height empty on every side.
- **Minimum size:** 20px for the bare mark. Below that, use the app icon, which holds up down to 16px.
- **Don't** recolour the ring outside the two versions above, rotate or outline it, put it on a busy background, or use orange or red for it. Those colours mean "needs action" and "loss".
