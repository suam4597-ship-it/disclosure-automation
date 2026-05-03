# Stage 6.3 duplicate group review state read projection implementation manual smoke

This smoke checklist covers the Stage 6.3 internal duplicate group review state read projection implementation.

## Expected files

```text
apps/backend/disclosure_api/lib/disclosure_automation/runtime/stage59_duplicate_group_internal_read_projection.ex
apps/backend/disclosure_api/test/stage59_duplicate_group_internal_read_projection_test.exs
apps/backend/disclosure_api/docs/stage63_duplicate_group_review_state_read_projection_implementation_manual_smoke.md
```

## Baseline smoke

Confirm the implementation is based on:

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 3cfeef64f58940ccd1d18d73c04f56825cd5233a
base source: PR #151 Design Stage 6.3 duplicate group review state read projection
```

## Scope smoke

Confirm the PR changes only the internal duplicate group read projection, its targeted projection test, and this manual-smoke document.

It must not add or modify:

```text
migrations
schema modules
router
controllers
UI code
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
```

## Review state projection smoke

Confirm internal duplicate group projections now include a bounded current-state summary from:

```text
source_duplicate_group_review_states
```

Allowed review state summary fields:

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

Confirm missing review state rows are represented with bounded null values and no write is performed.

## Action event summary smoke

Confirm the internal show projection includes a bounded action event summary from:

```text
source_duplicate_group_action_events
```

Allowed action event summary fields:

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

Confirm the action event summary is limited to the latest five events and does not include `operator_reason_redacted`.

Confirm list projection includes current review state summary but does not include action event history.

## Read-only smoke

Confirm read projection calls are read-only over action state tables.

They must not write, upsert, backfill, compact, repair, or delete rows in:

```text
source_duplicate_group_review_states
source_duplicate_group_action_events
```

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

Run the targeted projection test:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_internal_read_projection_test.exs
```

Optional adjacent checks:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage61_duplicate_group_action_state_writer_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage61_duplicate_group_action_state_schema_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage62_duplicate_group_action_route_test.exs
```

Suggested changed-file check:

```powershell
git diff --name-only 3cfeef64f58940ccd1d18d73c04f56825cd5233a...HEAD
```

Expected output should be limited to the three files listed above.
