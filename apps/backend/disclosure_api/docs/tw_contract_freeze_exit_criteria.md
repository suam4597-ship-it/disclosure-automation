# TW contract-freeze exit criteria

This document defines when the TW discovery-first stage may move to isolated runtime implementation.

## Exit condition

The TW work may leave discovery-freeze only when one family satisfies all of the following:

1. the official public discovery surface is identified
2. one first high-signal family is chosen
3. one deterministic public sample is captured
4. one stable external identity is visible in discovery or detail
5. one cursor key can be frozen without relying on title text only
6. one canonical event mapping is chosen
7. the minimum raw-document set is small enough for an isolated first lock

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

## Disqualifiers for preferred family

The preferred family (`material information / major announcement`) should be disqualified as the first implementation slice if any of the following holds:

- public search cannot isolate it without broad ambiguity
- no stable public id or URL token is visible
- cursor semantics require title-text heuristics
- the family is too broad for one deterministic fixture item

## Promotion rule for backup family

Promote `M&A / merger / acquisition / tender-offer style update` if it meets all exit criteria and the preferred material-information family does not.

## Implementation rule

Cross the phase boundary for one family only.
Do not open runtime code for two TW first-slice families in the same PR.
