# ADR 0009: Backend code structure: minimal APIs, vertical slices, pure domain libraries

- Status: accepted
- Date: 2026-11-24

## Context
The .NET backend has an API, a worker (ADR-0002) and a BFF. The hardest logic (money and FX, cross-source matching, categorisation rules, planning maths) must be correct, heavily tested, and shared between the API and the worker. I want structure an enterprise team would recognise, without ceremony that slows a solo project.

## Options considered
Endpoint style:
1. Controllers: pros: most common in existing enterprise code. cons: more ceremony; Microsoft's newer guidance and templates favour minimal APIs.
2. Minimal APIs: pros: current default; route groups, typed results, built-in OpenAPI and validation; fits per-feature files. cons: needs a convention so endpoints don't become long lambdas.

Code organisation:
1. Simple layered (one project; Controllers/Services/Data): pros: quickest. cons: no boundary around business logic; `Services/` grows into a pile.
2. Clean Architecture (Domain / Application / Infrastructure / Api projects): pros: strict dependency rule; very common in enterprise .NET. cons: each feature spread over four projects; many single-implementation interfaces.
3. Vertical slices: pros: one folder per feature; each slice only as complex as it needs. cons: shared logic can get duplicated; weaker domain boundary.
4. Hybrid: vertical slices in the apps + pure domain libraries: pros: Clean Architecture's main benefit (framework-free, testable core) without the ceremony; worker reuses the same libraries. cons: boundaries rely partly on convention.

Mediator (MediatR-style request/handler dispatch):
1. MediatR: pros: well-known; pipeline behaviours. cons: commercial licence since 2025; indirection hurts navigation.
2. Free alternative (Mediator, Wolverine): pros: same pattern, no licence cost. cons: smaller ecosystems.
3. None, with mediator-ready handlers: pros: simplest; direct navigation; minimal API filters and middleware cover cross-cutting concerns. cons: no enforced pipeline.

## Decision
- **Minimal APIs**, grouped per feature with `MapGroup`, returning `TypedResults`.
- **Option 4 (hybrid)**:
  ```
  libs/
    Cocia.Domain/     Money, Currency, FX conversion, matching + categorisation rules, planning maths. No EF Core, ASP.NET or I/O.
    Cocia.Imports/    IStatementParser + CSV and PdfPig parsers (from the POCs)
    Cocia.Finverse/   typed Finverse client
    Cocia.Data/       EF Core DbContext, entity configuration, migrations (shared by API and worker)
    Cocia.TestData/   synthetic data generator (tests + local seed)
  apps/
    api/      Features/<Area>/<UseCase>.cs  (vertical slices)
    worker/   jobs (FX poll, Finverse sync) calling the libs
    bff/
  ```
- **No mediator for now**, but every slice follows a **mediator-ready convention** so adding one later is mechanical:
  - one file per use case: a static class containing a `Command` or `Query` record, a `Handler` class with a single `Handle(request, CancellationToken)` method, and a `Map(RouteGroupBuilder)` method;
  - endpoints are thin: map HTTP input to the request, call the handler, map the result to HTTP. **No business logic in endpoint lambdas.**
  - handlers never call other handlers; shared logic goes in `Cocia.Domain` (or a shared service).
  - names show intent: `…Command` changes state, `…Query` reads (CQRS by convention).
- Cross-cutting concerns: validation with .NET's built-in minimal API validation (move to FluentValidation only if rules outgrow it), logging/tracing via middleware and OpenTelemetry.
- **Architecture tests** (NetArchTest or similar) enforce that `Cocia.Domain` references no EF Core, ASP.NET Core or HTTP packages.

## Consequences
- Domain logic is unit-tested without a database or web host; slices get integration tests (Testcontainers + `WebApplicationFactory`).
- Adding a mediator later: requests implement `IRequest<T>`, handlers implement `IRequestHandler<,>`, endpoints inject `ISender`. Logic is untouched.
- Simple read slices may query `AppDbContext` directly; complex logic must live in the domain library, not the slice.
- Libraries are class-library projects referenced by project reference (not NuGet packages).
