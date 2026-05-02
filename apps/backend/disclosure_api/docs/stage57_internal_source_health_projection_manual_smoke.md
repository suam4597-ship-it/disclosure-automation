# Stage 5.7 internal source health projection manual smoke

This manual smoke verifies Stage 5.7 PR C: internal read-only source health projection using existing `Sources` functions.

## Scope

```text
stage: Stage 5.7 PR C
scope: internal read-only source health projection
public routes: forbidden
UI code: forbidden
live fetch: forbidden
scheduler: forbidden
source health mutation: forbidden
schema/migration changes: forbidden
feed/controller changes: forbidden
canonical mutation: forbidden
```

## Guardrails

This PR may add only:

```text
internal source health projection module
internal source health projection unit/integration tests
manual smoke doc
```

It must not add:

```text
public routes
UI code
provider clients
live fetch
scheduler changes
fixtures
migrations
schema changes
feed/controller changes
materializer changes
API response shape changes
feed response shape changes
canonical feed mutation
provider canonical feed item creation
news-only canonical event creation
full article text storage
```

## Step 1: run targeted Stage 5.7 internal source health projection test

From:

```text
apps/backend/disclosure_api
```

Run:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage57_internal_source_health_projection_test.exs
```

Expected:

```text
all tests pass
```

The test should verify:

```text
projection wraps Sources.list_source_health/1
projection wraps Sources.get_source_health/1
projection output passes Stage57OperatorViewProjectionContract
projection output is operator-only
projection output is read-only
projection output is advisory-only
projection output is redacted
projection includes allowed fields only
projection includes cursor_keys on detail view
projection does not mutate source health
public exposure opt-in is rejected
live fetch opt-in is rejected
scheduler opt-in is rejected
source health mutation opt-in is rejected
missing source returns not_found
```

## Step 2: run Stage 5.7 projection contract regression

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage57_operator_view_projection_contract_test.exs
```

Expected:

```text
all tests pass
```

## Step 3: run Stage 5.6 regressions

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage56_redacted_provider_result_adapter_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage56_manual_provider_adapter_contract_test.exs
```

Expected:

```text
all tests pass
```

## Step 4: run Stage 5.5 health regressions

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage55_offline_provider_health_evaluator_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage55_provider_health_state_test.exs
```

Expected:

```text
all tests pass
```

## Step 5: run Stage 5.4 offline seam regressions

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage54_offline_provider_staging_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage54_provider_ingestion_boundary_test.exs
```

Expected:

```text
all tests pass
```

## Step 6: run Stage 5.3 response contract regression

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage53_multi_overlay_response_contract_test.exs
```

Expected:

```text
all tests pass
```

## Step 7: run core feed/API and TDnet regressions

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

## Step 8: changed-file guardrail

Changed files should be limited to:

```text
apps/backend/disclosure_api/lib/disclosure_automation/runtime/stage57_internal_source_health_projection.ex
apps/backend/disclosure_api/test/stage57_internal_source_health_projection_test.exs
apps/backend/disclosure_api/docs/stage57_internal_source_health_projection_manual_smoke.md
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

## Step 9: redaction check

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

## PASS criteria

```text
stage57 internal source health projection test: PASS
stage57 operator view projection contract regression: PASS
stage56 redacted provider result adapter regression: PASS
stage56 manual provider adapter contract regression: PASS
stage55 health evaluator regression: PASS
stage55 health state regression: PASS
stage54 offline provider staging regression: PASS
stage54 provider ingestion boundary regression: PASS
stage53 multi-overlay response contract regression: PASS
stage5 feed/API regressions: PASS
TDnet runtime/http regressions: PASS
list projection read-only: PASS
detail projection read-only: PASS
cursor_keys projected: PASS
operator-only defaults preserved: PASS
public exposure rejected: PASS
live fetch rejected: PASS
scheduler rejected: PASS
source health mutation rejected: PASS
no public routes: PASS
no UI code: PASS
no scheduler changes: PASS
no migrations/schema changes: PASS
no materializer/API/feed behavior changes: PASS
canonical no-mutation guardrail: PASS
redaction check: PASS
```
