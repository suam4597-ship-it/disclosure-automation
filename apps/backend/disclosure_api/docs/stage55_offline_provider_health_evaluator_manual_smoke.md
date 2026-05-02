# Stage 5.5 offline provider health evaluator manual smoke

This manual smoke verifies Stage 5.5 PR C: offline provider health evaluation from redacted diagnostics.

## Scope

```text
stage: Stage 5.5 PR C
scope: offline provider health evaluator using redacted diagnostics
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
offline provider health evaluator module
offline provider health evaluator unit tests
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

## Step 1: run targeted Stage 5.5 offline provider health evaluator test

From:

```text
apps/backend/disclosure_api
```

Run:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage55_offline_provider_health_evaluator_test.exs
```

Expected:

```text
all tests pass
```

The test should verify:

```text
success diagnostics -> healthy
partial metadata -> degraded
rate limit diagnostics -> rate_limited
timeout diagnostics -> timeout
error diagnostics -> failed
redaction violation -> redaction_violation
ambiguous match -> manual_review_required
missing match -> manual_review_required
paused source -> paused
unknown state remains unknown
invalid state is rejected by Stage55ProviderHealthState
live fetch opt-in is rejected
scheduler opt-in is rejected
```

## Step 2: run Stage 5.5 health state contract regression

```powershell
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
apps/backend/disclosure_api/lib/disclosure_automation/runtime/stage55_offline_provider_health_evaluator.ex
apps/backend/disclosure_api/test/stage55_offline_provider_health_evaluator_test.exs
apps/backend/disclosure_api/docs/stage55_offline_provider_health_evaluator_manual_smoke.md
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
Subscription-Key
Authorization
Cookie
credentials
fullArticleText
```

## PASS criteria

```text
stage55 offline provider health evaluator test: PASS
stage55 provider health state contract regression: PASS
stage54 offline provider staging regression: PASS
stage54 provider ingestion boundary regression: PASS
stage53 multi-overlay response contract regression: PASS
stage5 feed/API regressions: PASS
TDnet runtime/http regressions: PASS
healthy mapping: PASS
degraded mapping: PASS
rate_limited mapping: PASS
timeout mapping: PASS
failed mapping: PASS
redaction_violation mapping: PASS
manual_review_required mapping: PASS
paused mapping: PASS
unknown fallback: PASS
invalid state rejection: PASS
live fetch opt-in rejected: PASS
scheduler opt-in rejected: PASS
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
