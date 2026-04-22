# UK discovery + NSM minimal gate

This gate is intentionally split into two phases.

## Phase A — discovery freeze gate

Before code is added, the following must be explicit:

- source key
- display name
- region code
- adapter key strategy
- parser key strategy
- discovery mode
- hydrate mode
- first cursor key
- first document identity rule
- first event family
- first canonical event type

Pass condition for Phase A:

- the discovery inventory document is complete
- one first thin-slice path is chosen
- one isolated fixture strategy is chosen

## Phase B — isolated runtime gate

After the source shape is frozen, implementation should add:

- source helper
- isolated sample YAML
- fixture payloads
- runtime adapter if needed
- tests
- dedupe SQL
- manual smoke doc
- first-run triage doc

Pass condition for Phase B:

- runtime idempotency test green
- HTTP smoke test green
- repeated poll keeps a stable event id
- dedupe SQL clean
- source health healthy

## Guardrail

Do not call the UK first vertical locked until both phases are complete.
