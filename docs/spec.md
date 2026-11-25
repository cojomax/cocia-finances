# Cocia Finances: Product Spec

> Living document. Keep it current; Claude reads it before planning features.

## Goal
Give me insight into my spending, investments and estate, and help me plan.

## Users
- Primary: me (single user).
- I am the manager of a household account.
- Household: other household members' accounts appear in the app. Everything can be queried and filtered by person and
by account; every account shows its owner.

## Core areas
### Spending
- Access bank account data through Finverse APIs.
- Provide PDF upload (.NET)
- Provide CSV import (.NET)
- Should learn & predict categorisation; also allow user to edit.
- Trends
- Filter and search transactions

### Investments
- Connect to IBKR via IG Gateway
- TBC: accounts/platforms, holdings, performance, fees

### Estate
- Assets and liabilities
- Net worth

### Planning
- Goals
- Projections
- Retirement and scenario modelling

## Non-goals (for now)
- TBC

## Constraints
- Privacy first: data stays under my control. Hosted in my own Azure subscription (ADR-0005); sensitive fields encrypted
with keys I hold in Key Vault.
- Currency: USD primary, but multi-currency. Single items show their original currency; anything combined (totals,
net worth, charts) shows USD. Numbers use US formatting for every currency.

## Open questions
- TBC

## User stories
Use the form: *As a [user], I want [capability] so that [outcome].* Add acceptance criteria under each.
