# ADR 0005: Host on Azure (Container Apps + managed PostgreSQL)

- Status: proposed
- Date: 2026-11-22

## Context
The app runs as several containers (BFF, API, worker, later the IBKR gateway) plus PostgreSQL. I want to learn cloud hosting the way an enterprise .NET team does it, at low cost. Candidates: Azure, AWS, or a cheap VPS.

## Options considered
1. Azure: pros: the usual choice for enterprise .NET shops; I already have Azure experience, so I can go deeper (IaC, managed identity, private networking, cost control); generous free grants. cons: AWS has the largest overall market share.
2. AWS (ECS Fargate + RDS): pros: market leader; in demand for general backend/platform roles. cons: new console and IAM model to learn alongside everything else; less natural fit for .NET roles.
3. VPS + Docker Compose (Hetzner/DigitalOcean): pros: cheapest; full control; best fit for "privacy first". cons: no managed-cloud skills (IAM, managed DB, secret stores), which is what enterprise roles ask for.

## Decision
Azure, region South Africa North (confirm every service is available there; fall back to a nearby region if not):
- **Azure Container Apps** (Consumption plan) for `bff`, `api`, `worker` (and later the IBKR gateway), in one Container Apps environment. Only the BFF has public ingress; API and worker are internal.
- **Azure Database for PostgreSQL – Flexible Server** (Burstable B1ms to start; free for 12 months on a free account).
- **Azure Key Vault** for secrets (Finverse credentials, FX API key, encryption keys).
- **Azure Blob Storage** (private container) for original imported CSV/PDF files (ADR-0010).
- **Managed identities** for service-to-Azure access (Key Vault, registry, database where possible). No connection strings or keys in config.
- **Azure Container Registry** (Basic) for images, pulled by managed identity. CI pushes images there.
- **Log Analytics / Application Insights** for logs and OpenTelemetry data.
- Everything provisioned with Terraform (ADR-0006).

AWS stays an optional later exercise: deploy the same containers to ECS Fargate.

## Consequences
- The worker (always polling) and SignalR connections keep replicas active, so scale-to-zero won't apply to them; expect a small monthly cost. Set an Azure budget + alert on day one.
- The Postgres free grant ends after 12 months; review the size and cost then.
- Containers stay portable: the same images run under Docker Compose locally or on a VPS.
- Data lives in a cloud provider's data centre: encrypt sensitive columns (Finverse tokens) with keys in Key Vault, and keep the database off the public internet (private endpoint or firewall rules).
