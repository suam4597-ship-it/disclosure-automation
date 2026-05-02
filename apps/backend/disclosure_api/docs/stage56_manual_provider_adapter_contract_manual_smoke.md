# Stage 5.6 manual provider adapter contract manual smoke

This manual smoke verifies Stage 5.6 PR B: manual provider adapter behavior and fake transport contract.

## Scope

```text
stage: Stage 5.6 PR B
scope: manual provider adapter behavior + fake transport contract
real network calls: forbidden
real provider credentials: forbidden
scheduler: forbidden
schema/migration changes: forbidden
routes/feed-controller changes: forbidden
materializer changes: forbidden
canonical mutation: forbidden
```

## Guardrails

This PR may add only:

```text
manual provider adapter contract module
manual provider adapter contract unit tests
manual smoke doc
```

It must not add:

```text
real provider HTTP client
real provider credentials
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
provider canonical feed item creation
news-only canonical event creation
full article text storage
DB writes
```

## Step 1: run targeted Stage 5.6 manual provider adapter contract test

From:

```text
apps/backend/disclosure_api
```

Run:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage56_manual_provider_adapter_contract_test.exs
```

Expected:

```text
all tests pass
```

The test should verify:

```text
fake transport accepted
manual trigger required
real transport rejected by default
live fetch opt-in rejected
scheduler opt-in rejected
bounded timeout enforced
bounded retry count enforced
credentials rejected
request headers rejected
response headers rejected
raw response body rejected
fake transport result remains metadata-only
canonical_feed_mutation=false
news_only_event_creation=false
canonical_fact_override=false
```

## Step 2: run Stage 5.5 health regressions

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage55_offline_provider_health_evaluator_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage55_provider_health_state_test.exs
```

Expected:

```text
all tests pass
```

## Step 3: run Stage 5.4 offline seam regressions

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage54_offline_provider_staging_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage54_provider_ingestion_boundary_test.exs
```

Expected:

```text
all tests pass
```

## Step 4: run Stage 5.3 response contract regression

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage53_multi_overlay_response_contract_test.exs
```

Expected:

```text
all tests pass
```

## Step 5: run core feed/API and TDnet regressions

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_feed_visible_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_api_exposure_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

Expected:

```text
all tests pass
```

## Step 6: changed-file guardrail

Changed files should be limited to:

```text
apps/backend/disclosure_api/lib/disclosure_automation/runtime/stage56_manual_provider_adapter_contract.ex
apps/backend/disclosure_api/test/stage56_manual_provider_adapter_contract_test.exs
apps/backend/disclosure_api/docs/stage56_manual_provider_adapter_contract_manual_smoke.md
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
materializer code
```

## Step 7: redaction check

Inspect changed files and test output.

Must not expose real values for:

```text
Subscription-Key
Authorization
Cookie
provider credentials
request headers
response headers
signed private URLs
full article body text
raw provider response bodies
```

Allowed only in negative-test or prohibited-field documentation contexts:

```text
requestHeaders
responseHeaders
credentials
rawResponseBody
```

## PASS criteria

```text
stage56 manual provider adapter contract test: PASS
stage55 health evaluator regression: PASS
stage55 health state regression: PASS
stage54 offline provider staging regression: PASS
stage54 provider ingestion boundary regression: PASS
stage53 multi-overlay response contract regression: PASS
stage5 feed/API regressions: PASS
TDnet runtime/http regressions: PASS
fake transport accepted: PASS
manual trigger required: PASS
real transport rejected: PASS
live fetch opt-in rejected: PASS
scheduler opt-in rejected: PASS
bounded timeout enforced: PASS
bounded retry enforced: PASS
credentials rejected: PASS
request headers rejected: PASS
response headers rejected: PASS
raw response body rejected: PASS
metadata-only fake result: PASS
no DB writes: PASS
no network calls: PASS
no scheduler changes: PASS
no fixture changes: PASS
no migrations/schema changes: PASS
no routes/feed-controller endpoint changes: PASS
no materializer/API/feed behavior changes: PASS
canonical no-mutation guardrail: PASS
redaction check: PASS
```
