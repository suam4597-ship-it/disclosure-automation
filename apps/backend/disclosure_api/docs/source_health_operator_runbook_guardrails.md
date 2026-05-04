# Source health operator runbook guardrails

This checklist defines guardrails for the source health operator runbook.

This PR is documentation-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline guardrails

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 35d8fad453a3d6919348bd458c6bdf9a7088fa53
base source: PR #179 Design source health operator workflow
```

## Route guardrails

The runbook must reference only existing routes:

```text
GET /api/admin/source-health
GET /api/admin/source-health/:source_key
POST /api/admin/source-health/:source_key/recheck
POST /api/admin/sources/:source_key/poll
```

The runbook must not add, rename, remove, or repurpose routes.

## Operator pre-check guardrails

Operators must verify:

```text
authenticated operator
source health read permission
internal/admin route usage
known source_key
no public feed/API mutation intent
no canonical mutation intent
no secret/raw payload copying
```

## Read guardrails

Bounded fields only:

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

Forbidden read material:

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

## Recheck guardrails

Recheck route:

```text
POST /api/admin/source-health/:source_key/recheck
```

Allowed bounded operator metadata:

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

Forbidden request material:

```text
raw actor identifier
raw request identifier
raw idempotency key
unredacted reason
provider payload
secret
header
cookie
full article text
canonical payload
```

## Poll guardrails

Poll route:

```text
POST /api/admin/sources/:source_key/poll
```

Do not rely on poll operationally unless current implementation contract or later design states:

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

## Escalation guardrails

Escalation notes may include only:

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

Escalation notes must not include:

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

## Public response guardrails

Source health operator workflow must not change:

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

## Canonical guardrails

Source health operator workflow must not:

```text
mutate canonical_feed_items
create provider canonical feed items
create news-only canonical events
merge official TDnet events
override official TDnet facts
override official citations
mutate news_overlay_attachments
```

## Provider, scheduler, and materializer guardrails

The runbook does not approve:

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

## Stop conditions

Stop and re-scope if source health workflow requires:

```text
new routes
runtime behavior changes
public response changes
canonical mutation
provider clients
live fetch
scheduler enqueue
materializer behavior changes
secrets or raw payload display
unbounded diagnostics
```
