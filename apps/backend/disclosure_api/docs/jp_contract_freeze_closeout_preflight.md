# JP contract-freeze close-out preflight

This document bridges the JP discovery-first kickoff PR to a later JP contract-freeze close-out PR.

It does not freeze a JP source, family, sample, cursor, or identity rule.
Those require public-source inspection before the contract can be closed.

## Current baseline

Locked and not to be reopened:

- SEC 6-K
- SEC 8-K
- SEC SC TO-T
- SEC SC 14D-9
- SEC SC 13D/A
- AFM substantial holdings
- UK FCA NSM takeover/scheme
- TW MOPS material information
- CNInfo ownership-change

JP status:

- discovery-first kickoff docs: complete
- contract-freeze close-out: not complete
- runtime implementation: not started

## Why this preflight exists

The first JP discovery PR created the docs-only scaffold.
The next meaningful step is public-source inspection, but contract fields must not be filled by assumption.

This preflight keeps the next work bounded:

1. inspect candidate official source surfaces
2. choose one source and one family
3. capture one deterministic public sample
4. freeze stable identity and cursor semantics
5. prepare an isolated runtime workset plan

## Web/source inspection required

The following must be verified against public official source pages before contract-freeze:

- TDnet / JPX timely-disclosure public announcement surface
- JPX Company Announcements Disclosure Service latest-disclosure surface
- JPX Listed Company Search historical TDnet browsing surface
- EDINET API suitability for periodic/statutory backup family
- whether public JPX/TDnet surfaces expose stable disclosure number, history number, document id, or PDF URL token

For each inspected surface, record:

- source owner/operator
- whether it is exchange-operated or regulator-operated
- source tier candidate
- discovery endpoint or page
- detail endpoint or page
- attachment/PDF behavior
- stable id field or URL token
- timestamp field
- cursor candidate
- family/category filters
- JavaScript, paid API, retention-window, session, and pagination constraints

## Freeze candidates still open

### Source

No source is frozen.

Candidates remain:

- TDnet / Timely Disclosure Network
- JPX Company Announcements Disclosure Service
- JPX Listed Company Search
- EDINET
- TSE listed-company disclosure pages

### First family

No family is frozen.

Current provisional ranking remains:

1. timely disclosure / material information update
2. M&A / restructuring / major asset transaction style disclosure
3. shareholding / ownership change
4. tender-offer / takeover style update
5. periodic report

### Stable external identity

No identity rule is frozen.

Acceptable candidates remain:

- disclosure number
- disclosure history number
- document id
- TDnet/JPX artefact id
- stable PDF URL token
- security code + disclosure date/time + sequence number

Title text alone is not acceptable.

### Cursor

No cursor rule is frozen.

Acceptable candidates remain:

- disclosure datetime + disclosure number
- disclosure datetime + document id
- disclosure number + disclosure history number
- stable PDF URL token plus disclosure date

Title text alone is not acceptable.

## Close-out PR exit checklist

A future close-out PR may mark JP contract-freeze complete only when the docs name all of the following:

- chosen source key
- chosen display name
- region code = `jp`
- source class = `regulatory_filing_feed`
- source tier = `official_exchange_storage` or `official_regulatory_storage`
- chosen adapter key
- parser strategy
- discovery mode
- hydrate mode
- cursor key
- cursor value shape
- stable external identity rule
- stable external identity sample value
- raw document external id rule
- document identity rule
- raw event key seed
- duplicate group seed
- first event family
- first canonical event type
- sample company / issuer
- sample security code
- sample title
- sample publication datetime local
- sample publication datetime UTC
- sample detail URL
- sample attachment URL, if required
- minimum raw-document set
- source-appropriate canonical item source names

## Explicit non-goals

This preflight does not add:

- JP runtime adapter
- JP source helper
- JP sample YAML
- JP fixtures
- JP tests
- JP ops runner
- JP dedupe SQL
- news overlay
- cross-source merge
- broad JP all-disclosures ingestion
- JP multiple-family expansion

## Next PR after this preflight

The next PR should be either:

1. `JP official disclosure contract-freeze close-out`, if public-source inspection has been completed and the template can be filled with evidence; or
2. another docs-only investigation PR that records verified source findings without freezing runtime semantics yet.
