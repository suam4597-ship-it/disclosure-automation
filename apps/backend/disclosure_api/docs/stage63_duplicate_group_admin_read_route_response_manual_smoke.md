# Stage 6.3 duplicate group admin read route response manual smoke

This smoke checklist covers the Stage 6.3 admin read route response update for bounded duplicate group review state metadata.

## Expected files

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers/admin_duplicate_group_controller.ex
apps/backend/disclosure_api/test/stage59_duplicate_group_operator_read_route_test.exs
apps/backend/disclosure_api/docs/stage63_duplicate_group_admin_read_route_response_manual_smoke.md
```

## Baseline smoke

Confirm the implementation is based on:

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 4fcb9c5a0e559fc4143658e2b597bd4b52de5d1c
base source: PR #152 Add Stage 6.3 duplicate group review state read projection
```

## Scope smoke

Confirm this PR changes only admin duplicate group read response serialization, its targeted route test, and this manual-smoke document.

It must not add or modify:

```text
migrations
schema modules
internal read projection behavior
router
action endpoints
action route behavior
action writer behavior
scheduler code
provider clients
live fetch code
feed/controller behavior
public API response behavior
public feed response behavior
materializer behavior
canonical mutation behavior
UI code
```

## Admin read route smoke

Confirm these existing internal/operator-only read routes continue to work:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
```

Confirm no new routes are added.

## Review state response smoke

Confirm admin duplicate group read responses include a bounded `review_state_summary` object.

Allowed `review_state_summary` fields:

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

Confirm missing review state rows are serialized as bounded null values.

## Action event response smoke

Confirm only the show route response includes `action_event_summary`.

Allowed `action_event_summary` fields:

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

Confirm list route items do not include action event history.

Confirm action event summaries do not include:

```text
operator_reason_redacted
raw actor identifiers
raw request identifiers
raw idempotency keys
raw provider payloads
full article text
canonical payloads
private transport material
unbounded diagnostics
```

## Serialization smoke

Confirm `reviewed_at` and `inserted_at` timestamps are serialized as bounded ISO8601 strings or null.

Confirm the controller only serializes data already present in the internal read projection and does not directly query or write action state tables.

## Action/write separation smoke

Confirm the implementation does not change or bypass:

```text
Stage61DuplicateGroupActionStateWriter.record_action/3
Stage60DuplicateGroupOperatorActionAuthorizationGate
Stage60DuplicateGroupOperatorActionContract
Stage60DuplicateGroupOperatorActionAuditContract
SourceDuplicateGroupActionEvent changeset
SourceDuplicateGroupReviewState changeset
```

Confirm these action routes are unchanged:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

## Public response smoke

Confirm no public API/feed response behavior files are changed.

Public duplicate group review/action state fields must remain absent from:

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

## Canonical no-mutation smoke

Confirm the implementation does not:

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

Confirm the implementation does not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
store private provider material
materialize duplicate groups
materialize overlays
change materializer behavior
```

## UI smoke

Confirm UI remains out of scope.

The PR must not add UI code, UI routes, frontend components, screenshots, mock data fixtures, or operator console behavior.

## Redaction smoke

Confirm changed files include no raw actor identifiers, raw request identifiers, raw idempotency keys, unredacted operator reasons, raw provider payloads, full article text, canonical payloads, private transport material, SQL details, provider secrets, request headers, cookies, or unbounded diagnostics.

## Suggested checks

Run the targeted route test:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_operator_read_route_test.exs
```

Optional adjacent checks:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_internal_read_projection_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage62_duplicate_group_action_route_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage61_duplicate_group_action_state_writer_test.exs
```

Suggested changed-file check:

```powershell
git diff --name-only 4fcb9c5a0e559fc4143658e2b597bd4b52de5d1c...HEAD
```

Expected output should be limited to the three files listed above.
