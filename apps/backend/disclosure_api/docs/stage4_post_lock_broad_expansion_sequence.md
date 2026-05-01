# Stage 4 post-lock broad expansion sequence

This document defines how to proceed after AFM, UK, TW, CNInfo, and JP TDnet are locked.

The goal is to prepare broader regional expansion without breaking the locked isolated verticals.

## Current locked baseline

Keep these locked:

```text
SEC 6-K
SEC 8-K
SEC SC TO-T
SEC SC 14D-9
SEC SC 13D/A
AFM substantial holdings
UK FCA NSM takeover/scheme
TW MOPS material information
CNInfo ownership-change
JP TDnet timely disclosure
```

## Requested expansion axes

```text
1. broad JP all-disclosures ingestion
2. broad CN expansion
3. EDINET runtime
```

## Sequencing rule

Do not implement all three axes in one PR.

Use this sequence:

```text
A. EDINET contract-freeze/sample first, because it is a separate official API lane.
B. EDINET isolated runtime, one document family and one fixture item only.
C. JP TDnet broad-readiness package, preserving the locked TDnet sample.
D. CN broad expansion discovery/readiness package, preserving CNInfo ownership-change.
E. Only after A-D, decide whether Stage 5 news overlay/cross-source merge can start.
```

## Why EDINET first

EDINET already has a fallback candidate contract and input sheet. It is separate from TDnet and can be evaluated without changing the locked JP TDnet runtime.

The first EDINET implementation must still be isolated:

```text
one source
one family
one fixture item
one docID or equivalent official stable ID
```

Do not build broad EDINET ingestion first.

## Why JP broad next

JP TDnet timely disclosure is locked for one fixture item. Broad JP all-disclosures should be a second-layer expansion over TDnet/JPX surfaces, not a rewrite of the locked source.

The broad JP package must first decide:

```text
whether broad means all TDnet current-list rows within the 31-day window
whether broad means TDnet historical rows via JPX Listed Company Search
whether broad means a controlled family set over TDnet only
whether EDINET statutory reports remain a separate lane
```

Do not mix TDnet broad ingestion and EDINET runtime in one implementation PR.

## Why CN broad last

CNInfo ownership-change is locked from one official CNInfo sample. Broad CN expansion needs additional source/family decisions and may involve more than CNInfo if SSE/SZSE/BSE surfaces are considered.

Broad CN must not mutate the locked CNInfo ownership-change semantics.

## Required gate before any broad implementation

For every new broad lane, freeze:

```text
source_key
adapter_key
source tier
family boundary
stable external id rule
cursor rule
pagination/scope rule
fixture strategy
sample count
raw-document set
idempotency expectations
dedupe SQL expectations
fallback/no-go criteria
```

## Implementation guardrails

Never add in the same PR:

```text
TDnet broad ingestion + EDINET runtime
CN broad ingestion + JP changes
news overlay + regional ingestion expansion
cross-source merge + new source adapters
```

Never regress:

```text
existing event ids
existing stable_external_ids
existing cursor keys/values
existing raw document identities
existing canonical event type mappings
locked source health behavior
```

## Recommended next PRs

```text
PR next-1: EDINET sample-capture close-out or no-go
PR next-2: EDINET isolated runtime, if next-1 freezes a sample
PR next-3: JP TDnet broad ingestion readiness / contract-freeze preflight
PR next-4: CN broad expansion readiness / contract-freeze preflight
PR next-5: Stage 5 news overlay/cross-source merge kickoff
```

## Current decision

Start with EDINET sample-capture close-out. If no deterministic EDINET sample is available, record no-go and move to JP broad-readiness instead.
