# CN discovery-first kickoff

Current locked baseline:

- SEC 6-K
- SEC 8-K
- SEC SC TO-T
- SEC SC 14D-9
- SEC SC 13D/A
- AFM substantial holdings
- UK FCA NSM takeover/scheme
- TW MOPS material information

This file starts the next Stage 4 regional target:

- `CN official disclosure discovery-first kickoff`

## Why docs-first

CN should not start by guessing adapter, parser, cursor, or source identity semantics.
The first step is to inspect official disclosure surfaces, choose one high-signal family candidate, and prepare a contract-freeze decision.

This PR is intentionally discovery-only. It should create enough structure for the next CN contract-freeze decision without adding runtime code or fixtures.

## Current CN status

- CN source contract: not frozen
- CN first family: not frozen
- CN sample: not captured
- CN runtime implementation: not started

## Candidate official source surfaces

Inspect these as candidates only:

- Shanghai Stock Exchange / SSE disclosure pages
- Shenzhen Stock Exchange / SZSE disclosure pages
- Beijing Stock Exchange / BSE disclosure pages
- CNInfo / 巨潮资讯网
- CSRC public disclosure / regulatory filing surfaces

Do not treat this list as a frozen source contract.

## Preferred discovery direction

Start by looking for a narrow, high-signal official disclosure lane where one deterministic public sample can be isolated.
The initial preferred family to test is:

1. M&A / restructuring / major asset transaction style disclosure
2. material information / major announcement
3. shareholding / ownership change
4. takeover / tender-offer style update
5. periodic report

The first family may only be frozen after source-surface inspection confirms stable public identity and cursor semantics.

## Guardrail

Do not jump to:

- JP
- news overlay
- cross-source merge
- broad CN all-disclosures ingestion
- CN runtime implementation
- CN multiple-family implementation

until the CN discovery-freeze criteria are satisfied for one source and one family.

## Expected Stage 4 flow from here

1. inspect candidate official CN disclosure source surfaces
2. choose one high-signal first family candidate
3. capture one deterministic public sample
4. freeze stable external identity and cursor candidates
5. freeze the minimum raw-document set
6. open a later isolated runtime implementation PR
7. verify and lock the first CN slice
