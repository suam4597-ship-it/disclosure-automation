# JP TDnet contract-freeze preflight

This document narrows the JP discovery-first kickoff toward a first contract-freeze candidate.

It does not freeze a JP runtime contract yet.
Do not add runtime code, fixtures, tests, sample YAML, ops runner, or dedupe SQL from this document alone.

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

## Recommended first source candidate

Recommended next contract-freeze candidate:

- source: `TDnet / JPX timely disclosure surfaces`
- source key candidate: `jp_tdnet_timely_disclosure`
- first family candidate: `material_information_update`
- canonical event type candidate: `material_information_or_earnings_guidance`
- source tier candidate: `official_exchange_storage`

## Why TDnet / JPX is the preferred first JP candidate

Initial public-source findings indicate:

- TDnet is the Timely Disclosure Network used for listed-company timely disclosure.
- JPX/TSE describe listed companies as using TDnet for timely disclosure of corporate information.
- JPX Company Announcements Disclosure Service provides public inspection of information disclosed via TDnet.
- Public announcement index fields can include disclosure date/time, listed exchange, company code, company name, and disclosure title.
- JPX Listed Company Search can be used for a longer historical browsing surface when the latest-announcement public service retention window is too short.

This makes TDnet/JPX a stronger first JP lane than EDINET for as-it-happens listed-company material updates.

## Candidate source surfaces

### Primary public discovery surface candidate

```text
JPX Company Announcements Disclosure Service / TDnet public announcement inspection pages
```

Use this as the preferred public latest-announcements surface if a deterministic sample can be captured.

### Historical public discovery surface candidate

```text
JPX Listed Company Search / timely disclosure history
```

Use this if the latest-announcements surface retention window blocks deterministic sample capture.

### Backup official-regulatory source

```text
EDINET API
```

Use only if TDnet/JPX public surfaces cannot provide stable identity/cursor fields for a first high-signal fixture.

## Candidate family direction

Preferred:

```text
event_family: material_information_update
canonical_event_type: material_information_or_earnings_guidance
```

Backup if a cleaner sample is available:

```text
event_family: merger_or_asset_transaction_update
canonical_event_type: major_investment_or_asset_sale
```

Alternative if a tender-offer sample is cleaner:

```text
event_family: takeover_or_scheme_update
canonical_event_type: tender_offer_or_go_private
```

## Identity and cursor candidates

Preferred stable identity candidates:

1. TDnet disclosure number
2. TDnet disclosure history number
3. JPX document id or artefact id
4. stable PDF URL token
5. company/security code + disclosure datetime + sequence

Preferred cursor candidates:

1. latest disclosure datetime + disclosure number
2. latest disclosure datetime + disclosure history number
3. latest disclosure datetime + document id
4. disclosure date + stable PDF URL token, only if time is unavailable

Title text alone is not acceptable for identity or cursor.

## Contract-freeze blockers

The candidate cannot be frozen until source inspection captures one sample with:

- visible company/security code
- visible company name
- visible title
- visible local disclosure datetime
- stable detail URL or attachment URL
- stable identity field or URL token
- deterministic cursor candidate
- minimum raw-document set decision

## Explicit non-goals

This preflight does not add:

- JP runtime adapter
- JP source helper
- JP sample YAML
- JP fixtures
- JP tests
- JP ops runner
- JP dedupe SQL
- broad JP all-disclosures ingestion
- EDINET runtime
- news overlay
- cross-source merge

## Next PR after this preflight

The next PR should be either:

1. `JP TDnet contract-freeze close-out`, if public-source inspection has captured one deterministic sample and identity/cursor fields; or
2. another docs-only investigation PR that records verified TDnet/JPX source findings without freezing runtime semantics yet.
