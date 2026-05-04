# Source health route contract lock manual smoke

This manual smoke checklist validates the source health route contract lock design.

This PR is documentation-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: a04edff25e0d2293b6341eb172f72898a7a4ce4b
base source: PR #180 Add source health operator runbook
stream: source health route contract lock design
status: docs-only design
```

## Expected changed files

Expected files for this PR:

```text
apps/backend/disclosure_api/docs/source_health_route_contract_lock_design.md
apps/backend/disclosure_api/docs/source_health_route_contract_lock_guardrails.md
apps/backend/disclosure_api/docs/source_health_route_contract_lock_manual_smoke.md
```

## Static changed-file check

Suggested command:

```powershell
git diff --name-only a04edff25e0d2293b6341eb172f72898a7a4ce4b...HEAD
```

Expected output should be limited to the three docs above.

## Scope check

Verify this PR does not change:

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
public API behavior
public feed behavior
materializer behavior
canonical mutation behavior
```

## Route surface check

Verify the contract references only existing routes:

```text
GET /api/admin/source-health
GET /api/admin/source-health/:source_key
POST /api/admin/source-health/:source_key/recheck
POST /api/admin/sources/:source_key/poll
```

## List contract check

Verify list route candidate envelope includes only bounded operational metadata:

```text
mode
route_added
ui_added
item_count
items[]
redaction_status
public_response_shape_mutation
canonical_feed_mutation
trigger_live_fetch
scheduler_enabled
materializer_triggered
network_access
```

Verify candidate item fields are bounded:

```text
source_key
status
last_success_at
last_failure_at
last_checked_at
last_error_code
retry_after
freshness_status
redaction_status
```

## Detail contract check

Verify detail route candidate envelope includes only bounded operational metadata:

```text
mode
route_added
ui_added
source_key
item
redaction_status
public_response_shape_mutation
canonical_feed_mutation
trigger_live_fetch
scheduler_enabled
materializer_triggered
network_access
```

Verify detail does not approve raw/private material.

## Recheck contract check

Verify route-derived operation remains:

```text
recheck -> recheck_source_health
```

Verify request body cannot override route-derived operation.

Verify candidate request allowlist is bounded:

```text
actor_id_hash
actor_permissions
roles
request_id_hash
idempotency_key_hash
reason_redacted
redaction_status
created_at
```

## Poll contract check

Verify route-derived operation remains:

```text
poll -> poll_source
```

Verify request body cannot override route-derived operation.

Verify poll behavior remains gated until a separate design states:

```text
source_key allowlist
operator permission model
idempotency model
rate limit model
external network behavior
scheduler interaction
provider client interaction
materializer interaction
canonical impact
public response impact
test plan
rollback plan
```

## Forbidden material check

Verify route responses and requests forbid:

```text
raw provider payload
full article text
headers
cookies
secrets
API keys
raw transport response
SQL details
stack traces
canonical payload
private actor context
unbounded diagnostics
raw actor identifier
raw request identifier
raw idempotency key
unredacted reason
```

## Public response-shape check

Verify source health route contract work must not change:

```text
GET /api/events/:event_id
GET /api/events/:event_id/news-overlay
GET /api/feed/digest/latest
GET /api/feed/digest/:digest_date/:edition
GET /api/feed/hero
GET /api/feed/region/:region_code
public API envelope
public feed envelope
feed ordering
feed item_count
official TDnet fields
official citations
```

## Canonical check

Verify source health route contract work must not:

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

Verify the design does not approve:

```text
live provider fetch
provider client calls
scheduler enqueueing
stored private provider material
source materialization
overlay materialization
canonical materialization
materializer behavior changes
```

## Test command

No local test run is required for this docs-only design PR unless a reviewer asks for targeted checks.
