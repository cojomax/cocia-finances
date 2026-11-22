# ADR 0004: Transaction import, matching and deduplication

- Status: proposed
- Date: 2026-11-21

## Context
Transactions arrive from Finverse, CSV exports and PDF statements. The same real transaction can arrive from several sources, and the same file can be imported twice. An exact-match key over all fields fails both ways:
- Across sources the same transaction differs (description text, posting vs transaction date, sign conventions, missing fields), so it never matches → duplicates.
- Two genuinely identical transactions (two identical coffees the same day) collide → real data lost.

## Options considered
1. Exact hash of all fields, skip on match: pros: simple. cons: fails as described above.
2. Raw storage + within-source dedup + cross-source matching into canonical transactions: pros: accurate, can be audited, can reprocess; the standard reconciliation approach. cons: more tables and logic; needs a review UI.

## Decision
Option 2:
1. **Raw layer**: every imported row is stored untouched (source, import/sync id, original payload).
2. **Within-source dedup**: Finverse uses its own transaction ID. CSV/PDF use a hash of normalised fields **plus an occurrence index** (nth identical row in that statement), so re-imports are skipped but identical real transactions are kept.
3. **Cross-source matching**: candidates match on account + amount + currency (exact), date within ±3 days, and description similarity.
4. **Merge, don't skip**: one canonical transaction linked to all backing source rows. Finverse is the main source; CSV/PDF fill in fields it lacks, and vice versa.
5. **Uncertain matches** go to a review queue in the UI.

## Consequences
- Tables: `raw_import_rows`, `transactions` (canonical), `transaction_sources` (links).
- Can re-run matching after improving the rules, because raw data is kept.
- Thresholds (date window, similarity score) need tuning with synthetic edge-case data from `Cocia.TestData`.
