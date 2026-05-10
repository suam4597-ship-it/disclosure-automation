# GlobalPulse Turkey KAP Staging Live Poll Smoke Results

This document records the first Fly staging live-poll smoke for the Turkey KAP / PDP company-notification candidate.

The smoke keeps the source manual-only. It does not enable scheduled polling, does not set the source active, does not change backend digest JSON shape, and does not add frontend UI, poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
GLOBALPULSE_TURKEY_KAP_STAGING_DEPLOY_PASS
TURKEY_KAP_SOURCE_HEALTH_MANUAL_ONLY_PASS
TURKEY_KAP_LIVE_POLL_PASS
TURKEY_KAP_LIVE_FIXTURE_FALLBACK_DISABLED_PASS
TURKEY_KAP_LATEST_BACKEND_DIGEST_VISIBILITY_PASS
TURKEY_KAP_PUBLIC_BROWSER_VISUAL_SMOKE_PENDING
TURKEY_KAP_SCHEDULED_POLLING_DISABLED
```

## Context

```text
source_key: tr_kap_company_notifications
display_name: Turkey KAP Company Notifications
parser_key: kap_company_notifications_html_v1
candidate URL: https://www.kap.org.tr/en/bildirim-sorgu-sonuc?srcbar=Y&cmp=Y&cat=6&slf=ALL
authority: official KAP/PDP public-disclosure platform
PR: #465 Add Turkey KAP disclosure candidate
phase0-foundation deploy commit: 95e09601f7850b2ccb62f2faad87a0262761e3fe
Fly app: globalpulse-backend-staging
smoke date: 2026-05-10
```

## Fly Deploy

```text
command: fly deploy --remote-only --app globalpulse-backend-staging
deploy: PASS
release_command: PASS
app URL: https://globalpulse-backend-staging.fly.dev/
```

## Health Check

```text
GET /api/health
status: 200
response: {"status":"ok","service":"disclosure_automation","phase":"phase1","repo":"up"}
```

## Source Health

```text
GET /api/admin/source-health/tr_kap_company_notifications
status: 200
active: false
candidate_status: manual_staging_only
disable_live_fixture_fallback: true
health_status: healthy
last_seen_published_at: 2026-05-09T20:15:27.000000Z
last_success_at: 2026-05-10T10:58:58.912620Z
```

## Live Poll

```text
POST /api/admin/sources/tr_kap_company_notifications/poll?use_live_fetch=true&edition=breaking
status: 202
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 6018178
records_seen: 25
records_inserted: 25
first canonical item: breaking-2026-05-09-kap-1603889
last canonical item in bounded response: breaking-2026-05-09-kap-1603865
fixture fallback: disabled by source config and not used
```

## Latest Digest

```text
GET /api/feed/digest/latest?edition=breaking
status: 200
digest_date: 2026-05-09
item_count: 12
metadata.fallback_to_fixture: false
Turkey KAP items visible in latest backend digest: yes
top Turkey KAP headline: FONET ... - Representation Letter (Consolidated)
region bucket from first staging smoke backend canonicalizer: eu
coverage tags include: europe, turkey, tr, disclosure, listed_companies, public_disclosure_platform, kap
```

The public Pages UI consumes this latest digest endpoint through the configured Fly backend, so the Turkey KAP items are backend-visible for the public shell. A separate browser visual smoke remains pending before claiming a full public browser UI pass.

Follow-up PR #467 separated Turkey KAP into canonical region `tr`; see `globalpulse_turkey_kap_region_label_smoke_results.md` for the post-follow-up region-label smoke.

## Guardrails

```text
scheduled polling enabled: no
source active=true: no
EU scheduled canary inclusion: no
backend digest JSON shape changed: no
frontend framework added: no
public poll UI added: no
audit UI added: no
public Source Health UI added: no
detail fetch / attachment fetch controls added: no
```
