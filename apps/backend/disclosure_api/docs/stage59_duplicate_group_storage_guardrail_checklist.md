# Stage 5.9 duplicate group storage guardrail checklist

This checklist defines guardrails for any future internal duplicate group storage implementation.

This is a documentation-only checklist. It does not add migration files, schema modules, runtime grouping materialization, DB writes, tests, fixtures, scheduler code, provider clients, live fetch code, routes, feed/controller changes, UI code, action endpoints, materializer changes, API behavior changes, feed behavior changes, or canonical feed mutations.

## Scope

```text
stage: Stage 5.9 PR E
scope: duplicate group storage guardrail checklist
mode: docs-only
migration files: none
schema modules: none
DB writes: none
runtime materialization: none
new routes: none
UI code: none
action endpoints: none
scheduler: none
live fetch: none
canonical mutation: none
```

## Storage baseline checklist

Future storage work must preserve:

```text
internal/operator-only duplicate group visibility: PASS
advisory-only duplicate group semantics: PASS
non-canonical duplicate group semantics: PASS
Stage59CrossSourceDuplicateGroupContract validation path: PASS
Stage59DuplicateGroupProjectionContract projection path: PASS
Stage59DuplicateGroupNoopService no-op boundary until materialization is separately designed: PASS
```

## Table design checklist

Future storage design must prove:

```text
source_duplicate_groups table is internal-only: PASS
source_duplicate_group_members table is internal-only: PASS
group_id is bounded and unique: PASS
member_id is bounded: PASS
group_id + member_id is unique: PASS
confidence is allowlisted: PASS
member_kind is allowlisted: PASS
match_reasons are allowlisted and bounded: PASS
redaction_status is allowlisted: PASS
source_keys are bounded: PASS
member references are bounded: PASS
```

## Forbidden storage checklist

Future storage implementation must not store:

```text
full article text
raw provider payloads
provider credentials
provider transport metadata
request metadata
response metadata
signed private URLs
canonical feed item payloads
provider canonical creation payloads
raw similarity payloads
full text similarity payloads
unbounded diagnostics
secret-like values
```

## Idempotency checklist

Future persistence must prove:

```text
upsert by group_id is idempotent: PASS
member upsert by group_id + member_id is idempotent: PASS
re-running grouping does not duplicate rows: PASS
re-running grouping does not mutate canonical feed items: PASS
re-running grouping does not change public response shapes: PASS
re-running grouping does not create news-only canonical events: PASS
```

## Response-shape checklist

Future storage work must not change public response shapes:

```text
read model item.overlays[] unchanged: PASS
API item.overlays[] unchanged: PASS
feed news_overlays[] unchanged: PASS
feed item_count unchanged: PASS
feed ordering unchanged: PASS
official TDnet fields unchanged: PASS
official citations unchanged: PASS
API envelope unchanged: PASS
public API duplicate group fields absent: PASS
public feed duplicate group fields absent: PASS
```

## Canonical no-mutation checklist

Future storage work must not perform:

```text
canonical feed item mutation: PASS
provider canonical feed item creation: PASS
news-only canonical event creation: PASS
official TDnet event merge: PASS
official citation override: PASS
canonical fact override: PASS
public materializer output mutation: PASS
```

## Migration PR checklist for future work

A future migration PR must prove:

```text
migration adds internal duplicate group tables only: PASS
migration does not backfill rows unless separately designed: PASS
migration does not alter canonical_feed_items: PASS
migration does not alter news overlay attachment public semantics: PASS
migration does not add public API/feed columns: PASS
migration does not create provider canonical feed items: PASS
migration has rollback path: PASS
migration preserves existing tests: PASS
```

## Schema PR checklist for future work

A future schema module PR must prove:

```text
schema validations mirror Stage59 contracts: PASS
schema rejects forbidden fields: PASS
schema stores bounded metadata only: PASS
schema has no materialization side effects: PASS
schema has no public route exposure: PASS
schema has no canonical mutation behavior: PASS
```

## PASS criteria for this docs PR

```text
docs-only changed files: PASS
duplicate group storage schema design added: PASS
duplicate group storage guardrail checklist added: PASS
duplicate group storage manual smoke added: PASS
no migration/schema/runtime/test/fixture changes: PASS
no scheduler/provider/live-fetch/route/feed/UI/materializer/API/canonical code changes: PASS
redaction guardrails documented: PASS
canonical no-mutation guardrails documented: PASS
public response-shape guardrails documented: PASS
```
