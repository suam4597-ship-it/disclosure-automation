# GlobalPulse EU Scheduled Staging Canary Runbook

This document turns the EU batch-promotion design into a concrete first-canary runbook.

This is documentation-only. It does not add runtime code, routes, controllers, migrations, backend response-shape changes, frontend shell changes, frontend framework changes, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, workflow schedules, source activation, or scheduled polling.

## Conclusion

```text
EU_SCHEDULED_STAGING_CANARY_RUNBOOK_RECORDED
EU_FIRST_CANARY_SOURCE_LIST_FINALIZED
EU_WORKFLOW_CONFIG_PR_ALLOWED_AFTER_THIS_RUNBOOK
EU_PRODUCTION_SCHEDULED_POLLING_NOT_APPROVED
EU_PUBLIC_UI_AND_API_SHAPE_UNCHANGED
```

## Baseline

```text
design doc: globalpulse_eu_source_batch_promotion_design.md
backend URL: https://globalpulse-backend-staging.fly.dev
workflow candidate: .github/workflows/globalpulse-live-staging-poll.yml
current branch target: phase0-foundation
default branch scheduling caveat: GitHub schedule events run from the repository default branch workflow definition
current EU source default: active=false
current EU candidate status default: manual_staging_only
production EU scheduled polling: not approved
```

## First Canary Source List

The first scheduled staging canary should include only these source keys:

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

Why these sources are in the first canary:

```text
They are official listed-company disclosure, regulated-information, or issuer-announcement sources.
They already passed manual Fly staging live poll smoke.
They use API/RSS or comparatively bounded parser paths.
They keep the first scheduled EU canary small enough to isolate failures.
They cover western, southern, central, and UK/Swiss listed-company disclosure surfaces without scheduling every EU parser shape at once.
```

## Explicit First-Canary Exclusions

Do not include these source keys in the first scheduled staging canary:

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

Exclusion reasons:

```text
Germany Company Register has proven live compatibility, but the smoke date returned over_page_cap=true; separate pagination, duplicate, rate, captcha, and rollback design is recorded and multi-page staging smoke evidence is still required before scheduled polling.
Prague/PSE uses source-specific multi-ISIN fan-out; separate cadence/rate design is recorded and issuer-window rotation plus repeated staging smoke evidence are still required before scheduling.
The remaining manual candidates are valid, but the first canary should minimize parser-shape diversity and operational blast radius.
Sources with digest top-N or public latest visibility pending can stay manual-only until the first canary observation window is understood.
```

## Workflow Configuration Contract

The follow-up workflow/config PR may update `.github/workflows/globalpulse-live-staging-poll.yml` only for staging.

Allowed workflow behavior:

```text
add one EU canary cron
cron: 17 */4 * * 1-5
route that cron to a deterministic source list
poll one EU source per workflow run, or poll the full first-canary source list sequentially with fail-fast disabled
keep existing SEC and India NSE schedules intact
keep workflow_dispatch source_key override intact
keep backend_url and edition inputs intact
upload health, poll, and digest JSON artifacts
```

Preferred first implementation:

```text
poll the full first-canary source list sequentially in one scheduled run
write one poll JSON file per source, for example poll-eu_france_info_financiere_oam.json
continue polling remaining canary sources after one source fails
fail the workflow at the end if any source failed required checks
upload all per-source outputs as artifacts
```

Why this is preferred:

```text
One scheduled run gives a coherent EU canary snapshot.
Continuing after a single-source failure preserves evidence for the rest of the canary.
Per-source artifacts make the first scheduled smoke PR easier to write.
```

Fallback implementation:

```text
If sequential multi-source workflow changes are too large, route the EU cron to only eu_france_info_financiere_oam first.
Record the first scheduled run smoke.
Add the remaining first-canary sources in a later config PR after the single-source cron is stable.
```

## Required Checks Per Source

For every scheduled EU canary source, the workflow must verify:

```text
GET /api/health returns 2xx before polling begins
POST /api/admin/sources/<source_key>/poll?use_live_fetch=true&edition=breaking returns 2xx
poll.fetch.mode == live
poll.fetch.fixture_fallback == false
poll.records_seen <= 25
poll.records_inserted <= poll.records_seen
poll.canonical_items count <= poll.records_seen
poll.raw_documents count <= poll.records_seen
poll fetch status is 200 unless the source has a documented alternate 2xx success contract
GET /api/feed/digest/latest?edition=breaking returns 2xx after polling
digest.metadata.fallback_to_fixture == false
```

The workflow should fail on:

```text
fixture fallback claimed as live
unsupported content type
parser error
login page
captcha or security-query page
tokenless shell treated as success
records_seen above configured max_items_per_poll without explicit over-cap metadata
public digest endpoint non-2xx
```

## First Scheduled Smoke PR Requirements

After the first EU scheduled staging canary run, create a docs-only smoke result PR that records:

```text
workflow run URL
workflow artifact name and id
cron expression
resolved source list
backend URL
health status
per-source poll HTTP status
per-source fetch.mode
per-source fetch.status_code
per-source fixture_fallback
per-source records_seen
per-source records_inserted
per-source canonical_items count
latest digest status
latest digest fallback_to_fixture
latest digest source distribution
date-specific digest notes for sources not visible in latest top-N
any failed source and rollback action if needed
```

## Observation Window

The EU canary remains staging-only until a follow-up observation summary records:

```text
minimum duration: 7 calendar days
minimum successful scheduled runs per included source: 5
allowed fixture fallback live claims: 0
allowed unresolved parser/content-type failures: 0
allowed unresolved public digest shape changes: 0
```

The observation summary must include:

```text
run count by source
failure count by source
latest source-health state by source
latest digest source and region distribution
duplicate behavior notes
over-cap behavior notes
rate-limit or captcha observations
rollback readiness confirmation
public Pages UI smoke confirmation
```

## Rollback Runbook

Rollback triggers:

```text
one source repeatedly fails with parser/content-type errors
one source returns fixture fallback while being claimed as live
one source hits login, security-query, captcha, or tokenless-shell behavior
one source exceeds configured cap without explicit over-cap metadata
public digest JSON response shape changes
public Pages UI stops rendering existing regional digest sections
SEC or India NSE staging schedules regress after EU config changes
```

Rollback action:

```text
remove the affected EU source from the scheduled workflow source list
keep registry active=false
keep candidate_status=manual_staging_only unless a later PR explicitly adds scheduled_staging_paused
run GET /api/health
run a known-good latest digest smoke
record rollback evidence in a docs-only PR
```

## Default Branch Activation

GitHub scheduled workflows execute from the repository default branch. If the workflow/config PR is first merged only to `phase0-foundation`, scheduled runs may not fire from that branch.

Required activation path:

```text
1. Merge workflow/config PR to phase0-foundation.
2. Confirm CI passes.
3. Apply the workflow-only schedule change to the repository default branch if the default branch remains different from phase0-foundation.
4. Record default-branch activation evidence in the workflow/config result doc.
5. Wait for the next matching EU canary cron.
6. Record first scheduled EU canary smoke.
```

## Guardrails

```text
Do not set production scheduled EU polling from this runbook.
Do not set any EU source active=true from this runbook.
Do not include Germany Company Register in the first canary.
Do not include Prague/PSE in the first canary.
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
1. Add EU scheduled staging canary workflow/config for the finalized first-canary source list.
2. Record EU scheduled staging canary configuration results, including default-branch activation status.
3. Record first automated EU scheduled staging canary smoke after the cron fires.
4. Record 7-day EU canary observation summary.
5. Add separate Germany Company Register multi-page staging smoke only after the pagination/rate/captcha design is implemented in a staging-only path.
6. Add separate Prague/PSE issuer-window rotation smoke only after the cadence/rate design is implemented in a staging-only path.
```

## Current Conclusion

```text
EU_FIRST_SCHEDULED_STAGING_CANARY_RUNBOOK_READY
EU_FIRST_CANARY_SOURCE_LIST_FINAL
EU_WORKFLOW_CONFIG_PR_RECORDED
GERMANY_COMPANY_REGISTER_PAGINATION_RATE_CAPTCHA_DESIGN_RECORDED
PRAGUE_PSE_CADENCE_RATE_DESIGN_RECORDED
EU_PRODUCTION_SCHEDULED_POLLING_BLOCKED
```
