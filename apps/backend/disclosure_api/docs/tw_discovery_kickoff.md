# TW discovery-first kickoff

Current locked baseline:

- SEC 6-K
- SEC 8-K
- SEC SC TO-T
- SEC SC 14D-9
- SEC SC 13D/A
- AFM substantial holdings
- UK FCA NSM takeover/scheme

This file starts the next Stage 4 regional target:

- `TW discovery-first kickoff`

## Why docs-first

TW should not start by guessing adapter, parser, cursor, or source identity semantics.
The first step is to freeze the official source model and one high-signal disclosure family.

## Product direction

The first TW lock should prioritize important listed-company disclosures as they happen, not periodic reports.

Current provisional first-family priority:

1. material information / major announcement
2. M&A / merger / acquisition / tender-offer style update
3. shareholding / director / insider related update
4. periodic report

## Guardrail

Do not jump to:

- CN
- JP
- news overlay
- cross-source merge
- broad TW all-announcements ingestion

until the first TW source contract is frozen and locked.

## Expected Stage 4 flow from here

1. identify official TW disclosure source surface
2. freeze first high-signal family
3. capture one deterministic public sample
4. freeze stable external identity and cursor
5. open an isolated runtime implementation PR
6. verify and lock the first TW slice
