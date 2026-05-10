# Serbia BELEX Issuer News Staging Live Poll Smoke Results

Status: `SERBIA_BELEX_ISSUER_NEWS_STAGING_LIVE_POLL_PASS`

## Scope

This records the first Fly staging live-poll smoke for the inactive/manual staging-only Belgrade Stock Exchange issuer-news candidate.

```text
source_key: rs_belex_issuer_news
parser_key: belex_issuer_news_html_v1
candidate URL: https://www.belex.rs/eng/
backend URL: https://globalpulse-backend-staging.fly.dev
deployed commit: 0d52e814c3830eeb22183813af34645e5f3873ea
```

## Guardrails

```text
active=false
candidate_status=manual_staging_only
disable_live_fixture_fallback=true
scheduled polling disabled
symbol-detail rotation out of scope
backend digest JSON response shape unchanged
public poll UI not added
public Source Health UI not added
```

## Deployment Smoke

```text
Fly deploy: PASS
release_command: PASS
GET /api/health: 200
service: disclosure_automation
phase: phase1
repo: up
```

## Source Health Before Poll

```text
GET /api/admin/source-health/rs_belex_issuer_news: 200
active: false
candidate_status: manual_staging_only
disable_live_fixture_fallback: true
parser_key: belex_issuer_news_html_v1
base_url: https://www.belex.rs/eng/
health_status before poll: unknown
```

## Live Poll Result

Command:

```text
POST /api/admin/sources/rs_belex_issuer_news/poll?use_live_fetch=true&edition=breaking
```

Observed result:

```text
status: 202
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 30034
records_seen: 5
records_inserted: 5
canonical_items_count: 5
```

Canonical story keys:

```text
breaking-2026-04-30-belex-jesv-30-04-2026-annual-consolidated-report-for-2025-jedinstvo-a-d-sevojno
breaking-2026-04-30-belex-niis-30-04-2026-annual-report-for-2025-nis-a-d-novi-sad
breaking-2026-04-30-belex-niis-30-04-2026-remark-in-accordance-with-article-73-of-the-law-on-capital-market
breaking-2026-04-30-belex-niis-30-04-2026-quarterly-report-for-the-first-quarter-of-2026-nis-a-d-novi-s
breaking-2026-04-30-belex-niis-30-04-2026-nis-group-results-in-the-first-quarter-of-2026-nis-a-d-novi-s
```

## Source Health After Poll

```text
health_status: healthy
last_seen_published_at: 2026-04-30T00:00:00.000000Z
last_success_at: 2026-05-10T14:47:59.514996Z
last_error: null
```

## Digest Visibility

Date-specific digest:

```text
GET /api/feed/digest/2026-04-30/breaking: 200
metadata.fallback_to_fixture: false
item_count: 12
BELEX item count: 3
first BELEX headline: Annual Consolidated Report for 2025 - Jedinstvo a.d. , Sevojno
first BELEX region: eu_south
```

Latest digest:

```text
GET /api/feed/digest/latest?edition=breaking: 200
latest digest date: 2026-05-09
metadata.fallback_to_fixture: false
BELEX item count: 0
```

Latest public UI visibility is pending because the current latest digest date is newer than the observed BELEX issuer-news rows.

## Conclusion

```text
SERBIA_BELEX_ISSUER_NEWS_MANUAL_SOURCE_REGISTERED
SERBIA_BELEX_ISSUER_NEWS_LOCAL_PARSER_SMOKE_PASS
SERBIA_BELEX_ISSUER_NEWS_LIVE_ENDPOINT_PROBE_PASS
SERBIA_BELEX_ISSUER_NEWS_STAGING_LIVE_POLL_PASS
SERBIA_BELEX_ISSUER_NEWS_DATE_SPECIFIC_DIGEST_VISIBILITY_PASS
SERBIA_BELEX_ISSUER_NEWS_LATEST_PUBLIC_UI_VISIBILITY_PENDING
```
