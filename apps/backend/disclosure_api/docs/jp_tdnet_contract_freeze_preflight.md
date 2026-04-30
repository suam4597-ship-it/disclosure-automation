# JP TDnet contract-freeze preflight

This document is the bridge from the JP discovery-first kickoff PR to a later JP contract-freeze close-out PR.

It does not freeze a JP runtime contract yet.
Do not add JP runtime code, fixtures, tests, ops runner, sample YAML, or dedupe SQL from this document alone.

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

## Preferred source candidate

Recommended next contract-freeze candidate:

- source: `TDnet / JPX Company Announcements Disclosure Service`
- source key candidate: `jp_tdnet_timely_disclosure`
- first family candidate: `timely_disclosure_update`
- source tier candidate: `official_exchange_storage`

## Why TDnet / JPX is the preferred candidate

JPX describes TDnet as the Timely Disclosure Network used to enable fair, prompt, and wide-ranging timely disclosure.
JPX also says listed companies are obliged by Securities Listing Regulations to use TDnet when enacting timely disclosure of corporate information.

JPX describes the Company Announcements Disclosure Service as a Tokyo Stock Exchange web service for public inspection of corporate information disclosed through TDnet. JPX states that the public service displays timely disclosure information, disclosure date/time, listed exchange, company code, company name, and disclosure title.

The paid TDnet API documentation also confirms that TDnet index information has fields that are useful for stable identity and cursor design, including security code, date/time of disclosure, disclosure number, disclosure history number, title, public item code, and file existence flags.

## Backup source candidate

EDINET remains a backup official-regulatory source candidate for statutory/periodic filings.

- source: `EDINET`
- source tier candidate: `official_regulatory_storage`
- likely first-family fit: `periodic report / statutory securities report`
- reason not first: weaker fit for as-it-happens timely disclosure monitoring

## Freeze candidates still open

### Source

Preferred source is TDnet / JPX, but not frozen.

Open question:

- whether the public JPX Company Announcements Disclosure Service or Listed Company Search can expose enough stable identity/cursor fields without paid API access

### First family

Preferred family is timely disclosure / material information update, but not frozen.

Open question:

- whether one high-signal subtype can be isolated without broad all-disclosures ingestion

### Stable external identity

No identity rule is frozen.

Preferred candidate fields:

- disclosure number
- disclosure history number
- document id or TDnet/JPX artefact id
- stable PDF URL token
- security code + disclosure datetime + sequence number

Title text alone is not acceptable.

### Cursor

No cursor rule is frozen.

Preferred candidate fields:

- disclosure datetime + disclosure number
- disclosure datetime + document id
- disclosure number + disclosure history number
- stable PDF URL token + disclosure date

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
- broad CN expansion

## Next PR after this preflight

The next PR should be either:

1. `JP TDnet contract-freeze close-out`, if public-source inspection has completed and the template can be filled with evidence; or
2. another docs-only investigation PR that records verified TDnet/JPX sample findings without freezing runtime semantics yet.
