# ADR 0010: Data model foundations

- Status: accepted
- Date: 2026-11-25

## Context
Before the first EF Core migration, settle the data-model decisions that are expensive to reverse (they touch every table, or lose data if wrong). Everything else (splits, Postgres schemas, category hierarchy, rule design, transfer linking, investment tables) is decided per feature and added by migration.

Finverse is the main source going forward; CSV and PDF are used only to import older history (ADR-0004 amendment).

## Decisions

### 1. Primary keys: UUIDv7
- Every table's `id` is a `uuid` generated in code with `Guid.CreateVersion7()`.
- Why: IDs exist before saving (the import pipeline builds batches, raw rows and transactions in memory), safe to expose in URLs and the generated TS client (not guessable, doesn't reveal counts), time-ordered so B-tree inserts stay efficient. Cost (16 vs 8 bytes) is irrelevant at household scale.

### 2. Money: strict `Money` on `decimal` / `numeric(19,4)`
- C# `decimal`; Postgres `numeric(19,4)` for every money amount column (covers every ISO 4217 currency; the common ledger column type).
- `Money(decimal Amount, Currency Currency)` value object in `Cocia.Domain`, **strict**: the constructor rejects amounts with more decimals than the currency's ISO 4217 minor unit (2 for USD, ZAR, EUR, GBP, HKD). Calculated values become `Money` only via an explicit `Money.Round(value, currency, mode)`; default `MidpointRounding.ToEven`. `Allocate(n)` splits without losing cents.
- Calculated values (FX-converted amounts, totals in the reporting currency, projections) stay full-precision `decimal` until displayed or turned into a real amount. Convert and sum at full precision; round once at the end.
- Non-money numbers have their own precision: FX rates `numeric(19,10)`; unit prices and quantities (v2) `numeric(28,10)`; percentages `numeric(9,6)`.
- Sign convention: from the account's point of view: negative = money out, positive = money in (credit card purchases are negative).
- Supersedes the "integer minor units" wording in ADR-0003.

### 3. Dates and times
- **Calendar dates** → Postgres `date` ↔ C# `DateOnly`. Transactions have `posted_date` (required: when the bank recorded it; reports use this), `value_date` (nullable), `transaction_date` (nullable: when it was made, if the source gives it).
- **Moments in time** → Postgres `timestamptz` ↔ C# `DateTimeOffset`, always UTC. E.g. `created_at`, `updated_at`, `synced_at`, and a source's authorisation timestamp only when its time zone is known.
- Never use Postgres `timestamp` (without time zone). Times without a known zone are not stored as moments; the original text stays in the raw payload.
- "Now" comes from an injected `TimeProvider` (tests use `FakeTimeProvider`); `DateTime.Now` is banned. "Today", "this month" and default ranges are computed in the user's zone (`Africa/Johannesburg`).

### 4. Internal identity vs source identity; raw data always kept
- Every canonical transaction has our own UUIDv7 `id`. Source identifiers never act as primary keys or foreign keys.
- Each source record is stored once in `raw_import_rows` with `source` + `source_key`:
  - Finverse: its transaction ID.
  - CSV/PDF: `sha256(account | date | amount | normalised description)` + `#` + occurrence index.
  - Unique on `(account_id, source, source_key)`: re-imports are skipped; Finverse updates find and update the existing row.
- `payload` (`jsonb`) holds what the source said **as text, unparsed**: Finverse's transaction object as returned; a CSV row as header → cell; a PDF row's extracted fields plus the raw text line and statement period. Plus `row_ref` (CSV line, PDF page/line).
- Original files (CSV, PDF) are kept in a private Azure Blob Storage container; `import_batches` stores `file_sha256` (rejects re-uploading the same file) and `blob_path`.
- Raw rows and files are never edited. Canonical transactions can be rebuilt from them after parser or normalisation improvements.
- **One source row per transaction for now**: `transactions.raw_row_id` (unique FK). A link table is added only if multiple sources per transaction are ever needed.

### 5. Single owner
- One user (me) owns all data; no `household_id` or multi-tenant columns.
- Accounts can carry an owner label (e.g. Me / Spouse / Joint) for filtering.
- A future read-only login for my spouse is an authorisation concern (a viewer role, see the auth ADR), not a data-model change.

### 6. Conventions
- Postgres naming: snake_case tables and columns (EFCore.NamingConventions); PascalCase in C#.
- Every table has `created_at` and `updated_at` (`timestamptz`).
- One `public` schema for now.

## Initial v1 tables (indicative, will evolve by migration)
`institutions`, `connections`, `accounts`, `import_batches`, `raw_import_rows`, `transactions`, `categories`, `category_rules`, `fx_rates`, `audit_log`. Deferred: balance snapshots, transaction splits, match review queue, transfer linking, investment and planning tables.

## Consequences
- `Money` and `TimeProvider` must exist in `Cocia.Domain` before the first feature.
- Azure Blob Storage is added to the Terraform plan (ADR-0005).
- Raw payloads and stored files are real financial data: private storage, encryption at rest, never in logs, fixtures or commits.
- Re-processing is a first-class operation (rebuild canonical rows from raw rows; re-parse from stored files).
