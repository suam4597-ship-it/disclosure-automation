# JP discovery-first kickoff

Current locked baseline:

- SEC 6-K
- SEC 8-K
- SEC SC TO-T
- SEC SC 14D-9
- SEC SC 13D/A
- AFM substantial holdings
- UK FCA NSM takeover/scheme
- TW MOPS material information
- CNInfo ownership-change

This file starts the next Stage 4 regional target:

- `JP official disclosure discovery-first kickoff`

## Why docs-first

JP should not start by guessing adapter, parser, cursor, or source identity semantics.
The first step is to inspect official disclosure surfaces, choose one high-signal family candidate, and prepare a contract-freeze decision.

This PR is intentionally discovery-only. It should create enough structure for the next JP contract-freeze decision without adding runtime code or fixtures.

## Current JP status

- JP source contract: not frozen
- JP first family: not frozen
- JP sample: not captured
- JP runtime implementation: not started

## Candidate official source surfaces

Inspect these as candidates only:

- TDnet / Timely Disclosure Network operated by Tokyo Stock Exchange / JPX
- EDINET public disclosure surfaces operated by the Financial Services Agency
- JPX Listed Company Search / disclosure pages
- TSE listed company announcement surfaces
- J-REIT / investment corporation disclosure surfaces, only if needed later

Do not treat this list as a frozen source contract.

## Preferred discovery direction

Start by looking for a narrow, high-signal official disclosure lane where one deterministic public sample can be isolated.
The initial preferred family to test is:

1. timely disclosure / material information update
2. M&A / restructuring / major asset transaction style disclosure
3. shareholding / ownership change
4. tender-offer / takeover style update
5. periodic report

The first family may only be frozen after source-surface inspection confirms stable public identity and cursor semantics.

## Guardrail

Do not jump to:

- news overlay
- cross-source merge
- broad JP all-disclosures ingestion
- JP runtime implementation
- JP multiple-family implementation
- broad CN expansion

until the JP discovery-freeze criteria are satisfied for one source and one family.

## Expected Stage 4 flow from here

1. inspect candidate official JP disclosure source surfaces
2. choose one high-signal first family candidate
3. capture one deterministic public sample
4. freeze stable external identity and cursor candidates
5. freeze the minimum raw-document set
6. open a later isolated runtime implementation PR
7. verify and lock the first JP slice
