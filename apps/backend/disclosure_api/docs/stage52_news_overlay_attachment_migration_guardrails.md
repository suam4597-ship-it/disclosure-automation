# Stage 5.2 news overlay attachment migration guardrails

This document defines the migration and schema guardrails for a future `news_overlay_attachments` table.

This is a design document only. It does not add database migrations, Ecto schemas, runtime code, tests, fixtures, schedulers, provider fetches, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 947a516133781e110b84dabc253534324cc1cf25
base commit source: PR #88 Lock Stage 5.1 news overlay feed-visible rendering
stage: Stage 5.2 migration guardrails
status: design-only
```

## Migration principle

The migration must only add dedicated overlay attachment storage.

It must not modify existing official canonical storage semantics.

Allowed migration scope:

```text
create news_overlay_attachments table
add indexes on news_overlay_attachments
add check constraints on news_overlay_attachments
add foreign keys from news_overlay_attachments to existing tables
```

Disallowed migration scope:

```text
alter canonical_feed_items columns
alter raw_documents columns
alter raw_events columns
alter feed_snapshots columns
add provider credential tables
add news-only canonical item tables
add full article text storage
```

## Required foreign keys

Recommended foreign keys:

```text
official_canonical_feed_item_id references canonical_feed_items(id)
overlay_source_registry_id references source_registry(id)
overlay_raw_document_id references raw_documents(id)
overlay_raw_event_id references raw_events(id)
```

Foreign key delete behavior should be conservative.

Recommended:

```text
on delete restrict for official_canonical_feed_item_id
on delete set null for raw staging references if nullable
```

Do not cascade delete official canonical items from overlay attachments.

## Required check constraints

Stage 5.2 v1 should add conservative constraints:

```text
canonical_fact_override = false
overlay_mode = 'attach_only'
display_state in allowed Stage 5.1 states
source_tier = 'reputable_news_source'
document_role = 'news_article'
overlay_source_key <> ''
overlay_provider <> ''
overlay_external_id <> ''
overlay_id <> ''
official_event_id <> ''
```

If the DB helper style prefers application-level validation over DB check constraints, the implementation PR must explain that choice and add equivalent tests.

## Required uniqueness

Recommended unique indexes:

```text
unique_official_overlay_external_id:
  official_canonical_feed_item_id, overlay_source_key, overlay_external_id

unique_official_overlay_id:
  official_event_id, overlay_id
```

Both are useful:

```text
external id uniqueness prevents provider/article duplication
overlay id uniqueness preserves deterministic Stage 5.1 overlay identity
```

## Required query indexes

Recommended indexes:

```text
official_canonical_feed_item_id
official_event_id
overlay_source_key, overlay_external_id
official_canonical_feed_item_id, display_state
published_at
```

## Ecto schema guardrails

Recommended schema module:

```text
DisclosureAutomation.Schema.NewsOverlayAttachment
```

Recommended changeset guardrails:

```text
require official_canonical_feed_item_id
require official_event_id
require overlay_source_key
require overlay_provider
require overlay_external_id
require overlay_id
require overlay_mode
require display_state
require canonical_fact_override
require source_tier
require document_role
validate canonical_fact_override == false
validate overlay_mode == attach_only
validate source_tier == reputable_news_source
validate document_role == news_article
validate display_state in allowed values
```

## Migration naming

Recommended migration name:

```text
create_news_overlay_attachments
```

Recommended file scope:

```text
priv/repo/migrations/*_create_news_overlay_attachments.exs
```

The implementation PR should not include more than this one migration unless explicitly justified.

## Backfill separation

The migration PR should not automatically backfill rows unless the PR explicitly includes a deterministic materialization step and tests.

Preferred split:

```text
PR A: migration + schema + changeset tests
PR B: deterministic materializer from Stage 5.1 raw staging
PR C: read path preference switch, if needed
```

This keeps storage shape review separate from runtime behavior changes.

## Compatibility requirements

After migration only:

```text
Stage 5.1 read model still works
Stage 5.1 API route still works
Stage 5.1 feed-visible response still works
no overlay rows are required for existing Stage 5.1 behavior
```

The migration must be safe to deploy before materialization.

## Redaction requirements

The table must not contain:

```text
Subscription-Key values
Authorization header values
Cookie header values
provider credentials
signed private URLs
full Reuters article text
provider request headers
```

Schema tests should include representative payloads and assert no full article text storage if materialization is included.

## Rollback expectations

Rollback should drop only the `news_overlay_attachments` table and related indexes/constraints.

It must not alter or delete:

```text
canonical_feed_items
raw_documents
raw_events
feed_snapshots
source_registry
```

## Required tests for migration PR

Recommended tests:

```text
schema changeset accepts valid Stage 5.1 Reuters attachment
schema changeset rejects canonical_fact_override=true
schema changeset rejects non-attach overlay_mode
schema changeset rejects unknown display_state
schema changeset rejects non-news document_role
schema changeset rejects non-reputable source_tier
unique constraint prevents duplicate provider article attachment
foreign key links official canonical feed item
Stage 5.1 existing regressions still pass
```

## No-go conditions

The migration PR must fail review if it does any of the following:

```text
alters canonical_feed_items official fields
stores full Reuters article text
stores provider credentials
creates Reuters canonical items
creates news-only canonical items
adds live provider fetches
adds new fixtures
adds scheduler changes
changes feed rendering behavior without separate implementation scope
```
