# SEC local overlay checklist

Remaining step before expanding beyond 6-K.

Files to replace from the authoritative local workspace:
- .formatter.exs
- lib/disclosure_automation/schemas.ex
- lib/disclosure_automation_web/router.ex
- lib/disclosure_automation_web/controllers.ex
- lib/disclosure_automation/runtime/sec_adapter.ex
- lib/disclosure_automation/pipeline.ex

Then verify:
- sec_6k_runtime_idempotency_test.exs passes
- sec_6k_http_smoke_test.exs passes
- sec_thin_slice_dedupe_checks.sql is clean
