# Phase 0 Compatibility Shims

To keep the lightweight reference runtime under `apps/backend` coherent, the branch adds small compatibility shims for modules that would otherwise require a full Phoenix/Oban dependency graph.

## Added shim modules

- `Oban`
- `Oban.Job`
- `Oban.Worker`
- `Oban.Migrations`
- `Plug.Conn`
- `Phoenix.Controller`

## Why they exist

The Phase 0 branch intentionally commits:
- worker boundaries
- controller/router boundaries
- migration boundaries
- accepted-job responses

but does not yet commit the full generated Phoenix API-only app. Without compatibility shims, the bare reference runtime can be misleadingly incomplete.

## Scope

These shims are deliberately tiny. They exist to preserve module boundaries and keep the checked-in reference code easier to reason about.

They do **not** attempt to be drop-in replacements for real dependencies.

## Replacement path

Once `apps/backend/disclosure_api` is generated and wired with real dependencies, these shims should be treated as reference-runtime scaffolding rather than long-term application code.
