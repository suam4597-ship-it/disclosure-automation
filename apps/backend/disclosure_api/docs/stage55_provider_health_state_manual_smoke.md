# Stage 5.5 provider health state contract manual smoke

This manual smoke verifies Stage 5.5 PR B: provider health state contract and redacted diagnostic validation.

## Scope

```text
stage: Stage 5.5 PR B
scope: pure provider health state contract + validation tests
DB writes: forbidden
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
provider health state contract module
provider health state unit tests
manual smoke doc
```

It must not add:

```text
live provider fetch
provider credentials
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
provider canonical feed item creation
news-only canonical event creation
full article text storage
DB writes
```

## Step 1: run targeted Stage 5.5 provider health state test

From:

```text
apps/backend/disclosure_api
```

Run:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage55_provider_health_state_test.exs
```

Expected:

```text
all tests pass
```

The test should verify:

```text
safe default state is unknown
allowed states are accepted
unknown unsafe states are rejected
redacted diagnostic allowlist is enforced
non-allowlisted diagnostic metadata is dropped
request headers are rejected
credentials are rejected
full article text is rejected
secret-like diagnostic values are rejected
live fetch opt-in is rejected
scheduler opt-in is rejected
redaction_violation helper returns safe advisory state
```

## Step 2: run Stage 5.4 offline seam regressions

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage54_offline_provider_staging_test.exs
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

## Step 4: run core feed/API and TDnet regressions

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

## Step 5: changed-file guardrail

Changed files should be limited to:

```text
apps/backend/disclosure_api/lib/disclosure_automation/runtime/stage55_provider_health_state.ex
apps/backend/disclosure_api/test/stage55_provider_health_state_test.exs
apps/backend/disclosure_api/docs/stage55_provider_health_state_manual_smoke.md
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

## Step 6: redaction check

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
Subscription-Key
Authorization
Cookie
requestHeaders
credentials
fullArticleText
```

## PASS criteria

```text
stage55 provider health state test: PASS
stage54 offline provider staging regression: PASS
stage54 provider ingestion boundary regression: PASS
stage53 multi-overlay response contract regression: PASS
stage5 feed/API regressions: PASS
TDnet runtime/http regressions: PASS
allowed state validation: PASS
unsafe state rejection: PASS
redacted diagnostic allowlist: PASS
request headers rejected: PASS
credentials rejected: PASS
full article text rejected: PASS
live fetch opt-in rejected: PASS
scheduler opt-in rejected: PASS
redaction violation helper: PASS
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
