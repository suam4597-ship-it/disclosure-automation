# JP contract-freeze exit criteria

This document defines when the JP discovery-first stage may move to isolated runtime implementation.

## Exit condition

The JP work may leave discovery-freeze only when one source and one family satisfy all of the following:

1. the official public discovery surface is identified
2. the source tier is classified as `official_exchange_storage` or `official_regulatory_storage`
3. one first high-signal family is chosen
4. one deterministic public sample is captured
5. one stable external identity is visible in discovery, detail, or attachment metadata
6. one cursor key can be frozen without relying on title text only
7. one canonical event mapping is chosen
8. the minimum raw-document set is small enough for an isolated first lock
9. local/UTC publication timestamp rules are explicit
10. the future runtime workset remains one source, one family, one fixture item

## Minimum contract fields to freeze

- source key
- display name
- region code = `jp`
- source class = `regulatory_filing_feed`
- source tier
- adapter key
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
- minimum raw-document set
- source-appropriate canonical item source names

## Required sample fields

- sample company / issuer
- sample security code
- sample title
- sample source category
- sample publication datetime local
- sample publication datetime UTC
- sample detail URL
- sample attachment URL, if required

## Disqualifiers for preferred family

The preferred family (`timely disclosure / material information update`) should be disqualified as the first implementation slice if any of the following holds:

- public search cannot isolate it without broad ambiguity
- no stable public id, disclosure number, document id, URL token, or artefact id is visible
- cursor semantics require title-text heuristics
- the family is too broad for one deterministic fixture item
- the raw-document set requires many unrelated pages or attachments
- the source cannot be classified as official-exchange or official-regulatory storage

## Promotion rule for backup family

Promote `M&A / restructuring / major asset transaction style disclosure` if it meets all exit criteria and the preferred timely-disclosure family does not.

Promote `shareholding / ownership change` or `tender-offer / takeover style update` if either gives a cleaner official source, stable identity, and cursor.

Use `periodic report` only if the higher-signal families fail the freeze criteria.

## Implementation boundary

Cross the phase boundary for one family only.
Do not open runtime code for two JP first-slice families in the same PR.

## Runtime PR cannot start until

The next runtime PR must not start until this discovery-freeze package names:

- the chosen source
- the chosen first family
- the chosen deterministic sample
- the exact identity and cursor semantics
- the exact minimum raw-document set
- the exact verification expectations
