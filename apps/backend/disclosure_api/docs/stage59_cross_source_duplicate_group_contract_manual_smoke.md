# Stage 5.9 cross-source duplicate group contract manual smoke

This checklist verifies the pure Stage 5.9 cross-source duplicate group contract.

This is a manual-smoke document only. It does not add routes, UI, action endpoints, runtime grouping services, DB writes, scheduler work, provider clients, live fetch code, materializer changes, API behavior changes, feed behavior changes, or canonical feed mutations.

## Scope

```text
stage: Stage 5.9 PR B
scope: pure cross-source duplicate group contract
mode: pure runtime contract + targeted tests + manual smoke doc
runtime grouping service: none
runtime authorization integration: none
DB writes: none
network calls: none
scheduler: none
live fetch: none
routes: none
UI: none
materializer changes: none
canonical mutation: none
```

## Files expected in this PR

```text
apps/backend/disclosure_api/lib/disclosure_automation/runtime/stage59_cross_source_duplicate_group_contract.ex
apps/backend/disclosure_api/test/stage59_cross_source_duplicate_group_contract_test.exs
apps/backend/disclosure_api/docs/stage59_cross_source_duplicate_group_contract_manual_smoke.md
```

## Contract behavior smoke

Verify the contract locks these defaults:

```text
duplicate_group_scope=internal_operator_advisory_only: PASS
bounded=true: PASS
redacted=true: PASS
advisory_only=true: PASS
operator_only=true: PASS
non_canonical=true: PASS
public_response_shape_mutation=false: PASS
public_api_duplicate_group_fields=false: PASS
public_feed_duplicate_group_fields=false: PASS
item_overlays_shape_mutation=false: PASS
news_overlays_shape_mutation=false: PASS
materializer_output_mutation=false: PASS
canonical_feed_mutation=false: PASS
provider_canonical_feed_item_creation=false: PASS
news_only_event_creation=false: PASS
official_event_merge=false: PASS
official_fact_override=false: PASS
official_citation_override=false: PASS
trigger_live_fetch=false: PASS
scheduler_enabled=false: PASS
network_access=forbidden: PASS
db_write=false: PASS
route_added=false: PASS
ui_added=false: PASS
action_endpoint_added=false: PASS
schema_migration=false: PASS
```

## Group validation smoke

For a valid duplicate group, verify:

```text
group_id is required and bounded: PASS
confidence is required and allowlisted: PASS
at least two members are required: PASS
member_count is projected: PASS
has_official_tdnet_event is projected: PASS
has_provider_overlay is projected: PASS
source_keys are aggregated: PASS
match_reasons are aggregated and deduplicated: PASS
```

## Member validation smoke

For each member, verify:

```text
member_id is required and bounded: PASS
member_kind is required and allowlisted: PASS
source_key is required and bounded: PASS
provider is bounded when present: PASS
external_id is bounded when present: PASS
external_id_hash is hash-shaped when present: PASS
official_event_id is bounded when present: PASS
overlay_id is bounded when present: PASS
at least one member reference is required: PASS
confidence is required and allowlisted: PASS
match_reasons are required and allowlisted: PASS
redaction_status is required and allowlisted: PASS
created_at is bounded when present: PASS
updated_at is bounded when present: PASS
```

## Allowlist smoke

Verify all allowlisted values are accepted:

```text
member_kind official_tdnet_event: PASS
member_kind news_overlay_attachment: PASS
member_kind provider_staged_candidate: PASS
member_kind operator_review_candidate: PASS
confidence unknown: PASS
confidence candidate: PASS
confidence likely: PASS
confidence confirmed_by_operator: PASS
confidence rejected_by_operator: PASS
redaction_status passed: PASS
redaction_status failed: PASS
redaction_status blocked: PASS
redaction_status unknown: PASS
allowlisted match reasons: PASS
```

## Response-shape smoke

Verify the contract rejects opt-ins for public response changes:

```text
public_exposure=true rejected: PASS
public_response_shape_mutation=true rejected: PASS
public_api_duplicate_group_fields=true rejected: PASS
public_feed_duplicate_group_fields=true rejected: PASS
item_overlays_shape_mutation=true rejected: PASS
news_overlays_shape_mutation=true rejected: PASS
materializer_output_mutation=true rejected: PASS
```

## Canonical no-mutation smoke

Verify the contract rejects opt-ins for canonical behavior:

```text
canonical_feed_mutation=true rejected: PASS
provider_canonical_feed_item_creation=true rejected: PASS
news_only_event_creation=true rejected: PASS
official_event_merge=true rejected: PASS
official_fact_override=true rejected: PASS
official_citation_override=true rejected: PASS
```

## Runtime side-effect smoke

Verify the contract rejects opt-ins for behavior outside this PR:

```text
trigger_live_fetch=true rejected: PASS
use_live_fetch=true rejected: PASS
scheduler_enabled=true rejected: PASS
db_write=true rejected: PASS
network_access=true rejected: PASS
route_added=true rejected: PASS
ui_added=true rejected: PASS
action_endpoint_added=true rejected: PASS
schema_migration=true rejected: PASS
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
raw body similarity payloads
full text similarity payloads
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
$env:MIX_ENV='test'; mix.bat test test/stage59_cross_source_duplicate_group_contract_test.exs
```

Recommended nearby regressions:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage53_multi_overlay_response_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage52_news_overlay_attachment_materializer_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_feed_visible_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_api_exposure_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```

## Changed-file guardrail

This PR may add only:

```text
apps/backend/disclosure_api/lib/disclosure_automation/runtime/stage59_cross_source_duplicate_group_contract.ex
apps/backend/disclosure_api/test/stage59_cross_source_duplicate_group_contract_test.exs
apps/backend/disclosure_api/docs/stage59_cross_source_duplicate_group_contract_manual_smoke.md
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
stage59 cross-source duplicate group contract test: PASS
stage53 multi-overlay response contract regression: PASS
stage52 overlay attachment materializer regression: PASS
stage5 feed/API regressions: PASS
TDnet runtime/http regressions: PASS
changed-file strict redaction check: PASS
```
