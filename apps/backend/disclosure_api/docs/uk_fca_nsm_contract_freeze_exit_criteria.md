# UK FCA NSM contract-freeze exit criteria

This document defines the exact condition for leaving the UK discovery-freeze stage.

## Exit condition

The UK work may leave discovery-freeze and enter isolated implementation only when one family satisfies all of the following at the same time:

1. public discovery surface can isolate the family deterministically enough for a first slice
2. one stable immutable external identity is visible in public discovery or detail
3. one cursor field can be frozen without relying on title text heuristics
4. one first event family can be named without mixing adjacent families
5. one first canonical event type can be assigned cleanly
6. the minimum raw-document set per item is small enough for an isolated first lock

## Minimum contract fields to freeze

- source key
- display name
- adapter key
- parser strategy
- discovery mode
- hydrate mode
- cursor key
- raw document external id rule
- document identity rule
- raw event key seed
- duplicate group seed
- first event family
- first canonical event type

## Disqualifiers for the current preferred family

The current preferred family (`takeover / scheme related update`) should be disqualified as the first implementation slice if any of the following holds:

- the public search surface cannot isolate it without broad keyword ambiguity
- the public detail path does not expose a stable immutable identity consistently
- the required hydrate path is too wide for the first isolated lock
- the family boundary overlaps too heavily with adjacent corporate-action disclosure types

## Promotion rule for the backup family

The backup family (`major holdings / director dealings`) should be promoted when it meets all exit criteria and the current preferred family does not.

## Implementation rule

Cross the phase boundary for one family only.
Do not open runtime code for two UK first-slice families in the same PR.
