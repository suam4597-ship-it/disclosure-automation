# GlobalPulse Pipeline Format CI Recovery

Date: 2026-05-12 KST

This document records the CI recovery after `pipeline.ex` formatting drift caused Phase 1 backend checks to fail.

This is status documentation. It does not change backend runtime behavior, frontend runtime behavior, routes, public API response shapes, source activation, production polling, public poll UI, audit UI, or public Source Health UI.

## Conclusion

```text
PIPELINE_FORMAT_DRIFT_FIXED
PHASE1_BACKEND_VERIFY_RECOVERED
PHASE1_RUNTIME_SMOKE_STILL_PASSING
PHASE1_BACKEND_REPORT_RECOVERED
PHASE1_BACKEND_DIAGNOSE_RECOVERED
PHASE1_BACKEND_TRACE_RECOVERED
NO_BEHAVIOR_CHANGE
```

## Failure

The failing checks were observed after the source-promotion approval issue link PR reached `phase0-foundation`.

Failed workflows included:

```text
Phase 1 backend verify
Phase 1 backend report
Phase 1 backend diagnose
Phase 1 backend trace
```

Root cause:

```text
mix format --check-formatted failed on apps/backend/disclosure_api/lib/disclosure_automation/pipeline.ex
```

The formatter expected the HKEX unsupported-payload tuple on one line.

## Fix

PR:

```text
PR: https://github.com/suam4597-ship-it/disclosure-automation/pull/567
title: Format HKEX payload guard
merge commit: 34c7d06e0503bcf83f64d35a7c4b59b55b64a69e
```

Changed file:

```text
apps/backend/disclosure_api/lib/disclosure_automation/pipeline.ex
```

Scope:

```text
formatting-only
no behavior change
no source activation
no production polling
```

## Recovery Runs

Push-event checks on `phase0-foundation` at head SHA `34c7d06e0503bcf83f64d35a7c4b59b55b64a69e`:

```text
Phase 0 validate: success, run 25679821569
Phase 0 report: success, run 25679821556
Phase 1 backend verify: success, run 25679821578
Phase 1 runtime smoke: success, run 25679821689
Phase 1 backend report: success, run 25679821616
Phase 1 backend diagnose: success, run 25679821571
Phase 1 backend trace: success, run 25679821679
```

Pull-request-event checks on the same head SHA:

```text
Phase 0 validate: success, run 25679825680
Phase 0 report: success, run 25679825699
Phase 1 backend verify: success, run 25679825669
Phase 1 runtime smoke: success, run 25679825970
Phase 1 backend report: success, run 25679825665
Phase 1 backend diagnose: success, run 25679825662
Phase 1 backend trace: success, run 25679824002
```

## Warning

The backend verify run still emitted the GitHub-hosted Actions Node.js 20 deprecation warning for `actions/cache@v4` and `actions/checkout@v4`.

That warning did not fail the run and is separate from the formatting recovery.

## Local Verification Note

Local Windows Elixir verification could not complete cleanly because the local Erlang runtime emitted an `erl_crash.dump` around standard error handling during `mix format --check-formatted`.

Generated local verification artifacts were removed and not committed:

```text
apps/backend/disclosure_api/deps
apps/backend/disclosure_api/_build
apps/backend/disclosure_api/mix.lock
apps/backend/disclosure_api/erl_crash.dump
```

GitHub Actions remained the authoritative verification for this fix.

## Guardrails

```text
Do not treat this as a source behavior change.
Do not set HKEX active=true from this fix.
Do not enable production scheduled polling.
Do not change backend digest JSON response shape.
Do not add public poll UI.
Do not add audit UI.
Do not add public Source Health UI.
```
