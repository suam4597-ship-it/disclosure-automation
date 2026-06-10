# Serbia BELEX Issuer News Candidate Notes

Status: `MANUAL_SOURCE_REGISTERED_STAGING_LIVE_POLL_PASS`

## Scope

`rs_belex_issuer_news` is an inactive/manual staging-only candidate for listed-company issuer announcements published by the Belgrade Stock Exchange.

```text
candidate URL: https://www.belex.rs/eng/
surface label: News from Issuers
source owner: Belgrade Stock Exchange
```

## Why This Fits

The page is an official exchange surface for issuer news. The bounded homepage table exposes issuer symbols, publication dates, announcement titles, and links to official issuer-news pages under `/eng/trgovanje/vesti/hartija/`.

This is not a central-bank, macro, policy, or generic commentary feed.

## Guardrails

```text
active=false
candidate_status=manual_staging_only
disable_live_fixture_fallback=true
scheduled polling disabled
symbol detail pagination out of scope
backend digest JSON response shape unchanged
```

## Verification Plan

```text
local registry/capability smoke
local fixture parser smoke
external endpoint probe: PASS, HTTP 200 text/html via PowerShell/WinHTTP
application live fetch probe: PASS, Erlang :httpc receives HTTP 200 from homepage
Fly staging live poll smoke: PASS, 5 live records inserted
date-specific digest visibility smoke: PASS, 3 BELEX rows in 2026-04-30 digest
public latest UI visibility smoke: PENDING, current latest digest is newer than observed BELEX rows
```

## Open Follow-Up

The first registered slice parses the latest bounded homepage issuer-news table. The symbol-specific issuer pages expose deeper historical rows, but rotating through individual symbols is intentionally out of scope until a cadence/rate design exists.
