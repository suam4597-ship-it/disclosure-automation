# GlobalPulse Cyprus CSE OAM Candidate Notes

This document records the manual-only candidate integration notes for the Cyprus Stock Exchange / XAK Public OAM listing-version surface.

The change does not enable scheduled polling, does not set the source active, does not add the source to the EU scheduled canary, does not change public digest JSON shape, and does not add frontend UI, poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
CYPRUS_CSE_OAM_PUBLIC_LISTING_VERSIONS_AUTHORITY_CONFIRMED
CYPRUS_CSE_OAM_PUBLIC_LISTING_VERSIONS_JSON_PARSER_ADDED
CYPRUS_CSE_OAM_FIXTURE_PARSER_SMOKE_PASS
CYPRUS_CSE_OAM_LIVE_PARSER_SMOKE_PASS
CYPRUS_CSE_OAM_MANUAL_STAGING_ONLY
CYPRUS_CSE_OAM_SCHEDULED_POLLING_DISABLED
```

## Source

```text
source_key: eu_cyprus_cse_oam
display_name: Cyprus CSE OAM Regulated Information
authority: Cyprus Stock Exchange / XAK Public OAM
supporting URL: https://www.cse.com.cy/el-GR/Files/CSE_Services/ANN41900_EN/
candidate URL: https://publicoam.cse.com.cy/xak-public-pages-server/api/fetch-listing-versions?page=0&size=25&sort=ID,DESC
parser_key: cse_oam_listing_versions_json_v1
candidate_status: manual_staging_only
active: false
disable_live_fixture_fallback: true
region: eu_south / cyprus
```

## Why This Fits

The CSE announced an OAM RSS service for announcements and news published on the CSE OAM system and stated that those flows contain all published announcements of listed CSE companies among other market participants.

The current public OAM SPA exposes an official JSON endpoint used by the listing-version screen. The payload contains listed-company names, security codes, category names, publication timestamps, and bounded announcement content.

This is a listed-company regulated-information source, not a central-bank, macro-statistics, parliament, or broad policy-news feed.

## Parser Boundary

The first parser is intentionally bounded to the public listing-version JSON response:

```text
source shape: paged JSON with content[]
id field: content.id
issuer field: content.listedCompanyEnglish / content.companyNameEn
headline field: content.nameEnglish / content.name
summary fields: content.infoCategoriesNameEnglish, content.securityCodesCode, content.marketTypesDescription, bounded content excerpt
category field: content.infoCategoriesNameEnglish
published_at field: content.publicationTimestamp or content.translationRegistryTimestamp
url strategy: https://publicoam.cse.com.cy/card-details/:id/:translationSegment
timezone: epoch milliseconds UTC
listed filter: isListed/listed/listedComplete must be true
```

The parser does not fetch detail bodies, files, attachments, PDFs, raw identity material, cookies, tokens, session fields, or request headers.

The source disables live fixture fallback so staging cannot accidentally report a fixture-backed poll as live success.

## Local Validation

Validation completed locally before the first staging poll:

```text
fixture parser smoke: PASS, 3 records parsed from source_payloads/eu_cyprus_cse_oam.json
live endpoint smoke: PASS, candidate URL HTTP 200, application/json; charset=UTF-8, 91,458 bytes
live parser smoke: PASS, 21 listed-company records kept from the bounded 25-row page
```

Remaining staging validation:

```text
Fly staging deploy
manual live poll with use_live_fetch=true
confirm fetch.mode=live and fixture_fallback=false
source-health check remains active=false/manual_staging_only
date-specific digest visibility check if latest top-N does not show Cyprus
```

## Guardrails

```text
do not set active=true
do not add to scheduled EU canary yet
do not claim scheduled live polling
do not expose issuer detail fetch controls through public UI
do not change backend digest JSON response shape
do not add frontend framework code
do not add public poll UI, audit UI, or public Source Health UI
```
