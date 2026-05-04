# Source health route contract tests close-out

This document closes out the source health route contract test PR after the targeted route inventory test was merged.

This close-out PR is documentation-only. It does not add or modify frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: aa8ddfb9a5a23fa9ece73f766b986547f18a4883
base source: PR #186 Add source health route contract tests
stream: source health route contract tests close-out
status: docs-only
```

## Evidence

```text
PR #185 Choose source health next track
selected: Track A source health route contract tests

PR #186 Add source health route contract tests
scope: targeted route inventory test and manual smoke doc
validated: 4 tests, 0 failures
```

## Fixed issue during validation

Initial route contract test compared route verbs as strings:

```text
"GET"
"POST"
```

Phoenix route inventory uses atoms:

```text
:get
:post
```

The test was corrected to compare atom verbs.

## Locked test file

```text
apps/backend/disclosure_api/test/source_health_route_contract_test.exs
```

## Locked manual smoke file

```text
apps/backend/disclosure_api/docs/source_health_route_contract_tests_manual_smoke.md
```

## Locked route inventory

The test locks these internal/admin API routes:

```text
GET /api/admin/source-health
GET /api/admin/source-health/:source_key
POST /api/admin/source-health/:source_key/recheck
POST /api/admin/sources/:source_key/poll
```

Expected controller/action mapping:

```text
GET /api/admin/source-health -> AdminSourceHealthController.index
GET /api/admin/source-health/:source_key -> AdminSourceHealthController.show
POST /api/admin/source-health/:source_key/recheck -> AdminSourceHealthController.recheck
POST /api/admin/sources/:source_key/poll -> AdminSourcePollController.create
```

## Locked route-derived operation names

The test records route-derived operation expectations:

```text
/api/admin/source-health/:source_key/recheck -> recheck_source_health
/api/admin/sources/:source_key/poll -> poll_source
```

Request body operation override remains forbidden by design.

Forbidden override concepts:

```text
operation
action_operation
route_operation
```

## Locked public route guardrail

The test confirms no public source health routes are present:

```text
/api/public/source-health
/api/public/sources/:source_key/poll
/api/events/:event_id/source-health
/api/feed/source-health
```

The test also confirms expected public route inventory remains present:

```text
/api/events/:event_id
/api/events/:event_id/news-overlay
/api/feed/digest/latest
/api/feed/digest/:digest_date/:edition
/api/feed/hero
/api/feed/region/:region_code
```

## What this test does not cover yet

The test is route-inventory focused.

It does not yet prove:

```text
response body boundedness
request allowlist enforcement
authorization behavior
read-only rejection
idempotency behavior
provider client absence
scheduler absence
materializer absence
canonical no-mutation at runtime
public response-shape flags at runtime
```

Those require a future implementation or route behavior test proposal.

## Future implementation gates

Before adding behavior-level tests or runtime changes, a proposal should state:

```text
affected routes
request fields
response fields
authorization model
idempotency model
rate limit model
provider/scheduler/materializer impact
canonical impact
public response impact
redaction impact
test plan
rollback plan
```

## Stop conditions

Stop and re-scope future source health route work if it:

```text
adds new routes without design approval
changes existing route mappings unexpectedly
changes public response shapes
adds public source health fields
allows request-body operation override
calls provider clients unexpectedly
triggers scheduler work unexpectedly
triggers materializers unexpectedly
mutates canonical data unexpectedly
shows secrets, headers, cookies, tokens, raw payloads, full article text, or SQL details
returns unbounded diagnostics or stack traces
```

## Validation

This close-out PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_route_contract_tests_closeout.md
```

No local test run is required unless a reviewer asks for targeted checks.
