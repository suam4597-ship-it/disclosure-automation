# Stage 5.9 duplicate group operator review route design

This document defines a docs-only design for a future operator-only duplicate group review route.

This is a design document only. It does not add route code, controller code, UI code, action endpoints, runtime authorization integration, audit writes, scheduler work, provider clients, live fetch behavior, public API/feed behavior, materializer changes, schema changes, migrations, or canonical mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 1296e8c8eddbb90fb3476229d83db1f9dcbbbeb1
base source: PR #132 Add Stage 5.9 duplicate group internal materializer
stage: Stage 5.9 PR I duplicate group operator review route design
status: docs-only
locked Stage 5.9 storage: source_duplicate_groups and source_duplicate_group_members
locked Stage 5.9 schemas: SourceDuplicateGroup and SourceDuplicateGroupMember
locked Stage 5.9 materializer: internal duplicate group materializer only
locked Stage 5.7 model: operator-only read-only view pattern
locked Stage 5.8 model: operator action authorization and audit design for action seams
```

## Goal

Define the future operator-only read route before implementing any route/controller behavior.

The future route should allow authorized operators to inspect persisted duplicate group metadata without changing public responses or canonical disclosure data.

## Non-goals

This PR does not authorize or implement:

```text
runtime route implementation
controller implementation
UI implementation
action endpoints
confirm/reject actions
audit table writes
scheduler-triggered duplicate grouping
provider clients
live provider fetch
public duplicate group fields
public API response shape changes
public feed response shape changes
canonical feed mutation
provider canonical feed item creation
news-only canonical event creation
official TDnet event merge
official fact override
```

## Future route shape

Recommended future internal routes:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
```

Both routes must be operator-only and read-only.

The list route should support bounded filters only:

```text
confidence
source_key
member_kind
redaction_status
limit
cursor
```

The show route should read by deterministic `group_id` and return one duplicate group plus bounded members.

## Authorization policy

Future implementation must require authenticated operator/admin context.

Required actor context:

```text
actor_id_hash
actor_roles
actor_permissions
request_id_hash
```

Allowed read permission:

```text
duplicate_group:read
```

Forbidden:

```text
raw actor identifiers
anonymous access
public access
action permissions used as a substitute for read permission
read route granting confirm/reject powers
```

Unauthorized requests should fail closed and should not reveal whether a group exists.

## Audit policy

The read route should not write audit records in this docs-only PR.

For future implementation, read access audit can be designed separately. If read audit is later added, it must be bounded and redacted:

```text
actor_id_hash
request_id_hash
operation
result_status
group_id when authorized
redaction_status
created_at
```

Forbidden audit content:

```text
raw actor identifiers
raw request identifiers
provider secret material
provider transport material
raw provider bodies
full article text
canonical payloads
unbounded diagnostics
```

## Response shape policy

Future route response must be internal/admin only and bounded.

Allowed group fields:

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

Allowed member fields:

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

Forbidden response fields:

```text
raw provider body
full article text
provider secret material
provider transport material
canonical feed payload
provider canonical creation payload
raw similarity payload
unbounded diagnostic payload
```

## Public response guardrails

Future implementation must not change:

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

Public duplicate group fields must remain absent unless a later response-shape design explicitly changes that policy.

## Canonical no-mutation guardrails

The operator review route must be read-only.

It must not:

```text
mutate canonical_feed_items
create provider canonical feed items
create news-only canonical events
merge official TDnet events
override official TDnet facts
override official citations
mutate news overlay attachments
trigger materialization
trigger live fetch
trigger scheduler work
```

## Failure behavior

Recommended failure responses for future implementation:

```text
401 or 403 for unauthorized access
404 for not found or unauthorized-not-revealed show requests
400 for invalid bounded filters
200 with empty items for valid list filters with no matches
```

Errors must remain bounded and must not include raw SQL, provider payloads, or private operator context.

## Future implementation sequence

Recommended next steps after this docs-only design:

```text
1. Pure internal read projection module for duplicate group rows
2. Targeted projection tests using existing schema/materializer fixtures
3. Operator route/controller implementation with bounded read-only responses
4. Route tests for authorization, bounded filters, show/list responses, and public response regressions
5. Optional UI design after route behavior is locked
6. Optional action/audit design for confirm/reject after read route is locked
```

## Stop conditions

Do not merge a future route implementation if it:

```text
adds public duplicate group fields
changes public feed/API response shapes
adds action endpoints in the read route PR
adds UI in the route PR
mutates canonical feed rows
creates provider canonical feed items
creates news-only events
merges official TDnet events
overrides official facts
triggers live provider fetch
uses scheduler/provider clients
returns raw provider or private operator material
stores or displays unbounded diagnostics
bypasses operator/admin authorization
```
