# Source health next-track decision

This document chooses the next track after the source health next-track handoff was merged.

This decision PR is documentation-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: cf3fd8ef545d9f49536cfc704281335e34d5e002
base source: PR #184 Add source health next-track handoff
stream: source health next-track decision
status: docs-only
```

## Decision

Choose:

```text
Track A: source health route contract tests
```

This means the next source health implementation should add targeted tests for existing route contracts before changing runtime behavior.

## Deferred tracks

The following tracks are explicitly deferred:

```text
Track B: recheck runtime behavior implementation design
Track C: poll runtime behavior implementation design
Track D: source health internal UI design
Track E: pause source health work and switch streams
```

## Reasoning

Source health currently has documented design, runbook, route contract, and poll/recheck behavior boundaries.

Before changing runtime behavior, the safest next step is to lock the current route behavior with targeted tests.

This reduces risk because future implementation can compare intended changes against a known route contract baseline.

## Target route test scope

Track A should cover existing routes only:

```text
GET /api/admin/source-health
GET /api/admin/source-health/:source_key
POST /api/admin/source-health/:source_key/recheck
POST /api/admin/sources/:source_key/poll
```

Track A must not add, remove, rename, or repurpose routes.

## Target test assertions

Future route contract tests should verify:

```text
list route returns bounded metadata only
detail route returns bounded metadata only
recheck route accepts only bounded metadata
poll route accepts only bounded metadata
request body cannot override route-derived operation
read-only permission cannot recheck or poll
public response-shape flags remain false
canonical mutation flags remain false
provider/scheduler/materializer flags remain false or explicitly documented
raw/private materials are absent
```

## Runtime behavior restriction

Track A should be test-first.

Runtime changes are allowed only if tests reveal that an existing route violates the documented contract, and the fix remains scoped.

Any behavior change must explicitly state:

```text
changed route
changed response field
changed request field
public response impact
canonical impact
provider/scheduler/materializer impact
redaction impact
rollback plan
```

## Recheck policy remains

Recheck remains bounded by default:

```text
stored-state evaluation
no live provider fetch by default
no scheduler enqueue by default
no materializer execution by default
no canonical mutation
no public response mutation
```

## Poll policy remains

Poll remains high-risk and gated.

Track A tests may document current behavior, but must not expand poll behavior.

Before poll behavior is changed or used operationally, require a separate Track C design.

## Public response-shape guardrails

Track A work must not change:

```text
GET /api/events/:event_id
GET /api/events/:event_id/news-overlay
GET /api/feed/digest/latest
GET /api/feed/digest/:digest_date/:edition
GET /api/feed/hero
GET /api/feed/region/:region_code
public API envelope
public feed envelope
feed ordering
feed item_count
official TDnet fields
official citations
```

## Canonical no-mutation guardrails

Track A work must not:

```text
mutate canonical_feed_items
create provider canonical feed items
create news-only canonical events
merge official TDnet events
override official TDnet facts
override official citations
mutate news_overlay_attachments
```

## Provider, scheduler, and materializer guardrails

Track A work must not introduce unexpected:

```text
live provider fetch
provider client calls
scheduler enqueueing
stored private provider material
source materialization
overlay materialization
canonical materialization
materializer behavior changes
```

## Recommended next PR

Recommended next PR:

```text
Source health route contract tests
scope: targeted tests and manual smoke docs
```

A separate PR may follow with a lock close-out after the tests are merged.

## Stop conditions

Stop and re-scope if Track A implementation:

```text
adds public source health fields
adds new routes without design approval
allows request-body operation override
changes poll/recheck side effects without documenting them
calls provider clients unexpectedly
triggers scheduler work unexpectedly
triggers materializers unexpectedly
mutates canonical data unexpectedly
shows secrets, headers, cookies, tokens, raw payloads, full article text, or SQL details
returns unbounded diagnostics or stack traces
```

## Validation

This decision PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_next_track_decision.md
```

No local test run is required unless a reviewer asks for targeted checks.
