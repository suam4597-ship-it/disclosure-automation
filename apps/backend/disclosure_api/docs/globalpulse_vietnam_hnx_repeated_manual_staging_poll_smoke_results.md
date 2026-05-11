# GlobalPulse Vietnam HNX Repeated Manual Staging Poll Smoke Results

Date: 2026-05-11 KST

This document records a second Fly staging manual live-poll smoke for the inactive Vietnam HNX issuer-disclosure RSS candidate.

This is documentation-only. It does not enable production scheduled polling, activate the source, add workflows, add public poll UI, add audit UI, add public Source Health UI, change backend digest JSON shape, fetch HNX detail pages, fetch attachments, or change frontend shell behavior.

## Conclusion

```text
VIETNAM_HNX_ISSUER_DISCLOSURE_RSS_CONFIRMED
VIETNAM_HNX_ISSUER_DISCLOSURE_SOURCE_REGISTERED_INACTIVE
VIETNAM_HNX_REPEATED_MANUAL_STAGING_SMOKE_PASS
VIETNAM_HNX_DIGEST_VISIBLE_LIVE
VIETNAM_HNX_LIVE_FIXTURE_FALLBACK_FALSE
VIETNAM_HNX_DETAIL_FETCH_DISABLED
ASEAN_SCHEDULED_LIVE_POLLING_NOT_ENABLED
PRODUCTION_APAC_SCHEDULED_LIVE_POLLING_NOT_ENABLED
```

## Deployment Under Test

```text
repo: suam4597-ship-it/disclosure-automation
branch: phase0-foundation
deployed PR basis: #517 Add inactive Vietnam HSX listed company RSS candidate
deployed commit: cf0bc4aac18beb97ecc3e58b1239043b25e058e9
Fly app: globalpulse-backend-staging
deployed image: registry.fly.io/globalpulse-backend-staging:deployment-01KRANX01CREM0P4QZWHQV5HWN
```

The #517 merge commit CI was checked before the deployment used by this smoke:

```text
Phase 0 validate: success
Phase 0 report: success
Phase 1 backend verify: success
Phase 1 runtime smoke: success
Phase 1 backend report: success
Phase 1 backend diagnose: success
Phase 1 backend trace: success
```

## Health Check

```text
GET https://globalpulse-backend-staging.fly.dev/api/health
```

Observed:

```text
status: ok
service: disclosure_automation
phase: phase1
repo: up
```

## Manual Live Poll

```text
POST https://globalpulse-backend-staging.fly.dev/api/admin/sources/vn_hnx_issuer_disclosures/poll?use_live_fetch=true&edition=breaking
```

Observed:

```text
source_key: vn_hnx_issuer_disclosures
edition: breaking
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 46172
records_seen: 25
records_inserted: 25
first_canonical: breaking-2026-05-11-614570
```

## Source Health

```text
GET https://globalpulse-backend-staging.fly.dev/api/admin/source-health/vn_hnx_issuer_disclosures
```

Observed:

```text
health_status: healthy
active: false
candidate_status: manual_staging_only
disable_live_fixture_fallback: true
last_success_at: 2026-05-11T04:55:50.184768Z
last_seen_published_at: 2026-05-11T11:31:30.000000Z
last_error: null
```

## Digest Verification

```text
GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking
```

Observed:

```text
digest_date: 2026-05-11
generated_at: 2026-05-11T04:55:51Z
item_count: 12
hnx_item_count: 3
hsx_item_count: 2
metadata.fallback_to_fixture: false
```

Observed first HNX digest item:

```text
story_key: breaking-2026-05-11-614570
headline: Thay doi nhan su
source.source_key: vn_hnx_issuer_disclosures
metadata.fetch_mode: live
```

## Guardrails Confirmed

```text
source remains active=false
candidate_status remains manual_staging_only
disable_live_fixture_fallback remains true
fetch.mode is live
metadata.fallback_to_fixture is false
public digest JSON shape unchanged
production scheduled polling not enabled
public poll UI not added
audit UI not added
public Source Health UI not added
detail fetch not enabled
attachment fetch not enabled
```

## Next Allowed Steps

```text
1. Continue APAC official-source scanning within official exchange/OAM surfaces.
2. Keep observing India NSE scheduled staging runs until the 7-day window matures.
3. Repeat Taiwan MOPS manual staging smoke in another observation window.
4. Keep KR deferred until the dedicated KR backend/source authority path exists.
5. Keep JP blocked until issue #339 source authority is resolved.
```
