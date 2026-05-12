# GlobalPulse Luxembourg LuxSE OAM Staging Live Poll Smoke Results

This document records the first successful staging live poll for the Luxembourg LuxSE OAM regulated-information source candidate.

## Conclusion

```text
GLOBALPULSE_LUXSE_OAM_STAGING_DEPLOY_PASS
GLOBALPULSE_LUXSE_OAM_SOURCE_REGISTERED_MANUAL_ONLY
GLOBALPULSE_LUXSE_OAM_LIVE_POLL_PASS
GLOBALPULSE_LUXSE_OAM_LATEST_DIGEST_PASS
GLOBALPULSE_LUXSE_OAM_PUBLIC_PAGES_DOM_PASS
GLOBALPULSE_LUXSE_OAM_SCHEDULED_POLLING_STILL_DISABLED
```

## Scope

```text
source candidate/parser PR: #388 Add Luxembourg LuxSE OAM parser candidate
merge commit: 57d000775f8bbacb16ef817c4a140c5ff78f4f39
Fly app: globalpulse-backend-staging
backend URL: https://globalpulse-backend-staging.fly.dev
public Pages URL: https://suam4597-ship-it.github.io/disclosure-automation/
```

This smoke validates the bounded manual staging candidate only. It does not enable scheduled Luxembourg or EU live polling.

## CI

The merge commit completed the expected phase workflows successfully.

```text
Phase 0 validate: success
Phase 0 report: success
Phase 1 backend verify: success
Phase 1 runtime smoke: success
Phase 1 backend report: success
Phase 1 backend diagnose: success
Phase 1 backend trace: success
```

## Fly Staging Deploy

Fly deploy completed successfully.

```text
command: fly deploy --remote-only --app globalpulse-backend-staging
release_command: completed successfully
machine health: good state
public app URL: https://globalpulse-backend-staging.fly.dev/
```

The deploy output included a transient listener warning while the release command machine was running. The final machine health check passed and the public app responded successfully afterward.

## Health Check

```text
GET /api/health
HTTP: 200
response: {"status":"ok","service":"disclosure_automation","phase":"phase1","repo":"up"}
```

## Source Detail

```text
GET /api/admin/source-health/eu_luxembourg_luxse_oam
HTTP: 200
active: false
candidate_status: manual_staging_only
parser_key: luxse_oam_graphql_v1
live_headers:
  accept: application/json
  apollo-require-preflight: "true"
live_timeout_ms: 30000
```

## Manual Live Poll

```text
POST /api/admin/sources/eu_luxembourg_luxse_oam/poll?edition=breaking
HTTP: 202
fetch.mode: live
fetch.status_code: 200
fetch.loaded: true
fetch.bytes: 7099
records_seen: 25
records_inserted: 25
```

Canonical item keys included:

```text
breaking-2026-05-08-259040
breaking-2026-05-08-259036
breaking-2026-05-08-259035
breaking-2026-05-07-259011
breaking-2026-05-07-259016
```

The first parsed item was:

```text
headline: APERAM - Managers’ transactions
source: Luxembourg LuxSE OAM Regulated Information
region: eu_central
fetch_mode: live
summary: LuxSE OAM | Action: IINI | Reference period: 2026-05-07
```

## Digest Smoke

```text
GET /api/feed/digest/latest?edition=breaking
HTTP: 200
digest_date: 2026-05-08
edition: breaking
item_count: 12
LuxSE item present: yes
metadata.fetch_mode: live
```

Date-specific confirmation:

```text
GET /api/feed/digest/2026-05-08/breaking
HTTP: 200
metadata.fallback_to_fixture: false
LuxSE source items present: yes
```

## Public Pages DOM Smoke

Headless Chrome DOM smoke against the public Pages URL rendered the LuxSE item without frontend changes.

```text
URL: https://suam4597-ship-it.github.io/disclosure-automation/
Backend status: Backend ok
Region label: Central Europe
Source label: Luxembourg LuxSE OAM Regulated Information
Headline: APERAM - Managers’ transactions
Summary: LuxSE OAM | Action: IINI | Reference period: 2026-05-07
Region Mix includes Central Europe: yes
```

## Guardrails

```text
scheduled Luxembourg polling: not enabled
scheduled EU polling: not enabled
source active flag: false
candidate_status: manual_staging_only
fixture fallback claim: none
HTML rss_v1 polling: none
public digest JSON response shape change: none
frontend framework change: none
poll UI: none
audit UI: none
public Source Health UI: none
```

## EU Batch Status

LuxSE now joins the proven manual staging EU listed-company disclosure candidates:

```text
France Info-Financiere OAM: staging live poll pass
Spain CNMV Inside Information: staging live poll pass and public UI pass
Spain CNMV Other Relevant Information: staging live poll pass and public UI pass
Netherlands AFM Financial Reporting: staging live poll pass
Italy eMarket Storage Regulated Communications: staging live poll pass and public UI pass
Luxembourg LuxSE OAM Regulated Information: staging live poll pass and public UI pass
```

The next EU implementation step is still not scheduled polling. The safer path is to finish Germany/Euronext endpoint discovery, then make one explicit EU batch-promotion decision with rollback notes.
