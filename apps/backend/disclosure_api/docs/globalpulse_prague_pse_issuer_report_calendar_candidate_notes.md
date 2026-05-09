# GlobalPulse Prague PSE Issuer Report Calendar Candidate Notes

This document records the candidate-registration pass for the Prague Stock Exchange issuer report calendar JSON surface.

This candidate remains manual-only. It does not enable scheduled polling, public poll UI, public Source Health UI, audit UI, backend JSON response-shape changes, frontend framework changes, or batch EU promotion.

## Conclusion

```text
PRAGUE_PSE_ISSUER_REPORT_CALENDAR_OFFICIAL_JSON_CONFIRMED
PRAGUE_PSE_ISSUER_REPORT_CALENDAR_DATE_CONTRACT_CONFIRMED
PRAGUE_PSE_ISSUER_REPORT_CALENDAR_MANUAL_SOURCE_REGISTERED
PRAGUE_PSE_ISSUER_REPORT_CALENDAR_LOCAL_FIXTURE_SMOKE_PASS
PRAGUE_PSE_ISSUER_REPORT_CALENDAR_LIVE_AGGREGATE_PARSER_SMOKE_PASS
PRAGUE_PSE_ISSUER_REPORT_CALENDAR_STAGING_LIVE_POLL_PENDING
PRAGUE_PSE_ISSUER_REPORT_CALENDAR_SCHEDULED_POLLING_DISABLED
```

## Candidate

```text
source_key: cz_pse_issuer_report_calendar_multi_isin
display_name: Prague PSE Issuer Report Calendar Multi-ISIN
parser_key: pse_multi_isin_issuer_report_calendar_json_v1
source_type: api
base_url: https://www.pse.cz/en/market-data/shares/prime-market
healthcheck_url: https://www.pse.cz/en/market-data/shares/prime-market
live_fetch_strategy: pse_multi_isin_report_calendar_v1
authority: official Prague Stock Exchange issuer report/calendar surface
region: eu_central
active: false
candidate_status: manual_staging_only
```

## Discovery Result

The original `file-reports` API remains useful for document inventory, but it does not include a publication date field:

```text
issuer reports URL pattern: https://www.pse.cz/api/file-reports?isin=<ISIN>&order=year-desc&lang=en
observed row fields: uuid, extension, label, ref, size, path, sizeFormatted
observed missing fields: date, publishedAt, createdAt, updatedAt
registration decision: do not canonicalize file-reports rows directly
```

The official `corporation-calendar` API carries the missing date and a report file reference when a document is attached:

```text
issuer report calendar URL pattern: https://www.pse.cz/api/corporation-calendar?isin=<ISIN>&order=date-DESC&lang=en
observed HTTP: 200
observed content-type: application/json; charset=utf-8
observed row fields: id, date, isObligated, size, extension, ref, name, instrumentIsin, instrumentName, sizeFormatted
accepted rows: ref present, date present, instrumentIsin matches query ISIN
rejected rows: future calendar events without ref, rows for a different instrumentIsin, rows with missing date
```

Representative live observations:

```text
NL0010391108: rows=5, rows_with_ref=1, first_ref_date=25.02.2026, first_ref_name=Preliminary financial results
CZ0005112300: rows=6, rows_with_ref=2, first_ref_date=28.04.2026, first_ref_name=Annual Financial Report
CZ0009008942: rows=5, rows_with_ref=2, first_ref_date=27.04.2026, first_ref_name=Annual Financial Report
AT0000652011: rows=8, rows_with_ref=2, first_ref_date=30.04.2026, first_ref_name=Financial report for Q1
```

Download URL contract:

```text
official page JavaScript builds report links as /detail/<ISIN>?do=download&path=<ref>
canonical URL example: https://www.pse.cz/en/detail/CZ0005112300?do=download&path=Issuers.dta/Emitenti2/CEZXE012025.pdf
download behavior: a prior PSE detail-page session plus referer returned Content-Disposition attachment for a sample file
canonical decision: store the official detail download URL, not the direct ftp.pse.cz path
```

## Parser Contract

```text
input: source-specific fan-out JSON with responses[] from official corporation-calendar API calls
required response fields: isin, data[]
required row fields: id or ref, date, name, instrumentIsin, instrumentName, ref
published_at: date parsed from DD.MM.YYYY as UTC midnight
title: name
url: https://www.pse.cz/en/detail/<ISIN>?do=download&path=<ref>
summary: bounded metadata summary with issuer, ISIN, date, extension, size, file ref
external_id: pse-report-calendar:<query_isin>:<id or ref>
category: PSE issuer report
```

## Local Fixture Smoke

```text
fixture: priv/fixtures/source_payloads/cz_pse_issuer_report_calendar_multi_isin.json
parser: pse_multi_isin_issuer_report_calendar_json_v1
fixture_records: 4
fixture_first_title: Annual Financial Report
fixture_first_url: https://www.pse.cz/en/detail/CZ0005112300?do=download&path=Issuers.dta/Emitenti2/CEZXE012025.pdf
fixture_first_published_at: 2026-04-28T00:00:00.000000Z
fixture_first_category: PSE issuer report
fixture rejection coverage: future no-ref row rejected; wrong instrumentIsin row rejected
```

## Live Aggregate Parser Smoke

```text
universe_count: 63
selected_count: 10
response_count: 10
response_records: 65
strict_records: 20
live_first_title: Annual Financial Report
live_first_url: https://www.pse.cz/en/detail/CZ0009008942?do=download&path=Issuers.dta/Emitenti2/CZGCEXE012025.pdf
live_first_published_at: 2026-04-27T00:00:00.000000Z
live_first_category: PSE issuer report
```

## Guardrails

```text
scheduled Prague PSE report live polling remains disabled
source remains active=false
candidate_status remains manual_staging_only
fixture fallback is disabled for live fetch
no backend JSON response shape change
no public Source Health UI
no poll UI
no audit UI
no frontend framework change
no central-bank, macro, or policy feed added
```

## Next Step

```text
Merge this manual candidate, deploy to Fly staging, and run staging live poll smoke for cz_pse_issuer_report_calendar_multi_isin.
Record records_seen, records_inserted, fetch.strategy=pse_multi_isin_report_calendar_v1, fixture fallback=false, and digest visibility behavior.
Keep EU scheduled polling disabled.
```
