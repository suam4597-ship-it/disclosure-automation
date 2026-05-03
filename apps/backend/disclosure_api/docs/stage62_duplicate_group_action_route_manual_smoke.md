# Stage 6.2 duplicate group action route manual smoke

This smoke checklist covers the docs-only Stage 6.2 duplicate group action route design.

## Expected files

```text
apps/backend/disclosure_api/docs/stage62_duplicate_group_action_route_design.md
apps/backend/disclosure_api/docs/stage62_duplicate_group_action_route_guardrails.md
apps/backend/disclosure_api/docs/stage62_duplicate_group_action_route_manual_smoke.md
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
base commit: 2d45e6c86d21d9f290ce870518fab934bb4fb74d
base source: PR #147 Lock Stage 6.1 duplicate group action state
```

## Candidate route smoke

Confirm the design covers only future operator-only action routes:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

Confirm these routes are documented but not implemented.

## Read route separation smoke

Confirm existing read-only routes remain separate:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
```

Confirm the design says future action routes must not change read route behavior unless separately designed.

## Writer integration smoke

Confirm the design says future route handlers should call:

```text
Stage61DuplicateGroupActionStateWriter.record_action/3
```

Confirm the design says route handlers must not write directly to action state tables.

## Request body smoke

Confirm allowed request body fields are bounded and redacted:

```text
actor_id_hash
actor_permissions
idempotency_key_hash
request_id_hash
operator_reason_redacted
redaction_status
result_status
pre_review_state
post_review_state
failure_code
created_at
```

Confirm route-derived operation cannot be overridden by request body.

## Authorization smoke

Confirm future routes require:

```text
authenticated actor context
operator or admin role
action-specific permission
actor_id_hash
```

Confirm read-only permission cannot authorize action routes.

## Response smoke

Confirm future success and failure responses are bounded.

Confirm responses must not include raw actor identity, raw request identity, raw idempotency key, private provider material, raw provider payload, full article text, canonical payload, or unbounded diagnostics.

## Public response smoke

Confirm the design says future action routes must not change:

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

Confirm future action routes must not:

```text
mutate canonical_feed_items
create provider canonical feed items
create news-only canonical events
merge official TDnet events
override official TDnet facts
override official citations
mutate news_overlay_attachments
```

## Provider and scheduler smoke

Confirm future action routes must not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
store private provider material
materialize duplicate groups
materialize overlays
```

## Redaction smoke

Confirm changed files include no non-redacted provider secret values, raw header values, cookie values, raw operator identifiers, raw request identifiers, raw idempotency keys, raw provider bodies, full article text, canonical payloads, or unbounded diagnostics.

## Suggested static check

No mix test is required for this docs-only design PR unless a reviewer asks for targeted checks.

Suggested check:

```powershell
git diff --name-only 2d45e6c86d21d9f290ce870518fab934bb4fb74d...HEAD
```

Expected output should be limited to the three docs files listed above.
