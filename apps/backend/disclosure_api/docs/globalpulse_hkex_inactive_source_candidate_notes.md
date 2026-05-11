# GlobalPulse HKEX Inactive Source Candidate Notes

Date: 2026-05-11 KST

This document records the first bounded inactive/manual staging-only source candidate for official HKEXnews Latest Listed Company Information.

This is an implementation note for a candidate source. It does not activate the source, enable production scheduled polling, add public poll UI, add audit UI, add public Source Health UI, change the public digest JSON response shape, add a frontend framework, or fetch HKEX PDF/HTM/detail document bodies.

## Conclusion

```text
HKEX_INACTIVE_SOURCE_CANDIDATE_ADDED
HKEX_LATEST_LISTED_COMPANY_INFO_JSON_PARSER_ADDED
HKEX_HOMECAT0_FIXTURE_ADDED
HKEX_SOURCE_ACTIVE_FALSE
HKEX_CANDIDATE_STATUS_MANUAL_STAGING_ONLY
HKEX_LIVE_FIXTURE_FALLBACK_DISABLED
HKEX_ATTACHMENT_BODY_FETCH_DISABLED
HKEX_MANUAL_STAGING_LIVE_POLL_PASS
HKEX_DIGEST_VISIBLE_LIVE
HKEX_SOURCE_HEALTH_HEALTHY
HKEX_SECOND_MANUAL_OBSERVATION_PASS
NO_CNTW_SCHEDULED_LIVE_POLLING_ENABLED
HKEX_CADENCE_NOT_APPROVED
KR_LIVE_SOURCE_TRACK_DEFERRED
JP_LIVE_POLLING_STILL_BLOCKED_BY_ISSUE_339
```

## Source Candidate

```text
source_key: hkex_latest_listed_company_information
display_name: HKEX Latest Listed Company Information
source_type: api
base_url: https://www.hkexnews.hk/ncms/script/eds/homecat0_e.json
healthcheck_url: https://www.hkexnews.hk/homeLLCI.html
parser_key: hkex_latest_listed_company_info_json_v1
active: false
candidate_status: manual_staging_only
disable_live_fixture_fallback: true
max_items_per_poll: 25
```

Coverage tags:

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

## Parser Candidate

```text
parser_key: hkex_latest_listed_company_info_json_v1
input_types: json, api
source_shape: hkex_homecat0_newsinfo_json
target: newsInfo rows
timezone_strategy: Asia/Hong_Kong local time normalized to UTC
document_id_strategy: document id derived from webPath
stock_shape_strategy: first stock sc/sn with bounded string fallback
supports_detail_fetch: false
attachment_body_fetch_disabled: true
```

The parser maps only bounded metadata:

```text
webPath -> canonical_url and external document id
relY/relM/relD/relTime -> published_at
title -> headline component
sTxt -> bounded summary/category component
stock[0].sc -> issuer_code
stock[0].sn -> issuer_display_name
ext/size -> bounded summary metadata
```

## Attachment Boundary

The source candidate stores only the HKEX announcement link metadata from `webPath`.

Forbidden:

```text
PDF body fetch
HTM body fetch
detail page fetch
document text extraction
attachment table extraction
public attachment controls
```

## Fixture

```text
fixture: priv/fixtures/source_payloads/hkex_latest_listed_company_information.json
rows: 2
stock shape: list of sc/sn maps
includes ext=pdf row
includes ext=NaN / HTM-link row
```

The fixture is for parser/contract validation only. It cannot be used to claim live success.

## Completed Staging Validation

```text
manual Fly staging live poll: pass
second manual staging live poll: pass
fetch.mode=live: pass
fetch.status_code=200: pass
records_seen=5: pass
records_inserted=5: pass
public digest visibility smoke: pass
public Pages browser visibility smoke: pass
source health after poll: healthy
source active=false after poll: confirmed
fixture fallback disabled: confirmed
```

Staging result record:

```text
apps/backend/disclosure_api/docs/globalpulse_hkex_manual_staging_smoke_results.md
apps/backend/disclosure_api/docs/globalpulse_hkex_second_manual_observation_results.md
apps/backend/disclosure_api/docs/globalpulse_hkex_public_pages_browser_smoke_results.md
```

## Guardrails

```text
source remains active=false
production scheduled polling remains disabled
workflow schedule unchanged
backend digest JSON response shape unchanged
frontend shell unchanged
public poll UI not added
audit UI not added
public Source Health UI not added
no HKEX PDF/detail/attachment body fetch
fixture fallback cannot be claimed as live success
CN/TW scheduled polling remains disabled
KR remains deferred until the dedicated backend/source path exists
JP remains blocked until issue #339 is resolved
```

## Next Allowed Steps

```text
1. Design a staging-only cadence proposal before any schedule change.
2. Confirm digest diversity after HKEX appears alongside other regional sources.
3. Record rollback behavior if HKEX is disabled or unavailable.
4. Keep production scheduled polling disabled until a separate approval gate.
```
