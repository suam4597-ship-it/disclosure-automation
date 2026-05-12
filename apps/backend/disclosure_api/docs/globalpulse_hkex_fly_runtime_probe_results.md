# GlobalPulse HKEX Fly Runtime Probe Results

Date: 2026-05-11 KST

This document records a bounded Fly staging runtime HTTP probe for the official HKEXnews Latest Listed Company Information JSON asset.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend shell changes, frontend framework dependencies, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, workflow schedules, source registration, source activation, or production scheduled polling.

## Conclusion

```text
HKEX_FLY_RUNTIME_PROBE_RECORDED
HKEX_FLY_RUNTIME_HOMECAT0_JSON_FETCH_PASS
HKEX_FLY_RUNTIME_DISCLOSURE_AUTOMATION_HTTP_FETCH_PASS
HKEX_HOMECAT0_NEWSINFO_SHAPE_RECONFIRMED
HKEX_STOCK_LIST_SHAPE_RECORDED
HKEX_INACTIVE_SOURCE_CANDIDATE_ADDED
HKEX_SOURCE_ACTIVE_FALSE
NO_CNTW_SCHEDULED_LIVE_POLLING_ENABLED
KR_LIVE_SOURCE_TRACK_DEFERRED
JP_LIVE_POLLING_STILL_BLOCKED_BY_ISSUE_339
```

## Probe Target

```text
app: globalpulse-backend-staging
region: nrt
runtime path: /app/bin/disclosure_automation eval
HTTP wrapper: DisclosureAutomation.Http.fetch/2
target: https://www.hkexnews.hk/ncms/script/eds/homecat0_e.json
```

The Fly machine was initially auto-stopped. It was started by calling:

```text
GET https://globalpulse-backend-staging.fly.dev/api/health
status: 200
```

## Runtime Note

The first release-eval attempt showed that the standalone eval context did not have the Erlang `:httpc` manager started.

The successful probe explicitly started the network applications before calling the application HTTP wrapper:

```elixir
:ssl.start()
:inets.start()
DisclosureAutomation.Http.fetch("https://www.hkexnews.hk/ncms/script/eds/homecat0_e.json", timeout: 15_000)
```

This is an eval-context requirement, not a source-registration approval by itself.

## Result

```text
status_code: 200
content_type: application/json
bytes: 1864
lastupdatetime: 11/05/2026 20:16
newsInfo_count: 5
viewAllHyperlink: https://www1.hkexnews.hk/listedco/listconews/index/lci.html?lang=en
```

Observed response headers included:

```text
content-type: application/json
last-modified: Mon, 11 May 2026 12:16:26 GMT
access-control-allow-origin: https://sc.hkexnews.hk
strict-transport-security: max-age=31536000; includeSubDomains
```

## Bounded Item Markers

Observed first item markers:

```text
newsId: 12155321
relY: 2026
relM: 05
relD: 11
relTime: 20:16
title: Next Day Disclosure...
sTxt: Next Day Disclosure Returns - [Share Buyback]
ext: pdf
size: 89KB
webPath: https://www1.hkexnews.hk/listedco/listconews/sehk/2026/0511/2026051101330.pdf
stock[0].sc: 02373
stock[0].sn: BEAUTYFARM MED
```

Observed second item markers showed an HTML-style attachment link and `ext` value of `NaN`:

```text
title: PROPOSED CONNECTED...
sTxt: Documents on Display
ext: NaN
webPath: https://www1.hkexnews.hk/listedco/listconews/sehk/2026/0511/2026051101323.htm
multi: 1
stock[0].sc: 02411
stock[0].sn: PAGODA GP
```

Interpretation:

```text
The parser must treat stock as a list of issuer maps when present.
The parser must allow bounded document-link metadata for PDF or HTM links, but must not fetch document bodies.
The parser must treat ext=NaN and size=NaN as unknown metadata rather than failing open.
```

## Parser Contract Refinement

This runtime probe refines the parser contract recorded in `globalpulse_hkex_latest_listed_company_parser_contract.md`:

```text
stock may be a list of issuer maps with sc/sn keys
stock may still need defensive fallback handling if future rows differ
issuer_code should prefer stock[0].sc
issuer_display_name should prefer stock[0].sn
newsId may be recorded as bounded source metadata
external_id remains preferably derived from the stable document id in webPath
```

## Source Registration Decision

This probe clears the Fly/application-runtime GET verification gate for `homecat0_e.json`.

It does not register or activate an HKEX source.

The next implementation PR may add an inactive/manual staging-only source candidate if it also includes bounded parser tests and preserves the attachment boundary.

## Guardrails

```text
source registration not added in this docs-only PR
active=true not set
production scheduled polling not enabled
workflow schedule unchanged
backend digest JSON response shape unchanged
frontend shell unchanged
public poll UI not added
audit UI not added
public Source Health UI not added
no HKEX PDF/detail/attachment body fetch
fixture fallback cannot be claimed as live success
CN/TW scheduled polling remains disabled
KR remains deferred until the dedicated backend/source path exists
JP remains blocked until issue #339 is resolved
```

## Next Allowed Steps

```text
1. Deploy the inactive/manual staging-only HKEX parser/source candidate to Fly staging.
2. Run manual staging live poll with metadata.fallback_to_fixture=false.
3. Record public digest visibility smoke before considering any cadence.
```
