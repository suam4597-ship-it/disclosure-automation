# GlobalPulse Malta MSE Announcements Candidate Notes

This document records the manual-only candidate implementation for Malta Stock Exchange announcements.

The change adds a bounded parser and inactive source registration only. It does not enable scheduled polling, does not add Malta MSE to the EU canary, does not change public digest JSON shape, and does not add frontend UI.

## Conclusion

```text
MALTA_MSE_ANNOUNCEMENTS_OFFICIAL_HTML_SURFACE_CONFIRMED
MALTA_MSE_ANNOUNCEMENTS_BOUNDED_HTML_PARSER_ADDED
MALTA_MSE_ANNOUNCEMENTS_FIXTURE_PARSER_SMOKE_PASS
MALTA_MSE_ANNOUNCEMENTS_LIVE_PARSER_SMOKE_PASS
MALTA_MSE_ANNOUNCEMENTS_MANUAL_STAGING_ONLY
MALTA_MSE_SCHEDULED_POLLING_BLOCKED
```

## Candidate

```text
source_key: mt_mse_announcements
display_name: Malta Stock Exchange Announcements
parser_key: malta_mse_announcements_html_v1
source URL: https://www.borzamalta.com.mt/news-and-articles/announcements
authority: official Malta Stock Exchange announcement surface
region: eu_south
active: false
candidate_status: manual_staging_only
```

## Why This Fits

```text
The Malta Stock Exchange announcements page is an official exchange surface for issuer/company announcements.
The page is server-rendered HTML and includes bounded announcement cards with PDF links, issuer names, announcement titles, and publication dates.
This is a listed-company disclosure/announcement source, not a central-bank, macro, or policy-news feed.
```

## Parser Contract

The parser extracts only bounded card fields from the official announcements page:

```text
card selector: a.box.event-box
id: announcement PDF filename
title: issuer + announcement title
url: announcement PDF href
summary: bounded issuer/title metadata
published_at: date-only DD-MM-YYYY at UTC midnight
category: announcement title
```

Live payload validation requires:

```text
HTML content-type
Announcements - Malta Stock Exchange page title
box event-box card marker
cdn.borzamalta.com.mt/download/announcements/ PDF links
```

## Local Validation

Fixture parser smoke:

```text
fixture: priv/fixtures/source_payloads/mt_mse_announcements.html
fixture_records: 3
first_fixture_record:
  title: Loqus Holdings plc - Interim Update
  url: https://cdn.borzamalta.com.mt/download/announcements/LQS248.pdf
  published_at: 2026-05-08T00:00:00Z
```

Live parser smoke:

```text
request: GET https://www.borzamalta.com.mt/news-and-articles/announcements
status: 200
bytes: 229450
live_records: 9
first_live_record:
  title: Loqus Holding plc - Interim Update
  url: https://cdn.borzamalta.com.mt/download/announcements/LQS248.pdf
  published_at: 2026-05-08T00:00:00Z
```

Compile validation:

```text
MIX_ENV=test mix compile --warnings-as-errors: pass
```

Dependency warnings from Phoenix were observed during compilation and are existing dependency warnings, not Malta parser warnings.

## Guardrails

```text
source remains active=false
candidate_status remains manual_staging_only
scheduled Malta MSE live polling is not enabled
Malta MSE is not added to the EU scheduled canary
HTML root is not treated as rss_v1
no backend JSON response shape change
no public Source Health UI
no public poll UI
no audit UI
no frontend framework change
no central-bank, macro, or policy feed added
```

## Required Next Smoke

After merge and Fly staging deploy, run:

```text
GET /api/health
GET /api/admin/source-health/mt_mse_announcements
POST /api/admin/sources/mt_mse_announcements/poll?use_live_fetch=true&edition=breaking
GET /api/feed/digest/2026-05-08/breaking
```

Expected:

```text
health: 200
source active: false
candidate_status: manual_staging_only
poll status: 202
fetch.mode: live
fetch.status_code: 200
fixture_fallback: false
records_seen >= 1
records_inserted >= 1
date-specific digest renderability for Malta rows
```
