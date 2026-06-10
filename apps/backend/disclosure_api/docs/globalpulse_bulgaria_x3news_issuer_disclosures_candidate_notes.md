# GlobalPulse Bulgaria X3News Issuer Disclosures Candidate Notes

This document records the manual-only candidate integration notes for the Bulgaria X3News issuer-disclosure surface.

The change does not enable scheduled polling, does not set the source active, does not add the source to the EU scheduled canary, does not change public digest JSON shape, and does not add frontend UI, poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
BULGARIA_X3NEWS_OFFICIAL_BSE_GROUP_AUTHORITY_CONFIRMED
BULGARIA_X3NEWS_HTML_LIST_PARSER_ADDED
BULGARIA_X3NEWS_FIXTURE_PARSER_SMOKE_PASS
BULGARIA_X3NEWS_LIVE_PARSER_SMOKE_PASS
BULGARIA_X3NEWS_STAGING_LIVE_POLL_PASS
BULGARIA_X3NEWS_DATE_SPECIFIC_DIGEST_VISIBILITY_PASS
BULGARIA_X3NEWS_MANUAL_STAGING_ONLY
BULGARIA_X3NEWS_SCHEDULED_POLLING_DISABLED
```

## Source

```text
source_key: bg_x3news_issuer_disclosures
display_name: Bulgaria X3News Issuer Disclosures
authority: Financial Market Services / X3News, part of the Bulgarian Stock Exchange group
supporting URL: https://fms.capital/en/aboutus
candidate URL: https://www.x3news.com/?language=en
parser_key: bg_x3news_issuer_disclosures_html_v1
candidate_status: manual_staging_only
active: false
disable_live_fixture_fallback: true
region: eu_central / bulgaria
```

## Why This Fits

FMS states that it is part of the Bulgarian Stock Exchange group and that X3News is a specialized media portal through which issuers of financial instruments fulfill their legal obligations to disclose regulated information to the public.

The English X3News surface exposes server-rendered issuer-disclosure rows with:

```text
issuer/company name
disclosure headline/category
published date/time
ExtriID detail identifier
official ShowNews detail endpoint
```

This is a listed-company issuer-disclosure source, not a central-bank, macro-statistics, parliament, or broad policy-news feed.

## Parser Boundary

The first parser is intentionally bounded to the latest list rows:

```text
row selector: div.news-row
id field: javascript showNews ExtriID
live payload markers: x3news_logo, news-row, newsHeaderLink, javascript:showNews
issuer field: first row company bold text
headline field: newsHeaderLink show-date-on-right
date field: right-aligned DD-MM-YYYY HH:mm text
url strategy: https://www.x3news.com/?page=ShowNews&ExtriID={id}&output=ajax
timezone: Bulgaria EET/EEST approximation
```

The parser does not fetch detail bodies, attachments, raw issuer material, private material, cookies, tokens, or session fields.

The source disables live fixture fallback so staging cannot accidentally report a fixture-backed poll as live success.

## Local Validation

```text
fixture parser smoke: PASS
fixture_records: 3
first fixture title: Sopharma AD - Inside information under art. 17, para 1, in relation with art. 7 of the Regulation (EU) No 596/2014
first fixture URL: https://www.x3news.com/?page=ShowNews&ExtriID=198292&output=ajax
first fixture published_at: 2026-05-08T10:14:00Z

live parser smoke: PASS
live URL: https://www.x3news.com/?language=en
live_status: 200
live_content_type: text/html;charset=UTF-8
live_bytes: 17558
live_records: 11
first live title: Sopharma AD - Inside information under art. 17, para 1, in relation with art. 7 of the Regulation (EU) No 596/2014
first live URL: https://www.x3news.com/?page=ShowNews&ExtriID=198292&output=ajax
first live published_at: 2026-05-08T10:14:00Z
```

## Fly Staging Validation

Fly staging live smoke passed after the live payload validator was aligned with the official latest-news row marker and live fixture fallback remained disabled.

```text
deployed commit: 1742801c51c6a0f007b483df4c8e5d3547594218
Fly image: registry.fly.io/globalpulse-backend-staging:deployment-01KR8NHK132X30EW1PH0FEPMYE
health: 200 ok
source health: healthy
active: false
candidate_status: manual_staging_only
disable_live_fixture_fallback: true
poll status: 202
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 17558
records_seen: 11
records_inserted: 11
canonical_items: 11
date-specific digest visibility: PASS for 2026-05-07, 2026-05-06, and 2026-05-05
public latest UI visibility: PENDING_EXPECTED because the latest digest currently points to newer 2026-05-09 items
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
