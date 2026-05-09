# GlobalPulse Prague PSE Issuer News Staging Live Poll Smoke Results

This document records the staging live-poll smoke for the Prague Stock Exchange issuer-news-only multi-ISIN fan-out candidate.

## Conclusion

```text
GLOBALPULSE_BACKEND_CONNECTED_PASS
PRAGUE_PSE_ISSUER_NEWS_SOURCE_HEALTH_PASS
PRAGUE_PSE_ISSUER_NEWS_STAGING_LIVE_POLL_PASS
PRAGUE_PSE_ISSUER_NEWS_CANONICAL_INSERT_PASS
PRAGUE_PSE_ISSUER_NEWS_DATE_SPECIFIC_DIGEST_VISIBILITY_PASS
PRAGUE_PSE_ISSUER_NEWS_MANUAL_ONLY_READY
```

## Candidate

```text
source_key: cz_pse_issuer_news_multi_isin
display_name: Prague PSE Issuer News Multi-ISIN
parser_key: pse_multi_isin_issuer_news_json_v1
source URL: https://www.pse.cz/en/market-data/shares/prime-market
fetch strategy: pse_multi_isin_news_v1
authority: official Prague Stock Exchange issuer-news surface
region: eu_central
active: false
candidate_status: manual_staging_only
```

## Validation Context

```text
candidate PR: #435 Add Prague PSE issuer news candidate
candidate merge commit: 54fd6295c5c7153970cda722f99691bd3fc15aa7
local candidate validation: mix deps.get, mix format, MIX_ENV=test mix compile --warnings-as-errors, mix format --check-formatted, scripts/validate_phase0_artifacts.py, git diff --check
local parser smoke: fixture_records=2 after dropping an isin=null fixture row; live aggregate parser smoke universe_count=63, selected_count=10, response_count=10, response_records=10, strict_records=7, live_records=7
Fly app: globalpulse-backend-staging
Fly deploy image: registry.fly.io/globalpulse-backend-staging:deployment-01KR6DWYNP085R8QQHKN9Q5M2X
Fly release_command: success
```

## Backend Health

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/health
status: 200
response:
  status: ok
  service: disclosure_automation
  phase: phase1
  repo: up
```

## Source Health

Before live poll:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/admin/source-health/cz_pse_issuer_news_multi_isin
status: 200
observed:
  active: false
  candidate_status: manual_staging_only
  disable_live_fixture_fallback: true
  parser_key: pse_multi_isin_issuer_news_json_v1
  fixture_path: source_payloads/cz_pse_issuer_news_multi_isin.json
  live_fetch_strategy: pse_multi_isin_news_v1
  max_issuers_per_poll: 10
  max_news_items_per_issuer: 5
  health_status: unknown
```

After live poll:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/admin/source-health/cz_pse_issuer_news_multi_isin
status: 200
observed:
  active: false
  candidate_status: manual_staging_only
  parser_key: pse_multi_isin_issuer_news_json_v1
  health_status: healthy
  last_seen_published_at: 2022-02-25T07:16:33.000000Z
  last_success_at: 2026-05-09T13:15:11.973624Z
```

## Live Poll

```text
request: POST https://globalpulse-backend-staging.fly.dev/api/admin/sources/cz_pse_issuer_news_multi_isin/poll?use_live_fetch=true&edition=breaking
status: 202
fetch.mode: live
fetch.strategy: pse_multi_isin_news_v1
fetch.status_code: 200
fetch.url: https://www.pse.cz/en/market-data/shares/prime-market
fetch.bytes: 73980
fetch.universe_count: 63
fetch.selected_issuer_count: 10
fetch.issuer_request_count: 10
records_seen: 15
records_inserted: 15
canonical_items: 15
raw_documents: 15
fixture fallback: false
first observed canonical key: breaking-2021-11-18-pse-news-cz0009008942-5651
last observed canonical key: breaking-2020-02-27-pse-news-cz0005135970-3819
```

## Digest Visibility

Latest digest:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking
status: 200
digest_date: 2026-05-09
item_count: 3
pse_item_count: 0
metadata.fallback_to_fixture: false
metadata.top_n: 12
```

Date-specific digest checks:

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/2022-02-25/breaking
status: 200
item_count: 1
metadata.fallback_to_fixture: false
observed:
  headline: Cancellation of accelerated book-building of CEZ shares
  canonical_url: https://www.pse.cz/en/news/belviport-will-not-purchase-shares-in-cez
  duplicate_group_key: cz_pse_issuer_news_multi_isin-pse-news-cz0005112300-5979
  published_at: 2022-02-25T07:16:33.000000Z
  regions: eu_central
  category: PSE
  fetch_mode: live
```

```text
request: GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/2021-06-01/breaking
status: 200
item_count: 2
metadata.fallback_to_fixture: false
observed:
  headline: PX-GLOB Index Base
  canonical_url: https://www.pse.cz/en/news/px-glob-index-base-4
  duplicate_group_key: cz_pse_issuer_news_multi_isin-pse-news-at0000652011-5150
  published_at: 2021-06-01T15:00:00.000000Z
  regions: eu_central
  category: PSE
  fetch_mode: live
```

Interpretation:

```text
Prague PSE issuer-news live poll, source-specific fan-out fetch, parser, and canonical insert paths passed.
The latest digest did not include PSE rows because the current latest digest date is 2026-05-09 and PSE live rows are historical 2020-2022 records.
Date-specific digest visibility passed for PSE rows without fixture fallback.
```

## Guardrails

```text
scheduled Prague PSE live polling remains disabled
source remains active=false
candidate_status remains manual_staging_only
issuer reports remain deferred until precise report publication-date semantics are confirmed
no backend JSON response shape change
no public Source Health UI
no poll UI
no audit UI
no frontend framework change
no central-bank, macro, or policy feed added
```

## Next Step

```text
Continue Europe listed-company disclosure expansion with Germany official company-register preflight/token contract work or Prague/PSE issuer-report publication-date contract discovery.
Do not batch-promote scheduled EU polling until the wider source list, rollback path, source-specific risk, and staging evidence are documented together.
```
