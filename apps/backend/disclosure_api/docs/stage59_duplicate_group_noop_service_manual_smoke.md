# Stage 5.9 duplicate group no-op service manual smoke

This checklist verifies the Stage 5.9 duplicate group no-op service.

This is a manual-smoke document only. It does not add routes, UI, action endpoints, runtime grouping materialization, DB writes, scheduler work, provider clients, live fetch code, materializer changes, API behavior changes, feed behavior changes, or canonical feed mutations.

## Scope

```text
stage: Stage 5.9 PR D
scope: internal duplicate group no-op service
mode: pure runtime service + targeted tests + manual smoke doc
runtime grouping materialization: none
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
apps/backend/disclosure_api/lib/disclosure_automation/runtime/stage59_duplicate_group_noop_service.ex
apps/backend/disclosure_api/test/stage59_duplicate_group_noop_service_test.exs
apps/backend/disclosure_api/docs/stage59_duplicate_group_noop_service_manual_smoke.md
```

## Service behavior smoke

Verify the service locks these defaults:

```text
service_scope=internal_duplicate_group_noop_only: PASS
bounded=true: PASS
redacted=true: PASS
advisory_only=true: PASS
operator_only=true: PASS
non_canonical=true: PASS
no_op=true: PASS
fake_existing_fixtures_only=true: PASS
duplicate_group_contract_required=true: PASS
duplicate_group_projection_required=true: PASS
grouping_materialized=false: PASS
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

## No-op preview smoke

For a valid duplicate group, verify:

```text
duplicate group is validated through Stage59CrossSourceDuplicateGroupContract: PASS
duplicate group projection is built through Stage59DuplicateGroupProjectionContract: PASS
service returns no-op preview only: PASS
grouping_materialized=false: PASS
db_write=false: PASS
network_access=forbidden: PASS
trigger_live_fetch=false: PASS
scheduler_enabled=false: PASS
canonical_feed_mutation=false: PASS
provider_canonical_feed_item_creation=false: PASS
news_only_event_creation=false: PASS
official_event_merge=false: PASS
official_fact_override=false: PASS
official_citation_override=false: PASS
public_response_shape_mutation=false: PASS
public duplicate group fields absent: PASS
```

## Existing fixture source smoke

Verify the no-op service accepts only locked existing fixture/source keys:

```text
jp_tdnet_timely_disclosure accepted: PASS
stage5_news_overlay_fixture accepted: PASS
stage53_news_overlay_fixture accepted: PASS
unknown live provider source rejected: PASS
```

## Projection propagation smoke

Verify the service preserves projection contract failures:

```text
less than two members rejected: PASS
invalid confidence rejected: PASS
raw external_id rejected: PASS
created_at/updated_at rejected from projection: PASS
invalid match reason rejected: PASS
malformed external_id_hash rejected: PASS
```

## Response-shape smoke

Verify the service rejects opt-ins for public response changes:

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

Verify the service rejects opt-ins for canonical behavior:

```text
canonical_feed_mutation=true rejected: PASS
provider_canonical_feed_item_creation=true rejected: PASS
news_only_event_creation=true rejected: PASS
official_event_merge=true rejected: PASS
official_fact_override=true rejected: PASS
official_citation_override=true rejected: PASS
```

## Runtime side-effect smoke

Verify the service rejects opt-ins for behavior outside this PR:

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

Verify the service rejects:

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
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_noop_service_test.exs
```

Recommended nearby regressions:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_projection_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage59_cross_source_duplicate_group_contract_test.exs
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
apps/backend/disclosure_api/lib/disclosure_automation/runtime/stage59_duplicate_group_noop_service.ex
apps/backend/disclosure_api/test/stage59_duplicate_group_noop_service_test.exs
apps/backend/disclosure_api/docs/stage59_duplicate_group_noop_service_manual_smoke.md
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
stage59 duplicate group no-op service test: PASS
stage59 duplicate group projection contract regression: PASS
stage59 cross-source duplicate group contract regression: PASS
stage53 multi-overlay response contract regression: PASS
stage52 overlay attachment materializer regression: PASS
stage5 feed/API regressions: PASS
TDnet runtime/http regressions: PASS
changed-file strict redaction check: PASS
```
