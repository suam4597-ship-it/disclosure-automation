# GlobalPulse HKEX Latest Listed Company Parser Contract

Date: 2026-05-11 KST

This document records the bounded parser/source contract for the official HKEXnews Latest Listed Company Information JSON asset.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend shell changes, frontend framework dependencies, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, workflow schedules, source registration, source activation, or production scheduled polling.

## Conclusion

```text
HKEX_LATEST_LISTED_COMPANY_PARSER_CONTRACT_RECORDED
HKEX_HOMECAT0_JSON_FIRST_SOURCE_SCOPE_ACCEPTED
HKEX_HOMECAT0_NEWSINFO_FIELD_MAP_DESIGNED
HKEX_ATTACHMENT_DETAIL_FETCH_OUT_OF_SCOPE
HKEX_PDF_BODY_FETCH_FORBIDDEN_FOR_FIRST_CANDIDATE
HKEX_FLY_RUNTIME_HOMECAT0_JSON_FETCH_PASS
HKEX_STOCK_LIST_SHAPE_RECORDED
HKEX_SOURCE_REGISTRATION_READY_FOR_INACTIVE_CANDIDATE_PR
NO_HKEX_SOURCE_REGISTERED
NO_CNTW_SCHEDULED_LIVE_POLLING_ENABLED
KR_LIVE_SOURCE_TRACK_DEFERRED
JP_LIVE_POLLING_STILL_BLOCKED_BY_ISSUE_339
```

## Source Contract

```text
candidate source_key: hkex_latest_listed_company_information
authority: official HKEXnews Latest Listed Company Information surface
source URL: https://www.hkexnews.hk/ncms/script/eds/homecat0_e.json
source type: api
region_code: hk
region group: greater_china
source status for first implementation: active=false
candidate_status: manual_staging_only
disable_live_fixture_fallback: true
production scheduled polling: disabled
```

The first implementation candidate must use `homecat0_e.json` only.

Do not combine `homecat1_e.json` through `homecat7_e.json` into the first source. Those category assets need separate category/dedupe design before they can be added.

## Parser Target

The parser target is the bounded `newsInfo` array in the official JSON body.

Observed top-level shape:

```text
newsInfo: list
viewAllHyperlink: string
```

Observed item fields:

```text
relY
relM
relD
relTime
title
sTxt
ext
webPath
stock
dod
dodPath
newsId
size
multi
```

Fly runtime verification recorded `stock` as a list of issuer maps with `sc` and `sn` keys. The prior asset scan summarized stock as display text. The first parser must support the list shape and may keep a defensive string fallback if later rows differ.

The first parser must ignore unknown fields and must not fail open into raw JSON exposure.

## Field Mapping

```text
external_id:
  preferred: hkex-llci:<document-id-from-webPath>
  example: https://www1.hkexnews.hk/listedco/listconews/sehk/2026/0511/2026051100197.pdf
  mapped external_id: hkex-llci:2026051100197
  metadata fallback: newsId may be stored as bounded source metadata but should not replace webPath document id unless a later PR changes the id strategy

canonical_url:
  webPath

published_at:
  relY + relM + relD + relTime parsed as Asia/Hong_Kong local time and normalized to UTC

headline/title:
  title, trimmed and bounded

summary:
  sTxt, trimmed and bounded

issuer_display_name:
  preferred: stock[0].sn when stock is a non-empty list of issuer maps
  fallback: issuer short name derived from stock string after removing the leading numeric stock code when present
  example fallback: 00855 CHINA WATER -> CHINA WATER

issuer_code:
  preferred: stock[0].sc when stock is a non-empty list of issuer maps
  fallback: leading numeric stock code from stock string when present
  example fallback: 00855

category:
  source-derived category: Latest Listed Company Information / Latest Submissions

document_type:
  ext, lowercased and allowlisted; treat NaN or unknown values as unknown metadata
```

If `webPath` is missing or does not contain a stable document id, the parser candidate must use a bounded deterministic fallback id derived from source key, date/time, stock, title, and canonical_url. The fallback id must be hashed or otherwise bounded, and it must not include raw attachment contents.

## Timestamp Contract

HKEX item timestamps are local to the HKEX publication surface.

The parser candidate should parse:

```text
relY: four-digit year
relM: two-digit month
relD: two-digit day
relTime: HH:mm
timezone: Asia/Hong_Kong
```

Then normalize to the backend canonical timestamp representation.

If timestamp parsing fails for one row, that row should be skipped or marked invalid in a bounded parser error. Do not replace failed timestamps with ingestion time unless a separate contract approves that behavior.

## Attachment Boundary

The first HKEX source candidate may store or expose only the announcement link metadata from `webPath`.

Forbidden for the first candidate:

```text
fetching PDF bodies
fetching HTM attachment bodies
fetching detail pages
extracting PDF text
extracting attachment tables
embedding raw document contents
adding attachment worker controls
adding public document fetch controls
```

Allowed:

```text
record canonical_url from webPath
record ext as bounded metadata
record source category and issuer/stock metadata
render headline/summary/link through the existing digest shape
```

## Category Scope

The first source candidate represents only latest submissions.

```text
homecat0_e.json -> Latest Submissions
```

The other official category assets remain out of scope for this first candidate:

```text
homecat1_e.json -> Financial Statements/ESG Information
homecat2_e.json -> IPO Allotment Results
homecat3_e.json -> Notices of General Meetings
homecat4_e.json -> Prospectuses
homecat5_e.json -> Results Announcements
homecat6_e.json -> Results of General Meetings
homecat7_e.json -> Resumption / Suspension / Trading Halt
```

They can be revisited only after the first source has manual staging evidence and a separate dedupe/category expansion design.

## Required Tests For Candidate PR

A later implementation PR should include focused tests that lock:

```text
representative homecat0_e.json fixture parses into bounded canonical items
external_id derives from webPath document id
published_at parses from relY/relM/relD/relTime as Asia/Hong_Kong
stock list shape maps stock[0].sc and stock[0].sn into issuer_code and issuer_display_name
stock string fallback remains bounded if future rows differ
ext=NaN is treated as unknown metadata
title and sTxt are bounded and trimmed
unknown fields are ignored
missing optional fields do not expose raw JSON
PDF/detail bodies are not fetched
fixture fallback is disabled for live success claims
source remains active=false
backend digest JSON response shape remains unchanged
```

Required manual validation before any staging success claim:

```text
application/Fly runtime GET verification for homecat0_e.json: recorded in globalpulse_hkex_fly_runtime_probe_results.md
manual staging poll with fetch.mode=live
metadata.fallback_to_fixture=false
public digest visibility smoke after staging poll
rollback check that disabling the source does not affect SEC, NSE, SET, HNX, HSX, Taiwan MOPS, or Europe canaries
```

## Runtime Guardrails

```text
Do not register the HKEX source in this docs-only PR.
Do not set any HKEX source active=true.
Do not enable CN/TW production scheduled live polling.
Do not fetch PDFs, HTM attachments, detail pages, or document bodies in the first source candidate.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not change backend digest JSON response shape.
Do not treat fixture fallback as live success.
Do not use browser-only success as backend polling readiness.
Do not merge HKEX into Taiwan MOPS or Mainland China buckets.
Do not start JP live polling before issue #339 is resolved.
Do not start KR live-source implementation before the dedicated backend/source path exists.
```

## Next Allowed Steps

```text
1. Run a Fly/application-runtime GET probe against https://www.hkexnews.hk/ncms/script/eds/homecat0_e.json.
2. Add an inactive/manual staging-only HKEX parser/source candidate using this contract.
3. Validate with a representative fixture and focused parser/source tests.
4. Deploy to Fly staging and run a manual live poll only after runtime GET compatibility is recorded.
5. Record public digest visibility smoke before discussing any cadence.
```
