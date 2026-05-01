# Stage 5.3 second news overlay fixture manual smoke

This manual smoke verifies the Stage 5.3 second news overlay fixture and source attrs only.

## Scope

```text
stage: Stage 5.3 PR A
scope: second fixture + source attrs only
provider: Bloomberg fixture metadata
source_key: stage53_news_overlay_fixture
adapter_key: stage53_news_overlay_fixture_v1
runtime staging: out of scope
materializer support: out of scope
API/feed response changes: out of scope
canonical_feed_mutation: false
news_only_event_creation: false
```

## Guardrails

This PR may add only:

```text
one second overlay fixture JSON
one source registry sample YAML
one source attrs loader module
fixture/source policy tests
manual smoke doc
```

It must not add:

```text
runtime staging changes
materializer changes
read path changes
feed/API shape changes
migrations
schema changes
provider/live fetches
scheduler changes
new routes
canonical feed mutation
provider canonical feed item creation
news-only canonical event creation
full article text storage
```

## Step 1: run targeted fixture policy test

From:

```text
apps/backend/disclosure_api
```

Run:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage53_second_news_overlay_fixture_test.exs
```

Expected:

```text
5 tests, 0 failures
```

## Step 2: run Stage 5.2 regressions

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage52_news_overlay_attachment_read_path_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage52_news_overlay_attachment_materializer_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage52_news_overlay_attachment_schema_test.exs
```

Expected:

```text
all tests pass
```

## Step 3: run Stage 5.1 regressions

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_feed_visible_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_api_exposure_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_read_model_query_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_raw_staging_runtime_idempotency_test.exs
```

Expected:

```text
all tests pass
```

## Step 4: run TDnet regressions

```powershell
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

Expected:

```text
all tests pass
```

## Step 5: verify source attrs

The source attrs should load:

```elixir
DisclosureAutomation.Ops.Stage53SecondNewsOverlayFixtureSource.attrs()
```

Expected:

```text
source_key: stage53_news_overlay_fixture
adapter_key: stage53_news_overlay_fixture_v1
default_source_tier: reputable_news_source
discovery_mode: fixture
hydrate_mode: local_fixture
config.overlay_mode: attach_only
config.storage_mode: raw_staging
config.canonical_feed_mutation: false
config.news_only_event_creation: false
config.fixtures.overlay_result: source_payloads/stage53_news_overlay_fixture_jp_tdnet_140120260430515474_bloomberg_jp_article_001.json
```

## Step 6: verify fixture payload

The fixture should contain exactly one overlay.

Expected:

```text
fixtureVersion: stage53_second_news_overlay_fixture_v1
sourceKey: stage53_news_overlay_fixture
adapterKey: stage53_news_overlay_fixture_v1
sourceTier: reputable_news_source
documentRole: news_article
networkAccess: forbidden
overlayMode: attach_only
newsOnlyEventCreation: false
canonicalFactOverride: false
overlays length: 1
```

Expected overlay identities:

```text
overlayId: news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:bloomberg-jp-article-001
articleExternalId: NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:bloomberg-jp-article-001
canonicalEventId: jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474
sourceKey: stage53_news_overlay_fixture
provider/sourceName: Bloomberg related news article fixture
articlePublishedAt: 2026-04-30T10:45:00Z
```

The fixture identities must not reuse the existing Reuters overlay id or article external id.

## Step 7: verify direct official match evidence

Expected direct identifiers:

```text
officialAnchor.eventId equals official TDnet event id
officialAnchor.stableExternalId equals TDnet stable external id
matchEvidence.matchedCanonicalEventId equals official TDnet event id
matchEvidence.matchedOfficialStableExternalId equals TDnet stable external id
```

## Step 8: verify no prohibited content

The fixture must not contain keys or values indicating:

```text
articleBody
fullText
rawHtml
providerResponseBody
scrapedText
paywalledArticleText
requestHeaders
responseHeaders
credentials
apiKey
authorization
Authorization
cookie
Cookie
subscriptionKey
Subscription-Key
BEGIN PRIVATE KEY
```

## Step 9: verify no runtime behavior changes

Because this PR is fixture/source attrs only, these must remain unchanged:

```text
no runtime staging support for Stage 5.3 fixture yet
no materializer support for Stage 5.3 fixture yet
no feed/API response shape change
no new route
no migration
no schema change
no canonical feed mutation
```

## PASS criteria

```text
Stage 5.3 second fixture policy test: PASS
Stage 5.2 read path regression: PASS
Stage 5.2 materializer regression: PASS
Stage 5.2 schema regression: PASS
Stage 5.1 feed-visible regression: PASS
Stage 5.1 API exposure regression: PASS
Stage 5.1 read model regression: PASS
Stage 5 raw-staging regression: PASS
TDnet runtime regression: PASS
TDnet HTTP smoke regression: PASS
fixture contains exactly one overlay: PASS
fixture has distinct Bloomberg identities: PASS
fixture direct official match evidence: PASS
no prohibited content/secrets: PASS
no runtime staging changes
no materializer changes
no migrations/schema changes
no feed/API shape changes
no canonical mutation
```
