# ADR 0002: Backend-for-Frontend + separate API + worker

- Status: proposed
- Date: 2026-11-21

## Context
The app handles bank and investment data and holds third-party secrets (Finverse, later IBKR). I want an architecture an enterprise would recognise, and to learn how services talk to each other.

## Options considered
1. Single ASP.NET Core app serving React and the API: pros: simplest. cons: less to learn; auth tokens usually end up in the browser.
2. BFF + API + worker: pros: tokens never reach the browser (BFF holds the session, browser gets an HTTP-only cookie); clear split between UI concerns and the domain; long-running syncs leave the request path. cons: more services, more deployment and networking work.

## Decision
Option 2:
- **BFF** (ASP.NET Core): serves the React build, handles OIDC login and the cookie session, proxies API calls (YARP), hosts the SignalR hub.
- **API** (ASP.NET Core): domain logic, EF Core + PostgreSQL, publishes OpenAPI.
- **Worker** (.NET Worker Service): Finverse syncs and token refresh, FX polling, scheduled jobs.

## Consequences
- More containers to build, deploy and observe; the learning goal accepts this.
- Need service-to-service auth between BFF and API (network isolation at minimum; tokens later).
- Worker → BFF notifications (e.g. FX updates) need a channel: start with Postgres LISTEN/NOTIFY or Redis pub/sub; record the choice when made.
