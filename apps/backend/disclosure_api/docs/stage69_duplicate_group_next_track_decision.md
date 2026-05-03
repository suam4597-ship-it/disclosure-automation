# Stage 6.9 duplicate group next-track decision

This document chooses the next track after Stage 6.9 handoff was merged.

Stage 6.9 PR B is documentation-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 8140e4afa20c9e09dc3a8bfd8f9649d9fbe56f37
base source: PR #176 Add Stage 6.9 duplicate group next-track handoff
stage: Stage 6.9 PR B next-track decision
status: docs-only
```

## Decision

Choose:

```text
Track E: pause duplicate group work and switch streams
```

This decision pauses duplicate group implementation work after the internal operator workflow, UI, polish, public boundary, and next-track handoff have been locked.

No runtime implementation track is selected in this PR.

## Deferred tracks

The following tracks are explicitly deferred:

```text
Track A: internal UI maintenance
Track B: public exposure proposal
Track C: frontend framework or asset pipeline design
Track D: non-UI backend follow-up design
```

## Reasoning

Duplicate group work has reached a stable pause point:

```text
internal authorization gate is locked
internal action writer is locked
internal action routes are locked
internal read metadata is locked
internal operator UI is locked
UI polish is locked
public boundary is locked
next-track handoff is locked
```

Continuing immediately into public exposure or frontend framework work would require a new design gate and is intentionally deferred.

## Last merged PR

```text
PR #176 Add Stage 6.9 duplicate group next-track handoff
merge commit: 8140e4afa20c9e09dc3a8bfd8f9649d9fbe56f37
```

## Current branch baseline

```text
branch: sec-thin-slice-reconcile-v1
baseline: 8140e4afa20c9e09dc3a8bfd8f9649d9fbe56f37
```

## Locked routes

Internal/admin UI routes remain:

```text
GET /admin/duplicate-groups
GET /admin/duplicate-groups/:group_id
```

Internal/operator-only JSON APIs remain:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

## Locked public boundary

The current public boundary remains:

```text
public duplicate group review/action state fields are absent
operator UI remains internal/admin only
operator review state remains advisory-only and non-canonical
public feed/API response shapes remain unchanged
canonical records remain unchanged
```

## Open risks

Known risks to revisit if duplicate group work resumes:

```text
operator UI remains a thin HTML surface without a full frontend framework
permission-aware state is advisory only and backend authorization remains authoritative
public exposure is not approved
public-safe summary semantics are not defined
no public duplicate group cache/backward-compatibility model exists
frontend framework or asset pipeline has not been designed
```

These risks are acceptable while duplicate group work is paused because the public boundary remains locked and internal behavior remains guarded.

## Recommended resume point

If duplicate group work resumes, start with exactly one of these PRs:

```text
Track A resume: Stage 6.10 internal UI maintenance proposal
Track B resume: Stage 6.10 public exposure proposal
Track C resume: Stage 6.10 frontend framework or asset pipeline design
Track D resume: Stage 6.10 non-UI backend follow-up design
```

Do not resume with runtime implementation unless a corresponding design gate has already been merged.

## Next project stream

The next project stream is intentionally left for the caller to choose outside this duplicate group handoff.

This decision record only states:

```text
duplicate group stream is paused after Stage 6.9 PR B
next stream must start from its own scoped plan/design document
```

## Universal guardrails while paused

Do not merge duplicate group changes that:

```text
change public response shapes without explicit design approval
add public duplicate group fields without Track B approval
add new action operations without design approval
submit action_operation in UI request bodies
expose operator review state publicly
expose operator action state publicly
expose actor/request/idempotency metadata publicly
expose unredacted operator reasons
expose provider payloads or full article text
expose canonical payloads
mutate canonical data unexpectedly
trigger provider/scheduler/live-fetch/materializer work unexpectedly
add frontend framework or asset pipeline without Track C approval
```

## Validation

This decision PR is docs-only and should change only:

```text
apps/backend/disclosure_api/docs/stage69_duplicate_group_next_track_decision.md
```

No local test run is required unless a reviewer asks for targeted checks.
