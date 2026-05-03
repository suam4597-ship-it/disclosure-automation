# Stage 6.3 duplicate group review state read projection manual smoke

This smoke checklist covers the docs-only Stage 6.3 duplicate group review state read projection design.

## Expected files

```text
apps/backend/disclosure_api/docs/stage63_duplicate_group_review_state_read_projection_design.md
apps/backend/disclosure_api/docs/stage63_duplicate_group_review_state_read_projection_guardrails.md
apps/backend/disclosure_api/docs/stage63_duplicate_group_review_state_read_projection_manual_smoke.md
```

## Scope smoke

Confirm this PR is docs-only.

It must not add or modify:

```text
runtime code
tests
fixtures
migrations
schema modules
router
controllers
UI code
action endpoints
scheduler code
provider clients
live fetch code
feed/controller behavior
API response behavior
feed response behavior
materializer behavior
canonical mutation behavior
```

## Baseline smoke

Confirm the design names the correct baseline:

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 94956950410c7631c56545f51d6b476095f16964
base source: PR #150 Lock Stage 6.2 duplicate group action routes
```

## Read route scope smoke

Confirm the design covers only future internal/operator-only duplicate group read projections:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
```

Confirm the design does not implement any read route behavior.

## Source table smoke

Confirm the design documents read-only usage of:

```text
source_duplicate_group_review_states
source_duplicate_group_action_events
```

Confirm the design says future read projection code must not write, upsert, backfill, compact, repair, or delete rows in those tables.

## Review state field smoke

Confirm allowed review state fields are bounded to:

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

Confirm these fields are internal/operator-only.

## Action event summary field smoke

Confirm allowed action event summary fields are bounded to:

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

Confirm the design requires an explicit fixed limit before implementation.

## Neutral empty state smoke

Confirm missing review state rows are represented without writes.

Confirm a future implementation may return bounded null or empty values for missing review state/action event metadata.

## Action/write separation smoke

Confirm the design says future read projection work must not change action routes:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

Confirm the design says future read projection work must not change or bypass:

```text
Stage61DuplicateGroupActionStateWriter.record_action/3
Stage60DuplicateGroupOperatorActionAuthorizationGate
Stage60DuplicateGroupOperatorActionContract
Stage60DuplicateGroupOperatorActionAuditContract
SourceDuplicateGroupActionEvent changeset
SourceDuplicateGroupReviewState changeset
```

## Public response smoke

Confirm the design says future read projection work must not change:

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

Confirm future read projection work must not:

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

Confirm future read projection work must not:

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

Confirm the design does not add UI code, UI routes, frontend components, screenshots, mock data fixtures, or operator console behavior.

## Redaction smoke

Confirm changed files include no non-redacted provider secret values, raw header values, cookie values, raw operator identifiers, raw request identifiers, raw idempotency keys, raw provider bodies, full article text, canonical payloads, private transport material, or unbounded diagnostics.

## Suggested static check

No mix test is required for this docs-only design PR unless a reviewer asks for targeted checks.

Suggested check:

```powershell
git diff --name-only 94956950410c7631c56545f51d6b476095f16964...HEAD
```

Expected output should be limited to the three docs files listed above.
