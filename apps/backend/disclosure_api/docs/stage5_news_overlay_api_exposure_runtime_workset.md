# Stage 5.1 news overlay API exposure runtime workset

This document defines the recommended runtime workset for exposing the locked Stage 5.1 news overlay read model through an additive API route.

This is a planning document only. It does not add router code, controller code, serializer code, runtime code, tests, fixtures, database migrations, schedulers, feed rendering implementation, provider fetches, or canonical feed mutations.

## Baseline

```text
base branch: sec-thin-slice-reconcile-v1
base commit: 65b3bb3788fb767d7d84671d8ade13ae12477e4f
base commit source: PR #82 Lock Stage 5.1 news overlay read model query
locked read model: DisclosureAutomation.Runtime.Stage5NewsOverlayReadModel
read model implementation PR: #81
read model lock PR: #82
stage: Stage 5.1 API exposure runtime workset
status: design-only
```

## Recommended next implementation PR

Recommended title:

```text
Expose Stage 5.1 news overlay read model API
```

Recommended branch:

```text
chatgpt-stage5-news-overlay-api-exposure-v1
```

## Allowed implementation scope

Allowed files for the next implementation PR:

```text
router route addition
new EventNewsOverlayController or equivalent existing-controller action
JSON serializer/view changes for the locked read model response
controller/API tests
manual smoke doc or update
```

Allowed behavior:

```text
GET /api/events/:event_id/news-overlay
call Stage5NewsOverlayReadModel.get_by_event_id/1
return 200 with official item and overlays[]
return 404 when official event is missing
preserve official/overlay source namespaces
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
feed rendering implementation
dedicated overlay attachment table
full Reuters article text storage
Reuters canonical feed item creation
news-only canonical event creation
canonical feed item mutation
LLM-only duplicate decisions
social scraping
rumor ingestion
```

## Required route contract

First route:

```text
GET /api/events/:event_id/news-overlay
```

Recommended response states:

```text
200 OK with item.overlays=[] when no overlay exists
200 OK with one Reuters overlay when raw-staged overlay exists and direct official identifier match passes
404 Not Found when official canonical event does not exist
```

The first implementation should not alter existing event or feed endpoints.

## Required controller tests

The next implementation PR should add tests covering:

```text
GET /api/events/:event_id/news-overlay returns 200 for official TDnet event without overlay
response item.overlays is [] before Reuters raw staging
GET /api/events/:event_id/news-overlay returns 200 with one Reuters overlay after staging
response item.sourceKey remains jp_tdnet_timely_disclosure
response item.title remains official TDnet title
response item.publishedAt remains official TDnet published_at
response item.canonicalUrl remains official TDnet URL
response item.overlays[0].sourceKey is stage5_news_overlay_fixture
response item.overlays[0].provider is Reuters
response item.overlays[0].canonicalFactOverride is false
response keeps official and overlay citations separate
GET /api/events/:missing_event_id/news-overlay returns 404
```

## Required regression tests

Run these after implementation:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_api_exposure_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_read_model_query_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_raw_staging_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

The actual API test filename may differ, but it should be dedicated to Stage 5.1 API exposure.

## Required manual smoke

Manual smoke should verify:

```text
official TDnet event returns 200 before overlay staging
overlays is [] before overlay staging
Reuters raw staging command still stages exactly one overlay
official TDnet event returns 200 with one overlay after overlay staging
Reuters overlay appears only under item.overlays[]
official title, publishedAt, canonicalUrl, sourceKey remain unchanged
Reuters URL is not item.canonicalUrl
Reuters publishedAt is not item.publishedAt
no Reuters CanonicalFeedItem exists
missing official event returns 404
```

## Required redaction check

The next implementation PR should verify the API response and logs do not expose:

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
changed files match the allowed API/controller/test/doc scope
no migrations are present
no fixture changes are present
no scheduler changes are present
no provider fetch integration is present
no feed rendering implementation is present
all targeted API tests pass
Stage 5.1 read model regression passes
Stage 5 raw-staging regression passes
TDnet regressions pass
redaction check passes
manual smoke evidence is recorded
PR is mergeable
```

## Close-out after implementation

After a successful implementation merge, create a docs-only close-out PR that records:

```text
implementation PR number
implementation merge SHA
changed files
API route exposed
PASS evidence
canonical no-mutation evidence
redaction evidence
remaining out-of-scope items
runtime lock status
```

## Future work after API exposure

Only after the API route is locked should the feed-visible rendering implementation proceed.

Future candidate:

```text
Stage 5.1 feed-visible rendering implementation
```

Still separate future stages:

```text
Stage 5.2 dedicated overlay attachment table design
second overlay fixture
provider-backed news ingestion
cross-source duplicate group materialization
```
