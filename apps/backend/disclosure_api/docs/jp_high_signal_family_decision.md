# JP high-signal family decision

This document records the provisional first-family direction for the Japan regional vertical.

## Goal

The JP first slice should help users follow important official listed-company disclosures as they happen.
It should not start with broad all-disclosures ingestion.

## Decision status

No first JP family is frozen yet.
This document defines the discovery order and the promotion/disqualification rules for the later contract-freeze decision.

## Candidate families

### 1) Timely disclosure / material information update

Pros:

- closest match to the JPX/TDnet timely-disclosure surface
- likely best fit for important as-it-happens listed-company updates
- can include company code, disclosure date/time, title, and document metadata in source index fields

Cons:

- may be broad unless a source category or title/type field can isolate one family
- public surfaces may have JavaScript, retention, or access limitations

Current rank:

- `1`

### 2) M&A / restructuring / major asset transaction style disclosure

Pros:

- high-signal and narrower than generic timely-disclosure ingestion
- maps naturally to existing SEC/UK takeover/scheme and CN/TW major transaction semantics

Cons:

- category isolation must be confirmed on public TDnet/JPX surfaces
- may require PDF parsing if the index row is only title/metadata

Current rank:

- `2`

### 3) Shareholding / ownership change

Pros:

- high-signal for control and ownership monitoring
- maps naturally to AFM substantial holdings and CNInfo ownership-change work

Cons:

- may be better served by statutory large-shareholding report surfaces or EDINET rather than TDnet
- stable identity/cursor still must be confirmed directly

Current rank:

- `3`

### 4) Tender-offer / takeover style update

Pros:

- high-signal and close to prior SEC/UK tender-offer/scheme semantics
- likely low volume if source category or title pattern is clear

Cons:

- may be too sparse for deterministic sample capture during initial discovery
- may require a separate source surface or filing type

Current rank:

- `4`

### 5) Periodic report

Pros:

- likely easy to identify in EDINET
- stable document identifiers may be available

Cons:

- weaker fit for as-it-happens major disclosure monitoring
- lower signal density than timely/material announcements

Current rank:

- `5`

## Provisional direction

Start discovery with `timely disclosure / material information update` as the preferred first family, using TDnet/JPX public surfaces as the first source candidate.

Promote `M&A / restructuring / major asset transaction style disclosure` if it provides a narrower deterministic fixture and stable cursor.

Promote `shareholding / ownership change` or `tender-offer / takeover style update` if either provides a cleaner official source, stable identity, and cursor.

Use `periodic report` only if the higher-signal families cannot satisfy contract-freeze criteria.

## Disqualification rules

A family should not become the first JP implementation slice if:

- the public search cannot isolate it without broad ambiguity
- no stable public id, disclosure number, URL token, document id, or artefact id is visible
- cursor semantics require title-text heuristics
- the first sample requires ingesting multiple unrelated announcement families
- the raw-document set cannot be reduced to one deterministic item

## Implementation rule

Do not open runtime code for multiple JP families at once.
Freeze one source and one family, lock it, then expand.
