# Montenegro MNSE Corporate News Candidate Notes

Status: `MANUAL_SOURCE_REGISTERED_LOCAL_PARSER_SMOKE_PASS_LIVE_FETCH_BLOCKED_HTTP_CLIENT_TLS`

## Scope

`me_mnse_corporate_news` is an inactive/manual staging-only candidate for listed-company corporate announcements published by Montenegro Stock Exchange.

```text
candidate URL: http://www.mnse.me/code/navigate.asp?Id=852
HTTPS page probe: local PowerShell/WinHTTP returns 200, but application live fetch closed the TLS connection during the initial smoke.
HTTP page probe: local PowerShell/WinHTTP returns 200 with corporate-news markers and is used as the manual staging candidate fetch URL.
surface label: Korporativne novosti
source owner: Montenegro Stock Exchange
```

## Why This Fits

The page is an official exchange surface for issuer corporate news. The bounded HTML rows expose issuer name, publication date/time, announcement title, and a document URL under `/upload/documents/issuer/`.

This is not a central-bank, macro, policy, or generic market commentary feed.

## Guardrails

```text
active=false
candidate_status=manual_staging_only
disable_live_fixture_fallback=true
scheduled polling disabled
detail/PDF fetching out of scope
backend digest JSON response shape unchanged
```

## Verification Plan

```text
local registry/capability smoke: PASS
local fixture parser smoke: PASS, 3 bounded records
external endpoint probe: PASS, HTTP 200 text/html via PowerShell/WinHTTP
application live fetch smoke: RETRY_READY, HTTP fetch URL selected after HTTPS TLS close
Fly staging live poll smoke: BLOCKED until live fetch path is fixed
date-specific digest visibility smoke
public latest UI visibility smoke when top-N/date selection includes MNSE rows
```

## Open Blocker

PowerShell can fetch both `https://www.mnse.me/code/navigate.asp?Id=852` and `https://mnse.me/code/navigate.asp?Id=852` with HTTP 200. The initial Elixir/Erlang `:httpc` path returned `{:failed_connect, ... :closed}` during TLS connection setup. The same official page also responds over HTTP with the required corporate-news markers, so the manual staging candidate now uses the HTTP page URL for live fetch retry.

Do not claim staging live poll success or promote this source until the application fetch path has a bounded workaround.
