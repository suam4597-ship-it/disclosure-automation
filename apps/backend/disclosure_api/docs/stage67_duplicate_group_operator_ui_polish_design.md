# Stage 6.7 duplicate group operator UI polish design

This document defines a docs-only design for Phase 2 duplicate group operator UI polish after the Stage 6.6 internal operator UI was locked.

Stage 6.7 PR A is design-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: a0d5c006a70cf06449b86024a6f40df62060e505
base source: PR #167 Lock Stage 6.6 duplicate group operator UI
stage: Stage 6.7 PR A duplicate group operator UI polish/loading/error-state design
status: docs-only
```

Locked upstream behavior:

```text
GET /admin/duplicate-groups
GET /admin/duplicate-groups/:group_id
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
POST /api/admin/duplicate-groups/:group_id/mark-review
POST /api/admin/duplicate-groups/:group_id/clear-review-state
```

## Purpose

Stage 6.7 starts Phase 2 UI polish by designing usability improvements before implementation.

Phase 1 created a functional internal operator UI. Phase 2 should make the UI safer for repeated operator use without changing API behavior or public behavior.

## Non-goals

This design does not authorize or implement:

```text
new UI routes
new JSON API routes
new action operations
new request body fields outside the locked allowlist
new storage
new migrations
new schemas
read projection changes
action writer changes
action endpoint changes
public duplicate group fields
public feed response changes
public API response changes
provider live fetch
provider clients
scheduler work
materializer behavior changes
canonical feed mutation
provider canonical feed item creation
news-only canonical event creation
official TDnet event merge
official fact override
official citation override
unbounded action history
raw/private identifier display
unredacted operator reason display
```

## Phase 2 implementation sequence

Recommended Stage 6.7 sequence:

```text
PR 168: UI polish/loading/error-state design
PR 169: loading/empty/error state implementation
PR 170: action confirmation modal and duplicate-click prevention
PR 171: permission-aware button states
PR 172: UI accessibility/basic usability pass
PR 173: full operator UI polish lock close-out
```

This PR covers only PR 168.

## Locked design principle

Phase 2 polish must improve operator clarity and safety while preserving locked Stage 6.6 behavior:

```text
list screen uses only GET /api/admin/duplicate-groups
detail screen uses only GET /api/admin/duplicate-groups/:group_id
action controls use only locked POST action routes
route-derived action operation remains authoritative
action_operation request body override remains forbidden
show-response-only latest-five action_event_summary remains locked
backend authorization remains authoritative
public response shape remains unchanged
canonical data remains unchanged
provider/scheduler/live-fetch/materializer work remains forbidden
```

## Loading state design

Future implementation should make loading states explicit.

List loading states:

```text
initial ready state
loading duplicate groups
loaded duplicate groups
unable to load duplicate groups
```

Detail loading states:

```text
initial ready state
loading duplicate group detail
loaded duplicate group detail
unable to load duplicate group detail
```

Action loading states:

```text
ready for an operator action
submitting action
action submitted, refreshing detail
action submitted and detail refreshed
unable to submit action
```

Loading states must not expose raw request bodies, SQL details, provider payloads, canonical payloads, or unbounded diagnostics.

## Empty state design

Future implementation should render bounded empty states.

Allowed empty states:

```text
No duplicate groups found.
No members found.
No latest actions found.
No review state recorded yet.
```

Empty states must not suggest manual DB writes, manual backfills, provider fetches, scheduler reruns, materializer runs, or canonical changes.

## Error state design

Future implementation should render bounded error states.

Allowed error categories:

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

Forbidden error rendering:

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

## Action confirmation design

Before submitting an action, future UI should show a confirmation step.

The confirmation step should include:

```text
group_id
action label
locked route path
post_review_state
bounded redaction warning
operator_reason_redacted field
idempotency_key_hash field
```

The confirmation step must not include:

```text
action_operation request-body override
raw actor identifiers
raw request identifiers
raw idempotency keys
unredacted operator reason
provider payloads
canonical payloads
full article text
unbounded diagnostics
```

## Duplicate-click prevention design

The UI may disable action buttons while a request is pending.

Backend idempotency remains authoritative:

```text
group_id + action_operation + actor_id_hash + idempotency_key_hash
```

The UI should preserve the existing idempotency guidance:

```text
same intended action retries reuse the same idempotency key hash
new intended actions use a new idempotency key hash
```

## Permission-aware button state design

Future implementation may read bounded operator role/permission hints already available in the UI form or configuration.

Button behavior should be:

```text
show enabled only when the UI has the corresponding action permission hint
show disabled with a bounded reason when the UI has read-only permission only
still submit only to backend-authorized locked routes
backend authorization remains authoritative
```

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

Client-side permission state is advisory only.

## Success feedback design

Future implementation may show bounded success feedback after action completion.

Allowed success feedback:

```text
Action submitted.
Detail refreshed.
Review state updated.
```

Allowed bounded result fields:

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

Success feedback must not show unredacted operator reasons, raw/private identifiers, provider payloads, full article text, canonical payloads, or unbounded diagnostics.

## Filter persistence design

Future list polish may preserve filter values in the URL query string or browser state.

Allowed filters remain:

```text
confidence
source_key
member_kind
redaction_status
limit
```

No arbitrary query builder, raw SQL, provider payload search, canonical payload search, or unbounded diagnostics filter should be added.

## Accessibility and usability design

Future polish should improve basic usability without broad frontend framework changes.

Allowed improvements:

```text
button labels
status regions
form labels
keyboard-accessible controls
bounded error text
back-to-list link
visible disabled-state reason
simple table captions
```

Do not add external frontend dependencies unless separately designed and justified.

## Public response-shape guardrails

Stage 6.7 UI polish must not change:

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

Public duplicate group review/action state fields remain absent.

## Canonical no-mutation guardrails

Stage 6.7 UI polish must not:

```text
mutate canonical_feed_items
create provider canonical feed items
create news-only canonical events
merge official TDnet events
override official TDnet facts
override official citations
mutate news_overlay_attachments
```

Operator review state remains internal advisory metadata.

## Provider, scheduler, and materializer guardrails

Stage 6.7 UI polish must not:

```text
trigger live provider fetch
call provider clients
enqueue scheduler work
store private provider material
materialize duplicate groups from read/action/UI routes
materialize overlays
change materializer behavior
```

## Test design

Future implementation PRs should update or add tests for:

```text
loading states are present and bounded
empty states are present and bounded
error states are bounded
list screen still excludes action_event_summary
detail screen still uses show-response-only latest-five action_event_summary
action buttons map to locked routes only
action request body still excludes action_operation
pending state disables duplicate clicks
success feedback remains bounded
read-only permission disables action controls in UI while backend remains authoritative
public/canonical/provider/scheduler/materializer guardrails remain unchanged
```

## Stop conditions

Do not merge Stage 6.7 implementation PRs if they:

```text
add public duplicate group fields
change public response shapes
change existing JSON API route behavior
change action endpoint behavior
change action writer behavior
add new action operations
submit action_operation in request bodies
request unbounded action history
query duplicate group/action state tables from the UI controller
write action state from UI routes directly
show raw actor/request/idempotency identifiers
show unredacted operator reasons
show raw provider payloads or full article text
show canonical payloads
return unbounded diagnostics
mutate canonical data
trigger provider/scheduler/live-fetch work
change materializer behavior
```
