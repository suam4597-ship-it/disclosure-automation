# SEC SC 13D/A sibling expansion kickoff

This branch starts the next SEC sibling form after the locked 6-K, 8-K, SC TO-T, and SC 14D-9 paths.

## Position in program
- 6-K lock is complete
- 8-K lock is complete
- SC TO-T lock is complete
- SC 14D-9 lock is complete
- next sibling form is SC 13D/A

## Scope of this kickoff
- add a dedicated SC 13D/A sample source registry config
- add a minimal SC 13D/A discovery/detail/submission fixture set
- preserve the locked 6-K, 8-K, SC TO-T, and SC 14D-9 baselines while verifying SC 13D/A in isolation

## Next implementation steps
1. confirm existing SEC adapter mapping for `SC 13D/A`
2. add SC 13D/A runtime idempotency and HTTP smoke coverage
3. run the same minimal gate used for the prior SEC sibling forms
4. only then decide whether to tighten event-family assertions or mark SC 13D/A as locked

## Verification target for the next pass
- one SC 13D/A fixture closes discovery -> hydrate -> parse -> normalize -> store -> read path
- repeated poll keeps stable event_id
- raw_documents, raw_events, canonical_feed_items, and canonical_item_sources stay deduped
- event-family/canonical-type expectations are recorded only after adapter mapping is verified
