# CN discovery inventory

This document tracks official-source discovery work for the first China regional vertical.

## Status

No CN official disclosure source is frozen yet.
The sources below are inventory candidates only and must be inspected before any runtime contract is written.

## Candidate source surfaces

| Candidate | Why inspect | First questions | Freeze status |
| --- | --- | --- | --- |
| Shanghai Stock Exchange / SSE disclosure pages | Primary exchange disclosure surface for SSE-listed issuers | Are detail URLs stable? Is there a visible announcement id/document id? Can one high-signal family be isolated? | not frozen |
| Shenzhen Stock Exchange / SZSE disclosure pages | Primary exchange disclosure surface for SZSE-listed issuers | Are category filters deterministic? Can one sample be captured without broad ingestion? | not frozen |
| Beijing Stock Exchange / BSE disclosure pages | Primary exchange disclosure surface for BSE-listed issuers | Does the public surface expose stable detail/document ids and usable publication timestamps? | not frozen |
| CNInfo / 巨潮资讯网 | Broad market disclosure archive commonly used for A-share announcements | Is this official-regulatory enough for v0? Are announcement ids stable? Can it narrow to one family/sample? | not frozen |
| CSRC public disclosure / regulatory filing surfaces | Regulator-level source surface | Does it expose issuer-level market announcements suitable for the first vertical? | not frozen |

## Discovery questions to close

### 1) What is the official public source?

For each candidate, record:

- public discovery URL
- public detail URL shape
- source owner/operator
- whether the surface is exchange-operated, regulator-operated, or archive-like
- whether the source can be treated as `official_exchange_storage` or `official_regulatory_storage`

### 2) What is the first high-signal family?

Do not ingest every CN announcement type.
Evaluate whether a candidate source can isolate one family from this initial order:

1. M&A / restructuring / major asset transaction style disclosure
2. material information / major announcement
3. shareholding / ownership change
4. takeover / tender-offer style update
5. periodic report

### 3) What is the stable external identity?

The first implementation slice needs one stable immutable identifier for:

- raw document external id
- raw event key seed
- canonical duplicate group seed
- source cursor candidate

Candidate patterns to evaluate:

- announcement id
- document id
- disclosure id
- exchange artefact id
- detail URL token
- company/security code + publication date/time + sequence

Do not rely on title text alone.

### 4) What should the cursor be?

Candidate cursor shapes:

- latest publication datetime + announcement id
- latest filing datetime + document id
- latest exchange artefact id
- latest detail URL token
- latest sequence id

The cursor must be deterministic and should not require title-text heuristics.

### 5) What is the minimum raw-document set?

The first isolated slice should use the smallest deterministic set, for example:

- one discovery row
- one detail page
- one PDF/attachment only if the detail page is not enough

## Source inspection checklist

For every candidate source, fill:

- sample issuer/company
- sample security code
- sample title
- publication datetime local
- publication datetime UTC conversion rule
- detail URL
- attachment URL, if required
- visible stable id fields
- cursor field candidates
- category/family filter behavior
- pagination behavior
- whether anti-bot or session behavior blocks deterministic capture

## Implementation gate

Do not add runtime code until the following are written down in one place:

- chosen official source
- chosen source key
- chosen adapter key
- chosen parser strategy
- chosen discovery mode
- chosen hydrate mode
- chosen cursor key
- chosen document identity rule
- chosen first event family
- chosen first canonical event type
