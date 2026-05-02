# Stage 5.4 provider ingestion boundary manual smoke

This manual smoke verifies the Stage 5.4 offline provider ingestion boundary and redacted result contract.

## Scope

```text
stage: Stage 5.4 PR B
scope: offline provider ingestion boundary + redacted result contract
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
provider ingestion boundary module
boundary unit tests
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
canonical feed mutation
full article text storage
provider canonical feed item creation
news-only canonical event creation
```

## Step 1: run targeted Stage 5.4 boundary test

From:

```text
apps/backend/disclosure_api
```

Run:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage54_provider_ingestion_boundary_test.exs
```

Expected:

```text
all tests pass
```

The test should verify:

```text
use_live_fetch=false by default
network_access=forbidden
scheduler_enabled=false
overlay_mode=attach_only
canonical_feed_mutation=false
news_only_event_creation=false
canonical_fact_override=false
storage_mode=metadata_only
metadata-only provider results normalize successfully
request headers are rejected
full article body fields are rejected
nested credentials are rejected
secret-like header strings are rejected
non-allowlisted diagnostics are dropped
```

## Step 2: run Stage 5.3 response contract regression

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage53_multi_overlay_response_contract_test.exs
```

Expected:

```text
all tests pass
```

This confirms Stage 5.4 boundary work does not break locked multi-overlay response behavior.

## Step 3: run Stage 5.2 and Stage 5.1 core regressions

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

## Step 4: run TDnet regressions

```powershell
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

Expected:

```text
all tests pass
```

## Step 5: redaction check

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
Authorization: in prohibited-value tests or docs
Cookie: in prohibited-value tests or docs
```

## Step 6: changed-file guardrail

Changed files should be limited to:

```text
apps/backend/disclosure_api/lib/disclosure_automation/runtime/stage54_provider_ingestion_boundary.ex
apps/backend/disclosure_api/test/stage54_provider_ingestion_boundary_test.exs
apps/backend/disclosure_api/docs/stage54_provider_ingestion_boundary_manual_smoke.md
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
stage54 provider ingestion boundary test: PASS
stage53 multi-overlay response contract regression: PASS
stage52 read path/materializer regressions: PASS
stage5 feed/API regressions: PASS
TDnet runtime/http regressions: PASS
use_live_fetch default false: PASS
network access forbidden: PASS
request headers rejected: PASS
full article body rejected: PASS
credentials rejected: PASS
metadata-only normalized result: PASS
canonical no-mutation guardrail: PASS
redaction check: PASS
no live fetch code: PASS
no scheduler changes: PASS
no fixture changes: PASS
no migrations/schema changes: PASS
no routes/feed-controller endpoint changes: PASS
```
