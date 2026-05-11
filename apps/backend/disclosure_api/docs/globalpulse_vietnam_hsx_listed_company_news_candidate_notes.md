# GlobalPulse Vietnam HSX Listed Company News Candidate Notes

Date: 2026-05-11 KST

This document records the bounded inactive source candidate for the official Ho Chi Minh Stock Exchange listed-company news RSS feed.

This is a manual-staging-only candidate. It does not enable production scheduled polling, activate the source, add workflows, add public poll UI, add audit UI, add public Source Health UI, change backend digest JSON shape, fetch HSX detail pages, fetch attachments, or change frontend shell behavior.

## Conclusion

```text
VIETNAM_HSX_LISTED_COMPANY_NEWS_RSS_CONFIRMED
VIETNAM_HSX_LISTED_COMPANY_NEWS_SOURCE_REGISTERED_INACTIVE
VIETNAM_HSX_FIXTURE_PARSER_SAMPLE_ADDED
VIETNAM_HSX_LIVE_FIXTURE_FALLBACK_DISABLED
VIETNAM_HSX_DETAIL_FETCH_DISABLED
ASEAN_SCHEDULED_LIVE_POLLING_NOT_ENABLED
PRODUCTION_APAC_SCHEDULED_LIVE_POLLING_NOT_ENABLED
```

## Official Surfaces

```text
HSX public site:
https://www.hsx.vn/

HSX RSS index:
https://api.hsx.vn/n/api/v1/News/NewsFeed

HSX listed-company news RSS:
https://api.hsx.vn/n/api/v1/News/NewsByCateFeed/21

HSX public listed-company news shell:
https://www.hsx.vn/tin-tuc/tin-to-chuc-niem-yet
```

The official HSX public frontend exposes an RSS index backed by `api.hsx.vn`. The RSS index lists category feeds, including category 21:

```text
channel title: Tin To chuc niem yet
feed URL: https://api.hsx.vn/n/api/v1/News/NewsByCateFeed/21
```

The corresponding bounded RSS request returned:

```text
status: 200
content_type: application/rss+xml
root: rss
rss_version: 2.0
channel_title: Tin To chuc niem yet
items_observed: 10
first_item_guid: 2460982
first_item_updated: 2026-05-11T11:24:50+07:00
```

## Parser Compatibility

The HSX feed is RSS 2.0, but the first observed items use:

```text
title: escaped HTML span content
description: escaped HTML span content
timestamp: a10:updated
pubDate: absent
```

The existing `rss_v1` capability contract already describes HTML trimming and `updated` timestamp extraction. This PR aligns the bounded parser behavior with that contract by:

```text
cleaning escaped HTML from RSS title and description
accepting a10:updated / updated / published when pubDate is absent
preserving the existing rss_v1 parser key
```

## Candidate Source

```text
source_key: vn_hsx_listed_company_news
display_name: Vietnam HSX Listed Company News
source_type: rss
parser_key: rss_v1
base_url: https://api.hsx.vn/n/api/v1/News/NewsByCateFeed/21
active: false
candidate_status: manual_staging_only
disable_live_fixture_fallback: true
max_items_per_poll: 25
```

The candidate uses the existing `rss_v1` parser. No HSX-specific parser key is introduced in this step.

## Boundaries

```text
detail_fetch: disabled
attachment_fetch: disabled
source_activation: disabled
scheduled_polling: disabled
workflow_changes: none
public_digest_shape: unchanged
public_ui: unchanged
```

This candidate intentionally stores only bounded RSS item metadata first:

```text
guid
link
cleaned title
cleaned description summary
a10:updated / updated / published timestamp
```

## Required Next Step

Before claiming HSX live-source readiness, deploy this inactive candidate to Fly staging and run a manual staging live poll:

```text
POST /api/admin/sources/vn_hsx_listed_company_news/poll?use_live_fetch=true&edition=breaking
```

The smoke can pass only if:

```text
fetch.mode=live
metadata.fallback_to_fixture=false
records_seen > 0
records_inserted or duplicates are bounded and explained
digest remains valid
public digest JSON shape remains unchanged
```

## Guardrails

```text
Do not activate vn_hsx_listed_company_news yet.
Do not enable ASEAN scheduled live polling.
Do not enable production APAC scheduled live polling.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not fetch HSX detail pages or attachments in the initial candidate.
Do not use third-party Vietnam disclosure mirrors or aggregators.
Do not claim fixture fallback as live success.
Keep KR deferred until the dedicated KR backend/source authority path exists.
Keep JP blocked until issue #339 source authority is resolved.
```

## Allowed Next PRs

```text
1. Deploy the inactive HSX candidate to Fly staging and run manual staging live poll smoke.
2. Record HSX manual staging live poll smoke if fetch.mode=live and fixture fallback is false.
3. Repeat HNX manual staging live poll smoke in another observation window.
4. Continue APAC official-source scanning within official exchange/OAM surfaces.
```
