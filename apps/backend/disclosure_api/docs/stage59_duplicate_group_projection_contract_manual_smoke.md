# Stage 5.9 duplicate group projection contract manual smoke

This checklist verifies the pure Stage 5.9 duplicate group projection contract.

This is a manual-smoke document only. It does not add routes, UI, action endpoints, runtime grouping services, DB writes, scheduler work, provider clients, live fetch code, materializer changes, API behavior changes, feed behavior changes, or canonical feed mutations.

## Scope

```text
stage: Stage 5.9 PR C
scope: pure duplicate group projection contract
mode: pure runtime projection contract + targeted tests + manual smoke doc
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
apps/backend/disclosure_api/lib/disclosure_automation/runtime/stage59_duplicate_group_projection_contract.ex
apps/backend/disclosure_api/test/stage59_duplicate_group_projection_contract_test.exs
apps/backend/disclosure_api/docs/stage59_duplicate_group_projection_contract_manual_smoke.md
```

## Projection behavior smoke

Verify the projection contract locks these defaults:

```text
projection_scope=internal_operator_duplicate_group_projection_only: PASS
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

## Projected group field smoke

Verify projected group fields are limited to:

```text
group_id
confidence
member_count
has_official_tdnet_event
has_provider_overlay
match_reasons
source_keys
members
```

Verify projected member fields are limited to:

```text
member_id
member_kind
source_key
provider
external_id_hash
official_event_id
overlay_id
confidence
match_reasons
redaction_status
```

## Redacted projection smoke

Verify projection excludes:

```text
raw external_id
created_at
updated_at
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

Allowed identifiers in projection:

```text
bounded group_id
bounded member_id
bounded official_event_id
bounded overlay_id
bounded source_key
bounded provider
hash-shaped external_id_hash
```

## Contract propagation smoke

Verify projection first validates through `Stage59CrossSourceDuplicateGroupContract`:

```text
missing group_id rejected: PASS
invalid confidence rejected: PASS
less than two members rejected: PASS
invalid member_kind rejected: PASS
invalid match_reason rejected: PASS
invalid redaction_status rejected: PASS
missing member reference rejected: PASS
malformed external_id_hash rejected: PASS
```

## Response-shape smoke

Verify the projection contract rejects opt-ins for public response changes:

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

Verify the projection contract rejects opt-ins for canonical behavior:

```text
canonical_feed_mutation=true rejected: PASS
provider_canonical_feed_item_creation=true rejected: PASS
news_only_event_creation=true rejected: PASS
official_event_merge=true rejected: PASS
official_fact_override=true rejected: PASS
official_citation_override=true rejected: PASS
```

## Runtime side-effect smoke

Verify the projection contract rejects opt-ins for behavior outside this PR:

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

## Regression command

Run targeted test:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_projection_contract_test.exs
```

Recommended nearby regressions:

```powershell
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
apps/backend/disclosure_api/lib/disclosure_automation/runtime/stage59_duplicate_group_projection_contract.ex
apps/backend/disclosure_api/test/stage59_duplicate_group_projection_contract_test.exs
apps/backend/disclosure_api/docs/stage59_duplicate_group_projection_contract_manual_smoke.md
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
stage59 duplicate group projection contract test: PASS
stage59 cross-source duplicate group contract regression: PASS
stage53 multi-overlay response contract regression: PASS
stage52 overlay attachment materializer regression: PASS
stage5 feed/API regressions: PASS
TDnet runtime/http regressions: PASS
changed-file strict redaction check: PASS
```
