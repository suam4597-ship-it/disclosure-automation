# Source health operator runbook manual smoke

This manual smoke checklist validates the source health operator runbook.

This PR is documentation-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 35d8fad453a3d6919348bd458c6bdf9a7088fa53
base source: PR #179 Design source health operator workflow
stream: source health operator runbook
status: docs-only runbook
```

## Expected changed files

Expected files for this PR:

```text
apps/backend/disclosure_api/docs/source_health_operator_runbook.md
apps/backend/disclosure_api/docs/source_health_operator_runbook_guardrails.md
apps/backend/disclosure_api/docs/source_health_operator_runbook_manual_smoke.md
```

## Static changed-file check

Suggested command:

```powershell
git diff --name-only 35d8fad453a3d6919348bd458c6bdf9a7088fa53...HEAD
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

## Route check

Verify the runbook references only existing routes:

```text
GET /api/admin/source-health
GET /api/admin/source-health/:source_key
POST /api/admin/source-health/:source_key/recheck
POST /api/admin/sources/:source_key/poll
```

## Operator pre-check check

Verify the runbook requires operators to check:

```text
authentication
source health read permission
internal/admin route usage
known source_key
no public feed/API mutation intent
no canonical mutation intent
no secret/raw payload copying
```

## Read route check

Verify the runbook limits source health read inspection to bounded metadata:

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

Verify it forbids:

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

## Recheck procedure check

Verify the runbook describes:

```text
POST /api/admin/source-health/:source_key/recheck
```

Verify bounded request metadata:

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

Verify it does not approve live provider fetch, scheduler enqueue, materializer execution, canonical mutation, or public response mutation from recheck.

## Poll procedure check

Verify the runbook describes:

```text
POST /api/admin/sources/:source_key/poll
```

Verify it warns that poll is high-risk and must not be used routinely unless behavior is documented for:

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

## Escalation check

Verify escalation notes are bounded to:

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
request_id_hash
idempotency_key_hash
reason_redacted
```

Verify escalation notes forbid:

```text
raw provider payload
full article text
secret
header
cookie
API key
raw actor identifier
raw request identifier
raw idempotency key
unredacted operator reason
canonical payload
SQL detail
stack trace
unbounded diagnostic blob
```

## Public response-shape check

Verify source health operator workflow must not change:

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

Verify source health operator workflow must not:

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

Verify the runbook does not approve:

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

No local test run is required for this docs-only runbook PR unless a reviewer asks for targeted checks.
