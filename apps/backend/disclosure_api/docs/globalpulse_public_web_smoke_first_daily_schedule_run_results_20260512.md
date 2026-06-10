# GlobalPulse Public Web Smoke First Daily Schedule Run Results

Date: 2026-05-12 KST

This document records the first observed successful `event=schedule` run for the `GlobalPulse public web smoke` workflow.

This is documentation-only. It does not change workflows, frontend runtime behavior, backend runtime behavior, routes, public API response shapes, source activation, production polling, secrets, hosting configuration, public poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
GLOBALPULSE_PUBLIC_WEB_SMOKE_FIRST_DAILY_SCHEDULE_RUN_PASS
GLOBALPULSE_PUBLIC_WEB_SMOKE_EVENT_SCHEDULE_OBSERVED
PUBLIC_PAGES_SHELL_CONTRACT_PASS
PUBLIC_PAGES_CONFIG_CONTRACT_PASS
FLY_STAGING_HEALTH_PASS
FLY_STAGING_DIGEST_PASS
FLY_STAGING_DIGEST_FALLBACK_FALSE
PUBLIC_DIGEST_DIVERSITY_RECOVERED_IN_TOP_N
PUBLIC_DIGEST_HKEX_EU_INDIA_TOP_N_OBSERVED
PRODUCTION_CONFIG_PROMOTION_NOT_DONE
PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
```

## Run Evidence

```text
workflow: GlobalPulse public web smoke
run id: 25712711038
event: schedule
status: completed
conclusion: success
head_branch: main
head_sha: c9107fe00c10bf6a239289f1c5b8aab47feb610d
created_at: 2026-05-12T04:07:00Z
updated_at: 2026-05-12T04:07:18Z
job: smoke
job id: 75496119763
artifact: globalpulse-public-web-smoke-25712711038
artifact id: 6935425538
artifact digest: sha256:fbb95d7b166607ea11440d5a6ee1ef9a7057b7bbe01a68434196b34a005bfda6
```

## Public Web Contract Checks

The scheduled run checked the public Pages shell, runtime config, Fly staging health endpoint, and latest digest endpoint:

```text
pages_url: https://suam4597-ship-it.github.io/disclosure-automation/
pages status: 200
public shell contract: pass

config status: 200
public config contract: pass
config backend marker: https://globalpulse-backend-staging.fly.dev

health status: 200
health payload: {"status":"ok","service":"disclosure_automation","phase":"phase1","repo":"up"}
backend health contract: pass

digest status: 200
digest generated_at: 2026-05-12T04:07:12Z
digest item_count: 12
metadata.fallback_to_fixture: false
digest contract: pass
```

## Digest Diversity Evidence

The scheduled public web smoke observed a live-backed top-N digest with multiple sources and regions:

```text
hkex_latest_listed_company_information / greater_china / 00258 - TOMSON GROUP - Form of Proxy for...
eu_euronext_company_press_releases / eu / LINK Mobility - Q1 2026 - On track to organic growth
india_nse_announcements / india / Archean Chemical Industries Limited
hkex_latest_listed_company_information / greater_china / 00258 - TOMSON GROUP - Notice of...
eu_euronext_company_press_releases / eu / Atos and Backbase to accelerate secure, AI-native banking across regulated markets
india_nse_announcements / india / Archean Chemical Industries Limited
hkex_latest_listed_company_information / greater_china / 00258 - TOMSON GROUP - Proposed Amendments...
eu_euronext_company_press_releases / eu / Rapid Nutrition Extends AI-Powered Agentic Platform to Consumer Ecosystem Following Investor Rollout
india_nse_announcements / india / Archean Chemical Industries Limited
hkex_latest_listed_company_information / greater_china / 00258 - TOMSON GROUP - Proposed Amendments...
india_nse_announcements / india / Archean Chemical Industries Limited
hkex_latest_listed_company_information / greater_china / 01566 - CA CULTURAL - EXTRAORDINARY...
```

This closes the previous "India-only top-N" digest diversity observation for this window:

```text
HKEX rows observed in public top-N digest
EU Euronext rows observed in public top-N digest
India NSE rows observed in public top-N digest
metadata.fallback_to_fixture=false
```

## Warning Context

The run completed successfully. The only observed warnings were GitHub Actions runtime/dependency warnings from `actions/upload-artifact@v4`:

```text
Node.js 20 actions deprecation warning
punycode/url.parse deprecation warnings
```

These warnings did not fail the job and did not indicate a public web or backend contract failure.

## Interpretation

The daily scheduled public web smoke is no longer pending for first observation:

```text
workflow exists on main
daily cron marker exists on main
workflow state was previously verified active
first event=schedule run was observed
first event=schedule run passed
public Pages + config + Fly staging health + Fly staging digest all passed
latest public digest was live-backed and region-diverse
```

This does not approve production deployment or production scheduled polling. It only records the first successful scheduled public web smoke run against the current Pages UI and Fly staging backend.

## Follow-up

Next safe actions:

```text
keep daily public web smoke observation healthy
continue HKEX scheduled staging observation toward the 7-day / 10 successful run gate
continue EU canary, Denmark DFSA OAM, India NSE, and HKEX scheduled observation summaries
record future digest diversity regressions or recoveries as observation docs
keep production config promotion blocked until production approval values exist
keep source promotion blocked until source-by-source approvals exist
```

## Guardrails

```text
Do not promote frontend config to production from this observation.
Do not enable production scheduled polling.
Do not change backend digest JSON response shape.
Do not change workflow schedules in this observation PR.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not set candidate sources active=true.
Do not claim fixture fallback as live success.
```
