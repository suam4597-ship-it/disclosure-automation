# Stage 6.5 duplicate group operator runbook

This document defines a docs-only operator runbook for the locked duplicate group operator workflow after Stage 6 overall close-out.

This PR is documentation-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: d7b5c7b4b5c2b2cdd3effa6fc23a40a10e19af9f
base source: PR #158 Close out duplicate group operator workflow
stage: Stage 6.5 duplicate group operator runbook
status: docs-only
```

## Purpose

This runbook explains how an operator should safely use the locked duplicate group read/action workflow.

It covers:

```text
what to inspect before acting
how to interpret review state metadata
how to choose an action
what metadata must be redacted/hashed
how to retry safely with idempotency
how to verify results after an action
what not to do
when to escalate
```

## Workflow summary

The locked operator workflow consists of:

```text
1. Read duplicate group list
2. Open duplicate group detail
3. Inspect members, match reasons, confidence, and review state
4. Choose an operator action if authorized
5. Submit an action using the locked route
6. Refresh detail view
7. Confirm review_state_summary and action_event_summary updated as expected
```

Read routes:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
```

Action routes:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

## Operator pre-checks

Before taking any action, an operator should confirm:

```text
the group_id is the intended duplicate group
the group has at least two members
member source_key values look expected
member_kind values look expected
match_reasons explain why the members are grouped
confidence is understood
has_official_tdnet_event and has_provider_overlay are understood
redaction_status is acceptable for review
review_state_summary is understood
```

Operators must not use public feed/API responses to infer or mutate duplicate group review state.

## List review procedure

Use:

```text
GET /api/admin/duplicate-groups
```

Allowed filters:

```text
confidence
source_key
member_kind
redaction_status
limit
```

The list response is for triage only.

The list response may show `review_state_summary`, but it must not include action event history.

Operators should open the detail route before taking an action.

## Detail review procedure

Use:

```text
GET /api/admin/duplicate-groups/:group_id
```

Inspect:

```text
group_id
confidence
source_keys
match_reasons
member_count
has_official_tdnet_event
has_provider_overlay
redaction_status
members
review_state_summary
action_event_summary
```

The detail response may include `action_event_summary`, locked to the latest five events.

The detail response remains internal/operator-only and advisory-only.

## Interpreting review_state_summary

Allowed fields:

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

Interpretation guide:

```text
review_state null: no current review state row exists
review_state confirmed_by_operator: an operator confirmed the group
review_state rejected_by_operator: an operator rejected the group
review_state needs_review: an operator marked the group for more review
review_state cleared: an operator cleared the review state
```

A missing review state must not trigger manual DB backfill.

## Interpreting action_event_summary

Allowed fields:

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

The action event summary is a bounded latest-five view.

It is not a full audit export.

Operators must not request unbounded action event history through the read routes.

## Action selection guide

Use this mapping:

```text
confirm_duplicate_group:
  use when the operator agrees the members should be treated as duplicate/correlated review candidates
  route: POST /api/admin/duplicate-groups/:group_id/confirm
  permission: duplicate_group:confirm

reject_duplicate_group:
  use when the operator determines the group should not be considered a duplicate/correlated review candidate
  route: POST /api/admin/duplicate-groups/:group_id/reject
  permission: duplicate_group:reject

mark_duplicate_group_needs_review:
  use when the group needs additional human or procedural review before confirm/reject
  route: POST /api/admin/duplicate-groups/:group_id/mark-review
  permission: duplicate_group:mark_review

clear_duplicate_group_review_state:
  use when the current review state should be reset without creating canonical/provider/public effects
  route: POST /api/admin/duplicate-groups/:group_id/clear-review-state
  permission: duplicate_group:clear_review_state
```

The request body must not include an action operation intended to override the route mapping.

## Action request requirements

Allowed request fields:

```text
actor_id_hash
actor_permissions
roles
request_id_hash
idempotency_key_hash
operator_reason_redacted
result_status
redaction_status
pre_review_state
post_review_state
failure_code
created_at
```

Required operator discipline:

```text
use hashed actor identifiers only
use hashed request identifiers only
use hashed idempotency keys only
submit only operator_reason_redacted
never submit raw operator notes
never submit raw provider payloads
never submit full article text
never submit canonical payloads
```

## Idempotency and retry procedure

The locked idempotency identity is:

```text
group_id + action_operation + actor_id_hash + idempotency_key_hash
```

If the same operator retries the same intended action after a timeout or transient failure, the retry should reuse the same `idempotency_key_hash`.

If the operator is intentionally taking a new action, use a new `idempotency_key_hash`.

Expected behavior:

```text
same identity: no duplicate action event row
new identity: may create a new action event row and update current review state
```

## Post-action verification

After an action succeeds, refresh:

```text
GET /api/admin/duplicate-groups/:group_id
```

Verify:

```text
review_state_summary.review_state matches the intended post-review state
review_state_summary.last_action_operation matches the route-derived operation
review_state_summary.last_action_request_id_hash matches the request hash
action_event_summary contains a bounded matching latest event
action_event_summary does not contain operator_reason_redacted
no public feed/API response was changed by the action
no canonical/provider/scheduler/materializer side effect occurred
```

## Failure handling

Allowed failure categories:

```text
authentication required
action permission missing
duplicate group not found
invalid request
idempotency conflict
state transition rejected
temporary unavailable
```

Operators should not paste raw failure diagnostics into public tickets or comments.

Escalate with bounded metadata only:

```text
group_id
action_operation
request_id_hash
idempotency_key_hash
actor_id_hash
result_status
redaction_status
failure category
inserted_at or reviewed_at if present
```

## Escalation triggers

Escalate if:

```text
action route returns repeated unexpected failures
review_state_summary does not update after a successful action
action_event_summary shows unexpected result_status
an unauthorized actor appears to have performed an action
raw identifiers or unredacted text appear in a response
public API/feed output appears to change because of duplicate group review state
provider/scheduler/live-fetch/materializer behavior appears to be triggered by read or action routes
canonical data appears to be mutated by duplicate group review actions
```

## Forbidden operator behavior

Operators must not:

```text
use public feed/API routes to inspect duplicate group action state
manually write source_duplicate_group_review_states
manually write source_duplicate_group_action_events
change canonical_feed_items because of duplicate group review
create provider canonical feed items because of duplicate group review
create news-only canonical events because of duplicate group review
merge official TDnet events because of duplicate group review
override official facts or citations because of duplicate group review
trigger live provider fetch from duplicate group review
trigger scheduler work from duplicate group review
materialize duplicate groups from read/action/UI routes
paste raw actor/request/idempotency identifiers into comments or tickets
paste raw provider payloads/full article text/canonical payloads into comments or tickets
```

## Public response guardrails

Duplicate group operator actions must not change:

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

Public duplicate group review/action state fields must remain absent.

## Canonical no-mutation guardrails

Duplicate group operator actions must not:

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

Duplicate group read/action/UI workflows must not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
store private provider material
materialize duplicate groups from read/action/UI routes
materialize overlays
change materializer behavior
```

## Redaction checklist

Before sharing runbook output, logs, comments, or tickets, confirm there is no:

```text
raw actor identifier
raw request identifier
raw idempotency key
unredacted operator reason
raw provider payload
full article text
canonical payload
private transport material
SQL detail
provider secret
request header
cookie
unbounded diagnostic blob
```

Allowed placeholders:

```text
REDACTED_OPERATOR_ID
REDACTED_REQUEST_ID
REDACTED_IDEMPOTENCY_KEY
REDACTED_OPERATOR_REASON
REDACTED_PROVIDER_PAYLOAD
```

## Runbook status

This runbook is documentation-only.

It does not change runtime behavior, authorization, storage, routes, UI, public responses, canonical data, provider behavior, scheduler behavior, or materializer behavior.
