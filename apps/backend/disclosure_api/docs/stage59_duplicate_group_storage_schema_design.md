# Stage 5.9 duplicate group storage schema design

This document defines a docs-only storage/schema design for future internal cross-source duplicate group persistence.

This is a design document only. It does not add migrations, schema files, runtime grouping materialization, DB writes, tests, fixtures, scheduler code, provider clients, live fetch code, routes, feed/controller changes, UI code, action endpoints, materializer changes, API behavior changes, feed behavior changes, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: b55ee9d4172131ba20dce09a955aaf15425796ed
base source: PR #128 Add Stage 5.9 duplicate group noop service
stage: Stage 5.9 PR E duplicate group storage schema design
status: docs-only
locked design: Stage 5.9 cross-source duplicate group design
locked contract: Stage59CrossSourceDuplicateGroupContract
locked projection: Stage59DuplicateGroupProjectionContract
locked no-op service: Stage59DuplicateGroupNoopService
```

## Goal

Define the future internal storage shape for duplicate groups before any migration, schema module, materializer, route, UI, action endpoint, scheduler integration, live fetch behavior, public response behavior, or canonical mutation is implemented.

The design records:

```text
candidate internal tables
bounded field allowlists
redaction policy
idempotency and uniqueness policy
audit and operator-review relationship
response-shape guardrails
canonical no-mutation guardrails
migration stop conditions
```

## Non-goals

This PR does not authorize or implement:

```text
migration files
schema modules
DB writes
runtime duplicate group materialization
runtime duplicate group persistence
backfills
fixtures
provider clients
live provider fetch
scheduler-triggered grouping
routes
feed/controller changes
UI/admin tooling
action endpoints
materializer changes
public API duplicate group fields
public feed duplicate group fields
canonical feed item mutation
provider canonical feed item creation
news-only canonical event creation
official event merge
official fact override
```

## Storage principles

Future storage must preserve the locked Stage 5.9 semantics:

```text
duplicate groups are internal/operator-only by default
duplicate groups are advisory-only
duplicate groups are non-canonical
duplicate groups do not alter item.overlays[]
duplicate groups do not alter news_overlays[]
duplicate groups do not alter feed item_count or ordering
duplicate groups do not mutate canonical feed items
duplicate groups do not create provider canonical feed items
duplicate groups do not create news-only canonical events
duplicate groups do not merge official TDnet events
duplicate groups do not override official facts
```

## Candidate table design

Future implementation may use two internal tables:

```text
source_duplicate_groups
source_duplicate_group_members
```

These names are design suggestions only. This PR does not create the tables.

## source_duplicate_groups candidate fields

Allowed bounded fields:

```text
id
group_id
confidence
source_keys
match_reasons
member_count
has_official_tdnet_event
has_provider_overlay
redaction_status
created_at
updated_at
```

Required future constraints:

```text
group_id unique
group_id bounded
confidence allowlisted
source_keys bounded list
match_reasons bounded allowlisted list
member_count bounded integer
has_official_tdnet_event boolean
has_provider_overlay boolean
redaction_status allowlisted
```

Forbidden fields:

```text
full article text
raw provider payloads
provider credentials
provider transport metadata
request headers
response headers
canonical feed item payloads
provider canonical creation payloads
raw body similarity payloads
full text similarity payloads
unbounded diagnostics
```

## source_duplicate_group_members candidate fields

Allowed bounded fields:

```text
id
group_id
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
created_at
updated_at
```

Required future constraints:

```text
group_id references source_duplicate_groups.group_id
member_id bounded
member_kind allowlisted
source_key bounded
provider bounded
external_id_hash hash-shaped when present
official_event_id bounded when present
overlay_id bounded when present
at least one member reference required
confidence allowlisted
match_reasons bounded allowlisted list
redaction_status allowlisted
unique group_id + member_id
```

Forbidden fields:

```text
raw external provider response body
raw article body
full article text
provider credentials
provider transport metadata
request headers
response headers
canonical feed item payloads
provider canonical creation payloads
unbounded diagnostics
```

## Idempotency and uniqueness policy

Future persistence must be idempotent.

Recommended behavior:

```text
upsert by group_id
upsert members by group_id + member_id
stable group_id generation from bounded metadata
stable member_id generation from bounded metadata
re-running grouping does not duplicate rows
re-running grouping does not mutate canonical feed items
re-running grouping does not change public response shapes
```

## Redaction policy

Future migration/schema/materialization work must reject or omit:

```text
provider credential values
provider transport metadata
request metadata
response metadata
signed private URLs
raw provider payloads
full article text
unbounded diagnostics
secret-like values
canonical feed item payloads
provider canonical creation payloads
```

Allowed redacted placeholders in docs/tests:

```text
REDACTED_PROVIDER_KEY
REDACTED_PROVIDER_TOKEN
REDACTED_SUBSCRIPTION_KEY
```

## Relationship to contracts

Future storage implementation must validate or normalize through:

```text
Stage59CrossSourceDuplicateGroupContract
Stage59DuplicateGroupProjectionContract
```

Future storage implementation must preserve:

```text
internal_operator_advisory_only
bounded=true
redacted=true
non_canonical=true
public_response_shape_mutation=false
canonical_feed_mutation=false
```

## Operator review and audit relationship

Future duplicate group persistence may support operator review only after separate design.

Required future behavior:

```text
operator/admin authorization required for review
read-only review before mutation
confirm/reject actions require separate action design
audit trail required for review actions
raw actor identifiers not stored in group/member rows
review metadata remains bounded and redacted
```

This PR does not add review actions or audit tables.

## Response-shape policy

Future storage work must not change public response shapes:

```text
read model item.overlays[] unchanged
API item.overlays[] unchanged
feed news_overlays[] unchanged
feed item_count unchanged
feed ordering unchanged
official TDnet fields unchanged
official citations unchanged
API envelope unchanged
public API duplicate group fields absent
public feed duplicate group fields absent
```

## Canonical no-mutation policy

Future storage work must not perform:

```text
canonical feed item mutation
provider canonical feed item creation
news-only canonical event creation
official TDnet event merge
official citation override
canonical fact override
public materializer output mutation
```

## Future implementation sequence

Recommended future sequence after this docs-only design:

```text
1. Docs-only storage schema design and guardrails
2. Migration PR adding internal tables only after review
3. Schema module PR with validations and no runtime materialization
4. Internal materialization PR using existing fixtures only
5. Operator-only read route PR after authorization/audit design
6. UI implementation after route and audit behavior are locked
```

This PR covers only step 1.

## Stop conditions

Do not merge a future storage implementation if it:

```text
adds public duplicate group fields
changes item.overlays[] shape
changes news_overlays[] shape
changes feed item_count or ordering
mutates canonical feed items
creates provider canonical feed items
creates news-only canonical events
merges official TDnet events automatically
overrides official TDnet facts
stores provider credentials
stores provider transport metadata
stores raw provider payloads
stores full article text
stores unbounded diagnostics
adds scheduler-triggered provider work
triggers live provider fetch by default
adds route/UI/action endpoint behavior in a migration PR
breaks redaction checks
```
