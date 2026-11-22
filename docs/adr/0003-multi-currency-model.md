# ADR 0003: Multi-currency model, USD reporting currency

- Status: proposed
- Date: 2026-11-21

## Context
USD is the primary currency, but accounts are also held in HKD, ZAR, EUR and GBP. Reports (trends, net worth) need one currency, while the original amounts must stay accurate. I also want live rates as a learning exercise (background services + WebSockets).

## Options considered
1. Convert everything to USD when saving: pros: simple queries. cons: loses the original amount; rates can't be corrected later.
2. Store original amounts; convert when reading using a stored rate history: pros: accurate, can be audited, can reprocess. cons: more complex queries.

## Decision
Option 2.
- Every amount is stored as **integer minor units + ISO 4217 code**, in its original currency. Never overwritten by a converted value.
- `fx_rates` table: base, quote, rate (decimal), timestamp, source.
- **USD is the reporting currency.** Conversion happens when reading or reporting.
  - Historical views (spending trends): rate on the transaction date (daily close).
  - Current views (balances, net worth): latest rate.
- The **worker** polls FX providers (see ADR-0007 for sources and frequency) and stores a daily close for history. Rate changes are pushed to the UI via **SignalR** through the BFF.

## Consequences
- Report queries join to `fx_rates`; may need a materialised view for performance.
- Need a rule for missing rates (weekends/holidays: use the most recent earlier rate).
- Live rates are a learning feature, not a product need: banks settle at their own rates. Keep polling within the provider's free-tier limits.
- HKD is pegged to USD within a narrow band; ZAR/EUR/GBP move freely.
