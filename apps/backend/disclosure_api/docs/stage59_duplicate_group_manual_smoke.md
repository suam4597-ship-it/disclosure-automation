# Stage 5.9 duplicate group manual smoke

This checklist defines manual-smoke requirements for any future cross-source duplicate group implementation.

This is a documentation-only checklist. It does not add runtime grouping code, tests, fixtures, migrations, schema changes, scheduler code, provider clients, live fetch code, routes, feed/controller changes, UI code, action endpoints, materializer changes, API behavior changes, feed behavior changes, or canonical feed mutations.

## Scope

```text
stage: Stage 5.9 PR A
scope: duplicate group manual smoke checklist
mode: docs-only
runtime grouping code: none
new routes: none
UI code: none
action endpoints: none
schema/migrations: none
materializer changes: none
scheduler: none
live fetch: none
canonical mutation: none
```

## Baseline smoke

Before future duplicate group work, verify existing locked behavior:

```text
Stage 5.2 overlay materializer remains attach-only: PASS
Stage 5.3 read model returns item.overlays[] unchanged: PASS
Stage 5.3 event overlay API returns item.overlays[] unchanged: PASS
Stage 5.3 feed digest returns news_overlays[] unchanged: PASS
canonical feed item count remains official-only: PASS
provider overlays remain non-canonical: PASS
canonicalFactOverride remains false for provider overlays: PASS
```

## Duplicate group design smoke

For future duplicate group contract work, verify:

```text
group identity uses bounded metadata only: PASS
group membership is bounded and allowlisted: PASS
member_kind is allowlisted: PASS
match_reasons are allowlisted: PASS
confidence is allowlisted: PASS
source precedence preserves TDnet source-of-truth: PASS
group output is advisory-only: PASS
group output is internal/operator-only unless separately designed: PASS
```

## Public response smoke

Before and after future duplicate group implementation, verify:

```text
read model item.overlays[] unchanged: PASS
API item.overlays[] unchanged: PASS
feed news_overlays[] unchanged: PASS
feed item_count unchanged: PASS
feed ordering unchanged: PASS
official TDnet fields unchanged: PASS
official citations unchanged: PASS
API envelope unchanged: PASS
public duplicate group fields absent unless separately designed: PASS
```

## Canonical mutation smoke

Future duplicate group work must prove:

```text
canonical feed item count unchanged for provider overlays: PASS
provider canonical feed item creation absent: PASS
news-only canonical event creation absent: PASS
official TDnet event merge absent: PASS
official citation override absent: PASS
canonical fact override absent: PASS
materializer public output mutation absent: PASS
```

## Redaction smoke

Future duplicate group work must prove outputs omit:

```text
provider credential values
provider transport metadata
request metadata
response metadata
signed private URLs
raw provider payloads
full article text
unbounded diagnostics
secret-like values
```

Allowed redacted placeholders in docs and tests:

```text
REDACTED_PROVIDER_KEY
REDACTED_PROVIDER_TOKEN
REDACTED_SUBSCRIPTION_KEY
```

## Future targeted tests

When runtime contract work is introduced, add targeted tests for:

```text
deterministic group ID generation
bounded membership projection
allowlisted member kinds
allowlisted match reasons
allowlisted confidence states
redaction rejection
public response shape preservation
canonical no-mutation preservation
```

## Suggested regressions for future implementation

Future non-docs duplicate group PRs should run:

```powershell
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
apps/backend/disclosure_api/docs/stage59_cross_source_duplicate_group_design.md
apps/backend/disclosure_api/docs/stage59_duplicate_group_guardrail_checklist.md
apps/backend/disclosure_api/docs/stage59_duplicate_group_manual_smoke.md
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
cross-source duplicate group design added: PASS
duplicate group guardrail checklist added: PASS
duplicate group manual smoke added: PASS
Stage 5.2 attach-only overlay baseline preserved: PASS
Stage 5.3 public response shape baseline preserved: PASS
operator/internal-only duplicate group policy documented: PASS
redaction guardrails documented: PASS
canonical no-mutation guardrails documented: PASS
no runtime/test/fixture/migration/schema changes: PASS
no scheduler/provider/live-fetch/route/feed/UI/materializer/API/canonical code changes: PASS
```
