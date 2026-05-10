# North Macedonia SEI-NET Public Documents Candidate Notes

Status: `MANUAL_SOURCE_REGISTERED_LOCAL_AND_LIVE_PARSER_SMOKE_PASS_STAGING_LIVE_POLL_PENDING`

## Scope

`mk_seinet_public_documents` is an inactive/manual staging-only candidate for listed-company disclosures published through the official SEI-NET public disclosure system.

The candidate intentionally targets the bounded public documents API:

```text
POST https://api.seinet.com.mk/public/documents
body: {"languageId":2,"channelId":1,"page":1,"isPushRequest":false}
```

## Why This Fits

The source is an official North Macedonia SEI-NET listed-company disclosure surface. It returns issuer documents with bounded fields such as `documentId`, `publicId`, issuer, layout/category, publication timestamps, content excerpt, and attachments.

This is not a central-bank, macro, policy, or generic news feed.

## Guardrails

```text
active=false
candidate_status=manual_staging_only
disable_live_fixture_fallback=true
scheduled polling disabled
no detail/attachment fetch
no user/log/remote-address fields are emitted by the parser
backend digest JSON response shape unchanged
```

The live API response includes user/action-log material that is not needed for GlobalPulse. The parser deliberately ignores that material and only emits bounded listed-company disclosure fields.

## Verification Plan

```text
local registry/capability smoke: PASS
local fixture parser smoke: PASS, 3 bounded records
live parser smoke against the public documents API: PASS, HTTP 200, application/json, 50,183 bytes, 10 bounded records
Fly staging live poll smoke: PENDING
date-specific digest visibility smoke: PENDING
public latest UI visibility smoke when top-N/date selection includes SEI-NET rows: PENDING
```
