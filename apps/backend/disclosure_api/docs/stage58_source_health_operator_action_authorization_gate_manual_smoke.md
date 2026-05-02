# Stage 5.8 source health operator action authorization gate manual smoke

This checklist verifies the Stage 5.8 provider source health operator action authorization gate.

This is a manual-smoke document only. It does not add routes, UI, action endpoints, runtime authorization integration, DB writes, audit writes, scheduler work, provider clients, live fetch code, source health mutation behavior, materializer changes, API behavior changes, feed behavior changes, or canonical feed mutations.

## Scope

```text
stage: Stage 5.8 PR E
scope: source health operator action authorization gate
mode: pure runtime contract + targeted tests + manual smoke doc
runtime action endpoint: none
runtime authorization integration: none
DB writes: none
audit writes: none
enqueue work: none
network calls: none
scheduler: none
live fetch: none
routes: none
UI: none
canonical mutation: none
```

## Files expected in this PR

```text
apps/backend/disclosure_api/lib/disclosure_automation/runtime/stage58_source_health_operator_action_authorization_gate.ex
apps/backend/disclosure_api/test/stage58_source_health_operator_action_authorization_gate_test.exs
apps/backend/disclosure_api/docs/stage58_source_health_operator_action_authorization_gate_manual_smoke.md
```

## Authorization gate behavior smoke

Verify the gate locks these defaults:

```text
authorization_scope=operator_action_authorization_gate_only: PASS
authenticated_required=true: PASS
operator_role_required=true: PASS
action_permission_required=true: PASS
source_authorization_required=true: PASS
read_only_permissions_allowed_for_actions=false: PASS
no_op_preview_only=true: PASS
operator_only=true: PASS
advisory_only=true: PASS
public_response_shape_mutation=false: PASS
trigger_live_fetch=false: PASS
scheduler_enabled=false: PASS
network_access=forbidden: PASS
db_write=false: PASS
audit_write_performed=false: PASS
enqueue_performed=false: PASS
source_health_mutation=false: PASS
canonical_feed_mutation=false: PASS
provider_canonical_feed_item_creation=false: PASS
news_only_event_creation=false: PASS
action_endpoint_added=false: PASS
route_added=false: PASS
ui_added=false: PASS
```

## Authorized no-op preview smoke

For a valid action and actor context, verify:

```text
action request is validated through Stage58SourceHealthOperatorActionContract: PASS
no-op preview is created through Stage58SourceHealthOperatorActionNoopService: PASS
audit event is validated through Stage58SourceHealthOperatorActionAuditContract: PASS
actor_id_hash is required and preserved: PASS
authenticated actor required: PASS
operator/admin role required: PASS
explicit action permission required: PASS
source_key authorization required: PASS
operation preserved: PASS
required_permission equals operation: PASS
source_key preserved: PASS
authorization_result=allowed_noop_preview: PASS
preview no_op=true: PASS
preview fake_side_effects_only=true: PASS
preview action_result has no DB write: PASS
preview action_result has no audit write: PASS
preview action_result has no enqueue: PASS
preview action_result has no canonical mutation: PASS
```

## Permission and source authorization smoke

Verify the gate rejects:

```text
unauthenticated actor context: PASS
non-operator role: PASS
missing action permission: PASS
read-only permission used for action: PASS
source key outside actor source scope: PASS
malformed actor_id_hash: PASS
missing actor_id_hash: PASS
unknown actor context key: PASS
raw actor identifier: PASS
```

Verify allowed cases:

```text
operator role with matching action permission and source key: PASS
admin role with matching action permission and wildcard source key: PASS
```

## Contract propagation smoke

Verify the gate preserves underlying contract rejections:

```text
read-only operation rejected through action contract: PASS
invalid result_status rejected through audit contract: PASS
invalid redaction_status rejected through audit contract: PASS
secret-like action value rejected through redaction scan: PASS
credentials rejected through redaction scan: PASS
provider transport metadata rejected through redaction scan: PASS
raw provider payload rejected through redaction scan: PASS
```

## No-side-effect option smoke

Verify the gate rejects opt-ins for behavior that is outside this PR:

```text
db_write=true rejected: PASS
audit_write_performed=true rejected: PASS
enqueue_performed=true rejected: PASS
network_access=true rejected: PASS
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

## Redaction smoke

Verify the gate rejects:

```text
provider credentials
provider transport metadata
raw provider response bodies
full article text
signed private URLs
provider canonical creation payloads
canonical feed item payloads
raw actor identifiers
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
$env:MIX_ENV='test'; mix.bat test test/stage58_source_health_operator_action_authorization_gate_test.exs
```

Recommended nearby regressions:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage58_source_health_operator_action_noop_service_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage58_source_health_operator_action_audit_contract_test.exs
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
apps/backend/disclosure_api/lib/disclosure_automation/runtime/stage58_source_health_operator_action_authorization_gate.ex
apps/backend/disclosure_api/test/stage58_source_health_operator_action_authorization_gate_test.exs
apps/backend/disclosure_api/docs/stage58_source_health_operator_action_authorization_gate_manual_smoke.md
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
stage58 source health operator action authorization gate test: PASS
stage58 source health operator action noop service regression: PASS
stage58 source health operator action audit contract regression: PASS
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
