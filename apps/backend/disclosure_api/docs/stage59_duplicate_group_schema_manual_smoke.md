# Stage 5.9 duplicate group schema manual smoke

This checklist verifies the Stage 5.9 duplicate group schema modules.

This PR adds schema modules and changeset tests only. It does not add runtime grouping materialization, runtime persistence services, additional migrations, fixtures, scheduler code, provider clients, live fetch code, routes, feed/controller changes, UI code, action endpoints, materializer changes, API behavior changes, feed behavior changes, or canonical feed mutations.

## Scope

```text
stage: Stage 5.9 PR G
scope: internal duplicate group schema modules
schema modules: two
changeset tests: one
migration files: none
runtime materialization: none
runtime persistence service: none
fixtures: none
scheduler: none
live fetch: none
routes: none
UI: none
action endpoints: none
materializer changes: none
canonical mutation: none
```

## Files expected in this PR

```text
apps/backend/disclosure_api/lib/disclosure_automation/schema/source_duplicate_group.ex
apps/backend/disclosure_api/lib/disclosure_automation/schema/source_duplicate_group_member.ex
apps/backend/disclosure_api/test/stage59_duplicate_group_schema_test.exs
apps/backend/disclosure_api/docs/stage59_duplicate_group_schema_manual_smoke.md
```

## SourceDuplicateGroup smoke

Verify the group schema:

```text
uses source_duplicate_groups table: PASS
uses binary_id primary key: PASS
stores group_id: PASS
stores confidence: PASS
stores source_keys map: PASS
stores match_reasons map: PASS
stores member_count: PASS
stores has_official_tdnet_event: PASS
stores has_provider_overlay: PASS
stores redaction_status: PASS
validates required fields: PASS
validates confidence allowlist: PASS
validates redaction_status allowlist: PASS
validates member_count >= 2: PASS
validates bounded source_keys items: PASS
validates allowlisted match_reasons items: PASS
rejects forbidden fields and secret-like values: PASS
unique constraint on group_id: PASS
```

## SourceDuplicateGroupMember smoke

Verify the member schema:

```text
uses source_duplicate_group_members table: PASS
uses binary_id primary key: PASS
stores group_id: PASS
stores member_id: PASS
stores member_kind: PASS
stores source_key: PASS
stores provider: PASS
stores external_id_hash: PASS
stores official_event_id: PASS
stores overlay_id: PASS
stores confidence: PASS
stores match_reasons map: PASS
stores redaction_status: PASS
validates required fields: PASS
validates member_kind allowlist: PASS
validates confidence allowlist: PASS
validates redaction_status allowlist: PASS
validates hash-shaped external_id_hash when present: PASS
requires at least one bounded member reference: PASS
validates allowlisted match_reasons items: PASS
rejects forbidden fields and secret-like values: PASS
unique constraint on group_id + member_id: PASS
```

## Storage boundary smoke

Verify this PR does not add runtime behavior:

```text
no runtime grouping materialization: PASS
no runtime persistence service: PASS
no DB write code path outside changesets: PASS
no routes: PASS
no feed/controller changes: PASS
no UI: PASS
no action endpoints: PASS
no scheduler code: PASS
no provider clients: PASS
no live fetch code: PASS
no materializer changes: PASS
no API/feed response behavior changes: PASS
no canonical mutation behavior: PASS
```

## Response-shape smoke

Before and after this PR, verify:

```text
read model item.overlays[] unchanged: PASS
API item.overlays[] unchanged: PASS
feed news_overlays[] unchanged: PASS
feed item_count unchanged: PASS
feed ordering unchanged: PASS
official TDnet fields unchanged: PASS
official citations unchanged: PASS
API envelope unchanged: PASS
public API duplicate group fields absent: PASS
public feed duplicate group fields absent: PASS
```

## Redaction smoke

Schema changesets must reject or omit:

```text
provider credential values
provider transport metadata
request metadata
response metadata
signed private URLs
raw provider payloads
full article text
canonical feed item payloads
provider canonical creation payloads
raw similarity payloads
full text similarity payloads
unbounded diagnostics
secret-like values
```

Allowed redacted placeholders in docs and tests:

```text
REDACTED_PROVIDER_KEY
REDACTED_PROVIDER_TOKEN
REDACTED_SUBSCRIPTION_KEY
```

## Suggested checks

Run targeted schema test:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_schema_test.exs
```

Recommended regressions:

```powershell
$env:MIX_ENV='test'; mix.bat test test/stage59_cross_source_duplicate_group_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_projection_contract_test.exs
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_noop_service_test.exs
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
apps/backend/disclosure_api/lib/disclosure_automation/schema/source_duplicate_group.ex
apps/backend/disclosure_api/lib/disclosure_automation/schema/source_duplicate_group_member.ex
apps/backend/disclosure_api/test/stage59_duplicate_group_schema_test.exs
apps/backend/disclosure_api/docs/stage59_duplicate_group_schema_manual_smoke.md
```

It must not add or modify:

```text
runtime code
fixtures
migrations
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
stage59 duplicate group schema test: PASS
stage59 duplicate group contract regression: PASS
stage59 projection contract regression: PASS
stage59 no-op service regression: PASS
stage53/stage52/stage5 regressions: PASS
TDnet runtime/http regressions: PASS
changed-file strict redaction check: PASS
```
