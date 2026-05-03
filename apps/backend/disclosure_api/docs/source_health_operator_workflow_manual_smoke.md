# Source health operator workflow manual smoke

This manual smoke checklist validates the source health operator workflow design.

This PR is documentation-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 0901a0ed7c7fccf26b5c768bfaab4ce248361073
base source: PR #178 Lock Stage 6.9 duplicate group pause decision
stream: source health operator workflow
status: docs-only design
```

## Expected changed files

Expected files for this PR:

```text
apps/backend/disclosure_api/docs/source_health_operator_workflow_design.md
apps/backend/disclosure_api/docs/source_health_operator_workflow_guardrails.md
apps/backend/disclosure_api/docs/source_health_operator_workflow_manual_smoke.md
```

## Static changed-file check

Suggested command:

```powershell
git diff --name-only 0901a0ed7c7fccf26b5c768bfaab4ce248361073...HEAD
```

Expected output should be limited to the three docs above.

## Route surface check

Verify the design references only existing source health/operator routes:

```text
GET /api/admin/source-health
GET /api/admin/source-health/:source_key
POST /api/admin/source-health/:source_key/recheck
POST /api/admin/sources/:source_key/poll
```

No route should be added, removed, renamed, or repurposed by this PR.

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

## Read response design check

Verify candidate bounded read fields are limited to:

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

Verify forbidden read response material includes:

```text
raw provider payload
full article text
request headers
cookies
secrets
API keys
raw transport responses
unbounded stack traces
SQL details
canonical payloads
private actor context
```

## Recheck design check

Verify the recheck route remains:

```text
POST /api/admin/source-health/:source_key/recheck
```

Verify this design does not approve:

```text
live provider fetch
scheduler enqueue
materializer execution
canonical mutation
public response mutation
```

## Poll design check

Verify the poll route remains:

```text
POST /api/admin/sources/:source_key/poll
```

Verify poll behavior must not be changed or relied on operationally until a separate poll behavior design states:

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

## Authorization check

Verify backend authorization remains authoritative.

Candidate permissions:

```text
source_health:read
source_health:recheck
source:poll
```

Read-only source health permission must not authorize recheck or poll.

## Public response-shape check

Verify source health operator work must not change:

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

Verify source health operator work must not:

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

Verify this design does not approve:

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
