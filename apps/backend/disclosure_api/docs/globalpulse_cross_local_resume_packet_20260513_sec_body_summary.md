# GlobalPulse Cross-Local Resume Packet - SEC Filing Body Summaries

Date: 2026-05-13 KST

This document is the fastest current-state handoff for continuing GlobalPulse work from another local machine after SEC EDGAR filing-body summaries were implemented and deployed.

It is documentation-only. It does not change runtime behavior, frontend behavior, workflows, routes, public API response shapes, source activation, hosting configuration, production infrastructure, production scheduled polling, public poll UI, audit UI, or public Source Health UI.

## Current State

```text
repo: suam4597-ship-it/disclosure-automation
primary branch: phase0-foundation
latest verified head: c1bb3f2fac435157d740921294cd3d9c5b271670
latest merged PR: #642 Add SEC EDGAR filing body summaries
latest PR merge commit: c1bb3f2fac435157d740921294cd3d9c5b271670
worktree expectation: clean
```

Current product stage:

```text
GlobalPulse public GitHub Pages UI is connected to the Fly staging backend.
Public Pages deploy succeeded for c1bb3f2fac435157d740921294cd3d9c5b271670.
Fly staging backend was redeployed after #642.
SEC EDGAR current 8-K live poll was manually rerun after deploy.
US 8-K detail pages now can show original filing-body-based summaries.
Production scheduled polling is still not enabled.
No production source promotion decision is implied by this packet.
```

## Fresh Local Bootstrap

```powershell
git clone https://github.com/suam4597-ship-it/disclosure-automation.git
cd disclosure-automation
git checkout phase0-foundation
git fetch origin --prune
git pull --ff-only origin phase0-foundation
git rev-parse HEAD
git status --short
```

Expected:

```text
HEAD: c1bb3f2fac435157d740921294cd3d9c5b271670 or newer
git status --short: empty
```

If the checkout already has local work, do not overwrite it. Inspect the diff first or use a fresh clone.

## Public URLs

```text
Public Pages:
https://suam4597-ship-it.github.io/disclosure-automation/

Fly staging backend:
https://globalpulse-backend-staging.fly.dev

Health:
https://globalpulse-backend-staging.fly.dev/api/health

Latest digest:
https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking
```

## What Changed In #642

PR #642 added first-pass SEC EDGAR original filing-body summaries.

Changed files:

```text
apps/backend/disclosure_api/lib/disclosure_automation/pipeline.ex
apps/backend/disclosure_api/priv/config_samples/source_registry.sample.yaml
apps/backend/disclosure_api/priv/config_samples/source_registry.extended.sample.yaml
apps/web/index.html
```

Behavior now:

```text
SEC EDGAR current 8-K live poll fetches the RSS/Atom feed.
For the first bounded batch of SEC EDGAR records, the backend derives the complete submission .txt URL.
The backend fetches the SEC complete submission text directly from sec.gov.
The backend extracts the relevant 8-K Item body before persistence.
Item 3.02 has a structured Korean summary for securities offerings.
The frontend preserves backend-provided "원문 본문 기준" summaries instead of replacing them with metadata-only copy.
```

Current bounded config:

```yaml
detail_fetch_limit: 10
detail_fetch_timeout_ms: 8000
```

Important cost note:

```text
No AI/API summarization cost was introduced.
SEC EDGAR text is fetched directly and summarized with bounded rules.
If broader natural-language summaries are added later, cache them and measure cost before using an LLM in the live path.
```

## Deployment And Smoke Results

Fly staging deploy:

```text
app: globalpulse-backend-staging
image: globalpulse-backend-staging:deployment-01KRG0G9X6F4ZX6A9MDZ254ADX
machine: 9080d12db6d338
state after deploy: started
release migration: completed successfully
```

Health check:

```text
GET /api/health
status: 200
body: {"status":"ok","service":"disclosure_automation","phase":"phase1","repo":"up"}
```

Manual SEC poll after deploy:

```text
POST /api/admin/sources/sec_edgar_current_8k_filings/poll?use_live_fetch=true&edition=breaking
status: 202
records_seen: 50
records_inserted: 50
fetch.mode: live
fetch.status_code: 200
```

Digest verification after poll:

```text
GET /api/feed/digest/latest?edition=breaking&source_keys=sec_edgar_current_8k_filings&limit=1&max_per_source=1

Top SEC summary now starts with:
원문 본문 기준, Federal Agricultural Mortgage Corp는 2026년 5월 12일에 1억 달러($100 million) 규모 (400만 주) 6.875% 비누적 우선주, 시리즈 I 발행 가격을 확정했다고 공시했습니다...
```

Public Pages verification:

```text
Deploy Phase 0 web to GitHub Pages: success
Pages HTML contains the new detail note and SEC body-summary frontend hook.
```

## Verification Commands

Backend compile from a fresh local:

```powershell
cd apps/backend/disclosure_api
mix.bat deps.get
$env:MIX_ENV='dev'; mix.bat compile
```

Frontend inline script syntax from repo root:

```powershell
node -e "const fs=require('fs'); const html=fs.readFileSync('apps/web/index.html','utf8'); const scripts=[...html.matchAll(/<script[^>]*>([\s\S]*?)<\/script>/gi)].map(m=>m[1]).join('\n'); new Function(scripts); console.log('inline script syntax ok');"
```

Staging smoke from repo root:

```powershell
$health = Invoke-WebRequest -UseBasicParsing -Uri 'https://globalpulse-backend-staging.fly.dev/api/health' -TimeoutSec 30
$health.StatusCode
$health.Content

$digest = Invoke-WebRequest -UseBasicParsing -Uri 'https://globalpulse-backend-staging.fly.dev/api/feed/digest/latest?edition=breaking&source_keys=sec_edgar_current_8k_filings&limit=1&max_per_source=1' -TimeoutSec 60
($digest.Content | ConvertFrom-Json).items[0].summary
```

Expected summary signal:

```text
The summary should start with "원문 본문 기준," for the enriched top SEC 8-K item.
```

Optional manual SEC poll:

```powershell
Invoke-WebRequest `
  -UseBasicParsing `
  -Method POST `
  -Uri 'https://globalpulse-backend-staging.fly.dev/api/admin/sources/sec_edgar_current_8k_filings/poll?use_live_fetch=true&edition=breaking' `
  -TimeoutSec 120
```

## Read Order

Start here:

```text
GLOBALPULSE_HANDOFF.md
apps/backend/disclosure_api/docs/globalpulse_cross_local_resume_packet_20260513_sec_body_summary.md
apps/backend/disclosure_api/docs/globalpulse_remote_handoff_guide.md
apps/backend/disclosure_api/docs/globalpulse_web_implementation_current_checkpoint.md
apps/backend/disclosure_api/docs/globalpulse_scheduled_workflow_observation_cookbook.md
```

Use older packets only for historical context:

```text
apps/backend/disclosure_api/docs/globalpulse_cross_local_resume_packet_20260512.md
```

## Next Good Work Queue

Recommended next steps:

```text
1. Verify the public SEC detail page manually in a browser after Pages cache settles.
2. Improve generic SEC 8-K body summaries beyond Item 3.02 so Item 1.01, 2.02, 5.02, 8.01 do not fall back to English excerpts.
3. Add tests or a small fixture-based probe for SEC complete-submission text extraction.
4. Consider caching extracted SEC body summaries if detail_fetch_limit is raised.
5. Decide whether non-US regions should get source-document body extraction, starting with JP TDnet and HKEX where original document access is stable.
6. Keep any LLM/AI summarization out of the live path until cost, caching, and failure behavior are designed.
```

Immediate UX follow-up candidates:

```text
Make the SEC detail page show a "본문 기반 요약" label when the summary starts with "원문 본문 기준,".
Add a small "원문에서 추출한 주요 항목" block for amount/shares/date when parsed.
Reduce English fallback snippets in non-3.02 SEC items by adding targeted templates.
```

## Guardrails

Keep these constraints unless explicitly changed:

```text
Do not re-add KR to the public UI or delivery schedule.
Do not enable production scheduled polling.
Do not add public poll UI.
Do not add public Source Health UI.
Do not add audit UI.
Do not change backend digest JSON response shape without a contract PR.
Do not commit deps, _build, or mix.lock from local dependency installation.
Do not treat fixture fallback as live success.
Do not put an LLM call in the live poll path without a bounded design and cache strategy.
```

