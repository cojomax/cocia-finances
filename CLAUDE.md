# Cocia Finances

Personal finance app: insight into spending, investments and estate, plus planning tools.

## Status
POCs exist for CSV import, PDF parsing (PdfPig) and Finverse; main projects not initialised yet. Delivery plan: `docs/plan.md`. Product intent lives in `docs/spec.md`; decisions in `docs/adr/`.
Read both (and `docs/plan.md`) before planning any feature.

## Stack
- Frontend: React + Vite + TypeScript; TanStack Query for server state (ADR-0001)
- Web server: ASP.NET Core BFF (.NET 10): serves the SPA, owns the session, proxies to the API, SignalR (ADR-0002)
- Backend: ASP.NET Core API (.NET 10) + .NET Worker Service for syncs and scheduled jobs (ADR-0002)
- Database: PostgreSQL via EF Core (migrations from day one)
- Testing: xUnit v3, Testcontainers, Vitest, Playwright
- Containers: Docker (Compose locally)
- Hosting: Azure Container Apps, Azure Database for PostgreSQL, Key Vault, ACR, managed identities (ADR-0005)
- Infrastructure as code: Terraform in `infra/`, remote state in Azure Storage, applied from GitHub Actions via OIDC (ADR-0006)
- Source/CI: GitHub + GitHub Actions; AI review on PRs
- External services: Finverse (banks), IBKR gateway (investments, v2), FX rates: Open Exchange Rates + Frankfurter/ECB (ADR-0007)
Update this section (and add an ADR) as each choice is made.

## Layout
- Repo root: shared Claude config (`.claude/`), this file, `docs/`.
- Apps: `apps/web`, `apps/bff`, `apps/api`, `apps/worker`; shared .NET code in `libs/`; infrastructure in `infra/`.
- Each project gets its own `CLAUDE.md` for project-specific commands and conventions.

## Commands
TBC. Once projects exist, list install / dev / lint / typecheck / test commands here.

## Workflow
1. Non-trivial work starts in Plan Mode (or via the `planner` agent). Get approval before editing.
2. Write or update tests first (`test-writer` agent), then implement until they pass.
3. Before opening a PR: run `code-reviewer`, and `security-reviewer` for anything touching money, auth, imports or personal data.
4. Significant decisions get an ADR in `docs/adr/` (copy `0000-template.md`).

## Conventions (proposed: edit freely)
- Money: never use floating point. Amounts stay in their original currency; USD is the reporting currency (ADR-0003). Store integer minor units (cents) plus an ISO 4217 currency code, or use a decimal library.
- Dates: store UTC; convert to local time (Africa/Johannesburg default) only for display.
- Real financial data never goes into fixtures, tests, logs, screenshots or commits. Use synthetic data.
- Secrets live in env files that are git-ignored; never hard-code keys.
- Small, focused PRs; one feature or fix each.
