# Stage 5.4 offline provider staging manual smoke

This manual smoke verifies Stage 5.4 PR C: offline provider staging from the Stage 5.4 provider ingestion boundary result into raw staging tables.

## Scope

```text
stage: Stage 5.4 PR C
scope: offline provider staging test adapter
network calls: forbidden
scheduler: forbidden
provider credentials: forbidden
live provider fetch: forbidden
schema/migration changes: forbidden
routes/feed-controller changes: forbidden
canonical mutation: forbidden
```

## Guardrails

This PR may add only:

```text
Stage 5.4 offline provider raw staging module
Stage 5.4 offline provider staging tests
manual smoke doc
```

It must not add:

```text
live Reuters fetch
live Bloomberg fetch
provider credentials
provider request headers
provider clients that make network calls
scheduler changes
fixtures
migrations
schema changes
routes
feed/controller changes
materializer changes
API response shape changes
feed response shape changes
canonical feed mutation
full article text storage
provider canonical feed item creation
news-only canonical event creation
```

## Step 1: run targeted Stage 5.4 offline provider staging test

From:

```text
apps/backend/disclosure_api
```

Run:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage54_offline_provider_staging_test.exs
```

Expected:

```text
all tests pass
```

The test should verify:

```text
offline provider payload normalizes through Stage54ProviderIngestionBoundary
raw document is staged
raw event is staged
staging is idempotent
same provider article keeps one raw document
same provider article keeps one raw event
use_live_fetch=false
network_access=forbidden
scheduler_enabled=false
overlay_mode remains attach-only
canonical_feed_mutation=false
news_only_event_creation=false
canonical_fact_override=false
unsafe request headers are rejected before staging
live fetch opt-in is rejected before staging
```

## Step 2: run Stage 5.4 boundary regression

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage54_provider_ingestion_boundary_test.exs
```

Expected:

```text
all tests pass
```

## Step 3: run Stage 5.3 response contract regression

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage53_multi_overlay_response_contract_test.exs
```

Expected:

```text
all tests pass
```

## Step 4: run Stage 5.2 and Stage 5.1 core regressions

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage52_news_overlay_attachment_read_path_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage52_news_overlay_attachment_materializer_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_feed_visible_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_api_exposure_test.exs
```

Expected:

```text
all tests pass
```

## Step 5: run TDnet regressions

```powershell
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

Expected:

```text
all tests pass
```

## Step 6: raw staging checks

After staging the offline provider payload, verify:

```text
raw_documents count for source_key=stage54_offline_provider_fixture: 1
raw_events count for source_key=stage54_offline_provider_fixture: 1
raw document payload does not include articleBody
raw document payload does not include requestHeaders
raw document payload does not include credentials
raw event payload includes direct official match evidence
raw event payload includes canonical_feed_mutation=false
raw event payload includes news_only_event_creation=false
raw event payload includes canonical_fact_override=false
```

## Step 7: canonical no-mutation check

Expected storage state:

```text
canonical_feed_items where event_id = official TDnet event id: 1
canonical_feed_items where event_id = offline provider overlay id: 0
official TDnet title unchanged
official TDnet published_at unchanged
official TDnet official_source_url unchanged
```

## Step 8: redaction check

Inspect changed files and test output.

Must not expose:

```text
real Subscription-Key values
real Authorization header values
real Cookie header values
Reuters credentials
Bloomberg credentials
provider bearer tokens
signed private URLs
provider request headers
full article body text
```

Allowed redacted/negative-test strings:

```text
Subscription-Key in prohibited-key tests or docs
Authorization in prohibited-value tests or docs
Cookie in prohibited-value tests or docs
```

## Step 9: changed-file guardrail

Changed files should be limited to:

```text
apps/backend/disclosure_api/lib/disclosure_automation/runtime/stage54_offline_provider_raw_staging.ex
apps/backend/disclosure_api/test/stage54_offline_provider_staging_test.exs
apps/backend/disclosure_api/docs/stage54_offline_provider_staging_manual_smoke.md
```

No files should be changed under:

```text
priv/repo/migrations
lib/disclosure_automation/schema
lib/disclosure_automation_web/router.ex
lib/disclosure_automation_web/controllers
feed/controller implementation files
priv/fixtures
scheduler/provider live-fetch code
```

## PASS criteria

```text
stage54 offline provider staging test: PASS
stage54 provider ingestion boundary regression: PASS
stage53 multi-overlay response contract regression: PASS
stage52 read path/materializer regressions: PASS
stage5 feed/API regressions: PASS
TDnet runtime/http regressions: PASS
offline raw document idempotency: PASS
offline raw event idempotency: PASS
unsafe payload rejected before staging: PASS
live fetch opt-in rejected before staging: PASS
canonical no-mutation check: PASS
redaction check: PASS
no live fetch code: PASS
no scheduler changes: PASS
no fixture changes: PASS
no migrations/schema changes: PASS
no routes/feed-controller endpoint changes: PASS
no materializer/API/feed behavior changes: PASS
```
