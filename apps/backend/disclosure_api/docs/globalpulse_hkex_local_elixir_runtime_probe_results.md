# GlobalPulse HKEX Local Elixir Runtime Probe Results

Date: 2026-05-11 KST

This document records a local Erlang/Elixir runtime HTTP probe for the official HKEXnews listed-company title-search surface.

This is documentation-only. It does not add runtime code, routes, controllers, templates, migrations, backend response-shape changes, frontend shell changes, frontend framework dependencies, login UI, redirects, identity provider callback routes, poll UI, audit UI, public Source Health UI, provider behavior, materializer behavior, canonical behavior, dashboards, alerts, workflow schedules, source registration, source activation, or production scheduled polling.

## Conclusion

```text
HKEX_LOCAL_ELIXIR_RUNTIME_PROBE_RECORDED
HKEX_LOCAL_ERLANG_HTTPC_FETCH_PASS
HKEX_TITLE_SEARCH_HTML_RETURNED_FROM_LOCAL_ELIXIR
HKEX_BOUNDED_ISSUER_ROWS_DETECTED
HKEX_LLCI_JSON_LOCAL_ERLANG_HTTPC_FETCH_PASS
HKEX_FLY_RUNTIME_PROBE_STILL_PENDING
HKEX_SOURCE_REGISTRATION_STILL_BLOCKED
NO_CNTW_SOURCE_REGISTERED
NO_CNTW_SCHEDULED_LIVE_POLLING_ENABLED
KR_LIVE_SOURCE_TRACK_DEFERRED
JP_LIVE_POLLING_STILL_BLOCKED_BY_ISSUE_339
```

## Environment

```text
host: local Windows development machine
runtime: Elixir 1.18.4
Erlang/OTP: 28
HTTP path: Erlang :httpc
Fly CLI: unavailable in this local environment
Fly staging runtime result: not claimed by this probe
```

This probe is weaker than a Fly staging release eval. It confirms that the same Erlang/Elixir HTTP stack family can fetch the bounded HKEX URL from the local network, but it does not prove Fly edge/network compatibility.

## Probe Target

```text
official surface: HKEXnews Listed Company Information Title Search
URL: https://www1.hkexnews.hk/search/titlesearch.xhtml?category=0&market=SEHK&stockId=268
query type: bounded stock-specific issuer publication result
stockId: 268
market: SEHK
category: 0
```

Headers used were bounded and non-secret:

```text
user-agent: Mozilla/5.0 GlobalPulse HKEX local runtime probe
accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
accept-language: en-US,en;q=0.9
```

No cookies, credentials, response bodies, PDF contents, raw attachments, or detail documents were recorded.

## Probe Command Shape

The probe started `:ssl` and `:inets`, then called:

```text
:httpc.request(:get, {url, headers}, opts, body_format: :binary)
```

The response body was inspected only for bounded contract markers:

```text
Total records found
Release Time
Stock Code
BE ENVIRONMENT
/listedco/listconews/sehk/
```

## Observed Result

```text
status: 200
reason: OK
content_type: text/html;charset=UTF-8
bytes: 120707
has_total_records: true
total_records: 877
has_release_time: true
has_stock_code: true
has_be_environment: true
has_pdf_link: true
```

Interpretation:

```text
The bounded HKEX title-search URL can return issuer publication HTML through local Erlang :httpc.
The response includes stable enough markers for a possible bounded HTML parser design.
The first parser candidate would still need to avoid attachment/PDF fetching.
The source registration gate remains closed until Fly/application runtime compatibility is proven and the query contract is accepted.
```

## LLCI JSON Follow-Up

A later local Erlang/Elixir `:httpc` probe fetched the HKEXnews Latest Listed Company Information JSON assets:

```text
target: https://www.hkexnews.hk/ncms/script/eds/homecat_e.json
status: 200
content_type: application/json
bytes: 529
has_latest_submissions: true

target: https://www.hkexnews.hk/ncms/script/eds/homecat0_e.json
status: 200
content_type: application/json
bytes: 1940
has_news_info: true
has_stock_code: true
has_pdf_link: true
```

Interpretation:

```text
The local Erlang runtime can also fetch the smaller official HKEX LLCI JSON assets.
homecat0_e.json is now the preferred HKEX parser/source-contract candidate.
This still does not replace the required Fly staging or application-runtime verification before source registration.
```

## Remaining Blockers

```text
Fly staging release-eval probe not run from this local environment
homecat0_e.json source/parser contract not accepted yet
Fly/application-runtime verification for homecat0_e.json not recorded yet
JSON parser shape not designed
access-policy review not complete
source active=false/manual-staging-only contract not written
manual staging live-poll smoke not possible before source registration
```

## Guardrails

```text
source registration not added
active=true not set
production scheduled polling not enabled
workflow schedule unchanged
backend digest JSON response shape unchanged
frontend shell unchanged
public poll UI not added
audit UI not added
public Source Health UI not added
no HKEX PDF/detail/attachment fetch
fixture fallback cannot be claimed as live success
KR remains deferred until the dedicated backend/source path exists
JP remains blocked until issue #339 is resolved
```

## Next Allowed Steps

```text
1. Run the same bounded HKEX title-search URL through Fly staging release eval when Fly CLI/auth is available.
2. Run the official HKEX homecat0_e.json asset through Fly staging release eval when Fly CLI/auth is available.
3. Draft a bounded JSON parser/source contract for homecat0_e.json only if Fly runtime compatibility and access policy are accepted.
4. Keep CN/TW production scheduled polling disabled.
```
