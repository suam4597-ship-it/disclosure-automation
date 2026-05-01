# Stage 5.1 news overlay API exposure lock close-out

This document locks the Stage 5.1 additive API route/controller exposure for the locked news overlay read model.

This is a close-out document only. It does not add router code, controller code, serializer code, runtime code, tests, fixtures, database migrations, schedulers, feed rendering implementation, provider fetches, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: a4bc1de6ae139c66248447a604bde03f16438472
base commit source: PR #83 Stage 5.1 news overlay API exposure design
implementation PR: #84 Expose Stage 5.1 news overlay read model API
implementation head SHA: 3b3633394d6c0c8ad4340716d553af9f522ba874
implementation merge SHA: d4c56f588c576f3d2959cc4b085240eddb0723d5
runtime lock status: locked by this close-out
```

## Locked implementation scope

```text
route: GET /api/events/:event_id/news-overlay
controller: DisclosureAutomationWeb.EventNewsOverlayController
read model: DisclosureAutomation.Runtime.Stage5NewsOverlayReadModel
read path: Stage5NewsOverlayReadModel.get_by_event_id/1
mode: additive API exposure
overlay_mode: attach_only
canonical_feed_mutation: false
news_only_event_creation: false
canonicalFactOverride: false
```

## Added implementation files

PR #84 changed exactly these files:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/router.ex
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers/event_news_overlay_controller.ex
apps/backend/disclosure_api/test/stage5_news_overlay_api_exposure_test.exs
apps/backend/disclosure_api/docs/stage5_news_overlay_api_exposure_manual_smoke.md
```

No migration, fixture, scheduler, provider fetch, feed rendering, dedicated overlay table, or storage mutation files were added.

## Behavior locked

The Stage 5.1 API exposure locks these behaviors:

```text
GET /api/events/:event_id/news-overlay returns the locked read model response
GET /api/events/:event_id/news-overlay returns 200 with item.overlays=[] before Reuters raw staging
GET /api/events/:event_id/news-overlay returns 200 with one Reuters overlay after Reuters raw staging
GET /api/events/:event_id/news-overlay returns 404 when the official event does not exist
existing GET /api/events/:event_id behavior remains unchanged
GET request does not poll, stage, fetch, or mutate storage
```

## JSON serialization boundary

The first verification run found a controller JSON boundary issue:

```text
Jason.EncodeError for binary UUID/id values in the read model response
```

The implementation was fixed so the API controller converts the response to JSON-safe values before calling `Phoenix.Controller.json/2`.

Locked behavior:

```text
binary UUID/id values are serialized as UUID strings
invalid non-UTF8 binary values are not passed directly to Jason
```

## Official anchor preserved

The official TDnet canonical item remains the parent and source of official facts.

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

The API must not replace these official values with Reuters values.

## Overlay response preserved

The Reuters overlay remains namespaced under the API response:

```text
item.overlays[]
```

Locked overlay response properties:

```text
overlay_id: news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57
article_external_id: NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001
source_key: stage5_news_overlay_fixture
provider: Reuters
source_tier: reputable_news_source
document_role: news_article
canonicalFactOverride: false
displayState: visible when direct official identifier match passes
```

The Reuters URL remains an overlay URL and must not replace `item.canonicalUrl`.

## Verification summary

Verification was recorded on PR #84 after the JSON serialization fix.

```text
verified branch: chatgpt-stage5-news-overlay-api-exposure-v1
verified head SHA: 3b3633394d6c0c8ad4340716d553af9f522ba874
verification comment id: 4360277657
```

Results:

```text
stage5 API exposure test: PASS
stage5 read model query regression: PASS
stage5 raw-staging idempotency regression: PASS
TDnet runtime idempotency regression: PASS
TDnet HTTP smoke regression: PASS
no migrations: PASS
no fixture changes: PASS
no scheduler changes: PASS
no provider/live Reuters fetch: PASS
no feed rendering implementation: PASS
canonical no-mutation check: PASS
redaction check: PASS
existing /api/events/:event_id unchanged: PASS
```

Command results:

```text
test/stage5_news_overlay_api_exposure_test.exs: 3 tests, 0 failures
test/stage5_news_overlay_read_model_query_test.exs: 3 tests, 0 failures
test/stage5_news_overlay_raw_staging_runtime_idempotency_test.exs: 1 test, 0 failures
test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs: 1 test, 0 failures
test/jp_tdnet_timely_disclosure_http_smoke_test.exs: 1 test, 0 failures
```

## No-mutation evidence

The verification confirmed:

```text
no Reuters CanonicalFeedItem is created
official TDnet canonical fields remain unchanged
Reuters overlay appears only under item.overlays[]
canonicalFactOverride remains false
official TDnet citation remains before Reuters overlay citation
existing /api/events/:event_id remains unchanged
```

## Redaction evidence

The verification recorded:

```text
non-redacted Subscription-Key: not detected
Authorization header literal with secret value: not detected
Cookie header literal with secret value: not detected
secret-bearing files added: no
full Reuters article text storage: not added
provider request headers: not added
```

## Lock decision

The Stage 5.1 API exposure slice is locked.

Locked means:

```text
additive API route is accepted
GET /api/events/:event_id/news-overlay exposes the locked read model
response is JSON-safe at the controller boundary
raw-staged Reuters overlay can be returned under item.overlays[]
official TDnet canonical item remains unchanged
no Reuters canonical event is created
no news-only canonical event is created
no feed rendering implementation is added
no live Reuters fetch is added
no full Reuters article text is stored
```

## Still out of scope

The following remain out of scope after this lock:

```text
feed-visible rendering implementation
dedicated news_overlay_attachments table
database migrations
live Reuters fetch
provider API integration
Bloomberg backup fixture
multiple provider overlays
cross-source duplicate_group_key materialization
news-only canonical event creation
LLM-only duplicate decisions
social scraping
rumor ingestion
```

## Future work

The next stage may start only after a new design or implementation PR defines one of these separately:

```text
Stage 5.1 feed-visible rendering design/implementation using the locked API route
Stage 5.2 dedicated overlay attachment table design
second news overlay fixture
provider-backed news ingestion
cross-source duplicate group materialization
```
