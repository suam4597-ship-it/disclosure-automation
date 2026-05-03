# Stage 6.3 duplicate group review state read projection guardrails

This checklist defines guardrails for future internal/operator-only duplicate group review state read projection work.

This PR is docs-only. It does not add runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, UI code, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline guardrails

Future work must preserve this baseline:

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 94956950410c7631c56545f51d6b476095f16964
base source: PR #150 Lock Stage 6.2 duplicate group action routes
```

## Scope guardrails

Only future internal/operator-only duplicate group read projections are in scope:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
```

Future implementation must not change public API/feed behavior, action endpoint behavior, action write behavior, canonical mutation behavior, provider behavior, scheduler behavior, materializer behavior, or UI behavior.

## Source table guardrails

Future read projection work may read only bounded review/action metadata from:

```text
source_duplicate_group_review_states
source_duplicate_group_action_events
```

Future read projection work must not write directly to either table.

Future read projection work must not create, upsert, backfill, compact, repair, or delete review/action rows.

## Allowed review state field guardrails

Future operator-only read projections may expose only these review state fields:

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

These fields must remain internal/operator-only.

They must not be added to public event APIs, public feeds, canonical payloads, provider payloads, materializer outputs, logs, or unbounded diagnostics.

## Allowed action event summary field guardrails

Future operator-only detail projections may expose only these bounded action event summary fields:

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

Action event summaries must be bounded by an explicit fixed limit before implementation.

Future implementation must not load, return, log, or render an unbounded action event history.

## Forbidden field guardrails

Future read projection work must not expose:

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

Allowed placeholders must remain clearly redacted, for example:

```text
REDACTED_OPERATOR_ID
REDACTED_REQUEST_ID
REDACTED_IDEMPOTENCY_KEY
REDACTED_PROVIDER_KEY
REDACTED_PROVIDER_TOKEN
```

## Neutral empty state guardrails

A missing review state row must not cause a write during a read request.

A future implementation should represent missing review state with bounded null or empty values, for example:

```text
review_state: null
last_action_operation: null
reviewed_at: null
review_reason_redacted: null
action_event_summary: []
```

The exact response shape must be locked in the implementation PR before merge.

## Read behavior guardrails

Future read projection work must preserve:

```text
existing route authorization behavior
existing not-found behavior
existing duplicate group list pagination semantics
existing duplicate group list ordering semantics
existing duplicate group detail semantics
existing internal route envelopes unless separately documented
```

Future read projection work should avoid unbounded event loading and should avoid N+1 query behavior where practical.

## Action/write separation guardrails

Future read projection work must not change these locked action routes:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

Future read projection work must not change or bypass:

```text
Stage61DuplicateGroupActionStateWriter.record_action/3
Stage60DuplicateGroupOperatorActionAuthorizationGate
Stage60DuplicateGroupOperatorActionContract
Stage60DuplicateGroupOperatorActionAuditContract
SourceDuplicateGroupActionEvent changeset
SourceDuplicateGroupReviewState changeset
```

## Public response-shape guardrails

Future read projection work must not change:

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

Future read projection work must not:

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

Future read projection work must not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
store private provider material
materialize duplicate groups
materialize overlays
change materializer behavior
```

## UI guardrails

UI remains out of scope for this stage.

Do not add UI code, UI routes, frontend components, screenshots, mock data fixtures, or operator console behavior without a separate UI design PR after backend read behavior is locked.

## Validation guardrails for future implementation

Future implementation PRs should verify:

```text
changed files are limited to read projection/read route/tests/manual smoke unless justified
only internal/operator-only read projection behavior changes
source_duplicate_group_review_states is read-only
source_duplicate_group_action_events is read-only
review state fields are bounded
latest action event summary is bounded
missing state performs no write
read route authorization is preserved
list pagination and ordering are preserved
public response shapes are unchanged
action endpoint/write behavior is unchanged
no canonical mutation
no provider/scheduler/live-fetch behavior
materializer behavior is unchanged
UI remains out of scope
changed-file strict redaction check passes
```
