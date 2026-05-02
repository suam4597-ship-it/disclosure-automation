# Stage 5.7 operator view projection contract manual smoke

This manual smoke verifies Stage 5.7 PR B: pure operator view projection contract and redacted field allowlist.

## Scope

```text
stage: Stage 5.7 PR B
scope: pure operator view projection contract
DB writes: forbidden
network calls: forbidden
scheduler: forbidden
routes/feed-controller changes: forbidden
UI code: forbidden
schema/migration changes: forbidden
canonical mutation: forbidden
```

## Guardrails

This PR may add only:

```text
operator view projection contract module
operator view projection contract unit tests
manual smoke doc
```

It must not add:

```text
runtime routes
feed/controller changes
UI code
provider clients
live fetch
scheduler changes
fixtures
migrations
schema changes
materializer changes
API response shape changes
feed response shape changes
canonical feed mutation
provider canonical feed item creation
news-only canonical event creation
full article text storage
DB writes
```

## Step 1: run targeted Stage 5.7 operator view projection contract test

From:

```text
apps/backend/disclosure_api
```

Run:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage57_operator_view_projection_contract_test.exs
```

Expected:

```text
all tests pass
```

The test should verify:

```text
operator-only defaults
read-only defaults
advisory-only defaults
no public response shape mutation
no live fetch trigger
no scheduler trigger
no source health mutation
no canonical mutation
allowed projection fields accepted
non-allowlisted fields dropped
allowed health states accepted
unknown health states rejected
credentials rejected
request headers rejected
response headers rejected
full article text rejected
raw provider response body rejected
secret-like values rejected
public exposure rejected
```

## Step 2: run Stage 5.6 regressions

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage56_redacted_provider_result_adapter_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage56_manual_provider_adapter_contract_test.exs
```

Expected:

```text
all tests pass
```

## Step 3: run Stage 5.5 health regressions

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage55_offline_provider_health_evaluator_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage55_provider_health_state_test.exs
```

Expected:

```text
all tests pass
```

## Step 4: run Stage 5.4 offline seam regressions

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage54_offline_provider_staging_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage54_provider_ingestion_boundary_test.exs
```

Expected:

```text
all tests pass
```

## Step 5: run Stage 5.3 response contract regression

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage53_multi_overlay_response_contract_test.exs
```

Expected:

```text
all tests pass
```

## Step 6: run core feed/API and TDnet regressions

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

## Step 7: changed-file guardrail

Changed files should be limited to:

```text
apps/backend/disclosure_api/lib/disclosure_automation/runtime/stage57_operator_view_projection_contract.ex
apps/backend/disclosure_api/test/stage57_operator_view_projection_contract_test.exs
apps/backend/disclosure_api/docs/stage57_operator_view_projection_contract_manual_smoke.md
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
UI code
```

## Step 8: redaction check

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
fullArticleText
```

## PASS criteria

```text
stage57 operator view projection contract test: PASS
stage56 redacted provider result adapter regression: PASS
stage56 manual provider adapter contract regression: PASS
stage55 health evaluator regression: PASS
stage55 health state regression: PASS
stage54 offline provider staging regression: PASS
stage54 provider ingestion boundary regression: PASS
stage53 multi-overlay response contract regression: PASS
stage5 feed/API regressions: PASS
TDnet runtime/http regressions: PASS
allowed projection fields accepted: PASS
forbidden fields rejected: PASS
read-only defaults preserved: PASS
public exposure rejected: PASS
live fetch trigger rejected: PASS
scheduler trigger rejected: PASS
no DB writes: PASS
no network calls: PASS
no scheduler changes: PASS
no route/feed/controller changes: PASS
no UI code: PASS
no migrations/schema changes: PASS
no materializer/API/feed behavior changes: PASS
canonical no-mutation guardrail: PASS
redaction check: PASS
```
