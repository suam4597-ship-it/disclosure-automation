# Stage 6.5 duplicate group operator runbook manual smoke

This smoke checklist covers the docs-only Stage 6.5 duplicate group operator runbook.

## Expected files

```text
apps/backend/disclosure_api/docs/stage65_duplicate_group_operator_runbook.md
apps/backend/disclosure_api/docs/stage65_duplicate_group_operator_runbook_guardrails.md
apps/backend/disclosure_api/docs/stage65_duplicate_group_operator_runbook_manual_smoke.md
```

## Scope smoke

Confirm this PR is documentation-only.

It must not add or modify:

```text
frontend code
backend runtime code
tests
fixtures
migrations
schema modules
router
controllers
templates
UI routes
action endpoints
scheduler code
provider clients
live fetch code
feed/controller behavior
public API response behavior
public feed response behavior
materializer behavior
canonical mutation behavior
```

## Baseline smoke

Confirm the runbook names the correct baseline:

```text
base branch: sec-thin-slice-reconcile-v1
base commit: d7b5c7b4b5c2b2cdd3effa6fc23a40a10e19af9f
base source: PR #158 Close out duplicate group operator workflow
```

## Route usage smoke

Confirm the runbook references only locked internal/operator-only read routes:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
```

Confirm the runbook references only locked internal/operator-only action routes:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

Confirm the runbook does not instruct operators to use public APIs for duplicate group action state.

## Operator procedure smoke

Confirm the runbook documents:

```text
operator pre-checks
list review procedure
detail review procedure
action selection guide
action request requirements
post-action verification
failure handling
escalation triggers
forbidden operator behavior
```

## Review state smoke

Confirm the runbook references only bounded `review_state_summary` fields:

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

Confirm missing review state must not trigger manual DB writes or backfills.

## Action event summary smoke

Confirm the runbook references only bounded `action_event_summary` fields:

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

Confirm the runbook preserves show-only and latest-five action event summary behavior.

Confirm the runbook does not instruct operators to request unbounded action event history from read routes.

## Action mapping smoke

Confirm the runbook preserves locked route-to-operation mapping:

```text
confirm -> confirm_duplicate_group
reject -> reject_duplicate_group
mark-review -> mark_duplicate_group_needs_review
clear-review-state -> clear_duplicate_group_review_state
```

Confirm the runbook says request body must not override route-derived action operation.

## Request metadata smoke

Confirm allowed action request fields are bounded to:

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

Confirm forbidden raw/private/canonical/provider materials are documented.

## Idempotency smoke

Confirm the runbook preserves locked idempotency identity:

```text
group_id + action_operation + actor_id_hash + idempotency_key_hash
```

Confirm retry guidance says same intended action should reuse the same idempotency key hash.

## Authorization smoke

Confirm the runbook preserves backend authorization as authoritative.

Confirm read-only permission does not authorize actions:

```text
duplicate_group:read
```

Confirm action-specific permissions are documented:

```text
duplicate_group:confirm
duplicate_group:reject
duplicate_group:mark_review
duplicate_group:clear_review_state
```

## Escalation smoke

Confirm escalation metadata is bounded to:

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

Confirm escalations must not include raw/private/canonical/provider materials.

## Public response smoke

Confirm the runbook says duplicate group operator actions must not change:

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

Confirm public duplicate group review/action state fields remain absent.

## Canonical no-mutation smoke

Confirm the runbook says duplicate group operator actions must not:

```text
mutate canonical_feed_items
create provider canonical feed items
create news-only canonical events
merge official TDnet events
override official TDnet facts
override official citations
mutate news_overlay_attachments
```

## Provider, scheduler, and materializer smoke

Confirm duplicate group read/action/UI workflows must not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
store private provider material
materialize duplicate groups from read/action/UI routes
materialize overlays
change materializer behavior
```

## Redaction smoke

Confirm changed files include no raw actor identifiers, raw request identifiers, raw idempotency keys, unredacted operator reasons, raw provider payloads, full article text, canonical payloads, private transport material, SQL details, provider secrets, request headers, cookies, or unbounded diagnostics.

## Suggested static check

No mix test is required for this docs-only runbook PR unless a reviewer asks for targeted checks.

Suggested check:

```powershell
git diff --name-only d7b5c7b4b5c2b2cdd3effa6fc23a40a10e19af9f...HEAD
```

Expected output should be limited to the three docs files listed above.
