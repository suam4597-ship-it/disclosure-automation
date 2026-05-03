# Stage 6.3 duplicate group review state read projection design

This document defines a docs-only design for exposing bounded duplicate group review state metadata on internal/operator-only duplicate group read projections after Stage 6.2 action routes were locked.

This PR is design-only. It does not add runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, UI code, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 94956950410c7631c56545f51d6b476095f16964
base source: PR #150 Lock Stage 6.2 duplicate group action routes
stage: Stage 6.3 PR A duplicate group review state read projection design
status: docs-only
locked Stage 5.9 read routes: GET /api/admin/duplicate-groups and GET /api/admin/duplicate-groups/:group_id
locked Stage 6.1 storage: source_duplicate_group_review_states and source_duplicate_group_action_events
locked Stage 6.2 action routes: POST /api/admin/duplicate-groups/:group_id/confirm, reject, mark-review, clear-review-state
```

## Purpose

Stage 6.2 allows an authorized operator to record duplicate group actions. The next safe step is to design how existing internal/operator-only read projections may display the persisted review state and a bounded action event summary.

The goal is to make operator review status visible without changing write behavior, public response shapes, provider behavior, materializer behavior, scheduler behavior, or canonical data.

## Non-goals

This design does not authorize or implement:

```text
action endpoint changes
write behavior changes
new action operations
new authorization rules
new migrations
new schema modules
router changes
controller changes
UI changes
public duplicate group fields
public API response-shape changes
public feed response-shape changes
scheduler work
provider clients
live provider fetch
materializer behavior changes
canonical feed mutation
provider canonical feed item creation
news-only canonical event creation
official TDnet event merge
official fact override
official citation override
```

## Existing source tables

Future implementation may read from these locked internal tables:

```text
source_duplicate_group_review_states
source_duplicate_group_action_events
```

The review state table remains the source of the current per-group review state. The action events table remains the append-only audit source for bounded action event summaries.

Future read projection code must treat both tables as read-only inputs. It must not write, upsert, backfill, compact, or repair these tables.

## Read route scope

The only read routes in scope for a future implementation design are internal/operator-only duplicate group read routes:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
```

These routes may expose bounded review metadata only to authorized operator/admin callers.

The following public routes and feeds remain out of scope:

```text
GET /api/events/:event_id
GET /api/events/:event_id/news-overlay
GET /api/feed/digest/latest
GET /api/feed/digest/:digest_date/:edition
public feed item overlays
public news overlays
public API envelopes
public feed envelopes
```

## Projection model

Future implementation should enrich each internal duplicate group read projection with a bounded review state summary derived from `source_duplicate_group_review_states`.

For the detail route, future implementation may also include a bounded action event summary derived from `source_duplicate_group_action_events`.

Recommended behavior:

```text
list route: include current review state summary only
detail route: include current review state summary and a bounded latest action event summary
missing review state row: return neutral empty review state metadata
missing action events: return an empty bounded action event summary
unauthorized caller: preserve existing authorization behavior and do not reveal review metadata
```

This design intentionally avoids changing route authorization, pagination, sorting, duplicate group materialization, or action state writer behavior.

## Allowed review state fields

Future operator-only read projections may expose only these current-state fields:

```text
review_state
last_action_operation
last_action_request_id_hash
last_action_idempotency_key_hash
reviewed_by_actor_id_hash
reviewed_at
review_reason_redacted
redaction_status
```

These fields are allowed only for internal/operator-only duplicate group read projections.

They must not be added to public event APIs, public feeds, canonical payloads, provider payloads, or raw materializer outputs.

## Allowed action event summary fields

Future operator-only detail projection may expose a bounded action event summary using only these fields:

```text
action_operation
required_permission
actor_id_hash
request_id_hash
idempotency_key_hash
result_status
pre_review_state
post_review_state
failure_code
redaction_status
inserted_at
```

The action event summary must be bounded. A future implementation should document a fixed limit before implementation, for example latest one event for the list route and latest five events for the detail route.

The summary must not expose raw request bodies, raw actor context, SQL details, provider payloads, full article text, canonical payloads, private transport material, or unbounded diagnostics.

## Neutral empty state

When a duplicate group has no row in `source_duplicate_group_review_states`, the projection should represent that state without creating a row.

Recommended neutral metadata:

```text
review_state: null
last_action_operation: null
last_action_request_id_hash: null
last_action_idempotency_key_hash: null
reviewed_by_actor_id_hash: null
reviewed_at: null
review_reason_redacted: null
redaction_status: null
action_event_summary: []
```

A future implementation may choose an equivalent bounded representation, but it must not perform writes to synthesize missing state.

## Join and query behavior

Future implementation should use read-only joins or separate read-only queries from duplicate group projections to review state metadata.

Required constraints:

```text
join by group_id only
preserve duplicate group list pagination semantics
preserve duplicate group list ordering semantics
preserve existing not-found behavior
preserve existing authorization behavior
preserve existing route envelopes unless separately documented
avoid unbounded action event loading
avoid N+1 query behavior where practical
no writes during reads
```

Action event ordering should use `inserted_at` descending with a deterministic secondary key if needed.

## Redaction model

Review state and action event fields must be already-redacted or hashed before projection.

Allowed identifiers are limited to hashed fields:

```text
actor_id_hash
request_id_hash
idempotency_key_hash
last_action_request_id_hash
last_action_idempotency_key_hash
reviewed_by_actor_id_hash
```

Allowed reason text is limited to:

```text
review_reason_redacted
```

Future projection code must not attempt to recover, join, log, render, or return raw identifiers or unredacted operator reasons.

## Forbidden fields and materials

Future read projection changes must not expose:

```text
raw actor identifiers
raw request identifiers
raw idempotency keys
unredacted operator reason
raw provider payloads
full article text
canonical payloads
private transport material
unbounded diagnostics
SQL details
provider secrets
request headers
cookies
raw transport metadata
```

## Action/write separation

Future read projection work must not change these locked action routes:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

Future read projection work must not change:

```text
Stage61DuplicateGroupActionStateWriter.record_action/3
Stage60DuplicateGroupOperatorActionAuthorizationGate
Stage60DuplicateGroupOperatorActionContract
Stage60DuplicateGroupOperatorActionAuditContract
SourceDuplicateGroupActionEvent changeset
SourceDuplicateGroupReviewState changeset
```

The Stage 6.1 writer remains the only path for action state persistence.

## Public response guardrails

Future operator-only read projection work must not change:

```text
GET /api/events/:event_id
GET /api/events/:event_id/news-overlay
GET /api/feed/digest/latest
GET /api/feed/digest/:digest_date/:edition
item.overlays[]
news_overlays[]
feed item_count
feed ordering
official TDnet fields
official citations
public API envelope
public feed envelope
```

Public duplicate group review/action state fields must remain absent unless a separate public response-shape design explicitly changes that policy.

## Canonical no-mutation guardrails

Future review state read projection work must not:

```text
mutate canonical_feed_items
create provider canonical feed items
create news-only canonical events
merge official TDnet events
override official TDnet facts
override official citations
mutate news_overlay_attachments
```

Operator review state remains internal advisory metadata.

## Provider and scheduler guardrails

Future review state read projection work must not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
store private provider material
materialize duplicate groups
materialize overlays
```

## Implementation sequence

Recommended next steps after this docs-only design is verified:

```text
1. Stage 6.3 PR A: docs-only review state read projection design
2. Stage 6.3 PR B: internal read projection update for bounded review state metadata
3. Stage 6.3 PR C: admin read route response update, if needed after PR B
4. Stage 6.3 lock close-out after behavior and tests are verified
5. Optional UI design only after backend read behavior is locked
```

This PR covers only step 1.

## Stop conditions

Do not merge a future implementation if it:

```text
changes public response shapes
adds public review/action fields
changes action endpoint behavior
changes action write behavior
bypasses Stage 6.1 writer
bypasses Stage 6.0 authorization gate
mutates canonical data
triggers provider/scheduler/live-fetch work
changes materializer behavior
adds UI without separate design
stores raw actor/request/idempotency identifiers
returns unredacted operator reasons
returns raw provider payloads or full article text
returns canonical payloads
returns unbounded diagnostics
```
