# Sarajevo SASE Issuer Announcements Staging Live Poll Smoke Results

Status: `SARAJEVO_SASE_ISSUER_ANNOUNCEMENTS_STAGING_LIVE_POLL_PASS`

## Summary

The inactive/manual staging-only Sarajevo Stock Exchange issuer-announcement candidate was deployed to Fly staging and manually polled with live fetch enabled.

```text
source_key: ba_sase_issuer_announcements_multi_code
source owner: Sarajevo Stock Exchange
source type: api
parser: sase_multi_issuer_announcements_xml_v1
candidate URL: http://www.sase.ba/FeedServices/HandlerChart.ashx
candidate_status: manual_staging_only
active: false
disable_live_fixture_fallback: true
deploy commit: 5c7359b06435fa063c4350179e783c631f529845
smoke date: 2026-05-10
```

## Result

```text
health endpoint: PASS, 200
source health before poll: PASS, source registered and active=false
live poll: PASS, 202
fetch.mode: live
fetch.status_code: 200
fetch.fixture_fallback: false
fetch.selected_issuer_count: 5
fetch.issuer_request_count: 5
fetch.records_seen: 25
records_inserted: 25
source health after poll: healthy
last_seen_published_at: 2026-04-10T08:16:27.343000Z
date-specific digest: PASS, /api/feed/digest/2026-04-10/breaking
date-specific digest fallback_to_fixture: false
latest digest visibility: PENDING, current latest digest date remains 2026-05-09
```

## Live Poll Evidence

Manual staging poll:

```text
POST /api/admin/sources/ba_sase_issuer_announcements_multi_code/poll?use_live_fetch=true&edition=breaking
```

Returned:

```text
edition: breaking
source_key: ba_sase_issuer_announcements_multi_code
fetch.mode: live
fetch.strategy: sase_multi_issuer_announcements_xml_v1
fetch.url: http://www.sase.ba/FeedServices/HandlerChart.ashx
fetch.status_code: 200
fetch.bytes: 47231
fetch.fixture_fallback: false
fetch.selected_issuer_count: 5
fetch.issuer_request_count: 5
fetch.records_seen: 25
records_seen: 25
records_inserted: 25
```

Selected canonical keys included:

```text
breaking-2026-01-21-sase-bhts-29066
breaking-2026-01-07-sase-bhts-29034
breaking-2026-04-10-sase-bsnl-29495
breaking-2026-01-13-sase-asao-29049
breaking-2025-08-08-sase-alum-28592
```

## Digest Evidence

Date-specific digest:

```text
GET /api/feed/digest/2026-04-10/breaking
status: 200
item_count: 1
metadata.fallback_to_fixture: false
source_key: ba_sase_issuer_announcements_multi_code
headline: Bosnalijek d.d. Sarajevo - Notice on dividend payment
region: eu_south
published_at: 2026-04-10T08:16:27.343000Z
```

Latest digest:

```text
GET /api/feed/digest/latest?edition=breaking
status: 200
digest_date: 2026-05-09
sase_count: 0
```

Latest public UI visibility remains pending because the current latest digest date is newer than the SASE smoke rows. This is expected and should not be treated as a live polling failure.

## HTTPS Handler Note

The initial Fly staging smoke against the HTTPS handler failed with a closed TLS connection to `www.sase.ba:443`. Local HTTPS and HTTP probes returned 200, and the same official handler over HTTP succeeded from Fly staging. The source remains manual staging-only while this behavior is observed over repeated smoke runs.

## Guardrails

```text
scheduled polling not enabled
active=false preserved
fixture fallback disabled
configured issuer-code window only
download POST endpoint remains out of scope
backend digest JSON response shape unchanged
public poll UI not added
public Source Health UI not added
frontend framework not added
```

## Conclusion

```text
SARAJEVO_SASE_ISSUER_ANNOUNCEMENTS_STAGING_LIVE_POLL_PASS
SARAJEVO_SASE_ISSUER_ANNOUNCEMENTS_DATE_SPECIFIC_DIGEST_VISIBILITY_PASS
SARAJEVO_SASE_ISSUER_ANNOUNCEMENTS_LATEST_PUBLIC_UI_VISIBILITY_PENDING
```
