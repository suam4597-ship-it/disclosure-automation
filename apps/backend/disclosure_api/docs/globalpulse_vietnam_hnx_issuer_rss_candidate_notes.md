# GlobalPulse Vietnam HNX Issuer RSS Candidate Notes

Date: 2026-05-11 KST

This document records the bounded inactive source candidate for the official Hanoi Stock Exchange issuer-disclosure RSS feed.

This is a manual-staging-only candidate. It does not enable production scheduled polling, activate the source, add workflows, add public poll UI, add audit UI, add public Source Health UI, change backend digest JSON shape, fetch HNX detail pages, fetch attachments, or change frontend shell behavior.

## Conclusion

```text
VIETNAM_HNX_ISSUER_DISCLOSURE_RSS_CONFIRMED
VIETNAM_HNX_ISSUER_DISCLOSURE_SOURCE_REGISTERED_INACTIVE
VIETNAM_HNX_FIXTURE_PARSER_SAMPLE_ADDED
VIETNAM_HNX_LIVE_FIXTURE_FALLBACK_DISABLED
VIETNAM_HNX_DETAIL_FETCH_DISABLED
ASEAN_SCHEDULED_LIVE_POLLING_NOT_ENABLED
PRODUCTION_APAC_SCHEDULED_LIVE_POLLING_NOT_ENABLED
```

## Official Surfaces

```text
HNX Information Disclosure page:
https://www.hnx.vn/en-gb/thong-tin-cong-bo-ny-hnx.html

HNX RSS index:
https://www.vpdt.hnx.vn/rss.html

HNX issuer disclosure RSS:
https://www.hnx.vn/3/vi_vn/thong-tin-cong-bo-tu-to-chuc-phat-hanh.rss
```

The HNX information-disclosure page exposes issuer-disclosure sections for listed stocks. The HNX RSS index lists four RSS channels and includes:

```text
Thong tin cong bo tu to chuc phat hanh
```

The corresponding RSS endpoint returned:

```text
status: 200
content_type: application/rss+xml
root: rss
rss_version: 2.0
channel_title: HNX - Thong tin cong bo tu to chuc phat hanh
first_observed_pub_date: Mon, 11 May 2026 11:09:23 +0700
```

## Candidate Source

```text
source_key: vn_hnx_issuer_disclosures
display_name: Vietnam HNX Issuer Disclosures
source_type: rss
parser_key: rss_v1
base_url: https://www.hnx.vn/3/vi_vn/thong-tin-cong-bo-tu-to-chuc-phat-hanh.rss
active: false
candidate_status: manual_staging_only
disable_live_fixture_fallback: true
max_items_per_poll: 25
```

The candidate uses the existing `rss_v1` parser. No Vietnam-specific parser is introduced in this step.

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
title
description summary
pubDate
updated timestamp when present
```

## Why This Is Stronger Than Other Blocked ASEAN Paths

Unlike several previously reviewed ASEAN candidates, the HNX issuer-disclosure path is a simple official RSS feed:

```text
SGX: official JSON path observed but token/policy/runtime gates remain unresolved
Bursa Malaysia: official browser JSON path observed but runtime fetch is blocked
IDX Indonesia: official JSON path observed but clean backend runtime fetch is blocked by challenge-cookie dependency
PSE EDGE: official surface confirmed but approved data-access path is required before polling
HNX Vietnam: official RSS feed returned 200 application/rss+xml from a bounded direct request
```

## Required Next Step

Before claiming Vietnam live-source readiness, deploy this inactive candidate to Fly staging and run a manual staging live poll:

```text
POST /api/admin/sources/vn_hnx_issuer_disclosures/poll?use_live_fetch=true&edition=breaking
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
Do not activate vn_hnx_issuer_disclosures yet.
Do not enable ASEAN scheduled live polling.
Do not enable production APAC scheduled live polling.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not fetch HNX detail pages or attachments in the initial candidate.
Do not use third-party Vietnam disclosure mirrors or aggregators.
Do not claim fixture fallback as live success.
Keep KR deferred until the dedicated KR backend/source authority path exists.
Keep JP blocked until issue #339 source authority is resolved.
```

## Allowed Next PRs

```text
1. Deploy the inactive HNX candidate to Fly staging.
2. Run manual HNX staging live poll smoke.
3. Record HNX manual staging poll results.
4. Repeat SET Thailand manual staging smoke in another observation window.
5. Continue APAC official-source scanning within official exchange/OAM surfaces.
```
