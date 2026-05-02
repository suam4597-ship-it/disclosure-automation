# Stage 5.9 duplicate group operator review authorization and response guardrails

This checklist defines guardrails for a future operator-only duplicate group review route.

This PR is docs-only. It does not add routes, controllers, UI, action endpoints, runtime authorization integration, audit writes, provider clients, live fetch behavior, scheduler work, materializer changes, public response changes, or canonical mutations.

## Authorization guardrails

Future duplicate group review routes must require:

```text
authenticated operator/admin context
actor_id_hash
request_id_hash
duplicate_group:read permission
bounded role and permission fields
fail-closed unauthorized behavior
```

Future duplicate group review routes must reject:

```text
anonymous access
public access
raw actor identifiers
raw request identifiers
unknown actor context fields
read-only route requests that include action operations
confirm/reject intent in read-only route requests
```

Unauthorized show requests should not reveal whether a group exists.

## Route guardrails

Only these future read routes are in scope for the later route implementation:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
```

Out of scope for the read route implementation:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
PATCH /api/admin/duplicate-groups/:group_id
DELETE /api/admin/duplicate-groups/:group_id
```

Confirm/reject actions require a separate action/audit design.

## Allowed list filters

Future list route filters must be bounded and allowlisted:

```text
confidence
source_key
member_kind
redaction_status
limit
cursor
```

Forbidden filters:

```text
raw provider body search
full text search
secret material search
transport metadata search
canonical payload search
unbounded diagnostics search
```

## Internal response guardrails

Allowed internal group fields:

```text
group_id
confidence
source_keys
match_reasons
member_count
has_official_tdnet_event
has_provider_overlay
redaction_status
inserted_at
updated_at
members
```

Allowed internal member fields:

```text
member_id
member_kind
source_key
provider
external_id_hash
official_event_id
overlay_id
confidence
match_reasons
redaction_status
inserted_at
updated_at
```

Forbidden internal response fields:

```text
raw provider bodies
full article text
provider secret material
provider transport material
raw request metadata
raw response metadata
canonical feed payloads
provider canonical creation payloads
raw body similarity payloads
full text similarity payloads
unbounded diagnostics
```

## Public response guardrails

Future implementation must not change public endpoints or envelopes:

```text
GET /api/events/:event_id
GET /api/events/:event_id/news-overlay
GET /api/feed/digest/latest
GET /api/feed/digest/:digest_date/:edition
```

The following public shapes must remain unchanged:

```text
item.overlays[]
news_overlays[]
feed item_count
feed ordering
official TDnet fields
official citations
public API envelope
public feed envelope
```

Public duplicate group fields must remain absent unless separately designed.

## Canonical no-mutation guardrails

Future read route implementation must not:

```text
update source_duplicate_groups
update source_duplicate_group_members
update canonical_feed_items
create provider canonical feed items
create news-only canonical events
merge official TDnet events
override official TDnet facts
override official citations
mutate news_overlay_attachments
trigger duplicate group materialization
trigger live provider fetch
trigger scheduler work
call provider clients
```

## Redaction guardrails

Future responses, logs, docs, tests, review comments, and manual-smoke output must not include non-redacted private provider or operator material.

Allowed placeholders:

```text
REDACTED_PROVIDER_KEY
REDACTED_PROVIDER_TOKEN
REDACTED_OPERATOR_ID
REDACTED_REQUEST_ID
```

Forbidden material:

```text
provider secret values
raw transport metadata
private operator identifiers
raw request identifiers
raw provider body
full article text
canonical payloads
unbounded provider diagnostics
```

## Validation guardrails for future route PR

A future route PR should verify:

```text
changed files are limited to route/controller/read projection/tests/manual smoke unless justified
read route requires operator/admin authorization
list response is bounded and redacted
show response is bounded and redacted
invalid filters fail safely
unauthorized requests fail closed
not-found and unauthorized-not-revealed behavior is stable
public feed/API regression tests pass
canonical row counts do not change
materializer is not triggered by read route
provider clients and scheduler are not called
changed-file strict redaction check passes
```
