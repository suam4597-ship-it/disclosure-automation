# GlobalPulse Bulgaria X3News Issuer Disclosures Staging Live Poll Smoke Results

This document records the manual Fly staging smoke for the Bulgaria X3News issuer-disclosure candidate.

The smoke validates that the source can be fetched from the live X3News latest-disclosure page without fixture fallback. It does not enable scheduled polling, does not set the source active, does not add the source to the EU scheduled canary, does not change public digest JSON shape, and does not add frontend UI, poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
BULGARIA_X3NEWS_MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS
BULGARIA_X3NEWS_LIVE_FIXTURE_FALLBACK_DISABLED_PASS
BULGARIA_X3NEWS_DATE_SPECIFIC_DIGEST_VISIBILITY_PASS
BULGARIA_X3NEWS_PUBLIC_LATEST_UI_VISIBILITY_PENDING_EXPECTED
BULGARIA_X3NEWS_SCHEDULED_POLLING_DISABLED
```

## Scope

```text
source_key: bg_x3news_issuer_disclosures
display_name: Bulgaria X3News Issuer Disclosures
authority: Financial Market Services / X3News, part of the Bulgarian Stock Exchange group
candidate URL: https://www.x3news.com/?language=en
parser_key: bg_x3news_issuer_disclosures_html_v1
candidate_status: manual_staging_only
active: false
disable_live_fixture_fallback: true
region: eu_central / bulgaria
```

## Deployment

```text
base branch: phase0-foundation
deployed commit: 1742801c51c6a0f007b483df4c8e5d3547594218
candidate PR: #459 Add Bulgaria X3News issuer disclosures candidate
live-proof guard PR: #460 Require live proof for Bulgaria X3News smoke
payload marker fix PR: #461 Fix Bulgaria X3News live payload marker
Fly app: globalpulse-backend-staging
Fly image: registry.fly.io/globalpulse-backend-staging:deployment-01KR8NHK132X30EW1PH0FEPMYE
release_command: PASS
machine health check: PASS
```

## Health Check

```text
GET https://globalpulse-backend-staging.fly.dev/api/health
status: 200
body.status: ok
service: disclosure_automation
phase: phase1
repo: up
```

## Source Health

Before the successful smoke, the source was healthy-unknown after the intentionally strict live-fallback guard rejected a live payload marker mismatch.

After PR #461 and the Fly staging deploy:

```text
GET /api/admin/source-health/bg_x3news_issuer_disclosures
status: 200
health_status: healthy
active: false
candidate_status: manual_staging_only
disable_live_fixture_fallback: true
last_error: null
last_success_at: 2026-05-10T10:07:20.196613Z
last_seen_published_at: 2026-05-08T10:14:00.000000Z
```

## Live Poll

```text
POST /api/admin/sources/bg_x3news_issuer_disclosures/poll?use_live_fetch=true&edition=breaking
status: 202
fetch.mode: live
fetch.status_code: 200
fetch.url: https://www.x3news.com/?language=en
fetch.bytes: 17558
records_seen: 11
records_inserted: 11
canonical_items: 11
fixture_fallback: false by source guard
```

Canonical items created:

```text
breaking-2026-05-08-x3news-198292
breaking-2026-05-07-x3news-198259
breaking-2026-05-06-x3news-198257
breaking-2026-05-05-x3news-198241
breaking-2026-05-05-x3news-198235
breaking-2026-05-05-x3news-198234
breaking-2026-05-05-x3news-198233
breaking-2026-05-05-x3news-198226
breaking-2026-05-04-x3news-198207
breaking-2026-04-30-x3news-198178
breaking-2026-04-30-x3news-198160
```

## Digest Visibility

Latest public digest visibility remains pending because the public latest digest currently points to a newer 2026-05-09 window and top-N ranking is already filled by other live sources.

Date-specific digest visibility passed:

```text
GET /api/feed/digest/2026-05-07/breaking
source_key: bg_x3news_issuer_disclosures
headline: Sopharma AD - Inside information under art. 17, para 1, in relation with art. 7 of the Regulation (EU) No 596/2014
published_at: 2026-05-07T06:36:00.000000Z
priority_rank: 2
regions: eu_central

GET /api/feed/digest/2026-05-06/breaking
source_key: bg_x3news_issuer_disclosures
headline: Herti AD - Inside information under art. 17, para 1, in relation with art. 7 of the Regulation (EU) No 596/2014
published_at: 2026-05-06T05:48:00.000000Z
priority_rank: 3
regions: eu_central

GET /api/feed/digest/2026-05-05/breaking
source_key: bg_x3news_issuer_disclosures
matches: 4
regions: eu_central
```

## Guardrails

```text
source active=true not set
scheduled polling not enabled
EU scheduled canary not expanded
public latest UI pass not claimed
backend digest JSON response shape unchanged
frontend framework not added
public poll UI not added
audit UI not added
public Source Health UI not added
JP live polling untouched
```

## Next Gate

Keep Bulgaria X3News as `active=false/manual_staging_only` until the broader EU batch-promotion gate decides whether it belongs in scheduled staging canary coverage. Any promotion should include repeated live smoke, source-specific rollback notes, and rate/cadence review.
