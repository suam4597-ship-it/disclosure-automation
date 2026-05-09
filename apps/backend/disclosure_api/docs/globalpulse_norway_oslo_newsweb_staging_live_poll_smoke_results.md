# GlobalPulse Norway Oslo Bors NewsWeb Staging Live Poll Smoke Results

Date: 2026-05-09

## Conclusion

```text
NORWAY_OSLO_BORS_NEWSWEB_MAIN_MARKET_SOURCE_REGISTERED
NORWAY_OSLO_BORS_NEWSWEB_MAIN_MARKET_STAGING_LIVE_POLL_PASS
NORWAY_OSLO_BORS_NEWSWEB_DATE_SPECIFIC_DIGEST_PASS
NORWAY_OSLO_BORS_NEWSWEB_PUBLIC_LATEST_UI_VISIBILITY_PENDING_EXPECTED
NORWAY_OSLO_BORS_NEWSWEB_SCHEDULED_POLLING_DISABLED
```

## Source Under Test

```text
source_key: no_oslo_bors_newsweb_main_market
display_name: Norway Oslo Bors NewsWeb Main Market Announcements
parser_key: oslo_newsweb_json_v1
region: eu_north
candidate_status: manual_staging_only
active: false
```

## Deployment

```text
repo: suam4597-ship-it/disclosure-automation
branch: phase0-foundation
merge commit: 0bf637ae0724dcdfa9be89ce07758fe7d0794598
Fly app: globalpulse-backend-staging
Fly backend URL: https://globalpulse-backend-staging.fly.dev
release_command: success
deploy result: success
```

## CI Status

```text
Phase 0 validate: success
Phase 0 report: success
Phase 1 backend verify: success
Phase 1 runtime smoke: success
Phase 1 backend report: success
Phase 1 backend trace: success
Phase 1 backend diagnose: success
```

## Health Check

```text
GET /api/health: 200
status: ok
service: disclosure_automation
```

## Live Poll

Command shape:

```text
POST /api/admin/sources/no_oslo_bors_newsweb_main_market/poll?use_live_fetch=true&edition=breaking
```

Observed result:

```text
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 374782
records_seen: 25
records_inserted: 25
canonical_items: 25
metadata.fallback_to_fixture: false
```

Representative canonical item:

```text
story_key: breaking-2026-05-08-54496879-69a6-4d41-9325-e74967215f7d
headline: Okeanis Eco Tankers Corp. - Invitation to Q1 2026 Results Webcast
canonical_url: https://newsweb.oslobors.no/message/672925
region: eu_north
source: Norway Oslo Bors NewsWeb Main Market Announcements
summary: Oslo Bors NewsWeb issuer announcement | Issuer: Okeanis Eco Tankers Corp. | Ticker: OET | Market: XOSL | Category: NON-REGULATORY PRESS RELEASES | Attachments: 0
```

## Digest Check

Latest digest:

```text
GET /api/feed/digest/latest?edition=breaking: 200
digest_date: 2026-05-09
item_count: 3
metadata.fallback_to_fixture: false
```

Date-specific digest:

```text
GET /api/feed/digest/2026-05-08/breaking: 200
digest_date: 2026-05-08
item_count: 12
metadata.fallback_to_fixture: false
Norway Oslo Bors item present: yes
region: eu_north
```

## UI Visibility

```text
public latest UI visibility: pending expected
reason: the NewsWeb live records were published on 2026-05-08, while the current public latest digest date is 2026-05-09.
date-specific backend digest visibility: pass
```

## Guardrails

```text
scheduled polling remains disabled
source remains active=false
candidate remains manual_staging_only
no central-bank, ECB, macro, or policy feed added
no JP live source changes
no public poll UI added
no audit UI added
no public Source Health UI added
no backend JSON response shape change
no fixture fallback claimed as live success
```
