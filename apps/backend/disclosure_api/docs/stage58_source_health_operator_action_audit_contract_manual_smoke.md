# Stage 5.8 source health operator action audit contract manual smoke

This checklist verifies the pure Stage 5.8 provider source health operator action audit contract.

This is a manual-smoke document only. It does not add routes, UI, action endpoints, runtime authorization integration, DB writes, scheduler work, provider clients, live fetch code, source health mutation behavior, materializer changes, API behavior changes, feed behavior changes, or canonical feed mutations.

## Scope

```text
stage: Stage 5.8 PR C
scope: pure source health operator action audit contract
mode: pure runtime contract + targeted tests + manual smoke doc
runtime action endpoint: none
runtime authorization integration: none
DB writes: none
audit writes: none
network calls: none
scheduler: none
live fetch: none
routes: none
UI: none
canonical mutation: none
```

## Files expected in this PR

```text
apps/backend/disclosure_api/lib/disclosure_automation/runtime/stage58_source_health_operator_action_audit_contract.ex
apps/backend/disclosure_api/test/stage58_source_health_operator_action_audit_contract_test.exs
apps/backend/disclosure_api/docs/stage58_source_health_operator_action_audit_contract_manual_smoke.md
```

## Contract behavior smoke

Verify the audit contract locks these defaults:

```text
audit_scope=operator_action_audit_only: PASS
bounded=true: PASS
redacted=true: PASS
action_attempt_recorded=true: PASS
operator_only=true: PASS
advisory_only=true: PASS
public_response_shape_mutation=false: PASS
trigger_live_fetch=false: PASS
scheduler_enabled=false: PASS
network_access=forbidden: PASS
audit_write_performed=false: PASS
source_health_mutation=false: PASS
canonical_feed_mutation=false: PASS
provider_canonical_feed_item_creation=false: PASS
news_only_event_creation=false: PASS
action_endpoint_added=false: PASS
route_added=false: PASS
ui_added=false: PASS
```

## Audit event field smoke

For a valid action audit event, verify:

```text
operation is required: PASS
permission is required: PASS
permission must match operation: PASS
source_key is required and bounded: PASS
actor_id_hash is required and must be hash-shaped: PASS
request_id_hash is required and must be hash-shaped: PASS
idempotency_key_hash is required and must be hash-shaped: PASS
operator_reason_redacted is required and bounded: PASS
result_status is required and allowlisted: PASS
redaction_status is required and allowlisted: PASS
pre_action_health_status is allowlisted when present: PASS
post_action_health_status is allowlisted when present: PASS
pre_action_operational_state is allowlisted when present: PASS
post_action_operational_state is allowlisted when present: PASS
failure_code_redacted is bounded when present: PASS
started_at is bounded when present: PASS
completed_at is bounded when present: PASS
```

## Raw identifier rejection smoke

Verify the audit contract rejects raw identifiers and unredacted reason fields:

```text
actor_id rejected: PASS
request_id rejected: PASS
idempotency_key rejected: PASS
operator_reason rejected: PASS
operator_note rejected: PASS
```

Only the following bounded redacted/hash fields are allowed:

```text
actor_id_hash
request_id_hash
idempotency_key_hash
operator_reason_redacted
failure_code_redacted
```

## Permission separation smoke

Verify read-only permissions cannot be audited as source health actions:

```text
source_health.view rejected as action audit operation: PASS
source_health.detail rejected as action audit operation: PASS
source_health.export_redacted rejected as action audit operation: PASS
read-only permission cannot authorize action audit: PASS
permission mismatch rejected: PASS
unknown operation rejected: PASS
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

Verify the contract rejects opt-ins for behavior that is outside this PR:

```text
public_exposure=true rejected: PASS
trigger_live_fetch=true rejected: PASS
use_live_fetch=true rejected: PASS
scheduler_enabled=true rejected: PASS
db_write=true rejected: PASS
audit_write_performed=true rejected: PASS
network_access=true rejected: PASS
source_health_mutation=true rejected: PASS
canonical_feed_mutation=true rejected: PASS
provider_canonical_feed_item_creation=true rejected: PASS
news_only_event_creation=true rejected: PASS
action_endpoint_added=true rejected: PASS
route_added=true rejected: PASS
ui_added=true rejected: PASS
```

## Redaction smoke

Verify the contract rejects:

```text
provider credentials
provider transport metadata
raw provider response bodies
full article text
signed private URLs
provider canonical creation payloads
canonical feed item payloads
raw actor/request/idempotency identifiers
unredacted operator reason fields
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
$env:MIX_ENV='test'; mix.bat test test/stage58_source_health_operator_action_audit_contract_test.exs
```

Recommended nearby regressions:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage58_source_health_operator_action_contract_test.exs
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
apps/backend/disclosure_api/lib/disclosure_automation/runtime/stage58_source_health_operator_action_audit_contract.ex
apps/backend/disclosure_api/test/stage58_source_health_operator_action_audit_contract_test.exs
apps/backend/disclosure_api/docs/stage58_source_health_operator_action_audit_contract_manual_smoke.md
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
stage58 source health operator action audit contract test: PASS
stage58 source health operator action contract regression: PASS
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
