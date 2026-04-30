# JP source decision after TDnet no-go

This document records the JP source decision gate after the first automated TDnet public sample capture attempt failed to produce a freeze-ready official row.

This is docs-only. It does not add runtime code, sample YAML, fixtures, tests, ops runner, or dedupe SQL.

## Current status

- PR #40: JP TDnet contract-freeze preflight merged
- PR #41: JP TDnet public sample capture no-go runbook merged
- current base commit: `fdc91131d0ccbd4180f9969290430816d3e51caa`
- TDnet contract-freeze status: `not frozen`
- runtime status: `not started`

## Locked baseline

Keep these locked:

- SEC 6-K
- SEC 8-K
- SEC SC TO-T
- SEC SC 14D-9
- SEC SC 13D/A
- AFM substantial holdings
- UK FCA NSM takeover/scheme
- TW MOPS material information
- CNInfo ownership-change

## Decision summary

Do not start JP runtime yet.

TDnet / JPX remains the preferred first source, but it has not passed the freeze gate because no official row-level sample was captured in the automated environment.

The next decision is a two-step gate:

```text
Gate 1: Try one manual TDnet or JPX Listed Company Search sample capture.
Gate 2: If Gate 1 fails, pivot to EDINET as a separate official-regulatory fallback contract.
```

## Why not freeze TDnet yet

TDnet cannot be frozen from the current evidence because the attempt did not capture all required row-level values:

```text
sample issuer
sample security code
sample official title
sample publication datetime local
sample publication datetime UTC
sample category/material type if visible
sample detail URL if any
sample PDF/document URL
sample stable id/token
sample document MIME type
```

Secondary-observed PDF tokens are useful hints but not enough for freeze. A frozen runtime contract must be based on an official row or official historical row, not only a PDF-token candidate discovered indirectly.

## Gate 1: TDnet / JPX retry

Try exactly one more TDnet-family sample capture path before promoting EDINET:

1. current Company Announcements Disclosure Service row, if accessible manually
2. JPX Listed Company Search historical timely-disclosure row, if it exposes a stable row and document link

Gate 1 passes only if one sample supports:

```text
stable_external_id
cursor_key
cursor_value
event_id
event_family
canonical_event_type
minimum raw-document set
```

Gate 1 fails if identity or cursor still requires title-only or fuzzy matching.

## Gate 2: EDINET fallback

If Gate 1 fails, evaluate EDINET as a different first JP source/family.

EDINET should not be treated as TDnet replacement within the same contract. It is a separate official-regulatory source with a different first-family fit.

Candidate fallback direction:

```text
source candidate: EDINET
source_key candidate: jp_edinet_statutory_report
adapter_key candidate: jp_edinet_statutory_report_v1
source_tier candidate: official_regulatory_storage
first family candidate: periodic_report_update / statutory_report_update
```

## Why EDINET is backup, not preferred first

EDINET is official and API-friendly, but it is a weaker fit for the original JP first-family goal.

TDnet is better for:

- timely disclosure
- material information update
- public listed-company announcements
- as-it-happens exchange disclosure

EDINET is better for:

- securities reports
- statutory disclosure documents
- periodic reports
- document API workflows

## Branching rule

Do not mix TDnet and EDINET runtime work in the same PR.

If TDnet passes Gate 1, create a true TDnet contract-freeze close-out.

If TDnet fails Gate 1 and EDINET is promoted, create a new EDINET contract-freeze preflight and eventually a separate EDINET contract-freeze close-out.

## Runtime still blocked

Runtime cannot start until one source/family/sample has all of:

```text
source_key
adapter_key
sample issuer/security code
stable_external_id
cursor_key
cursor_value
event_id
event_family
canonical_event_type
raw-document external ids
minimum raw-document set
local/UTC timestamp rule
```

## Current recommendation

Proceed with one final TDnet/JPX manual or Listed Company Search sample attempt.

If it fails, pivot to EDINET fallback preflight rather than trying broad JP all-disclosures ingestion.
