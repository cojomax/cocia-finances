# ADR 0001: React for the frontend

- Status: proposed
- Date: 2026-11-21

## Context
`CLAUDE.md` originally listed Angular, which I already know well. A main goal of this project is to learn and demonstrate new skills to an enterprise standard.

## Options considered
1. Angular: pros: I'm already productive in it; batteries included. cons: little new learning.
2. React + Vite + TypeScript: pros: the most widely used frontend library; the learning goal; large ecosystem. cons: more choices to make (routing, data fetching, state, forms).

## Decision
React with Vite and TypeScript. TanStack Query for server state; a small library (Zustand) or React context for client-only state. TypeScript API client generated from the API's OpenAPI spec.

## Consequences
- Slower start while learning React idioms.
- Each ecosystem choice (router, forms, component library) needs a short decision; record the significant ones here or in new ADRs.
- The `check.sh` hook already runs `lint` and `typecheck` for `package.json` projects.
