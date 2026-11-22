# ADR 0007: FX rate sources and polling

- Status: proposed
- Date: 2026-11-22

## Context
ADR-0003 needs exchange rates for USD reporting: daily history for trend reports, and frequent "live" rates for net worth (mainly a learning feature: background services + SignalR). Currencies: USD, HKD, ZAR, EUR, GBP. True streaming FX feeds are aimed at traders and mostly paid.

## Options considered
1. Paid streaming feed (WebSocket): pros: true real-time. cons: monthly cost; no product need, since banks settle at their own rates.
2. Free REST APIs + polling: pros: free; enough accuracy for personal finance. cons: hourly at best.
3. IBKR gateway FX quotes: pros: near-real-time, free with my account. cons: depends on the gateway session (v2 work).

## Decision
Option 2 now, option 3 later:
- **Open Exchange Rates (free plan)** for "live" rates: hourly updates, USD base (matches our reporting currency), 1,000 requests/month. The worker polls **hourly** (~744 requests in a 31-day month); polling more often gains nothing.
- **Frankfurter (ECB reference rates)** for daily closes and backfilling history: free, no key, covers ZAR, HKD, EUR, GBP, USD.
- Rates are stored in `fx_rates` with `source`. When a rate changes, the worker notifies the BFF, which pushes it to clients via SignalR.
- Providers sit behind an `IFxRateProvider` interface so IBKR can be added later as a source.
- API key in Key Vault (ADR-0005).

## Consequences
- "Live" means up to an hour old; the UI shows the rate's timestamp.
- Weekends/holidays: use the most recent earlier rate (ADR-0003).
- Two sources can disagree slightly; reports state which source they used.
- Check provider terms and limits again before relying on them; free tiers change.
