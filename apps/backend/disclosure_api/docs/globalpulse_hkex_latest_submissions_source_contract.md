# GlobalPulse HKEX Latest Submissions Source Contract

Date: 2026-05-11 KST

This document records the bounded parser/source contract for a future inactive HKEX Latest Listed Company Information source candidate.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend shell changes, frontend framework dependencies, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, workflow schedules, source registration, source activation, or production scheduled polling.

## Conclusion

```text
HKEX_LATEST_SUBMISSIONS_SOURCE_CONTRACT_RECORDED
HKEX_HOMECAT0_JSON_PARSER_CONTRACT_RECORDED
HKEX_ATTACHMENT_FETCH_EXCLUSION_RECORDED
HKEX_INACTIVE_MANUAL_STAGING_ONLY_SOURCE_PROPOSAL_RECORDED
HKEX_SOURCE_REGISTRATION_NOT_ADDED
HKEX_PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
NO_HKEX_PDF_OR_DETAIL_FETCH
NO_CNTW_PUBLIC_POLL_UI_ADDED
KR_LIVE_SOURCE_TRACK_DEFERRED
JP_LIVE_POLLING_STILL_BLOCKED_BY_ISSUE_339
```

## Proposed Source

```text
source_key: hk_hkex_latest_submissions
display_name: HKEX Latest Listed Company Submissions
authority: official HKEXnews Latest Listed Company Information surface
source_type: api
base_url: https://www.hkexnews.hk/ncms/script/eds/homecat0_e.json
healthcheck_url: https://www.hkexnews.hk/homeLLCI.html
parser_key: hkex_latest_submissions_json_v1
active: false
candidate_status: manual_staging_only
disable_live_fixture_fallback: true
max_items_per_poll: 25
detail_fetch_disabled: true
attachment_fetch_disabled: true
```

Suggested coverage tags:

```text
apac
greater_china
hong_kong
hk
disclosure
exchange
listed_companies
issuer_announcement
latest_submissions
markets
```

This proposed source should not replace the existing fixture-backed `hk_market_news` bucket until a staging live-poll smoke and public digest visibility smoke pass.

## Endpoint Contract

The source uses the official HKEXnews LLCI latest-submissions JSON asset confirmed in `globalpulse_hkex_latest_listed_company_asset_scan.md`.

```text
GET https://www.hkexnews.hk/ncms/script/eds/homecat0_e.json
accept: application/json,*/*;q=0.8
referer: https://www.hkexnews.hk/homeLLCI.html
```

Observed response:

```text
status: 200
content_type: application/json
top_level_keys: lastupdatetime, newsInfo, viewAllHyperlink
newsInfo_count: 5
```

Accepted top-level shape:

```text
lastupdatetime: optional string
viewAllHyperlink: optional official HKEXnews URL
newsInfo: required array
```

The parser must reject payloads without a top-level `newsInfo` array.

## Item Shape

Observed `newsInfo` row keys:

```text
newsId
sTxt
title
ext
size
webPath
dod
multi
stock
relD
relM
relY
relTime
```

Observed first row on 2026-05-11 KST:

```text
newsId: 12154388
sTxt: Announcements and Notices - [Overseas Regulatory Announcement - Issue...]
title: OVERSEAS REGULATORY...
ext: pdf
size: 5MB
webPath: https://www1.hkexnews.hk/listedco/listconews/sehk/2026/0511/2026051100197.pdf
dod: N
multi: 0
stock[0].sc: 00855
stock[0].sn: CHINA WATER
relD: 11
relM: 05
relY: 2026
relTime: 12:23
```

Accepted row shape:

```text
newsId: integer or string, preferred
title: string, may be shortened by HKEX
sTxt: string, may be shortened by HKEX
webPath: official HKEXnews listedco/listconews URL
relY: four-digit year string
relM: two-digit month string
relD: two-digit day string
relTime: HH:MM local Hong Kong time
stock: array of {sc, sn}; empty or missing stock is allowed only if title/sTxt/webPath are otherwise usable
ext: file extension metadata only
size: file-size metadata only
multi: multi-file metadata only
dod: display/download metadata only
```

## Canonical Mapping

```text
external_id:
  preferred: hkex:{newsId}
  fallback: hkex:{relY}{relM}{relD}:{relTime}:{first_stock_code}:{webPath_or_title_slug}

title:
  preferred: {first_stock_code} {first_stock_name} - {title}
  fallback: {title}
  fallback if title missing: {sTxt}

url:
  webPath

published_at:
  relY-relM-relD relTime interpreted as Asia/Hong_Kong, converted to UTC

category:
  hkex_latest_submission

summary:
  bounded metadata summary using sTxt, ext, size, multi, dod, stock code/name list, and viewAllHyperlink when present
```

The parser must not fetch `webPath` to expand shortened titles or summaries.

## Normalization Rules

```text
trim leading/trailing whitespace
collapse repeated whitespace
decode HTML entities if present
preserve HKEX stock codes as zero-padded strings
preserve issuer short names as supplied by HKEX
convert Asia/Hong_Kong local timestamp to UTC
bound output to max_items_per_poll
drop rows with no usable title/sTxt and no usable official URL
```

Allowed official URL hosts:

```text
www.hkexnews.hk
www1.hkexnews.hk
www3.hkexnews.hk
```

Allowed first-candidate path family:

```text
/listedco/listconews/
```

Rows with non-HKEXnews hosts or unrelated path families must be rejected.

## Parser Capability Proposal

```text
parser_key: hkex_latest_submissions_json_v1
display_name: HKEX Latest Listed Company Submissions JSON Parser
enabled: true
input_types: [json, api]
output_contract: canonical_document_v1
timeout_ms: 5000
max_items_per_poll: 25
supports_pagination: false
supports_detail_fetch: false
```

Extraction:

```text
id_fields:
  - newsInfo.newsId
  - newsInfo.webPath
title_fields:
  - newsInfo.title
  - newsInfo.sTxt
summary_fields:
  - newsInfo.sTxt
  - newsInfo.ext
  - newsInfo.size
  - newsInfo.stock[].sc
  - newsInfo.stock[].sn
url_fields:
  - newsInfo.webPath
published_at_fields:
  - newsInfo.relY
  - newsInfo.relM
  - newsInfo.relD
  - newsInfo.relTime
category_fields:
  - hkex_latest_submission
```

Quality gates:

```text
reject_non_hkex_latest_submissions_payload: true
reject_empty_newsInfo: false
reject_non_hkexnews_webPath: true
reject_future_timestamps: true
reject_unbounded_item_count: cap_to_max_items_per_poll
minimum_title_length: 4
detail_fetch_disabled: true
attachment_fetch_disabled: true
```

## Implementation Boundaries

The future implementation PR may add only the bounded candidate pieces:

```text
parser capability entry
fixture sample for homecat0_e.json
parser function for hkex_latest_submissions_json_v1
live payload validator for application/json and newsInfo shape
inactive source registry sample entry
parser/source tests
candidate notes
```

It must not add:

```text
active=true
production scheduled polling
workflow schedule
public poll UI
audit UI
public Source Health UI
backend digest JSON response-shape changes
HKEX title-search pagination
issuer enumeration
PDF fetch
HTM attachment fetch
detail document fetch
third-party filing API fallback
fixture fallback while claiming live success
```

## Test Contract For Future Implementation

Required focused tests:

```text
parser accepts a bounded homecat0_e.json fixture
parser maps newsId to hkex:{newsId}
parser preserves zero-padded stock code
parser converts Asia/Hong_Kong rel timestamp to UTC
parser rejects non-HKEXnews webPath hosts
parser does not fetch webPath, PDFs, HTM documents, or detail pages
source registry entry is active=false
source config disables live fixture fallback
source config caps max_items_per_poll at 25
public digest JSON response shape remains unchanged
```

Required adjacent checks:

```text
SEC live source behavior remains unchanged
India NSE source behavior remains unchanged
SET/HNX/HSX/Taiwan MOPS inactive source behavior remains unchanged
CN/TW public UI smoke assumptions remain unchanged
JP live polling remains blocked
KR remains deferred
```

## Manual Staging Acceptance

After a future parser/source PR is merged and deployed to Fly staging, manual staging smoke must prove:

```text
GET /api/health: 200
POST /api/admin/sources/hk_hkex_latest_submissions/poll?use_live_fetch=true&edition=breaking: 2xx
fetch.mode: live
metadata.fallback_to_fixture: false
records_seen: bounded and non-negative
records_inserted: bounded by max_items_per_poll
source active: false
candidate_status: manual_staging_only
GET /api/feed/digest/latest?edition=breaking: 200
HKEX item appears only if fresh records were inserted
```

The smoke must not claim success from fixture fallback.

## Rollback

```text
Remove or disable the inactive source registry entry.
Keep parser capability disabled if parser behavior is disputed.
Do not touch SEC, NSE, SET, HNX, HSX, Taiwan MOPS, or other APAC sources.
Do not change public digest JSON shape.
```

## Next Allowed Steps

```text
1. Run a Fly/application-runtime GET probe against homecat0_e.json when Fly CLI/auth is available.
2. Add the bounded inactive HKEX parser/source candidate only after the runtime probe and this contract are accepted.
3. Keep CN/TW production scheduled polling disabled.
```
