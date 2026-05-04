# Source health route target realization checklist

This document defines the route-target realization checklist after the source health recheck implementation readiness audit was merged.

This PR is documentation-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: deca16e96e9af21741280919c327ba72f936179b
base source: PR #190 Add source health recheck implementation readiness audit
stream: source health route-target realization checklist
status: docs-only checklist
```

## Purpose

The router declares source health route targets, but before runtime behavior work continues, the implementation stream should confirm that the route target modules and actions are present and return bounded JSON responses.

This checklist separates route-target realization from full recheck runtime behavior.

## Locked existing routes

```text
GET /api/admin/source-health
GET /api/admin/source-health/:source_key
POST /api/admin/source-health/:source_key/recheck
POST /api/admin/sources/:source_key/poll
```

## Route target checklist

Confirm these route targets before behavior work:

```text
AdminSourceHealthController.index/2
AdminSourceHealthController.show/2
AdminSourceHealthController.recheck/2
AdminSourcePollController.create/2
```

## Minimal realization PR scope

If any target is missing or not safely callable, the next runtime PR should be minimal and add only:

```text
missing controller module or action
bounded placeholder JSON response
route dispatch tests
manual smoke doc
```

## Minimal response shape

A placeholder route-target response may include only bounded fields:

```text
mode
route_added
ui_added
source_key
operation
accepted
result_status
redaction_status
public_response_shape_mutation
canonical_feed_mutation
trigger_live_fetch
scheduler_enabled
materializer_triggered
network_access
```

## Forbidden in minimal realization

A minimal route-target realization PR must not add:

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
unbounded diagnostics
secrets, headers, cookies, or tokens
raw provider payloads
full article text
SQL details or stack traces
```

## Required tests for minimal realization

If route targets are implemented or adjusted, add tests that verify:

```text
routes dispatch successfully
responses are JSON
responses include bounded flags
public_response_shape_mutation is false
canonical_feed_mutation is false
trigger_live_fetch is false
scheduler_enabled is false
materializer_triggered is false
network_access is forbidden or explicitly bounded
raw/private fields are absent
```

## Later behavior PR scope

Only after route targets are confirmed should a later behavior PR implement stored-state recheck logic.

That later PR must follow:

```text
source health recheck runtime design
source health recheck runtime close-out
source health route contract tests close-out
```

## Stop conditions

Stop and re-scope if route-target realization work would require:

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

This checklist PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_route_target_realization_checklist.md
```

No local test run is required unless a reviewer asks for targeted checks.
