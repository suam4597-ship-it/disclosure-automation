# Source health operator runbook

This runbook documents operator procedures for the source health route surface after the source health operator workflow design was merged.

This PR is documentation-only. It does not add frontend code, backend runtime code, tests, fixtures, migrations, schema modules, router changes, controllers, templates, UI routes, action endpoint changes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer behavior, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 35d8fad453a3d6919348bd458c6bdf9a7088fa53
base source: PR #179 Design source health operator workflow
stream: source health operator runbook
status: docs-only runbook
```

## Existing route surface

Operator route surface:

```text
GET /api/admin/source-health
GET /api/admin/source-health/:source_key
POST /api/admin/source-health/:source_key/recheck
POST /api/admin/sources/:source_key/poll
```

This runbook does not add, remove, rename, or repurpose any route.

## Operator pre-checks

Before source health investigation, verify:

```text
operator is authenticated
operator has source health read permission
operator is using internal/admin routes only
source_key is known and expected
public feed/API behavior is not part of the investigation
canonical mutation is not part of the investigation
provider payloads, secrets, headers, and cookies are not copied into tickets
```

## List source health

Use:

```text
GET /api/admin/source-health
```

Operator should inspect bounded fields only:

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

Do not expect or request:

```text
raw provider payloads
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

## Inspect source health detail

Use:

```text
GET /api/admin/source-health/:source_key
```

Operator should confirm:

```text
source_key matches the intended source
status is bounded
freshness metadata is bounded
failure metadata is bounded
redaction_status is present or clearly absent by design
no secrets or raw transport material are displayed
```

## Recheck procedure

Use only if the route is authorized and the operator has a reason to refresh internal source health state:

```text
POST /api/admin/source-health/:source_key/recheck
```

Before recheck, record bounded operator metadata:

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

Do not include:

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

A recheck must not be assumed to perform live provider fetch, scheduler enqueue, materializer execution, canonical mutation, or public response mutation unless a later implementation design explicitly locks that behavior.

## Poll procedure

Use the poll route only when existing implementation behavior and operator authorization allow it:

```text
POST /api/admin/sources/:source_key/poll
```

Polling is high-risk because it may be connected to source runtime behavior.

Before relying on poll operationally, verify the current implementation contract or a later poll behavior design states:

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

If any of those are unknown, do not use poll as a routine remediation action. Escalate instead.

## Escalation triggers

Escalate when:

```text
source status is stale beyond expected retry_after
last_success_at is missing or unexpectedly old
last_failure_at is recent and repeated
last_error_code indicates authentication, rate limit, schema, or transport failure
redaction_status is missing or failed
recheck result is ambiguous
poll behavior is not documented
operator permissions are unclear
public feed/API symptoms appear related but source health metadata is inconclusive
```

Escalation note should include only bounded material:

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

## Forbidden escalation material

Never include:

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

Source health operator work must not change:

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

## Canonical no-mutation guardrails

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

unless a separate canonical-impact design explicitly approves the behavior.

## Provider, scheduler, and materializer guardrails

This runbook does not approve:

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

## Operator do-not-do list

Do not:

```text
manually write source health rows
manually write canonical rows
manually alter provider payloads
manually enqueue scheduler work outside approved route behavior
manually run materializers as part of source health review
paste secrets, headers, cookies, tokens, full text, raw payloads, or stack traces into tickets
use public routes for operator source health checks
```

## Post-action verification

After recheck or poll, verify only bounded state:

```text
GET /api/admin/source-health/:source_key
```

Confirm:

```text
status is updated or unchanged in a bounded way
last_checked_at is understandable
last_success_at or last_failure_at changed only if expected
last_error_code remains bounded
redaction_status remains acceptable
no public response shape changed
no canonical mutation occurred
no unexpected provider/scheduler/materializer side effect occurred
```

## Stop conditions

Stop and re-scope if the workflow requires:

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
