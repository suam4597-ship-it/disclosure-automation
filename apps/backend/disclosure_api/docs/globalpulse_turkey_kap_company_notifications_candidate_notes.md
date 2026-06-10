# GlobalPulse Turkey KAP Company Notifications Candidate Notes

This document records the manual-only candidate integration notes for the Turkey KAP / PDP company-notification surface.

The change does not enable scheduled polling, does not set the source active, does not add the source to the EU scheduled canary, does not change public digest JSON shape, and does not add frontend UI, poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
TURKEY_KAP_OFFICIAL_PUBLIC_DISCLOSURE_PLATFORM_AUTHORITY_CONFIRMED
TURKEY_KAP_COMPANY_NOTIFICATIONS_HTML_PARSER_ADDED
TURKEY_KAP_FIXTURE_PARSER_SMOKE_PASS
TURKEY_KAP_LIVE_PARSER_SMOKE_PASS
TURKEY_KAP_MANUAL_STAGING_ONLY
TURKEY_KAP_SCHEDULED_POLLING_DISABLED
```

## Source

```text
source_key: tr_kap_company_notifications
display_name: Turkey KAP Company Notifications
authority: Public Disclosure Platform (KAP/PDP), operated by MKK and described by Borsa Istanbul as the electronic system for required public disclosures
supporting URL: https://www.borsaistanbul.com/en/companies/public-disclosure-platform
candidate URL: https://www.kap.org.tr/en/bildirim-sorgu-sonuc?srcbar=Y&cmp=Y&cat=6&slf=ALL
parser_key: kap_company_notifications_html_v1
candidate_status: manual_staging_only
active: false
disable_live_fixture_fallback: true
region: europe / turkey
```

## Why This Fits

Borsa Istanbul describes the Public Disclosure Platform as the electronic system where notifications required to be disclosed under capital-market and exchange legislation are conveyed and announced to the public. KAP's own about page describes it as the electronic system where disclosures required under capital-market and exchange legislation are submitted and published.

This is a listed-company issuer-notification source, not a central-bank, macro-statistics, parliament, or broad policy-news feed.

## Parser Boundary

The first parser is intentionally bounded to the server-rendered notification-search result payload:

```text
source shape: Next/RSC HTML containing escaped disclosureBasic data
id field: disclosureBasic.disclosureIndex
issuer field: disclosureBasic.companyTitle
stock code field: disclosureBasic.stockCode
headline field: disclosureBasic.title
summary field: disclosureBasic.summary
category field: disclosureBasic.disclosureClass
published_at field: disclosureBasic.publishDate
url strategy: https://www.kap.org.tr/en/Bildirim/{disclosureIndex}
timezone: Turkey UTC+3
```

The parser does not fetch detail bodies, attachments, PDFs, signatures, raw identity material, cookies, tokens, session fields, or request headers.

The source disables live fixture fallback so staging cannot accidentally report a fixture-backed poll as live success.

## Local Validation

Validation completed locally before the first staging poll:

```text
fixture parser smoke: PASS, 3 records parsed from source_payloads/tr_kap_company_notifications.html
live parser smoke: PASS, candidate URL HTTP 200, text/html, 6,018,178 bytes, 25 records after bounded parser limit
compile check: PASS, MIX_ENV=test mix.bat compile --warnings-as-errors
parser escape handling: PASS, embedded summary quotes survive JSON decode
```

Remaining staging validation:

```text
Fly staging deploy
manual live poll with use_live_fetch=true
confirm fetch.mode=live and fixture_fallback=false
source-health check remains active=false/manual_staging_only
date-specific digest visibility check if latest top-N does not show Turkey
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
