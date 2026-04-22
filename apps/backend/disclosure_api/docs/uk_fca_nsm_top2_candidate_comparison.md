# UK FCA NSM top-2 candidate comparison

This document compares the two highest-priority UK first-slice candidates.
It exists to make the next contract-freeze decision explicit instead of ad hoc.

## Candidates

1. `takeover / scheme related update`
2. `major holdings / director dealings`

## Decision criteria

### A) User value fit

Question:

- does the family match the goal of following important listed-company disclosures as they happen?

Assessment:

- takeover / scheme related update: `very strong`
- major holdings / director dealings: `strong`

## B) Expected volume control

Question:

- can the first slice stay narrow enough to avoid unnecessary document volume?

Assessment:

- takeover / scheme related update: `strong` expected volume control
- major holdings / director dealings: `medium` expected volume control

Why:

- takeover / scheme items are likely narrower as a first event stream
- holdings and director-related items may require more careful family boundary control

## C) Isolatability in public NSM discovery

Question:

- can the public search surface isolate the family deterministically enough for a first implementation slice?

Current state:

- takeover / scheme related update: `unknown, must verify directly`
- major holdings / director dealings: `unknown, must verify directly`

This is currently the most important unresolved criterion.

## D) Stable identity confidence

Question:

- is there one stable public id that can support raw document identity, raw event keying, and cursor semantics?

Current state:

- takeover / scheme related update: `unknown, must verify directly`
- major holdings / director dealings: `unknown, must verify directly`

## E) Canonical mapping reuse

Question:

- does the family map naturally to canonical event logic already used in the repo?

Assessment:

- takeover / scheme related update: `medium`
- major holdings / director dealings: `strong`

Why:

- ownership / control-watch semantics are already familiar from AFM and SEC ownership-related work

## Current recommendation

Keep `takeover / scheme related update` as the preferred first candidate **unless** one of the following becomes true during source inspection:

- the public NSM search surface cannot isolate takeover / scheme items cleanly enough
- stable immutable identity is not consistently present for takeover / scheme items
- takeover / scheme items require a wider multi-document hydrate path than is reasonable for the first UK lock

If any of the above is true, promote `major holdings / director dealings` to the first implementation slice.

## Fallback trigger

Promote the backup candidate when all three are true:

- holdings / director-dealing items are easier to isolate in public discovery
- holdings / director-dealing items expose a more stable public id field
- the minimum raw-document set per item is simpler or more deterministic

## Implementation rule

Do not open runtime code for both families at once.
Freeze one family first, lock it, then expand.
