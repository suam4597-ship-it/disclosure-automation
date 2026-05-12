# Sarajevo SASE Issuer Announcements Candidate Notes

Status: `MANUAL_SOURCE_REGISTERED_LOCAL_PARSER_SMOKE_PASS_LIVE_ENDPOINT_PROBE_PASS_STAGING_LIVE_POLL_PASS`

## Scope

`ba_sase_issuer_announcements_multi_code` is an inactive/manual staging-only candidate for listed-company issuer announcements published through Sarajevo Stock Exchange's official handler endpoint.

```text
candidate URL: http://www.sase.ba/FeedServices/HandlerChart.ashx
HTTPS handler probe: local PowerShell/WinHTTP returns 200, but Fly staging app fetch closed the TLS connection during the first staging smoke.
HTTP handler probe: local PowerShell/WinHTTP returns 200 for the same bounded POST body and is used as the manual staging candidate fetch URL.
surface label: Reports > Companies > Financial reports / issuer announcements
source owner: Sarajevo Stock Exchange
```

## Why This Fits

The SASE public site exposes issuer announcement data through the official `FeedServices/HandlerChart.ashx` endpoint. The candidate uses bounded configured issuer codes and `type=24` issuer-announcement responses, returning XML-like announcement rows with subject, company id, announcement date, event date, announcement type, and optional document file references.

This is not a central-bank, macro, policy, or generic market commentary feed.

## Guardrails

```text
active=false
candidate_status=manual_staging_only
disable_live_fixture_fallback=true
scheduled polling disabled
configured issuer window only
download POST endpoint out of scope
backend digest JSON response shape unchanged
```

## Verification Plan

```text
local registry/capability smoke: PASS
local fixture parser smoke: PASS
external endpoint probe: PASS, HandlerChart type=3 issuer universe returns JSON
external issuer announcement probe: PASS, HandlerChart type=24 returns XML-ish issuer announcements for configured issuer prefixes
application live fetch smoke
Fly staging live poll smoke: PASS, 25 live rows inserted
date-specific digest visibility smoke: PASS, 2026-04-10 breaking digest includes Bosnalijek d.d. Sarajevo
public latest UI visibility smoke: PENDING, current latest digest date remains newer than SASE smoke rows
```

## Open Follow-Up

The first registered slice uses a configured issuer-code window:

```text
BHTS
JPES
BSNL
ASA
ALUM
```

Do not promote this source to scheduled polling until a cadence/rate design is recorded and repeated staging smoke confirms the handler remains stable.

## Staging Smoke Record

```text
record: globalpulse_sarajevo_sase_issuer_announcements_staging_live_poll_smoke_results.md
deploy commit: 5c7359b06435fa063c4350179e783c631f529845
live poll: PASS
fixture_fallback: false
records_seen: 25
records_inserted: 25
latest public UI visibility: pending by digest date selection
```
