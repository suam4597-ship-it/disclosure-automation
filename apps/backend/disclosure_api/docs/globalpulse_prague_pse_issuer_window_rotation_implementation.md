# GlobalPulse Prague PSE Issuer Window Rotation Implementation

This document records the staging-only implementation gate for Prague Stock Exchange multi-ISIN issuer window selection.

The change does not enable scheduled polling, does not set either PSE source active, does not add PSE to the first EU scheduled canary, does not change public digest JSON shape, and does not add frontend UI.

## Conclusion

```text
PRAGUE_PSE_ISSUER_WINDOW_ROTATION_IMPLEMENTED
PRAGUE_PSE_STATIC_OFFSET_WINDOW_DEFAULT_RETAINED
PRAGUE_PSE_SELECTED_WINDOW_METADATA_RECORDED
PRAGUE_PSE_MANUAL_STAGING_ONLY_REMAINS
PRAGUE_PSE_SCHEDULED_POLLING_STILL_BLOCKED
```

## Implemented Behavior

Both existing PSE multi-ISIN sources now select issuers through a shared bounded issuer-window helper:

```text
cz_pse_issuer_news_multi_isin
cz_pse_issuer_report_calendar_multi_isin
```

Default behavior remains unchanged:

```text
pse_issuer_window_strategy: static_offset
pse_issuer_window_offset: 0
max_issuers_per_poll: 10
```

With the default offset, the sources continue to poll the first deterministic 10-issuer window from the official PSE issuer universe.

## Manual Staging Override

Staging can now test a different deterministic issuer window by changing source config only:

```yaml
config:
  max_issuers_per_poll: 10
  pse_issuer_window_strategy: static_offset
  pse_issuer_window_offset: 10
```

The offset is normalized against the live universe count, so an offset greater than the universe size wraps safely.

This is a staging/manual smoke mechanism only. Do not expose this as a public route, query param, UI control, or production scheduling control.

## Smoke Metadata

Live PSE poll responses now include bounded issuer-window metadata in the source fetch info:

```text
selected_issuer_window_strategy
selected_issuer_window_offset
selected_issuer_window_size
selected_issuer_window_universe_count
```

The raw bounded fan-out payload also includes:

```text
issuer_window.strategy
issuer_window.offset
issuer_window.size
issuer_window.universe_count
selected_isins
```

This gives the next staging smoke enough evidence to prove that two manual runs used different issuer windows.

## Required Next Smoke

Before PSE can be considered for any scheduled staging canary, record at least two successful manual staging smokes for a single PSE source using different offsets:

```text
offset 0
offset 10
```

For each smoke result, record:

```text
source_key
active=false
fetch.mode=live
fetch.status_code=200
fixture_fallback=false
universe_count
selected_issuer_window_offset
selected_issuer_window_size
selected_isins
issuer_request_count or calendar_request_count
records_seen
records_inserted
digest visibility
source health after the run
```

## Guardrails

```text
do not set PSE active=true
do not add PSE to the first EU scheduled staging canary
do not enable production scheduled polling
do not run issuer news and report calendar simultaneously
do not increase max_issuers_per_poll above 10 in this track
do not expose issuer-window offset through public API or UI
do not change backend digest JSON response shape
do not add public poll UI
do not add public Source Health UI
do not add frontend framework
```

## Next Step

Run a manual Fly staging smoke for `cz_pse_issuer_report_calendar_multi_isin` using the default offset, then a second manual smoke after setting `pse_issuer_window_offset: 10` in staging config.

Keep `cz_pse_issuer_news_multi_isin` separate until report-calendar rotation smoke passes.
