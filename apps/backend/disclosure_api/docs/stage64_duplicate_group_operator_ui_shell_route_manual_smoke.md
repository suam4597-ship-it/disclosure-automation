# Stage 6.4 duplicate group operator UI shell route manual smoke

This smoke checklist covers the docs-only Stage 6.4 duplicate group operator UI shell route design.

## Expected files

```text
apps/backend/disclosure_api/docs/stage64_duplicate_group_operator_ui_shell_route_design.md
apps/backend/disclosure_api/docs/stage64_duplicate_group_operator_ui_shell_route_guardrails.md
apps/backend/disclosure_api/docs/stage64_duplicate_group_operator_ui_shell_route_manual_smoke.md
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

Confirm the design names the correct baseline:

```text
base branch: sec-thin-slice-reconcile-v1
base commit: fedfde71e92b61e423020486f7c406bde8295a66
base source: PR #155 Design Stage 6.4 duplicate group operator UI experience
```

## Candidate shell route smoke

Confirm the design documents only candidate internal/admin shell routes:

```text
GET /admin/duplicate-groups
GET /admin/duplicate-groups/:group_id
```

Confirm those routes are candidates only and are not implemented.

Confirm forbidden public/provider/scheduler/materializer/canonical route namespaces are documented.

## Existing JSON API dependency smoke

Confirm future shell routes depend only on existing JSON read routes:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
```

Confirm future shell routes depend only on existing action routes:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

Confirm no alternate read/action/write API is designed.

## Shell responsibility smoke

Confirm allowed shell responsibilities are bounded:

```text
serve an internal operator-only page shell
load initial static configuration that contains no private identifiers
identify existing API routes the UI may call
show a generic redaction/guardrail notice
fail closed for unauthenticated or non-operator users
```

Confirm forbidden shell responsibilities include no direct table reads/writes, provider work, scheduler work, materializer work, canonical mutation, public response changes, or embedded raw/private material.

## List shell smoke

Confirm the list shell design uses only existing bounded filters:

```text
confidence
source_key
member_kind
redaction_status
limit
```

Confirm the list shell must not fetch or display action event history.

## Detail shell smoke

Confirm the detail shell may display only bounded detail data from the locked show API.

Allowed sections:

```text
group summary
member summary table
review_state_summary
action_event_summary
action controls
redaction/guardrail notice
```

Confirm `action_event_summary` remains bounded and show-only.

## Authorization smoke

Confirm future shell routes require:

```text
authenticated actor
operator or admin role for shell access
read permission for viewing list/detail data
action-specific permissions for enabling action controls
backend authorization remains authoritative
```

Confirm client-side authorization does not replace backend authorization.

## Action control smoke

Confirm future shell action controls map exactly to locked action routes:

```text
Confirm duplicate group -> POST /api/admin/duplicate-groups/:group_id/confirm
Reject duplicate group -> POST /api/admin/duplicate-groups/:group_id/reject
Mark needs review -> POST /api/admin/duplicate-groups/:group_id/mark-review
Clear review state -> POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

Confirm request body cannot override route-derived action operation.

## Action request smoke

Confirm allowed future shell action request fields are bounded to:

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

Confirm the design preserves locked idempotency identity:

```text
group_id + action_operation + actor_id_hash + idempotency_key_hash
```

Confirm backend idempotency remains authoritative.

## Failure rendering smoke

Confirm failure rendering is bounded to allowed categories:

```text
authentication required
action permission missing
duplicate group not found
invalid request
idempotency conflict
state transition rejected
temporary unavailable
```

Confirm forbidden failure rendering material is documented.

## Public response smoke

Confirm the design says future shell route work must not change:

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

Confirm future shell route work must not:

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

Confirm future shell route work must not:

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
git diff --name-only fedfde71e92b61e423020486f7c406bde8295a66...HEAD
```

Expected output should be limited to the three docs files listed above.
