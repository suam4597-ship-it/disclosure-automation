# Stage 5.9 duplicate group operator read route manual smoke

This smoke checklist covers Stage 5.9 operator-only duplicate group read routes.

## Scope

This PR adds read-only admin routes backed by the Stage 5.9 internal duplicate group read projection.

Expected changed files:

```text
apps/backend/disclosure_api/lib/disclosure_automation_web/router.ex
apps/backend/disclosure_api/lib/disclosure_automation_web/controllers/admin_duplicate_group_controller.ex
apps/backend/disclosure_api/test/stage59_duplicate_group_operator_read_route_test.exs
apps/backend/disclosure_api/docs/stage59_duplicate_group_operator_read_route_manual_smoke.md
```

## Prerequisites

```text
PR #130 merged: duplicate group storage migration
PR #131 merged: duplicate group schemas
PR #132 merged: internal duplicate group materializer
PR #133 merged: operator review route design
PR #134 merged: internal read projection
```

Base for this PR:

```text
19badf3ffd80717ea5a8f57b49e5aadefb7efa2c
```

## Route smoke

Confirm only these read routes are added:

```text
GET /api/admin/duplicate-groups
GET /api/admin/duplicate-groups/:group_id
```

Confirm no action endpoints are added:

```text
POST /api/admin/duplicate-groups/:group_id/confirm
POST /api/admin/duplicate-groups/:group_id/reject
PATCH /api/admin/duplicate-groups/:group_id
DELETE /api/admin/duplicate-groups/:group_id
```

## List route smoke

1. Materialize a valid locked-fixture duplicate group.
2. Request `GET /api/admin/duplicate-groups?limit=10`.
3. Confirm the response is operator-only, read-only, advisory-only, bounded, redacted, and non-canonical.
4. Confirm the response contains one group and two bounded members.
5. Confirm the response does not include raw provider body, full article text, raw external IDs, provider secret material, transport material, or canonical payloads.

## Show route smoke

1. Materialize a valid locked-fixture duplicate group.
2. Request `GET /api/admin/duplicate-groups/:group_id`.
3. Confirm one bounded duplicate group is returned.
4. Confirm member fields are limited to bounded group/member metadata.
5. Confirm missing `group_id` returns 404 with bounded error output.

## Filter smoke

Allowed filters:

```text
confidence
source_key
member_kind
redaction_status
limit
```

Confirm unsupported filters return 400 and do not create rows.

## No materialization smoke

Confirm read routes do not:

```text
trigger duplicate group materialization
write source_duplicate_groups rows
write source_duplicate_group_members rows
trigger live provider fetch
trigger scheduler work
call provider clients
```

## Public response smoke

Confirm this PR does not change public endpoints:

```text
GET /api/events/:event_id
GET /api/events/:event_id/news-overlay
GET /api/feed/digest/latest
GET /api/feed/digest/:digest_date/:edition
```

Confirm public duplicate group fields remain absent from public response shapes.

## Canonical no-mutation smoke

Confirm read routes do not:

```text
mutate canonical_feed_items
create provider canonical feed items
create news-only canonical events
merge official TDnet events
override official TDnet facts
override official citations
mutate news_overlay_attachments
```

## Redaction smoke

Confirm changed files and route responses do not include:

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
$env:MIX_ENV='test'; mix.bat test test/stage59_duplicate_group_operator_read_route_test.exs
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
