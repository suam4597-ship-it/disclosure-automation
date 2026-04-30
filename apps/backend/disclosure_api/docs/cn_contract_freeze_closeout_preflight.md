# CN contract-freeze close-out preflight

This document is the bridge from the CN discovery-first kickoff PR to the later CN contract-freeze close-out PR.

It does not freeze a CN source, family, sample, cursor, or identity rule.
Those require live public-source inspection before the contract can be closed.

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

CN status:

- discovery-first kickoff docs: complete
- contract-freeze close-out: not complete
- runtime implementation: not started

## Why this preflight exists

The first CN discovery PR created the docs-only scaffold.
The next meaningful step is public-source inspection, but contract fields must not be filled by assumption.

This preflight keeps the next work bounded:

1. inspect candidate official source surfaces
2. choose one source and one family
3. capture one deterministic public sample
4. freeze stable identity and cursor semantics
5. prepare an isolated runtime workset plan

## Web/source inspection required

The following must be verified against public official source pages before contract-freeze:

- SSE disclosure surface URL shape and category metadata
- SZSE disclosure surface URL shape and category metadata
- BSE disclosure surface URL shape and category metadata
- CNInfo / 巨潮资讯网 official/archival role and announcement id behavior
- CSRC public disclosure surface suitability for issuer-level listed-company disclosure monitoring

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
- anti-bot/session/pagination constraints

## Freeze candidates still open

### Source

No source is frozen.

Candidates remain:

- SSE disclosure pages
- SZSE disclosure pages
- BSE disclosure pages
- CNInfo / 巨潮资讯网
- CSRC public disclosure surfaces

### First family

No family is frozen.

Current provisional ranking remains:

1. M&A / restructuring / major asset transaction style disclosure
2. material information / major announcement
3. shareholding / ownership change
4. takeover / tender-offer style update
5. periodic report

### Stable external identity

No identity rule is frozen.

Acceptable candidates remain:

- explicit announcement id
- document id
- disclosure id
- exchange artefact id
- stable detail URL token
- company/security code + publication date/time + sequence number

Title text alone is not acceptable.

### Cursor

No cursor rule is frozen.

Acceptable candidates remain:

- latest publication datetime + stable id
- latest filing datetime + stable id
- source sequence id
- stable detail URL token

Title text alone is not acceptable.

## Close-out PR exit checklist

A future close-out PR may mark CN contract-freeze complete only when the docs name all of the following:

- chosen source key
- chosen display name
- region code = `cn`
- source class = `regulatory_filing_feed`
- source tier = `official_regulatory_storage` or `official_exchange_storage`
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

- CN runtime adapter
- CN source helper
- CN sample YAML
- CN fixtures
- CN tests
- CN ops runner
- CN dedupe SQL
- JP work
- news overlay
- cross-source merge
- broad CN all-disclosures ingestion
- CN multiple-family expansion

## Next PR after this preflight

The next PR should be either:

1. `CN official disclosure contract-freeze close-out`, if public-source inspection has been completed and the template can be filled with evidence; or
2. another docs-only investigation PR that records verified source findings without freezing runtime semantics yet.
