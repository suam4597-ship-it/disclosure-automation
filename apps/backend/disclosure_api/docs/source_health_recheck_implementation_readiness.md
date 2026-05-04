# Source health recheck implementation readiness audit

This document records a docs-only readiness check before implementing source health recheck runtime behavior.

This PR does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 82a34e6e644761f87514466a76450f6924cf2380
base source: PR #189 Lock source health recheck runtime design
stream: source health recheck implementation readiness
status: docs-only readiness audit
```

## Current route observation

The router declares these source health/operator routes:

```text
GET /api/admin/source-health
GET /api/admin/source-health/:source_key
POST /api/admin/source-health/:source_key/recheck
POST /api/admin/sources/:source_key/poll
```

The route inventory test locks these declarations, but route inventory alone does not prove response behavior.

## Required pre-implementation checks

Before runtime implementation, confirm:

```text
controller modules are present
controller actions are present
routes dispatch successfully
bounded JSON response shapes are known
source_key validation location is known
authorization policy is known
idempotency policy is known
source health read model is known
public response-shape guardrails are testable
canonical no-mutation guardrails are testable
provider/scheduler/materializer absence is testable
```

## Readiness decision

Do not start full recheck behavior implementation until route targets and response contracts are confirmed.

If route targets are incomplete, the first implementation PR should be a minimal route-target realization PR.

## Minimal route-target realization scope

A minimal route-target realization PR may add only:

```text
source health controller actions
source poll controller action
route-target tests
bounded placeholder JSON responses
manual smoke doc
```

That PR must not add:

```text
provider client calls
live fetch
scheduler enqueue
materializer execution
canonical mutation
public response mutation
storage writes
new routes
new schemas
new migrations
```

## Later recheck behavior scope

After route targets are confirmed, a later recheck behavior PR may implement bounded stored-state evaluation.

It must follow the locked design:

```text
route-derived operation = recheck_source_health
request body operation override forbidden
bounded request allowlist
bounded response allowlist
backend authorization authoritative
read-only permission rejected
no provider calls by default
no scheduler enqueue by default
no materializer execution by default
no canonical mutation
no public response mutation
```

## Test gates before runtime changes

A future implementation PR should include tests for:

```text
route dispatch
bounded list response
bounded detail response
bounded recheck response
request body operation override rejection
read-only permission rejection
public response-shape flags
canonical mutation flags
provider/scheduler/materializer flags
raw/private material absence
```

## Stop conditions

Stop and re-scope if implementation would require:

```text
new routes
public response changes
canonical mutation
provider client calls
live fetch
scheduler enqueue
materializer execution
schema or migration changes without design
secret/header/cookie rendering
raw provider payload rendering
full article text rendering
SQL detail or stack trace rendering
unbounded diagnostics
```

## Validation

This readiness PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_recheck_implementation_readiness.md
```

No local test run is required unless a reviewer asks for targeted checks.
