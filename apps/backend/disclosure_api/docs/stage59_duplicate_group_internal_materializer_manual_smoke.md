# Stage 5.9 duplicate group internal materializer manual smoke

## Scope

This smoke checklist covers Stage 5.9 PR H: an internal duplicate group materializer that persists bounded duplicate-group metadata into the existing Stage 5.9 storage tables.

Expected changed files:

- `apps/backend/disclosure_api/lib/disclosure_automation/runtime/stage59_duplicate_group_internal_materializer.ex`
- `apps/backend/disclosure_api/test/stage59_duplicate_group_internal_materializer_test.exs`
- `apps/backend/disclosure_api/docs/stage59_duplicate_group_internal_materializer_manual_smoke.md`

## Prerequisites

- PR #130 is merged so `source_duplicate_groups` and `source_duplicate_group_members` exist.
- PR #131 is merged so `SourceDuplicateGroup` and `SourceDuplicateGroupMember` schemas and changesets exist.
- Base commit for this PR is `85326e048717f4585a0dc8629aaaff68da2f9940`.

## Materializer smoke

1. Run the targeted materializer test.
2. Confirm a valid locked-fixture duplicate group creates one `source_duplicate_groups` row.
3. Confirm the same valid group creates two `source_duplicate_group_members` rows.
4. Run the same materializer input again.
5. Confirm the group row count remains one and member row count remains two.
6. Confirm the result remains bounded metadata only:
   - `mode`
   - `group_id`
   - `members_seen`
   - `groups_upserted`
   - `members_upserted`
   - public shape mutation flags remain false
   - canonical mutation flags remain false

## Source allowlist smoke

Confirm only these existing fixture/source keys are accepted:

- `jp_tdnet_timely_disclosure`
- `stage5_news_overlay_fixture`
- `stage53_news_overlay_fixture`

Confirm an unreviewed source key returns an error and writes no duplicate-group rows.

## No public surface smoke

Confirm this PR does not add or modify:

- public routes
- UI
- action endpoints
- feed/controller files
- API response behavior
- feed response behavior
- scheduler code
- provider client code
- live fetch code

## No canonical mutation smoke

Confirm the materializer never opts into:

- canonical feed mutation
- provider canonical feed item creation
- news-only canonical event creation
- official event merge
- official fact override
- official citation override

The materializer should persist advisory duplicate-group metadata only.

## Redaction smoke

Confirm bounded projection/schema validation rejects unbounded or private provider material before any DB write, including raw provider body fields, transport metadata fields, full article text fields, canonical payload fields, and private provider secret fields.

Confirm changed files do not include non-redacted provider keys, header values, cookie values, or other private transport material.

## Suggested commands

```powershell
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
