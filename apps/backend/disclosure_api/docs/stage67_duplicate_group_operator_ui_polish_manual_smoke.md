# Stage 6.7 duplicate group operator UI polish manual smoke

This manual smoke checklist validates the Stage 6.7 duplicate group operator UI polish design.

Stage 6.7 PR A is docs-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: a0d5c006a70cf06449b86024a6f40df62060e505
base source: PR #167 Lock Stage 6.6 duplicate group operator UI
stage: Stage 6.7 PR A duplicate group operator UI polish/loading/error-state design
status: docs-only
```

## Expected changed files for this PR

This design PR should change only these files:

```text
apps/backend/disclosure_api/docs/stage67_duplicate_group_operator_ui_polish_design.md
apps/backend/disclosure_api/docs/stage67_duplicate_group_operator_ui_polish_guardrails.md
apps/backend/disclosure_api/docs/stage67_duplicate_group_operator_ui_polish_manual_smoke.md
```

## Static changed-file check

Suggested command:

```powershell
git diff --name-only a0d5c006a70cf06449b86024a6f40df62060e505...HEAD
```

Expected output:

```text
apps/backend/disclosure_api/docs/stage67_duplicate_group_operator_ui_polish_design.md
apps/backend/disclosure_api/docs/stage67_duplicate_group_operator_ui_polish_guardrails.md
apps/backend/disclosure_api/docs/stage67_duplicate_group_operator_ui_polish_manual_smoke.md
```

If any runtime, router, controller, template, frontend, test, fixture, migration, schema, scheduler, provider, live-fetch, feed, API, materializer, or canonical file appears, stop and re-scope the PR.

## Documentation scope check

Verify the design records:

```text
Stage 6.7 PR A is docs-only
baseline commit is PR #167 merge commit
Phase 2 begins after Stage 6.6 UI lock
future implementation sequence starts with loading/empty/error states
public response-shape guardrails remain unchanged
canonical no-mutation guardrails remain unchanged
provider/scheduler/live-fetch/materializer guardrails remain unchanged
```

## Locked route check

Verify the design preserves locked UI routes:

```text
GET /admin/duplicate-groups
GET /admin/duplicate-groups/:group_id
```

Verify the design preserves locked JSON APIs:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

No new UI/API routes should be introduced by this design.

## Loading state design check

Verify the design covers bounded loading states for:

```text
list loading
list loaded
list load failure
detail loading
detail loaded
detail load failure
action submitting
action submitted and detail refreshed
action submission failure
```

Verify loading states do not allow raw request bodies, SQL details, provider payloads, canonical payloads, stack traces, or unbounded diagnostics.

## Empty state design check

Verify the design allows only bounded empty states:

```text
No duplicate groups found.
No members found.
No latest actions found.
No review state recorded yet.
```

Verify empty states do not suggest manual DB writes, manual backfills, provider fetches, scheduler work, materializer work, or canonical changes.

## Error state design check

Verify the design allows only bounded error categories:

```text
authentication required
action permission missing
duplicate group not found
invalid request
idempotency conflict
state transition rejected
temporary unavailable
unable to load duplicate groups
unable to load duplicate group detail
unable to submit action
```

Verify error rendering forbids:

```text
SQL details
raw request bodies
private actor context
provider payloads
full text
canonical payloads
headers
cookies
secrets
unbounded diagnostics
stack traces
```

## Action confirmation design check

Verify the design allows a confirmation step that shows only:

```text
group_id
action label
locked route path
post_review_state
bounded redaction warning
operator_reason_redacted field
idempotency_key_hash field
```

Verify the confirmation step forbids:

```text
action_operation request-body override
raw actor identifiers
raw request identifiers
raw idempotency keys
unredacted operator reasons
provider payloads
canonical payloads
full article text
unbounded diagnostics
```

## Duplicate-click design check

Verify the design preserves backend idempotency as authoritative:

```text
group_id + action_operation + actor_id_hash + idempotency_key_hash
```

Verify the design allows button disabling while pending but does not introduce new idempotency identities.

## Permission-aware design check

Verify the design preserves backend authorization as authoritative.

Read-only permission must not authorize actions:

```text
duplicate_group:read
```

Action-specific permissions remain:

```text
duplicate_group:confirm
duplicate_group:reject
duplicate_group:mark_review
duplicate_group:clear_review_state
```

## Success feedback design check

Verify allowed success feedback is bounded to:

```text
action_operation
required_permission
actor_id_hash
request_id_hash
idempotency_key_hash
result_status
redaction_status
pre_review_state
post_review_state
review_state
action_event_inserted
```

Verify success feedback forbids raw/private identifiers, unredacted reasons, provider payloads, full article text, canonical payloads, or unbounded diagnostics.

## List screen guardrail check

Verify list screen still uses only:

```text
GET /api/admin/duplicate-groups
```

Allowed filters remain:

```text
confidence
source_key
member_kind
redaction_status
limit
```

List screen must still exclude:

```text
action_event_summary
operator_reason_redacted action history
raw actor identifiers
raw request identifiers
raw idempotency keys
provider payloads
canonical payloads
full article text
unbounded diagnostics
```

## Detail screen guardrail check

Verify detail screen still uses only:

```text
GET /api/admin/duplicate-groups/:group_id
```

Verify action event summary remains:

```text
show-response-only
latest-five-from-show-response
```

## Action control guardrail check

Verify action buttons still map exactly to locked routes:

```text
Confirm duplicate group -> POST /api/admin/duplicate-groups/:group_id/confirm
Reject duplicate group -> POST /api/admin/duplicate-groups/:group_id/reject
Mark needs review -> POST /api/admin/duplicate-groups/:group_id/mark-review
Clear review state -> POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

Verify the route chooses the operation and the UI must not submit `action_operation` in request bodies.

## Public response-shape check

Verify the design says future polish must not change:

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

Verify public duplicate group review/action state fields remain absent.

## Canonical no-mutation check

Verify the design says future polish must not:

```text
mutate canonical_feed_items
create provider canonical feed items
create news-only canonical events
merge official TDnet events
override official TDnet facts
override official citations
mutate news_overlay_attachments
```

## Provider, scheduler, and materializer check

Verify the design says future polish must not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
store private provider material
materialize duplicate groups from read/action/UI routes
materialize overlays
change materializer behavior
```

## Redaction check

Search changed docs for forbidden raw/private material.

Suggested command:

```powershell
git grep -n -E "raw actor|raw request|raw idempotency|provider payload|canonical payload|full article text|SQL detail|cookie|secret|stack trace" -- apps/backend/disclosure_api/docs/stage67_duplicate_group_operator_ui_polish_*.md
```

Expected result: only guardrail/checklist references to forbidden material, no actual raw/private values.

## Test command

No mix test run is required for this docs-only design PR unless a reviewer asks for targeted checks.

If a reviewer requests a smoke check, run the changed-file check above and confirm no runtime files changed.

## Stop conditions

Stop and re-scope this PR if it changes any of these:

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
