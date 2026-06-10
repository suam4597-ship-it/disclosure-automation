# GlobalPulse Live SEC Polling Smoke Results

This document records the first successful live SEC RSS polling smoke against the Fly.io staging backend.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend static shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, or integrations.

## Baseline

```text
backend app: globalpulse-backend-staging
backend URL: https://globalpulse-backend-staging.fly.dev
source_key: sec_press_releases
edition: breaking
live source URL: https://www.sec.gov/news/pressreleases.rss
workflow: GlobalPulse live staging poll
workflow run: https://github.com/suam4597-ship-it/disclosure-automation/actions/runs/25532038227
artifact: globalpulse-live-staging-poll-25532038227
artifact id: 6870223786
```

## Related PRs

```text
PR #332 Add GlobalPulse live staging poll workflow
PR #334 Fix live RSS punctuation parsing
```

PR #334 was deployed to Fly staging before the successful workflow run:

```text
commit: 0421671bb834ad0ededb653719dee0ad761cc4fc
command: flyctl deploy --remote-only --app globalpulse-backend-staging
release_command: completed successfully
image: globalpulse-backend-staging:deployment-01KR2M4XA0ZS53C9GKS3P83GZP
```

## Pre-fix Failure

Before deploying PR #334, the live SEC RSS poll reached Fly staging but failed while parsing RSS XML:

```text
Health check: success
Poll live source: failure
HTTP status: 400
error: invalid_xml
parser detail: bad_character, 8230
```

The failing character was a typographic ellipsis in the live SEC feed. PR #334 normalized common smart punctuation before handing live RSS XML to the XML parser.

## Successful Workflow Result

After deploying PR #334, the manual workflow dispatch completed successfully:

```text
Health check: success
Poll live source: success
Verify digest: success
```

### Health Check

```text
GET /api/health
HTTP status: 200
response: {"status":"ok","service":"disclosure_automation","phase":"phase1","repo":"up"}
```

### Live SEC Poll

```text
POST /api/admin/sources/sec_press_releases/poll?use_live_fetch=true&edition=breaking
HTTP status: 202
fetch.loaded: true
fetch.mode: live
fetch.status_code: 200
fetch.bytes: 17785
fetch.url: https://www.sec.gov/news/pressreleases.rss
records_seen: 25
records_inserted: 25
edition: breaking
```

### Latest Digest

```text
GET /api/feed/digest/latest?edition=breaking
HTTP status: 200
digest_date: 2026-05-08
generated_at: 2026-05-08T01:48:30Z
generated_by: repo
item_count: 11
metadata.fallback_to_fixture: false
```

## Current Conclusion

```text
LIVE_SEC_POLL_WORKFLOW_ADDED
LIVE_SEC_POLL_PASS
FLY_STAGING_DIGEST_UPDATED_FROM_LIVE_SOURCE
GLOBALPULSE_PAGES_LIVE_DATA_READY
```

## Guardrails

The live SEC polling smoke did not require or introduce:

```text
frontend framework changes
backend route changes
backend JSON response-shape changes
database schema changes
login UI
identity provider callback routes
poll UI
audit UI
public Source Health UI
provider/materializer/canonical contract expansion
request-param actor_permissions as production authority
raw provider/auth/session/request material in public responses
```

## Recommended Next Action

Use SEC live polling as the first stable live data source, then add other regions only after their live endpoints are verified:

```text
SEC RSS live polling stable
KR live source URL verification
JP live source URL verification
EU live source URL verification
CN live source URL verification
APAC live source URL verification
```

Stop and re-scope if adding a regional source requires fixture fallback, public Source Health UI, poll UI, audit UI, backend response-shape changes, or unbounded provider diagnostics.
