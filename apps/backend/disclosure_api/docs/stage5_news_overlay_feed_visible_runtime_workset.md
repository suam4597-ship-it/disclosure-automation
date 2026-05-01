# Stage 5.1 news overlay feed-visible runtime workset

This document defines the recommended runtime workset for making the locked Stage 5.1 news overlay visible in feed-facing responses.

This is a planning document only. It does not add feed controller code, route code, renderer code, runtime code, tests, fixtures, database migrations, schedulers, provider fetches, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: f2c2091e863095b1f2781370541e269bac82da4a
base commit source: PR #85 Lock Stage 5.1 news overlay API exposure
locked API route: GET /api/events/:event_id/news-overlay
locked read model: DisclosureAutomation.Runtime.Stage5NewsOverlayReadModel
stage: Stage 5.1 feed-visible runtime workset
status: design-only
```

## Recommended next implementation PR

Recommended title:

```text
Expose Stage 5.1 news overlay in feed responses
```

Recommended branch:

```text
chatgpt-stage5-news-overlay-feed-visible-v1
```

## Allowed implementation scope

Allowed files for the next implementation PR:

```text
feed digest serialization/renderer code
feed controller response shaping code if needed
small helper for mapping read model overlays into feed item overlay objects
feed API tests
manual smoke doc
```

Allowed behavior:

```text
add news_overlays[] to feed item JSON
call locked Stage5NewsOverlayReadModel by event_id for feed items
preserve existing official feed item fields
preserve item count and ordering
return [] when no overlay exists
return one Reuters overlay when raw-staged overlay exists
```

## Disallowed implementation scope

The next implementation PR must not include:

```text
database migrations
fixture changes
scheduler changes
new source adapters
live Reuters fetch
provider API integration
new feed routes
dedicated overlay attachment table
full Reuters article text storage
Reuters canonical feed item creation
news-only canonical event creation
canonical feed item mutation
LLM-only duplicate decisions
social scraping
rumor ingestion
```

## Preferred implementation approach

The implementation should decorate feed item responses after official items are selected.

Recommended flow:

```text
1. Build existing digest/feed item list exactly as today.
2. For each item event_id, call Stage5NewsOverlayReadModel.get_by_event_id/1.
3. Map read model overlays into feed overlay objects.
4. Add news_overlays[] to the item.
5. Do not change item ranking, filtering, count, or official fields.
```

If a read model call returns not found for an item, treat it as:

```text
news_overlays: []
```

Do not fail the whole feed response.

## Required API tests

The implementation PR should add tests covering:

```text
GET /api/feed/digest/latest?edition=breaking returns existing TDnet item with news_overlays=[] before Reuters staging
GET /api/feed/digest/latest?edition=breaking returns existing TDnet item with one Reuters overlay after staging
item_count remains 1 for the locked fixture case
item event_id remains official TDnet event id
item headline/title remains official TDnet title
item published_at_utc remains official TDnet timestamp
item official_source_url remains official TDnet URL
item source_meta.stable_external_id remains TDnet stable external id
news_overlays[0].source_key is stage5_news_overlay_fixture
news_overlays[0].provider is Reuters
news_overlays[0].canonical_fact_override is false
Reuters URL does not replace official_source_url
existing /api/events/:event_id/news-overlay still passes
existing /api/events/:event_id still passes
```

## Required regression tests

Run these after implementation:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_feed_visible_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_api_exposure_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_read_model_query_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_raw_staging_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

The actual feed-visible test filename may differ, but it should be dedicated to Stage 5.1 feed response behavior.

## Required manual smoke

Manual smoke should verify:

```text
official TDnet digest item appears before Reuters overlay staging
news_overlays is [] before Reuters overlay staging
Reuters raw staging command still stages exactly one overlay
official TDnet digest item appears after Reuters overlay staging
news_overlays has exactly one Reuters overlay after staging
item_count unchanged
item ordering unchanged
official fields unchanged
portable_citations unchanged as official citations
overlay citations live under news_overlays[].citations[]
existing event overlay API route still works
```

## Required redaction check

The next implementation PR should verify feed responses and logs do not expose:

```text
Subscription-Key values
Authorization header values
Cookie header values
Reuters credentials
EDINET keys
signed private URLs
full Reuters article text
provider request headers
raw stack traces in JSON responses
```

## Merge criteria

The next implementation PR should only be merged if:

```text
changed files match the allowed feed response/test/doc scope
no migrations are present
no fixture changes are present
no scheduler changes are present
no provider fetch integration is present
no new routes are added unless separately justified
all targeted feed-visible tests pass
Stage 5.1 API exposure regression passes
Stage 5.1 read model regression passes
Stage 5 raw-staging regression passes
TDnet regressions pass
redaction check passes
manual smoke evidence is recorded
PR is mergeable
```

## Close-out after implementation

After successful implementation merge, create a docs-only close-out PR recording:

```text
implementation PR number
implementation merge SHA
changed files
feed response field exposed
PASS evidence
canonical no-mutation evidence
redaction evidence
remaining out-of-scope items
runtime lock status
```

## Future work after feed-visible rendering

After feed-visible rendering is locked, possible future work includes:

```text
Stage 5.2 dedicated overlay attachment table design
second news overlay fixture
provider-backed news ingestion
cross-source duplicate_group_key materialization
multiple overlay providers in feed responses
```
