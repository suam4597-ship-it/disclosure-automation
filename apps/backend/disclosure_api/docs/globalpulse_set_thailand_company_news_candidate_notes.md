# GlobalPulse SET Thailand Company News Candidate Notes

Date: 2026-05-11 KST

This document records the bounded inactive source/parser candidate for Stock Exchange of Thailand company-news announcements.

This is a manual-staging-only candidate. It does not enable production scheduled polling, activate the source, add workflows, add public poll UI, add audit UI, add public Source Health UI, change backend digest JSON shape, fetch SET detail pages, fetch attachments, or change frontend shell behavior.

## Conclusion

```text
SET_THAILAND_COMPANY_NEWS_PARSER_CANDIDATE_ADDED
SET_THAILAND_SOURCE_REGISTERED_INACTIVE
SET_THAILAND_FIXTURE_PARSER_SAMPLE_ADDED
SET_THAILAND_LIVE_FIXTURE_FALLBACK_DISABLED
SET_THAILAND_DETAIL_FETCH_DISABLED
SET_THAILAND_MANUAL_STAGING_SMOKE_PENDING
ASEAN_SCHEDULED_LIVE_POLLING_NOT_ENABLED
PUBLIC_UI_AND_BACKEND_DIGEST_SHAPE_UNCHANGED
```

## Candidate Scope

```text
source_key: th_set_company_news
parser_key: set_thailand_company_news_json_v1
source_type: api
active: false
candidate_status: manual_staging_only
fixture: source_payloads/th_set_company_news.json
live_source_contract: globalpulse_set_thailand_fly_elixir_runtime_probe_results.md
disable_live_fixture_fallback: true
max_items_per_poll: 25
```

The candidate uses the official SET company-news JSON endpoint with an explicit bounded date window:

```text
https://www.set.or.th/api/cms/v1/news/set?sourceId=company&securityTypeIds=S&fromDate=11/05/2026&toDate=11/05/2026&orderBy=date&lang=en
```

The bounded live headers are non-secret and match the previously recorded Fly Elixir runtime probe:

```text
accept: application/json, text/plain, */*
accept-language: en-US,en;q=0.9
referer: https://www.set.or.th/en/market/news-and-alert/news?newsType=company
x-channel: WEB_SET
x-client-uuid: fixed non-secret probe UUID
user-agent: Mozilla/5.0 GlobalPulse SET runtime probe
```

## Parser Contract

The parser accepts only the SET JSON response shape:

```text
top-level newsGroups: list
group.newsInfoList: list
record.id: present
record.datetime: present
record.symbol: present
record.headline: present
record.url: official set.or.th URL
```

The parser extracts bounded list metadata only:

```text
external_id
title
url
summary
published_at
category
```

It does not fetch detail pages, issuer attachments, or any downstream document bodies.

## Safety Boundaries

```text
source active=true: not allowed in this PR
production scheduled polling: not allowed
public poll UI: not added
public Source Health UI: not added
audit UI: not added
backend digest JSON shape: unchanged
fixture fallback as live success: forbidden by disable_live_fixture_fallback
detail/attachment fetch: disabled
third-party mirrors or aggregators: not used
KR source path: still deferred
JP live polling: still blocked until source authority issue is resolved
```

## Next Step

After this branch is merged and deployed to Fly staging, run a manual staging smoke only:

```text
POST /api/admin/sources/th_set_company_news/poll?use_live_fetch=true&edition=breaking
GET /api/feed/digest/latest?edition=breaking
```

The smoke result must record whether the live fetch used the SET JSON endpoint and whether fixture fallback stayed false. If it fails, document the exact bounded error class before any further source expansion.
