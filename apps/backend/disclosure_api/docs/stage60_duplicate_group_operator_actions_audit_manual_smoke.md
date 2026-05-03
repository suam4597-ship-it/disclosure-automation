# Stage 6.0 duplicate group operator actions audit manual smoke

This manual smoke checklist covers the docs-only design for future Stage 6.0 duplicate group operator actions and audit behavior.

## Expected files

```text
apps/backend/disclosure_api/docs/stage60_duplicate_group_operator_actions_audit_design.md
apps/backend/disclosure_api/docs/stage60_duplicate_group_operator_action_permission_checklist.md
apps/backend/disclosure_api/docs/stage60_duplicate_group_operator_actions_audit_manual_smoke.md
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
base commit: 3cc59f3e091d9eef6da666840ce5e0a8038a89c9
base source: PR #136 Lock Stage 5.9 duplicate group workflow
```

## Action design smoke

Confirm the design covers only future operator actions:

```text
confirm_duplicate_group
reject_duplicate_group
mark_duplicate_group_needs_review
clear_duplicate_group_review_state
```

Confirm the design does not implement action endpoints or runtime action code.

## Permission smoke

Confirm action permissions are separate from read permission.

Read permission:

```text
duplicate_group:read
```

Action permissions:

```text
duplicate_group:confirm
duplicate_group:reject
duplicate_group:mark_review
duplicate_group:clear_review_state
```

Confirm read permission alone must not authorize action operations.

## Actor and request redaction smoke

Confirm future action requests require hashed/redacted actor and request context:

```text
actor_id_hash
request_id_hash
idempotency_key_hash
```

Confirm the design rejects:

```text
raw actor identifiers
raw request identifiers
raw idempotency keys
unredacted operator reasons
unknown actor context fields
```

## Audit smoke

Confirm allowed future audit fields are bounded and redacted:

```text
action_operation
group_id
actor_id_hash
request_id_hash
idempotency_key_hash
required_permission
result_status
pre_review_state
post_review_state
redacted_operator_reason
failure_code
redaction_status
created_at
```

Confirm forbidden audit fields are documented:

```text
raw actor identifiers
raw request identifiers
raw idempotency keys
raw provider bodies
full article text
provider secret values
provider transport metadata
canonical feed payloads
provider canonical creation payloads
unbounded diagnostics
```

## Route smoke

Confirm future route candidates are documented but not implemented:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

Confirm existing Stage 5.9 read routes remain separate:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
```

## Public response smoke

Confirm the design says future action work must not change:

```text
GET /api/events/:event_id
GET /api/events/:event_id/news-overlay
GET /api/feed/digest/latest
GET /api/feed/digest/:digest_date/:edition
item.overlays[]
news_overlays[]
feed item_count
feed ordering
public API envelope
public feed envelope
```

## Canonical no-mutation smoke

Confirm future duplicate group actions must not:

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

Confirm future duplicate group actions must not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
read provider credentials
store provider credentials
store provider transport metadata
materialize duplicate groups
materialize overlays
```

## Redaction smoke

Confirm changed files include no non-redacted provider secret values, raw header values, cookie values, raw operator identifiers, raw request identifiers, raw idempotency keys, raw provider bodies, full article text, canonical payloads, or unbounded diagnostics.

## Suggested local checks

No mix test is required for this docs-only design PR unless a reviewer asks for targeted checks.

Suggested static check:

```powershell
git diff --name-only 3cc59f3e091d9eef6da666840ce5e0a8038a89c9...HEAD
```

Expected output should be limited to the three docs files listed above.
