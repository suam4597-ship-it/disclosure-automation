# GlobalPulse EU Source Batch Promotion Design

This document defines the decision gate for moving selected EU listed-company disclosure sources from manual staging smoke to a conservative scheduled staging canary.

This is documentation-only. It does not add runtime code, routes, controllers, migrations, backend response-shape changes, frontend shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, workflow schedules, source activation, or scheduled polling.

## Conclusion

```text
EU_LISTED_COMPANY_DISCLOSURE_MANUAL_SOURCE_BATCH_VERIFIED
EU_BATCH_PROMOTION_DESIGN_RECORDED
EU_SCHEDULED_STAGING_CANARY_ALLOWED_ONLY_AFTER_SEPARATE_PR
EU_PRODUCTION_SCHEDULED_POLLING_NOT_APPROVED
EU_PUBLIC_UI_AND_API_SHAPE_UNCHANGED
```

## Baseline

```text
backend URL: https://globalpulse-backend-staging.fly.dev
public Pages URL: https://suam4597-ship-it.github.io/disclosure-automation/
latest Germany candidate PR: #442 Add Germany Company Register manual candidate
latest Germany smoke PR: #443 Record Germany Company Register staging smoke
latest Germany scheduling-blocker design: globalpulse_germany_company_register_pagination_rate_captcha_design.md
first canary runbook: globalpulse_eu_scheduled_staging_canary_runbook.md
first canary configuration result: globalpulse_eu_scheduled_staging_canary_configuration_results.md
current source default: active=false
current candidate status default: manual_staging_only
scheduled EU polling: disabled
```

The EU track now has broad manual staging evidence across official OAM, exchange, regulator, and issuer-announcement surfaces. That evidence proves parser and live-fetch compatibility. It does not by itself approve scheduled polling.

## Promotion Scope

The next allowed promotion is only:

```text
CONSERVATIVE_EU_SCHEDULED_STAGING_CANARY
```

The next allowed promotion is not:

```text
PRODUCTION_SCHEDULED_POLLING
ALL_EU_SOURCE_BATCH_ENABLEMENT
PUBLIC_POLL_UI
PUBLIC_SOURCE_HEALTH_UI
AUDIT_UI
BACKEND_DIGEST_JSON_SHAPE_CHANGE
FRONTEND_FRAMEWORK_CHANGE
```

## First Canary Source Set

Use a small source set first. The first scheduled staging canary should prefer official, bounded, machine-readable, or parser-stable sources that have already passed staging live poll smoke.

Recommended first canary candidates:

```text
eu_france_info_financiere_oam
eu_spain_cnmv_inside_information
eu_spain_cnmv_other_relevant_information
eu_belgium_fsma_stori
uk_fca_nsm_regulated_information
ch_six_ser_official_notices
eu_euronext_company_press_releases
pt_cmvm_portal_info_privi
```

Rationale:

```text
These sources are official listed-company disclosure or issuer-announcement surfaces.
They have manual staging live poll evidence.
They are API/RSS or bounded parser paths with source-level caps.
They provide regional spread without immediately scheduling every EU parser shape.
```

## Excluded From First Canary

Do not include these in the first scheduled staging canary:

```text
de_company_register_capital_market_info
cz_pse_issuer_news_multi_isin
cz_pse_issuer_report_calendar_multi_isin
at_oekb_oam_issuer_info
de_xetra_frankfurt_newsboard
eu_austria_wiener_borse_announcements
eu_netherlands_afm_financial_reporting
eu_italy_emarket_storage_regulated_communications
eu_luxembourg_luxse_oam
eu_nasdaq_nordic_company_news
gr_athex_issuer_announcements
gr_athex_corporate_actions
no_oslo_bors_newsweb_main_market
pl_gpw_espi_ebi_reports
hu_bse_issuers_news
ro_bvb_current_reports
si_oam_regulated_information
hr_zse_eho_issuer_news
hr_zse_eho_financial_reports
sk_ceri_regulated_information
ee_oam_market_announcements
lt_oam_regulated_information
lv_csri_regulated_information
```

Rationale:

```text
Germany Company Register has a proven over_page_cap=true condition for the smoke date; its pagination/rate/captcha design is recorded separately and still requires multi-page staging smoke evidence before scheduling.
Prague/PSE uses source-specific multi-ISIN fan-out and should get its own cadence/rate design before scheduling.
The remaining sources are valid manual candidates, but the first canary should be deliberately small to isolate failures and digest impact.
Some bounded HTML and high-volume sources have digest top-n or public latest visibility pending, which is acceptable for manual status but not enough for first batch scheduling.
```

This exclusion is not a rejection. It is a sequencing rule.

## Conservative Staging Cadence

If a separate PR enables the first canary schedule, use this starting policy:

```text
workflow: GlobalPulse EU scheduled staging canary
edition: breaking
use_live_fetch: true
source status in registry: active=false
candidate_status: manual_staging_only or scheduled_staging_canary
max_items_per_poll: keep each source at 25 or lower
cadence: every 4 hours on weekdays
cron example: 17 */4 * * 1-5
timezone: UTC cron
environment: Fly staging only
```

Rationale:

```text
The source set spans several official authorities.
Four-hour weekday cadence is enough to observe stability without creating unnecessary traffic.
Keeping each source capped prevents any one source from dominating materialization or public digest windows.
Leaving source active=false avoids confusing manual/staging source status with production enablement.
```

## Required Scheduled Staging Checks

Each scheduled staging run must record or make inspectable:

```text
GET /api/health: 2xx
POST /api/admin/sources/<source_key>/poll?use_live_fetch=true&edition=breaking: 2xx
poll.fetch.mode: live
poll.fetch.status_code: 200 or documented accepted source-specific 2xx
poll.fetch.fixture_fallback: false
poll.records_seen <= configured max_items_per_poll
poll.records_inserted <= poll.records_seen
poll.canonical_items count <= poll.records_seen
GET /api/feed/digest/latest?edition=breaking: 2xx
digest.metadata.fallback_to_fixture: false
public digest JSON response shape unchanged
no source returns unsupported content type, parser error, login page, captcha page, or tokenless shell as live success
```

Daily observation should also sample date-specific digest endpoints for sources whose rows are not expected in the latest top-N window.

## Observation Window

Before production scheduled polling can be considered, observe the scheduled staging canary for:

```text
minimum duration: 7 calendar days
minimum successful scheduled runs per source: 5
allowed fixture fallback live claims: 0
allowed unresolved parser/content-type failures: 0
allowed unresolved public digest shape changes: 0
```

Failure classes:

```text
transient_network
unexpected_status
unsupported_live_content_type
unsupported_live_payload
parser_error
over_cap_unexpected
rate_limit_or_captcha
duplicate_reference_noise
digest_diversity_regression
public_ui_regression
```

## Rollback Policy

Rollback immediately if any of the following occur:

```text
any scheduled source repeatedly fails with parser/content-type errors
any scheduled source returns fixture fallback while being claimed as live
any scheduled source hits a login, security-query, captcha, or tokenless shell path
records_seen exceeds the configured cap without explicit over-cap metadata
one source dominates the public top-12 digest despite existing diversity guard behavior
public digest JSON response shape changes
GitHub Pages GlobalPulse UI stops rendering existing regional sections
SEC, India NSE, or other already observed live paths regress after EU schedule changes
```

Rollback action:

```text
remove the affected EU source from the scheduled staging workflow
keep source active=false
set candidate_status to manual_staging_only or scheduled_staging_paused if a status field is changed in a later PR
run GET /api/health
run one known-good non-EU live smoke or latest digest smoke
record rollback smoke results in a docs-only PR
```

## Production Promotion Blockers

Production scheduled polling remains blocked until a separate approval document records:

```text
7-day scheduled staging canary summary
run count and failure count per source
latest source health state per source
latest digest source/region distribution
duplicate and over-cap behavior summary
rate-limit/captcha observation summary
explicit rollback confirmation
explicit public Pages UI smoke confirmation
operator-approved final source list
```

## Explicit Non-Goals

```text
Do not set any EU source active=true in this design PR.
Do not add scheduled workflow configuration in this design PR.
Do not enable Germany Company Register scheduled polling from this design.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
Do not change public digest JSON response shape.
Do not add frontend framework dependencies.
Do not claim fixture fallback as live success.
Do not include ECB, Eurostat, parliament, central-bank, macro, or policy feeds.
Do not enable JP live polling before issue #339 source-authority decision is resolved.
```

## Allowed Next PRs

```text
1. Add a docs-only scheduled staging canary runbook with the final first-canary source list.
2. Add scheduled staging workflow/config for only the approved first-canary sources.
3. Record first scheduled staging canary smoke after the workflow runs.
4. Record a 7-day EU canary observation summary before any production decision.
5. Record Germany Company Register multi-page staging smoke only after the separate pagination/rate/captcha design is implemented in a staging-only path.
```

## Current Conclusion

```text
EU_MANUAL_SOURCE_BATCH_READY_FOR_CONSERVATIVE_STAGING_CANARY_DESIGN
EU_FIRST_CANARY_SOURCE_SET_RECOMMENDED
EU_SCHEDULED_STAGING_CANARY_RUNBOOK_RECORDED
EU_SCHEDULED_STAGING_CANARY_PHASE0_CONFIG_READY
EU_DEFAULT_BRANCH_ACTIVATION_PASS
EU_CANARY_MANUAL_DISPATCH_PATH_RECORDED
EU_CANARY_WORKFLOW_DISPATCH_PASS
GERMANY_COMPANY_REGISTER_PAGINATION_RATE_CAPTCHA_DESIGN_RECORDED
EU_HIGHER_RISK_MANUAL_SOURCES_DEFERRED
EU_PRODUCTION_SCHEDULED_POLLING_BLOCKED
NEXT_STEP_EU_FIRST_AUTOMATED_CANARY_SMOKE
```
