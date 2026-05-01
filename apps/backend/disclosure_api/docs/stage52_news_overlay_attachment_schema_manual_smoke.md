# Stage 5.2 news overlay attachment schema manual smoke

This manual smoke verifies the Stage 5.2 migration and schema guardrails for the dedicated `news_overlay_attachments` table.

## Scope

```text
stage: Stage 5.2 PR A
scope: migration + schema + changeset tests
migration: create_news_overlay_attachments
schema: DisclosureAutomation.Schema.NewsOverlayAttachment
runtime materializer: out of scope
feed/API read path change: out of scope
canonical_feed_items mutation: forbidden
```

## Guardrails

This PR may add only:

```text
news_overlay_attachments migration
NewsOverlayAttachment schema
schema/changeset tests
manual smoke doc
```

It must not add:

```text
runtime materializer
feed/API read path switch
fixtures
scheduler changes
provider/live Reuters fetch
new routes
Reuters CanonicalFeedItem creation
news-only CanonicalFeedItem creation
canonical feed mutation
full Reuters article text storage
```

## Step 1: run the schema test

From:

```text
apps/backend/disclosure_api
```

Run:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage52_news_overlay_attachment_schema_test.exs
```

Expected:

```text
8 tests, 0 failures
```

## Step 2: run Stage 5.1 regressions

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

## Step 3: run TDnet regressions

```powershell
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

Expected:

```text
all tests pass
```

## Step 4: migration smoke

Reset or migrate a disposable dev/test DB and confirm the table exists.

Example:

```powershell
$env:MIX_ENV='test'; mix.bat ecto.reset
```

Then inspect through Ecto or psql-equivalent tooling:

```text
news_overlay_attachments exists
unique index on official_canonical_feed_item_id, overlay_source_key, overlay_external_id exists
unique index on official_event_id, overlay_id exists
check constraint canonical_fact_override=false exists
check constraint overlay_mode='attach_only' exists
check constraint display_state allowed list exists
check constraint source_tier='reputable_news_source' exists
check constraint document_role='news_article' exists
```

## Step 5: changeset guardrail smoke

In IEx/test context, a valid Stage 5.2 attachment changeset should pass with:

```text
canonical_fact_override=false
overlay_mode=attach_only
display_state=visible
source_tier=reputable_news_source
document_role=news_article
```

The changeset should reject:

```text
canonical_fact_override=true
overlay_mode=replace_official
unknown display_state
source_tier=unverified_social_media
document_role=official_disclosure
blank overlay_id
missing official/overlay identity fields
```

## Step 6: no behavior-change check

Because this PR is schema-only, existing Stage 5.1 behavior must remain unchanged:

```text
GET /api/events/:event_id/news-overlay still uses locked Stage 5.1 behavior
GET /api/feed/digest/latest?edition=breaking still returns locked news_overlays[] behavior
no materialized attachment rows are required for Stage 5.1 responses
```

## Step 7: redaction check

Check the diff and test output for accidental secret or article-text storage.

Must not expose:

```text
Subscription-Key values
Authorization header values
Cookie header values
Reuters credentials
EDINET keys
signed private URLs
full Reuters article text
provider request headers
```

## PASS criteria

```text
Stage 5.2 attachment schema test: PASS
Stage 5.1 feed-visible regression: PASS
Stage 5.1 API exposure regression: PASS
Stage 5.1 read model regression: PASS
Stage 5 raw-staging regression: PASS
TDnet runtime regression: PASS
TDnet HTTP smoke regression: PASS
migration smoke: PASS
no runtime materializer added
no feed/API read path switch added
no fixtures changed
no scheduler changes
no provider/live Reuters fetch
no canonical mutation
redaction check: PASS
```
