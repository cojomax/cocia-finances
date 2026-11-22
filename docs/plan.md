# Cocia Finances: Delivery Plan

> Living document. Update as phases complete. Product intent is in `spec.md`; decisions are in `adr/`.

## Why this project exists
Two goals, in this order:
1. A personal finance app I actually use.
2. Practice building it the way an enterprise team would: React, .NET, PostgreSQL, Docker, CI/CD, cloud hosting, AI-assisted review. Some choices are deliberately heavier than a solo app needs. That's intended, but each one gets an ADR explaining it.

## Guiding principle: walking skeleton first
Get one request flowing through every layer (React → BFF → API → Postgres), containerised, built by CI and deployed to the cloud, before building features. Deployment, networking and auth problems surface early.

## Architecture (target)
| Service | Tech | Role |
|---|---|---|
| `apps/web` | React + Vite + TypeScript | UI. TanStack Query for server state; Zustand/context for client state. |
| `apps/bff` | ASP.NET Core (.NET 10) | Backend-for-Frontend: serves the React build, owns the cookie session, proxies to the API (YARP), hosts SignalR hub. See ADR-0002. |
| `apps/api` | ASP.NET Core (.NET 10) | Domain API. EF Core + PostgreSQL. Publishes an OpenAPI spec. |
| `apps/worker` | .NET Worker Service | Finverse syncs + token refresh, FX rate polling, scheduled jobs. |
| `libs/*` | .NET class libraries | Import parsers (CSV, PDF), domain logic, planning maths, `Cocia.TestData`. |
| Postgres | PostgreSQL | Primary store. Azure Database for PostgreSQL Flexible Server in the cloud; container locally. |
| (later) IBKR gateway | Java process | Its own container. |

Hosting: **Azure** (ADR-0005), Container Apps + managed PostgreSQL + Key Vault + ACR, using managed identities; provisioned with **Terraform** (ADR-0006). Only the BFF is public.

Contracts: the TypeScript client is generated from the API's OpenAPI spec (Kiota or NSwag), so types can't drift between C# and TS.

## v1 definition of done
- Finverse bank sync running in the worker, with token refresh and a "reconnect bank" state in the UI.
- CSV and PDF imports (ported from the POCs) feeding the same raw → canonical pipeline (ADR-0004).
- Transactions list: filter, search, edit category.
- Categorisation: user-editable rules (ML comes later).
- Spending trends chart.
- Multi-currency net worth reported in USD (ADR-0003), with live FX via SignalR.
- Single-user OIDC login with MFA.
- Deployed to the cloud from GitHub Actions; backups tested by an actual restore.

Everything else is v2+.

## Phases

### Phase 0: Foundations
- [x] Update `CLAUDE.md` for the new stack and draft ADRs 0001–0004 (status: proposed; review and accept).
- [ ] `git init`, push to GitHub, protect `main` (PRs only, checks required).
- [ ] Turn on Dependabot, CodeQL, secret scanning.
- [ ] Monorepo layout: `apps/web`, `apps/bff`, `apps/api`, `apps/worker`, `libs/`, `infra/`, `docs/`. A `CLAUDE.md` per app.
- [ ] Extend `.claude/hooks/check.sh` to handle `.csproj` (`dotnet build`, `dotnet format --verify-no-changes`).
- [x] Hosting (ADR-0005: Azure), IaC (ADR-0006: Terraform), FX sources (ADR-0007) drafted.
- [x] Secrets: `dotnet user-secrets` locally, Azure Key Vault in production (via managed identity).
- [ ] ADRs still to write: auth provider, worker→BFF messaging, API structure, data model.

### Phase 1: Walking skeleton
- [ ] React page → BFF → API → Postgres "hello" round trip.
- [ ] EF Core with migrations from day one.
- [ ] Multi-stage Dockerfile per service; `docker-compose.yml` for local development.
- [ ] Azure: free account, subscription, budget + cost alert.
- [ ] Terraform bootstrap: remote state storage account (`infra/bootstrap`).
- [ ] GitHub → Azure OIDC federated credentials (no client secrets).
- [ ] Terraform `envs/prod`: resource group, Log Analytics, Container Apps environment, ACR, Key Vault, PostgreSQL Flexible Server, managed identities.
- [ ] GitHub Actions (app): lint, test, build images, push to ACR, deploy new revision to Container Apps.
- [ ] GitHub Actions (infra): fmt/validate/plan on PR (plan as PR comment), apply on merge with environment approval.
- [ ] AI review on every PR: Claude Code GitHub Action using the `code-reviewer` / `security-reviewer` agent prompts.
- [ ] Generated TS client from OpenAPI wired into CI.

### Phase 2: Auth and security
- [ ] OIDC + MFA (Keycloak self-hosted, or Entra ID/Auth0). Tokens stay in the BFF; browser gets an HTTP-only cookie.
- [ ] Secrets: user-secrets locally, Key Vault in production via managed identity. Finverse secrets and refresh tokens encrypted at rest (keys in Key Vault).
- [ ] Postgres off the public internet (private endpoint or firewall rules).
- [ ] Audit log for imports, syncs and edits.

### Phase 3: Spending (v1 core)
- [ ] Raw import tables + canonical transactions + source links (ADR-0004).
- [ ] Port CSV import POC into `libs/` behind a parser interface, with tests.
- [ ] Port PdfPig POC the same way.
- [ ] Finverse sync in the worker (port POC; refresh tokens; scheduled + manual sync).
- [ ] Cross-source matching + review queue UI.
- [ ] Transactions list (filter, search, edit).
- [ ] Rules-based categorisation, editable by the user.
- [ ] Trends charts.

### Phase 4: Currency
- [ ] `fx_rates` table; daily closing rates for history.
- [ ] Worker polls Open Exchange Rates hourly; Frankfurter (ECB) for daily closes and backfill (ADR-0007).
- [ ] SignalR push to the UI; net worth updates live.

### Phase 5: Investments (v2)
- [ ] IBKR gateway container; handle session expiry ("reconnect needed").
- [ ] Daily holdings snapshots (history can't be fetched later).
- [ ] Performance and fees.

### Phase 6: Estate and Planning (v2)
- [ ] Assets, liabilities, net worth history.
- [ ] Planning maths in a pure C# library with heavy unit tests: goals, projections, retirement scenarios.
- [ ] ML.NET categorisation trained on my corrections.

### Phase 7: Hardening
- [ ] Optional: `envs/staging` from the same Terraform modules.
- [ ] Optional learning exercise: deploy the same containers to AWS ECS Fargate with Terraform.
- [ ] OpenTelemetry (logs, traces, metrics) to Application Insights. Try .NET Aspire after Docker Compose is understood.
- [ ] Automated encrypted Postgres backups; restore drill.
- [ ] Playwright end-to-end tests for the main flows.

## Testing
- .NET: **xUnit v3**, **Shouldly** or **AwesomeAssertions** (FluentAssertions v8+ is commercially licensed), **Testcontainers** for real Postgres in integration tests.
- React: **Vitest** + Testing Library. **Playwright** for end-to-end.
- Test data: Finverse sandbox for the happy path. `libs/Cocia.TestData` generates synthetic edge cases: same-day identical transactions, cross-source overlaps with shifted dates, refunds/reversals, FX transactions, large volumes. Used by tests and a local `seed` command. Never real data (see `CLAUDE.md`).
