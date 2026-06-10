# GlobalPulse Vietnam HNX Manual Staging Poll Smoke Results

Date: 2026-05-11 KST

This document records the manual Fly staging smoke for the inactive Vietnam HNX issuer-disclosure RSS source candidate.

This is a manual-staging-only result. It does not enable production scheduled polling, activate the source, add workflows, add public poll UI, add audit UI, add public Source Health UI, change backend digest JSON shape, fetch HNX detail pages, fetch attachments, or change frontend shell behavior.

## Conclusion

```text
VIETNAM_HNX_MANUAL_STAGING_POLL_PASS
VIETNAM_HNX_LIVE_FETCH_FROM_FLY_STAGING_PASS
VIETNAM_HNX_RECORDS_SEEN_25
VIETNAM_HNX_RECORDS_INSERTED_25
VIETNAM_HNX_DIGEST_VISIBLE_ITEM_COUNT_6
VIETNAM_HNX_FIXTURE_FALLBACK_FALSE
VIETNAM_HNX_SOURCE_REMAINS_INACTIVE
ASEAN_SCHEDULED_LIVE_POLLING_NOT_ENABLED
PRODUCTION_APAC_SCHEDULED_LIVE_POLLING_NOT_ENABLED
```

## Deployment

```text
deployed PR: #514 Add inactive Vietnam HNX issuer RSS candidate
merge commit: a78ed47e5a1b55770139bb38bc9805baa427d216
Fly app: globalpulse-backend-staging
Fly image: registry.fly.io/globalpulse-backend-staging:deployment-01KRAMCZFXH1W8W85XAZM7FA0W
```

#514 merge commit CI was green before deployment:

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
status: 200
body.status: ok
body.service: disclosure_automation
body.phase: phase1
body.repo: up
```

## Manual Poll

```text
POST https://globalpulse-backend-staging.fly.dev/api/admin/sources/vn_hnx_issuer_disclosures/poll?use_live_fetch=true&edition=breaking
status: 202
source_key: vn_hnx_issuer_disclosures
edition: breaking
fetch.mode: live
fetch.loaded: true
fetch.status_code: 200
fetch.bytes: 46172
fetch.url: https://www.hnx.vn/3/vi_vn/thong-tin-cong-bo-tu-to-chuc-phat-hanh.rss
records_seen: 25
records_inserted: 25
first_canonical_item: breaking-2026-05-11-614564
last_canonical_item_in_batch: breaking-2026-05-11-614540
raw_documents: 25
```

## Source Health

```text
GET https://globalpulse-backend-staging.fly.dev/api/admin/source-health/vn_hnx_issuer_disclosures
status: 200
source.active: false
source.health_status: healthy
source.last_success_at: 2026-05-11T04:25:27.145579Z
source.last_seen_published_at: 2026-05-11T11:24:45.000000Z
source.last_error: null
source.config.candidate_status: manual_staging_only
source.config.disable_live_fixture_fallback: true
```

## Digest Verification

```text
GET https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking
status: 200
edition: breaking
digest_date: 2026-05-11
generated_at: 2026-05-11T04:26:13Z
item_count: 12
hnx_item_count: 6
first_hnx_source_key: vn_hnx_issuer_disclosures
first_hnx_fetch_mode: live
metadata.fallback_to_fixture: false
```

Representative first HNX headline:

```text
Lâm Tường Vinh - người có liên quan đến Ủy viên HĐQT - đã bán 14.294 CP
```

## Boundary Confirmation

```text
source remains active=false
candidate_status remains manual_staging_only
fixture fallback remains disabled for live smoke
detail fetch not added
attachment fetch not added
workflow not added
scheduled polling not enabled
public poll UI not added
audit UI not added
public Source Health UI not added
backend digest JSON shape unchanged
KR remains deferred
JP remains blocked by issue #339
```

## Next Step

```text
Vietnam HNX has one successful manual staging live smoke.
Keep the source inactive.
Do not enable ASEAN or APAC production scheduled polling.
Prefer one more observation-window smoke before any schedule or activation discussion.
```
