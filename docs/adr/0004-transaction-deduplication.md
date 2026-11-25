# ADR 0004: Transaction import, matching and deduplication

- Status: accepted (amended 2026-11-25)
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

## Amendment (2026-11-25): Finverse first, historical imports by cutoff
Finverse is the main source going forward; CSV and PDF are only used to import history from before Finverse's data starts. That removes most of the need for cross-source matching:
- **Cutoff rule**: per account, CSV/PDF rows are imported only for dates **before** the earliest `posted_date` Finverse has for that account. Sources don't overlap, so there are no cross-source duplicates.
- **One source row per canonical transaction**: `transactions.raw_row_id` (unique). The `transaction_sources` link table, cross-source matching (point 3), merging (point 4) and the review queue (point 5) are **deferred** until a real need appears (e.g. deliberately overlapping a few days to check the join).
- Within-source dedup (point 2) and the raw layer (point 1) stand, detailed in ADR-0010: `source_key` per source, payload kept as text, original files in Blob Storage, `file_sha256` to reject re-uploading the same file.
- CSV/PDF rows lack Finverse's richer fields (merchant, category…): those canonical columns are nullable; enrichment comes from category rules and description clean-up.
- Import whole days only, so occurrence indexes stay stable across overlapping exports.
