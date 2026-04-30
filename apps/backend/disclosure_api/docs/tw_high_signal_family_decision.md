# TW high-signal family decision

This document records the first-family direction for the Taiwan regional vertical.

## Goal

The TW first slice should help users follow important listed-company disclosures as they happen.
It should not start with periodic reports unless high-signal discovery is not feasible.

## Candidate families

### 1) Material information / major announcement

Pros:

- closest match to the product goal
- should capture important disclosures as they happen
- likely a strong first Taiwan user-facing lane

Cons:

- may be a broad category if the official source does not expose subtypes cleanly
- stable identity and cursor must be confirmed directly

Current rank:

- `1`

### 2) M&A / merger / acquisition / tender-offer style update

Pros:

- high-signal and generally lower volume
- maps naturally to prior SEC/UK tender-offer and scheme logic

Cons:

- may be harder to isolate if the public source does not expose a clean category

Current rank:

- `2`

### 3) Shareholding / director / insider related update

Pros:

- high-signal and relevant to ownership/control monitoring
- maps naturally to AFM and SEC ownership-related families

Cons:

- may require separate disclosure surfaces or categories

Current rank:

- `3`

### 4) Periodic report

Pros:

- likely easy to identify
- official source examples may be easier to locate

Cons:

- weaker fit for the goal of as-it-happens major disclosures
- potentially higher volume and lower signal density

Current rank:

- `4`

## Decision

Start discovery with `material information / major announcement` as the preferred first family.

Promote `M&A / merger / acquisition / tender-offer style update` if material-information discovery is too broad or lacks stable public identity/cursor fields.

## Implementation rule

Do not open runtime code for multiple TW families at once.
Freeze one family, lock it, then expand.
