# Stage 6.9 duplicate group next-track handoff

This document defines the handoff after Stage 6.8 public-boundary close-out.

Stage 6.9 PR A is documentation-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 645cdcb215873d170d6cad5d0e3197593af46c92
base source: PR #175 Lock Stage 6.8 duplicate group public boundary
stage: Stage 6.9 PR A next-track handoff
status: docs-only
```

## Purpose

Stages 6.0 through 6.8 established and locked the internal duplicate group operator workflow, UI, polish, public boundary, and public-boundary close-out.

Stage 6.9 does not choose a runtime implementation. It records the allowed next tracks and the required gates for each track.

## Completed scope summary

Locked prior work includes:

```text
Stage 6.0 authorization gate
Stage 6.1 action state writer
Stage 6.2 action routes
Stage 6.3 read metadata
Stage 6.4 UI shell route design
Stage 6.5 operator runbook lock
Stage 6.6 internal operator UI implementation and lock
Stage 6.7 UI polish and lock
Stage 6.8 public boundary design and lock
```

## Current locked policy

Current locked policy remains:

```text
operator UI remains internal/admin only
operator review state remains advisory-only and non-canonical
public duplicate group review/action state fields remain absent
public feed/API response shapes remain unchanged
canonical records remain unchanged
provider/scheduler/live-fetch/materializer behavior remains unchanged
```

## Allowed next tracks

Exactly one next track should be chosen before implementation.

Allowed tracks:

```text
Track A: internal UI maintenance
Track B: public exposure proposal
Track C: frontend framework or asset pipeline design
Track D: non-UI backend follow-up design
Track E: pause duplicate group work and switch to another project stream
```

This handoff does not implement any track.

## Track A: internal UI maintenance

Use this track for small internal/admin UI changes that do not alter routes or APIs.

Required PR proposal fields:

```text
affected UI route
changed controller/template/assets
action route impact
JSON API impact
public response-shape impact
canonical impact
provider/scheduler/materializer impact
redaction impact
test impact
rollback plan
```

Allowed examples:

```text
copy refinements
small layout changes
additional bounded help text
bounded client-side validation hints
manual smoke doc updates
test hardening
```

Forbidden without a separate design:

```text
new UI route
new JSON API route
new action operation
public response change
canonical mutation
provider/scheduler/materializer work
unbounded diagnostics
raw/private metadata display
```

## Track B: public exposure proposal

Use this track only for a new public exposure design proposal.

A Track B PR must remain design-only unless a separate implementation plan has already been approved.

Required proposal fields:

```text
exact public route or response field names
exact response envelope impact
redaction model
abuse/misinterpretation risk
operator metadata exclusion proof
canonical no-mutation proof
public feed ordering impact
public feed item_count impact
official TDnet field impact
official citation impact
cache/backward compatibility impact
test plan
rollback plan
```

Track B must not implement public exposure in the same PR that proposes it.

## Track C: frontend framework or asset pipeline design

Use this track before adding a framework, build pipeline, static asset bundle, or external dependency.

Required proposal fields:

```text
selected framework or no-framework rationale
asset build pipeline impact
Phoenix endpoint/static path impact
CSP/security impact
test strategy
bundle ownership
operator-only access model
rollback plan
fallback no-JavaScript behavior
```

Track C must not change public routes or public responses.

## Track D: non-UI backend follow-up design

Use this track for backend work related to duplicate group reliability, observability, or data quality.

Required proposal fields:

```text
affected runtime module
schema or migration impact
read projection impact
writer impact
action route impact
scheduler/provider/materializer impact
public response-shape impact
canonical impact
redaction impact
test plan
rollback plan
```

Track D must not change public response shapes without a separate public design gate.

## Track E: pause and switch streams

Use this track when duplicate group work is intentionally paused.

Required handoff note fields:

```text
last merged PR
current branch baseline
locked routes
locked public boundary
open risks
recommended resume point
next project stream name
```

## Universal stop conditions

Stop and re-scope any next-track PR if it:

```text
changes public response shapes without explicit design approval
adds public duplicate group fields without Track B approval
adds new action operations without design approval
submits action_operation in UI request bodies
exposes operator review state publicly
exposes operator action state publicly
exposes actor/request/idempotency metadata publicly
exposes unredacted operator reasons
exposes provider payloads or full article text
exposes canonical payloads
mutates canonical data unexpectedly
triggers provider/scheduler/live-fetch/materializer work unexpectedly
adds frontend framework or asset pipeline without Track C approval
```

## Recommended next PR

If work continues immediately, the recommended next PR is:

```text
Stage 6.9 PR B: choose next duplicate group track
scope: docs-only decision record
```

That PR should choose exactly one of Track A through Track E and state why the other tracks are deferred.

## Validation

This handoff PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/stage69_duplicate_group_next_track_handoff.md
```

No local test run is required unless a reviewer asks for targeted checks.
