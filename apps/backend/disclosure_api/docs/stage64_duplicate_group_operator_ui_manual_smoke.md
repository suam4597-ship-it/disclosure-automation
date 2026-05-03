# Stage 6.4 duplicate group operator UI experience manual smoke

This smoke checklist covers the docs-only Stage 6.4 duplicate group operator UI/experience design.

## Expected files

```text
apps/backend/disclosure_api/docs/stage64_duplicate_group_operator_ui_design.md
apps/backend/disclosure_api/docs/stage64_duplicate_group_operator_ui_guardrails.md
apps/backend/disclosure_api/docs/stage64_duplicate_group_operator_ui_manual_smoke.md
```

## Scope smoke

Confirm this PR is docs-only.

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

Confirm the design names the correct baseline:

```text
base branch: sec-thin-slice-reconcile-v1
base commit: a798eed49c1e27c8fa7666d763695774a93d7fbc
base source: PR #154 Lock Stage 6.3 duplicate group review state read projection
```

## Existing API dependency smoke

Confirm the design depends only on existing internal/operator-only read routes:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
```

Confirm the design depends only on existing internal/operator-only action routes:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

Confirm no new route is implemented.

## List view smoke

Confirm the list view design uses only existing bounded filters:

```text
confidence
source_key
member_kind
redaction_status
limit
```

Confirm the list view design may show current review state metadata but must not show action event history.

## Detail view smoke

Confirm the detail view design may show:

```text
group summary
member summary table
current review state panel
latest action event summary panel
action control panel
redaction/guardrail notice
```

Confirm the detail view design relies on the locked show route response for `action_event_summary`.

## Review state field smoke

Confirm the design allows only these `review_state_summary` fields:

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

Confirm missing review state is displayed as a neutral state without creating or backfilling review state rows.

## Action event summary smoke

Confirm the design allows only these `action_event_summary` fields:

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

Confirm action event history remains bounded and show-only.

Confirm the design does not allow displaying `operator_reason_redacted` in action event history.

## Action control smoke

Confirm the action controls map exactly to locked action routes:

```text
Confirm duplicate group -> POST /api/admin/duplicate-groups/:group_id/confirm
Reject duplicate group -> POST /api/admin/duplicate-groups/:group_id/reject
Mark needs review -> POST /api/admin/duplicate-groups/:group_id/mark-review
Clear review state -> POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

Confirm request body cannot override route-derived action operation.

Confirm read-only permission does not enable action controls.

## Action request smoke

Confirm allowed future UI action request fields are bounded to:

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

Confirm the design does not allow raw actor identifiers, raw request identifiers, raw idempotency keys, or unredacted operator reasons.

## Idempotency smoke

Confirm the design preserves locked idempotency identity:

```text
group_id + action_operation + actor_id_hash + idempotency_key_hash
```

Confirm server-side idempotency remains authoritative.

## Authorization smoke

Confirm the design requires internal/operator-only access and preserves backend authorization as authoritative.

Confirm future UI work must not bypass:

```text
Stage60DuplicateGroupOperatorActionAuthorizationGate
Stage61DuplicateGroupActionStateWriter
```

## Public response smoke

Confirm the design says future UI work must not change:

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

Confirm future UI work must not:

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

Confirm future UI work must not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
store private provider material
materialize duplicate groups
materialize overlays
change materializer behavior
```

## Redaction smoke

Confirm changed files include no raw actor identifiers, raw request identifiers, raw idempotency keys, unredacted operator reasons, raw provider payloads, full article text, canonical payloads, private transport material, SQL details, provider secrets, request headers, cookies, or unbounded diagnostics.

## Suggested static check

No mix test is required for this docs-only design PR unless a reviewer asks for targeted checks.

Suggested check:

```powershell
git diff --name-only a798eed49c1e27c8fa7666d763695774a93d7fbc...HEAD
```

Expected output should be limited to the three docs files listed above.
