# CN high-signal family decision

This document records the provisional first-family direction for the China regional vertical.

## Goal

The CN first slice should help users follow important official listed-company disclosures as they happen.
It should not start with broad all-announcements ingestion.

## Decision status

No first CN family is frozen yet.
This document defines the discovery order and the promotion/disqualification rules for the later contract-freeze decision.

## Candidate families

### 1) M&A / restructuring / major asset transaction style disclosure

Pros:

- high-signal and generally narrower than a broad announcement feed
- maps naturally to existing canonical families around major investment, asset sale, merger, acquisition, or restructuring
- likely easier to lock with one deterministic sample if the source exposes category filters or stable document metadata

Cons:

- may appear under different source-specific category names across SSE, SZSE, BSE, CNInfo, or regulator surfaces
- may require attachment/PDF capture if the detail page is only a summary shell

Current rank:

- `1`

### 2) Material information / major announcement

Pros:

- close fit to the product goal of important as-it-happens company disclosures
- likely useful as a user-facing CN disclosure lane

Cons:

- may be broad and high-volume
- may include many subtypes that require source-specific classification before runtime lock

Current rank:

- `2`

### 3) Shareholding / ownership change

Pros:

- high-signal for control and ownership monitoring
- maps naturally to AFM substantial holdings and SEC ownership-related work

Cons:

- may require a different official source surface or separate category taxonomy
- stable identity/cursor still must be confirmed directly

Current rank:

- `3`

### 4) Takeover / tender-offer style update

Pros:

- high-signal and close to prior SEC/UK tender-offer/scheme semantics
- likely low volume if the source exposes this family cleanly

Cons:

- may be too sparse for deterministic sample capture during initial discovery
- may not be a first-class category on all candidate CN surfaces

Current rank:

- `4`

### 5) Periodic report

Pros:

- likely easy to identify and sample
- may have stable document identifiers and predictable publication dates

Cons:

- weaker fit for as-it-happens major disclosure monitoring
- likely broad and less urgent than transaction/control-change disclosures

Current rank:

- `5`

## Provisional direction

Start discovery with `M&A / restructuring / major asset transaction style disclosure` as the preferred first family.

Promote `material information / major announcement` if it is the only family with deterministic public identity/cursor fields and a small first raw-document set.

Promote `shareholding / ownership change` or `takeover / tender-offer style update` if either provides a cleaner official-source fixture and stable cursor than the first two options.

Use `periodic report` only if the higher-signal families cannot satisfy contract-freeze criteria.

## Disqualification rules

A family should not become the first CN implementation slice if:

- the public search cannot isolate it without broad ambiguity
- no stable public id, URL token, or document id is visible
- cursor semantics require title text or fuzzy matching
- the first sample requires ingesting multiple unrelated announcement families
- the raw-document set cannot be reduced to one deterministic item

## Implementation rule

Do not open runtime code for multiple CN families at once.
Freeze one source and one family, lock it, then expand.
