# Stage 5.2 news overlay attachment storage lock close-out

This document locks the Stage 5.2 dedicated news overlay attachment storage slice after the schema, materializer, and read path preference implementation PRs were verified and merged.

This is a close-out document only. It does not add migrations, schemas, runtime code, tests, fixtures, schedulers, provider fetches, routes, feed/controller changes, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: fe7c796521513b49108a27c40b63a0724755fb0b
base commit source: PR #92 Prefer Stage 5.2 news overlay attachments in read path
stage: Stage 5.2 attachment storage lock close-out
runtime lock status: locked by this close-out
```

## Locked implementation PRs

```text
design PR: #89 Stage 5.2 news overlay attachment storage design
schema PR: #90 Add Stage 5.2 news overlay attachment schema
schema merge SHA: a474d28ca66ed0c076be584fafb877a84f21caf2
materializer PR: #91 Add Stage 5.2 news overlay attachment materializer
materializer merge SHA: 8ee77b9632163a30a508a034e60d7f0c0e42d24e
read path PR: #92 Prefer Stage 5.2 news overlay attachments in read path
read path merge SHA: fe7c796521513b49108a27c40b63a0724755fb0b
```

## Locked storage scope

```text
table: news_overlay_attachments
schema: DisclosureAutomation.Schema.NewsOverlayAttachment
materializer: DisclosureAutomation.Runtime.Stage52NewsOverlayAttachmentMaterializer
read model: DisclosureAutomation.Runtime.Stage5NewsOverlayReadModel
source: locked Stage 5.1 raw-staged Reuters overlay
feed field: news_overlays[]
API route: GET /api/events/:event_id/news-overlay
canonical_feed_mutation: false
news_only_event_creation: false
canonical_fact_override: false
```

## Locked files

PR #90 added:

```text
apps/backend/disclosure_api/priv/repo/migrations/20260501170500_create_news_overlay_attachments.exs
apps/backend/disclosure_api/lib/disclosure_automation/schema/news_overlay_attachment.ex
apps/backend/disclosure_api/test/stage52_news_overlay_attachment_schema_test.exs
apps/backend/disclosure_api/docs/stage52_news_overlay_attachment_schema_manual_smoke.md
```

PR #91 added:

```text
apps/backend/disclosure_api/lib/disclosure_automation/runtime/stage52_news_overlay_attachment_materializer.ex
apps/backend/disclosure_api/test/stage52_news_overlay_attachment_materializer_test.exs
apps/backend/disclosure_api/docs/stage52_news_overlay_attachment_materializer_manual_smoke.md
```

PR #92 changed/added:

```text
apps/backend/disclosure_api/lib/disclosure_automation/runtime/stage5_news_overlay_read_model.ex
apps/backend/disclosure_api/test/stage52_news_overlay_attachment_read_path_test.exs
apps/backend/disclosure_api/docs/stage52_news_overlay_attachment_read_path_manual_smoke.md
```

## Locked schema behavior

The `news_overlay_attachments` table locks these Stage 5.2 v1 guardrails:

```text
one row attaches one overlay to one official canonical feed item
official_canonical_feed_item_id references canonical_feed_items(id)
overlay_source_registry_id references source_registry(id)
overlay_raw_document_id references raw_documents(id)
overlay_raw_event_id references raw_events(id)
unique official item + overlay source + overlay external id
unique official event id + overlay id
canonical_fact_override=false
overlay_mode=attach_only
display_state is one of the allowed Stage 5.1 states
source_tier=reputable_news_source
document_role=news_article
```

The schema and changeset preserve these guardrails at application level and database constraint level.

## Locked materializer behavior

The Stage 5.2 materializer locks these behaviors:

```text
reads locked Stage 5.1 read model by official event id
materializes only visible overlays
creates or updates one news_overlay_attachments row for the locked Reuters fixture
is idempotent across repeated runs
keeps canonical_fact_override=false
keeps overlay_mode=attach_only
keeps display_state=visible
keeps source_tier=reputable_news_source
keeps document_role=news_article
never mutates canonical_feed_items
never creates Reuters CanonicalFeedItem
never creates news-only CanonicalFeedItem
```

## Locked read path behavior

The Stage 5.2 read path locks these behaviors:

```text
Stage5NewsOverlayReadModel prefers visible news_overlay_attachments rows when present
Stage5NewsOverlayReadModel falls back to locked Stage 5.1 raw-staging projection when no attachment rows exist
API response shape remains item.overlays[]
feed response shape remains news_overlays[]
official TDnet fields remain unchanged
digest item_count remains unchanged
digest item ordering remains unchanged
```

## Official anchor preserved

The official TDnet canonical event remains the source of truth.

```text
official_source_key: jp_tdnet_timely_disclosure
event_id: jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
stable_external_id: TDNET:4527:20260430:1900:140120260430515474
issuer: ロート製薬株式会社
security_code: 4527
official_title: 株主提案に関する書面受領のお知らせ
published_at_utc: 2026-04-30T10:00:00.000000Z
canonical_event_type: material_information_update
```

The attachment storage must not replace official title, timestamp, URL, event type, issuer, security code, or stable external id with Reuters values.

## Reuters overlay preserved

The locked Reuters overlay remains attach-only context.

```text
overlay_source_key: stage5_news_overlay_fixture
overlay_provider: Reuters
overlay_external_id: NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001
overlay_id: news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57
overlay_mode: attach_only
display_state: visible
canonical_fact_override: false
source_tier: reputable_news_source
document_role: news_article
```

The Reuters URL remains an overlay URL and must not replace the official TDnet URL.

## Verification summary: PR #90

Verification for the schema PR was recorded against:

```text
verified branch: chatgpt-stage52-overlay-attachment-schema-v1
verified head SHA: 5ee71209b57115440120a614bb7d6d91a64d1366
review id: 4212445082
```

Results:

```text
stage52 attachment schema test: PASS
stage5 feed-visible regression: PASS
stage5 API exposure regression: PASS
stage5 read model query regression: PASS
stage5 raw-staging idempotency regression: PASS
TDnet runtime idempotency regression: PASS
TDnet HTTP smoke regression: PASS
migration smoke: PASS
no runtime materializer: PASS
no feed/API read path switch: PASS
no fixture changes: PASS
no scheduler changes: PASS
no provider/live Reuters fetch: PASS
no new routes: PASS
canonical no-mutation check: PASS
redaction check: PASS
```

Command evidence included:

```text
test/stage52_news_overlay_attachment_schema_test.exs: 8 tests, 0 failures
test/stage5_news_overlay_feed_visible_test.exs: 1 test, 0 failures
test/stage5_news_overlay_api_exposure_test.exs: 3 tests, 0 failures
test/stage5_news_overlay_read_model_query_test.exs: 3 tests, 0 failures
test/stage5_news_overlay_raw_staging_runtime_idempotency_test.exs: 1 test, 0 failures
test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs: 1 test, 0 failures
test/jp_tdnet_timely_disclosure_http_smoke_test.exs: 1 test, 0 failures
```

## Verification summary: PR #91

Verification for the materializer PR was recorded against:

```text
verified branch: chatgpt-stage52-overlay-materializer-v1
verified head SHA: bc1f958757bb59107f74cf557925c9fabe531db9
review id: 4212567779
```

Results:

```text
stage52 attachment materializer test: PASS
stage52 attachment schema regression: PASS
stage5 feed-visible regression: PASS
stage5 API exposure regression: PASS
stage5 read model query regression: PASS
stage5 raw-staging idempotency regression: PASS
TDnet runtime idempotency regression: PASS
TDnet HTTP smoke regression: PASS
materializer idempotency: PASS
no migrations: PASS
no schema changes: PASS
no fixture changes: PASS
no scheduler changes: PASS
no provider/live Reuters fetch: PASS
no new routes: PASS
no feed/API read path switch: PASS
canonical no-mutation check: PASS
redaction check: PASS
```

Command evidence included:

```text
test/stage52_news_overlay_attachment_materializer_test.exs: 1 test, 0 failures
test/stage52_news_overlay_attachment_schema_test.exs: 8 tests, 0 failures
test/stage5_news_overlay_feed_visible_test.exs: 1 test, 0 failures
test/stage5_news_overlay_api_exposure_test.exs: 3 tests, 0 failures
test/stage5_news_overlay_read_model_query_test.exs: 3 tests, 0 failures
test/stage5_news_overlay_raw_staging_runtime_idempotency_test.exs: 1 test, 0 failures
test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs: 1 test, 0 failures
test/jp_tdnet_timely_disclosure_http_smoke_test.exs: 1 test, 0 failures
```

## Verification summary: PR #92

Verification for the read path PR was recorded against:

```text
verified branch: chatgpt-stage52-overlay-read-path-v1
verified head SHA: 86faec8e29b05c5d111942c8373982c46fd3556b
review id: 4212653587
```

Results:

```text
stage52 attachment read path test: PASS
stage52 attachment materializer regression: PASS
stage52 attachment schema regression: PASS
stage5 feed-visible regression: PASS
stage5 API exposure regression: PASS
stage5 read model query regression: PASS
stage5 raw-staging idempotency regression: PASS
TDnet runtime idempotency regression: PASS
TDnet HTTP smoke regression: PASS
fallback to raw projection when no attachment exists: PASS
materialized attachment preference when attachment exists: PASS
API/feed response shape unchanged: PASS
no migrations: PASS
no schema changes: PASS
no fixture changes: PASS
no scheduler changes: PASS
no provider/live Reuters fetch: PASS
no new routes: PASS
canonical no-mutation check: PASS
redaction check: PASS
```

Command evidence included:

```text
test/stage52_news_overlay_attachment_read_path_test.exs: 2 tests, 0 failures
test/stage52_news_overlay_attachment_materializer_test.exs: 1 test, 0 failures
test/stage52_news_overlay_attachment_schema_test.exs: 8 tests, 0 failures
test/stage5_news_overlay_feed_visible_test.exs: 1 test, 0 failures
test/stage5_news_overlay_api_exposure_test.exs: 3 tests, 0 failures
test/stage5_news_overlay_read_model_query_test.exs: 3 tests, 0 failures
test/stage5_news_overlay_raw_staging_runtime_idempotency_test.exs: 1 test, 0 failures
test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs: 1 test, 0 failures
test/jp_tdnet_timely_disclosure_http_smoke_test.exs: 1 test, 0 failures
```

## No-mutation evidence

Across PR #90, PR #91, and PR #92, verification confirmed:

```text
no Reuters CanonicalFeedItem is created
no news-only CanonicalFeedItem is created
official TDnet canonical fields remain unchanged
Reuters overlay appears under item.overlays[] in the event overlay API
Reuters overlay appears under news_overlays[] in feed responses
canonical_fact_override remains false
attachment materialization is idempotent
fallback to Stage 5.1 raw projection works when no attachment rows exist
materialized attachment preference works when attachment rows exist
```

## Redaction evidence

Verification recorded:

```text
non-redacted Subscription-Key: not detected
Authorization header literal with secret value: not detected
Cookie header literal with secret value: not detected
secret-bearing files added: no
full Reuters article text storage: not added
provider request headers: not added
```

## Lock decision

The Stage 5.2 attachment storage slice is locked.

Locked means:

```text
news_overlay_attachments table is accepted
NewsOverlayAttachment schema and changeset guardrails are accepted
deterministic materializer from locked Stage 5.1 raw staging is accepted
read path preference for visible attachment rows is accepted
fallback to Stage 5.1 raw projection is accepted
API and feed response shapes remain compatible
official TDnet canonical item remains the source of truth
Reuters remains attach-only overlay context
```

## Still out of scope

The following remain out of scope after this lock:

```text
live Reuters fetch
provider API integration
Bloomberg backup fixture
multiple provider overlays
cross-source duplicate_group_key materialization
news-only canonical event creation
LLM-only duplicate decisions
social scraping
rumor ingestion
attachment admin/review UI
```

## Future work

Possible future stages:

```text
second news overlay fixture design
provider-backed news ingestion design
multiple overlay provider support
cross-source duplicate group materialization
attachment review/admin tooling
```
