# Source health next-track handoff

This document defines the handoff after the source health operator workflow close-out was merged.

This handoff PR is documentation-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: b394543a54ad34d91e0ef823df944c9a0c42a344
base source: PR #183 Lock source health operator workflow
stream: source health next-track handoff
status: docs-only
```

## Completed source health scope

The source health documentation stream is locked through:

```text
source health operator workflow design
source health operator runbook
source health route contract lock design
source health poll/recheck behavior design
source health operator workflow close-out
```

## Current locked route surface

Existing source health/operator route surface remains:

```text
GET /api/admin/source-health
GET /api/admin/source-health/:source_key
POST /api/admin/source-health/:source_key/recheck
POST /api/admin/sources/:source_key/poll
```

No route was added, removed, renamed, or repurposed by the documentation stream.

## Current locked policy

Current policy remains:

```text
source health work is internal/operator-only
read responses must be bounded
recheck is bounded stored-state evaluation by default
poll is high-risk and must remain gated until a concrete implementation contract is locked
request body must not override route-derived operation
public API/feed response shapes remain unchanged
canonical records remain unchanged
provider/scheduler/materializer side effects are not approved
```

## Allowed next tracks

Exactly one next track should be chosen before implementation.

Allowed tracks:

```text
Track A: source health route contract tests
Track B: recheck runtime behavior implementation design
Track C: poll runtime behavior implementation design
Track D: source health internal UI design
Track E: pause source health work and switch streams
```

This handoff does not implement any track.

## Track A: source health route contract tests

Use this track to add targeted tests for existing route contracts without changing runtime behavior.

Required proposal fields:

```text
affected route tests
expected response fields
forbidden response fields
request operation override checks
public response-shape checks
canonical no-mutation checks
provider/scheduler/materializer side-effect checks
redaction checks
```

Track A should not change route/controller behavior unless a failing test exposes a pre-existing mismatch and a separate fix PR is opened.

## Track B: recheck runtime behavior implementation design

Use this track before changing or relying on recheck runtime behavior.

Required proposal fields:

```text
source_key validation
operator permission model
request allowlist
response allowlist
idempotency model
stored-state read model
whether any writes are allowed
public response impact
canonical impact
provider/scheduler/materializer impact
test plan
rollback plan
```

Default policy remains no live provider fetch, no scheduler enqueue, no materializer execution, and no canonical mutation.

## Track C: poll runtime behavior implementation design

Use this track before changing or relying on poll runtime behavior.

Required proposal fields:

```text
source_key allowlist
operator permission model
idempotency model
rate limit model
external network behavior
provider client interaction
scheduler interaction
materializer interaction
canonical impact
public response impact
stored private provider material impact
test plan
rollback plan
```

Poll remains high-risk and should not be implemented or used as routine remediation without this design.

## Track D: source health internal UI design

Use this track before adding any internal/admin UI for source health.

Required proposal fields:

```text
candidate UI routes
existing JSON API dependencies
list/detail behavior
action/recheck/poll controls
authorization model
redaction model
error/loading/empty states
public response impact
canonical impact
provider/scheduler/materializer impact
test plan
rollback plan
```

Track D must not add public UI or public fields.

## Track E: pause source health work and switch streams

Use this track when source health work is intentionally paused.

Required handoff note fields:

```text
last merged PR
current branch baseline
locked routes
locked policy
open risks
recommended resume point
next project stream name
```

## Universal stop conditions

Stop and re-scope any next-track PR if it:

```text
changes public response shapes without explicit design approval
adds public source health fields
adds new routes without design approval
allows request-body operation override
calls provider clients unexpectedly
triggers scheduler work unexpectedly
triggers materializers unexpectedly
mutates canonical data unexpectedly
shows secrets, headers, cookies, tokens, raw payloads, full article text, or SQL details
returns unbounded diagnostics or stack traces
omits rate limiting for poll implementation
omits idempotency for operator-triggered poll/recheck writes
adds internal UI without a UI design gate
```

## Recommended next PR

If source health work continues immediately, the recommended next PR is:

```text
Source health next-track decision
scope: docs-only decision record
```

That PR should choose exactly one of Track A through Track E and state why the other tracks are deferred.

## Validation

This handoff PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/source_health_next_track_handoff.md
```

No local test run is required unless a reviewer asks for targeted checks.
