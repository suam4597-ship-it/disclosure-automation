# GlobalPulse Stale Stacked PR Cleanup

Date: 2026-05-12 KST

This document records the cleanup of stale open stacked PRs from the previous Fast MVP / Source Health branch stack.

This is documentation-only. It does not change frontend code, backend code, routes, public API response shapes, workflow behavior, source activation, production infrastructure, production scheduled polling, public poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
STALE_FAST_MVP_SOURCE_HEALTH_STACKED_PRS_CLOSED
STALE_PHASE1_SEC_THIN_SLICE_HISTORICAL_PRS_CLOSED
CURRENT_CONTINUATION_PATH_IS_GLOBALPULSE_PHASE0_FOUNDATION
ACTIVE_HANDOFF_POINTERS_REFRESHED_THROUGH_PR_614
OLD_BRANCHES_REMAIN_RECOVERABLE_IF_NEEDED
ONLY_PHASE0_TO_MAIN_INTEGRATION_PR_LEFT_OPEN
PRODUCTION_SCHEDULED_POLLING_NOT_ENABLED
```

## Cleanup Scope

Closed as superseded by the current GlobalPulse `phase0-foundation` workflow:

```text
#277 Design fast MVP existing HTML backend connection plan
#278 Add frontend API client and health status rendering
#279 Render feed digest in existing HTML shell
#280 Link existing HTML shell to source health operator page
#281 Use auth context in source health internal UI recheck action
#282 Use auth context in source health internal UI recheck submit flow
#283 Use auth context in source health operator smoke test
#284 Add source health legacy permission param inventory
#285 Design source health production-mode permission param denial
#286 Add source health production-mode permission param denial contract tests
#287 Gate source health legacy permission params behind test harness config
#288 Lock source health production-mode permission param denial
#289 Design source health production session source
#290 Add source health production session source contract tests
#291 Add source health production auth context builder
#292 Wire production source health auth context into operator routes
#293 Lock source health production session source
#294 Design upstream auth provider handoff for SourceHealthAuthContext
#295 Add source health upstream auth handoff contract tests
#296 Add source health upstream auth handoff plug skeleton
#297 Wire upstream auth handoff into source health operator pipeline
#298 Lock source health upstream auth handoff
#299 Design real upstream auth session provider integration for Source Health handoff
#300 Add source health real upstream auth provider integration contract tests
#301 Add source health upstream auth provider adapter skeleton
#302 Wire source health upstream auth provider adapter into operator pipeline
#303 Lock source health real upstream auth provider integration
#304 Design source health internal UI access policy
#305 Add source health internal UI access policy contract tests
#306 Add source health internal UI access guard
#307 Lock source health internal UI access policy
#308 Design fast MVP frontend backend deployment smoke plan
#309 Add fast MVP frontend backend smoke contract tests
#310 Add fast MVP deployment smoke runbook
#311 Lock fast MVP frontend backend deployment smoke
```

Each PR received a superseded comment pointing to the current continuation path:

```text
#612 Refresh GlobalPulse regional dashboard mapping
#613 Record refreshed GlobalPulse digest diversity
#614 Refresh GlobalPulse handoff after mapping update
GLOBALPULSE_HANDOFF.md
apps/backend/disclosure_api/docs/globalpulse_cross_local_resume_packet_20260512.md
```

## Why These Were Closed

The closed PRs formed an old stacked branch path that no longer matched the active repository shape.

The current active GlobalPulse path is:

```text
primary branch: phase0-foundation
current handoff: GLOBALPULSE_HANDOFF.md
current cross-local resume packet: globalpulse_cross_local_resume_packet_20260512.md
current public web surface: GitHub Pages + Fly staging backend
current production state: blocked pending issue #561 / issue #565 approvals
```

Closing these PRs reduces ambiguity in the GitHub PR queue without deleting the branch history. Any branch can still be inspected or recovered later if a specific old change is needed.

## Remaining Open PRs

The older March/April PRs were triaged next.

Closed as superseded historical PRs:

```text
#2 Phase 1 fix: format config and clear source-health compile warning
#3 Phase 1 backend: verification fix branch
#4 Phase 1 backend: verification fix branch v2
#5 Phase 1 warning cleanup v2
#6 Phase 1 backend: verification fix branch v3
#7 Phase 1 backend: verification fix branch v4
#8 p1-v5
#9 p1-v6
#10 p1v7
#11 p1v8
#12 p19
#13 p20
#14 p20p0
#15 p21
#16 r1
#17 u1
#18 z2
#19 sec thin slice upload v3
#20 WIP: lock SEC 6-K before form expansion
```

The only remaining open PR after this cleanup is:

```text
#1 Phase 0 foundation: Codespaces + Vercel entry + backend runbook
```

#1 is intentionally left open because it represents the broader `phase0-foundation` to `main` integration decision. It is not the same as the stale branch-stack cleanup. Current day-to-day work should continue on `phase0-foundation` unless the operator explicitly decides to resolve the main-branch integration path.

## Guardrails

```text
Do not infer production approval from PR cleanup.
Do not create production infrastructure.
Do not promote frontend runtime config to production.
Do not enable production scheduled polling.
Do not set candidate sources active=true.
Do not change backend digest JSON response shape.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
```
