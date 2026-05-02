# Stage 5.8 source health operator action contract manual smoke

This checklist verifies the pure Stage 5.8 provider source health operator action contract.

This is a manual-smoke document only. It does not add routes, UI, action endpoints, scheduler work, provider clients, live fetch code, source health mutation behavior, materializer changes, API behavior changes, feed behavior changes, or canonical feed mutations.

## Scope

```text
stage: Stage 5.8 PR B
scope: pure source health operator action contract
mode: pure runtime contract + targeted tests + manual smoke doc
runtime action endpoint: none
runtime authorization integration: none
DB writes: none
network calls: none
scheduler: none
live fetch: none
routes: none
UI: none
canonical mutation: none
```

## Files expected in this PR

```text
apps/backend/disclosure_api/lib/disclosure_automation/runtime/stage58_source_health_operator_action_contract.ex
apps/backend/disclosure_api/test/stage58_source_health_operator_action_contract_test.exs
apps/backend/disclosure_api/docs/stage58_source_health_operator_action_contract_manual_smoke.md
```

## Contract behavior smoke

Verify the contract locks these defaults:

```text
action_scope=operator_only: PASS
read_only_permission_allowed=false: PASS
action_permission_required=true: PASS
operator_reason_required=true: PASS
idempotency_required=true: PASS
audit_required=true: PASS
advisory_only=true: PASS
public_response_shape_mutation=false: PASS
trigger_live_fetch=false: PASS
scheduler_enabled=false: PASS
network_access=forbidden: PASS
action_endpoint_added=false: PASS
route_added=false: PASS
ui_added=false: PASS
source_health_mutation=false: PASS
canonical_feed_mutation=false: PASS
provider_canonical_feed_item_creation=false: PASS
news_only_event_creation=false: PASS
```

## Action envelope smoke

For a valid action request, verify:

```text
operation is required: PASS
source_key is required: PASS
operator_reason is required: PASS
idempotency_key is required: PASS
request_id is required: PASS
required_permission equals operation: PASS
expected_current_health_status is allowlisted when present: PASS
expected_current_operational_state is allowlisted when present: PASS
expected_current_redaction_status is allowlisted when present: PASS
operator_note_redacted is bounded when present: PASS
```

## Permission separation smoke

Verify read-only permissions cannot execute actions:

```text
source_health.view rejected as action operation: PASS
source_health.detail rejected as action operation: PASS
source_health.export_redacted rejected as action operation: PASS
unknown action operation rejected: PASS
```

Verify action operations are explicit and allowlisted:

```text
source_health.recheck accepted: PASS
source_health.pause accepted: PASS
source_health.resume accepted: PASS
source_health.acknowledge_manual_review accepted: PASS
source_health.clear_redaction_violation accepted: PASS
source_health.manual_provider_trigger accepted: PASS
source_health.export_redacted_diagnostics accepted: PASS
```

## No-side-effect option smoke

Verify the contract rejects opt-ins for future behavior that is outside this PR:

```text
public_exposure=true rejected: PASS
trigger_live_fetch=true rejected: PASS
use_live_fetch=true rejected: PASS
scheduler_enabled=true rejected: PASS
source_health_mutation=true rejected: PASS
canonical_feed_mutation=true rejected: PASS
provider_canonical_feed_item_creation=true rejected: PASS
news_only_event_creation=true rejected: PASS
action_endpoint_added=true rejected: PASS
route_added=true rejected: PASS
ui_added=true rejected: PASS
```

## Audit envelope smoke

Verify audit envelope output is bounded and redacted:

```text
audit_scope=operator_action_only: PASS
bounded=true: PASS
redacted=true: PASS
operation preserved: PASS
permission preserved: PASS
source_key preserved: PASS
request_id_hash emitted instead of raw request_id: PASS
idempotency_key_hash emitted instead of raw idempotency_key: PASS
operator_reason_redacted emitted: PASS
result_status defaults to pending: PASS
redaction_status defaults to unknown: PASS
canonical_feed_mutation=false: PASS
public_response_shape_mutation=false: PASS
```

## Redaction smoke

Verify the contract rejects:

```text
provider credentials
request headers
response headers
raw provider response bodies
full article text
signed private URLs
provider canonical creation payloads
canonical feed item payloads
secret-like string values
```

Allowed redacted placeholders in docs and tests:

```text
REDACTED_PROVIDER_KEY
REDACTED_PROVIDER_TOKEN
REDACTED_SUBSCRIPTION_KEY
```

## Regression command

Run targeted test:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage58_source_health_operator_action_contract_test.exs
```

Recommended nearby regressions:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage57_operator_view_projection_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage57_internal_source_health_projection_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage56_redacted_provider_result_adapter_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage56_manual_provider_adapter_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage55_offline_provider_health_evaluator_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage55_provider_health_state_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage54_offline_provider_staging_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage54_provider_ingestion_boundary_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage53_multi_overlay_response_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_feed_visible_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_api_exposure_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

## Changed-file guardrail

This PR may add only:

```text
apps/backend/disclosure_api/lib/disclosure_automation/runtime/stage58_source_health_operator_action_contract.ex
apps/backend/disclosure_api/test/stage58_source_health_operator_action_contract_test.exs
apps/backend/disclosure_api/docs/stage58_source_health_operator_action_contract_manual_smoke.md
```

It must not add or modify:

```text
fixtures
migrations
schema files
scheduler code
provider clients
live fetch code
routes
feed/controller code
UI code
action endpoints
materializer code
API behavior
feed behavior
canonical feed mutation behavior
```

## PASS criteria for this PR

```text
stage58 source health operator action contract test: PASS
stage57 operator view projection contract regression: PASS
stage57 internal source health projection regression: PASS
stage56 redacted provider result adapter regression: PASS
stage56 manual provider adapter contract regression: PASS
stage55 health evaluator regression: PASS
stage55 health state regression: PASS
stage54 offline provider staging regression: PASS
stage54 provider ingestion boundary regression: PASS
stage53 multi-overlay response contract regression: PASS
stage5 feed/API regressions: PASS
TDnet runtime/http regressions: PASS
changed-file strict redaction check: PASS
```
