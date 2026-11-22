# ADR 0006: Infrastructure as code with Terraform

- Status: proposed
- Date: 2026-11-22

## Context
All Azure resources (ADR-0005) should be reproducible, reviewable in PRs, and checked for drift. I also want skills that carry over if I deploy to AWS later.

## Options considered
1. Click-ops in the portal: pros: fastest first time. cons: not reproducible or reviewable; not how enterprises work.
2. Bicep: pros: Azure-native, simple, day-one support for new Azure features. cons: Azure-only.
3. Terraform (azurerm provider): pros: most common IaC tool in job ads; one tool for Azure, AWS, Cloudflare, GitHub; plan/apply workflow fits PR review. cons: state management to run; licence is BSL (OpenTofu is the open-source fork).
4. Pulumi (C#/TS): pros: real languages. cons: less common in job ads.

## Decision
Terraform.
- Code in `infra/`: reusable `modules/` (container app, postgres, key vault, …) and an `envs/prod` root. Add `envs/staging` later by reusing the modules.
- **Remote state** in an Azure Storage account (with blob locking). Bootstrap that storage once with a small separate `infra/bootstrap` config.
- **GitHub Actions**: `terraform fmt -check`, `validate` and `plan` on every PR (plan posted as a PR comment); `apply` on merge to `main`, behind a GitHub Environment approval.
- **Auth from CI to Azure via OIDC federated credentials** (workload identity). No long-lived client secrets in GitHub.
- Pin provider and Terraform versions; Dependabot keeps them updated.
- Secret *values* are never in Terraform code or state where avoidable: Terraform creates Key Vault and access policies; values are set separately or generated in Key Vault.

## Consequences
- Every infrastructure change goes through a PR and the AI reviewer, like application code.
- The state file contains sensitive data: lock down access to the storage account.
- Moving to AWS later means rewriting the resource blocks but keeping the workflow, CI and module structure.
