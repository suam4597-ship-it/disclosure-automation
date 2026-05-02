# Stage 5.9 duplicate group internal read projection manual smoke

This smoke checklist covers Stage 5.9 internal duplicate group read projection.

## Scope

The projection reads persisted `source_duplicate_groups` and `source_duplicate_group_members` rows and returns bounded operator-only review metadata.

Expected changed files:

```text
apps/backend/disclosure_api/lib/disclosure_automation/runtime/stage59_duplicate_group_internal_read_projection.ex
apps/backend/disclosure_api/test/stage59_duplicate_group_internal_read_projection_test.exs
apps/backend/disclosure_api/docs/stage59_duplicate_group_internal_read_projection_manual_smoke.md
```

## Prerequisites

```text
PR #130 merged: duplicate group storage migration
PR #131 merged: duplicate group schemas
PR #132 merged: internal duplicate group materializer
PR #133 merged: operator review route design
```

Base for this PR:

```text
c297e7d23f2618070af168d7e33fc1a5aa45beb1
```

## Projection smoke

1. Materialize a valid locked-fixture duplicate group.
2. Call the internal read projection list function.
3. Confirm the list output is bounded and operator-only.
4. Confirm it returns the group metadata and member metadata only.
5. Call the show function by `group_id`.
6. Confirm it returns one group and its bounded members.
7. Confirm the projection does not write rows or trigger materialization when no rows exist.

## Allowed list filter smoke

Confirm only these filters are allowed:

```text
confidence
source_key
member_kind
redaction_status
limit
```

Confirm unsupported filters are rejected and do not cause DB writes.

Confirm limit is bounded to 1 through 100.

## Operator-only output smoke

Confirm projected top-level output includes guardrail metadata with:

```text
read_only: true
advisory_only: true
operator_only: true
non_canonical: true
bounded: true
redacted: true
network_access: forbidden
trigger_live_fetch: false
scheduler_enabled: false
route_added: false
ui_added: false
action_endpoint_added: false
materializer_triggered: false
```

## Allowed field smoke

Allowed group fields:

```text
group_id
confidence
source_keys
match_reasons
member_count
has_official_tdnet_event
has_provider_overlay
redaction_status
inserted_at
updated_at
members
```

Allowed member fields:

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
inserted_at
updated_at
```

## Forbidden behavior smoke

Confirm the read projection does not:

```text
add public routes
add controller behavior
add UI code
add action endpoints
trigger duplicate group materialization
trigger live provider fetch
trigger scheduler work
call provider clients
mutate source_duplicate_groups
mutate source_duplicate_group_members
mutate canonical_feed_items
create provider canonical feed items
create news-only canonical events
merge official TDnet events
override official TDnet facts
override official citations
change public API response shapes
change public feed response shapes
```

## Redaction smoke

Confirm projected output and changed files do not include:

```text
raw provider bodies
full article text
provider secret values
provider transport material
raw request metadata
raw response metadata
canonical feed payloads
provider canonical creation payloads
raw similarity payloads
unbounded diagnostics
```

## Suggested commands

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_internal_read_projection_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_internal_materializer_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_schema_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_noop_service_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_projection_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage59_cross_source_duplicate_group_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage53_multi_overlay_response_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage52_news_overlay_attachment_materializer_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_feed_visible_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage5_news_overlay_api_exposure_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_runtime_idempotency_test.exs
$env:MIX_ENV='test'; mix.bat test test/jp_tdnet_timely_disclosure_http_smoke_test.exs
```
