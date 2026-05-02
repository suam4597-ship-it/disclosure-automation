# Stage 5.9 duplicate group storage manual smoke

This checklist defines manual-smoke requirements for any future internal duplicate group storage implementation.

This is a documentation-only checklist. It does not add migration files, schema modules, runtime grouping materialization, DB writes, tests, fixtures, scheduler code, provider clients, live fetch code, routes, feed/controller changes, UI code, action endpoints, materializer changes, API behavior changes, feed behavior changes, or canonical feed mutations.

## Scope

```text
stage: Stage 5.9 PR E
scope: duplicate group storage manual smoke checklist
mode: docs-only
migration files: none
schema modules: none
DB writes: none
runtime materialization: none
new routes: none
UI code: none
action endpoints: none
scheduler: none
live fetch: none
canonical mutation: none
```

## Baseline smoke

Before future storage work, verify existing locked behavior:

```text
Stage 5.9 duplicate group contract test: PASS
Stage 5.9 duplicate group projection contract test: PASS
Stage 5.9 duplicate group no-op service test: PASS
Stage 5.3 multi-overlay response contract test: PASS
Stage 5.2 overlay attachment materializer test: PASS
Stage 5 feed/API tests: PASS
TDnet runtime/http tests: PASS
```

## Future migration smoke

For a future migration PR, verify:

```text
internal duplicate group tables added only after design approval: PASS
canonical_feed_items untouched: PASS
news_overlay_attachments public semantics untouched: PASS
no public API/feed columns added: PASS
no provider canonical feed item table mutation: PASS
no news-only canonical event creation behavior: PASS
rollback path exists: PASS
migration is idempotent in test setup: PASS
```

## Future schema smoke

For a future schema module PR, verify:

```text
group schema stores bounded fields only: PASS
member schema stores bounded fields only: PASS
group_id unique validation: PASS
group_id + member_id unique validation: PASS
confidence allowlist validation: PASS
member_kind allowlist validation: PASS
match_reasons allowlist validation: PASS
redaction_status allowlist validation: PASS
external_id_hash shape validation: PASS
forbidden field rejection: PASS
```

## Future persistence smoke

For a future persistence implementation, verify:

```text
upsert by group_id is idempotent: PASS
upsert members by group_id + member_id is idempotent: PASS
re-running grouping does not duplicate rows: PASS
re-running grouping does not change item.overlays[]: PASS
re-running grouping does not change news_overlays[]: PASS
re-running grouping does not change feed item_count: PASS
re-running grouping does not mutate canonical feed items: PASS
re-running grouping does not create provider canonical feed items: PASS
re-running grouping does not create news-only canonical events: PASS
```

## Redaction smoke

Future storage work must prove stored rows omit:

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

## Response-shape smoke

Before and after future storage implementation, verify:

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

## Canonical no-mutation smoke

Future storage work must prove:

```text
canonical feed item count unchanged for provider overlays: PASS
provider canonical feed item creation absent: PASS
news-only canonical event creation absent: PASS
official TDnet event merge absent: PASS
official citation override absent: PASS
canonical fact override absent: PASS
materializer public output mutation absent: PASS
```

## Suggested regressions for future implementation

Future non-docs storage PRs should run:

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

## Changed-file guardrail for this docs PR

This PR may add only:

```text
apps/backend/disclosure_api/docs/stage59_duplicate_group_storage_schema_design.md
apps/backend/disclosure_api/docs/stage59_duplicate_group_storage_guardrail_checklist.md
apps/backend/disclosure_api/docs/stage59_duplicate_group_storage_manual_smoke.md
```

It must not add or modify:

```text
runtime code
tests
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

## PASS criteria for this docs PR

```text
docs-only changed files: PASS
duplicate group storage schema design added: PASS
duplicate group storage guardrail checklist added: PASS
duplicate group storage manual smoke added: PASS
no migration/schema/runtime/test/fixture changes: PASS
no scheduler/provider/live-fetch/route/feed/UI/materializer/API/canonical code changes: PASS
redaction guardrails documented: PASS
canonical no-mutation guardrails documented: PASS
public response-shape guardrails documented: PASS
```
