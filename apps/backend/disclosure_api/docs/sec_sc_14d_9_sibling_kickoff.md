# SEC SC 14D-9 sibling expansion kickoff

This branch starts the next SEC sibling form after the locked 6-K, 8-K, and SC TO-T paths.

## Position in program
- 6-K lock is complete
- 8-K lock is complete
- SC TO-T lock is complete
- next sibling form is SC 14D-9
- later sibling remains SC 13D/A

## Scope of this kickoff
- add a dedicated SC 14D-9 sample source registry config
- add a minimal SC 14D-9 discovery/detail/submission fixture set
- preserve the locked 6-K, 8-K, and SC TO-T baselines while verifying SC 14D-9 in isolation

## Next implementation steps
1. confirm existing SEC adapter mapping for `SC 14D-9`
2. add SC 14D-9 runtime idempotency and HTTP smoke coverage
3. run the same minimal gate used for 6-K, 8-K, and SC TO-T
4. only then decide whether to tighten event-family assertions or promote SC 14D-9 into the active SEC sibling set

## Verification target for the next pass
- one SC 14D-9 fixture closes discovery -> hydrate -> parse -> normalize -> store -> read path
- repeated poll keeps stable event_id
- raw_documents, raw_events, canonical_feed_items, and canonical_item_sources stay deduped
- event-family/canonical-type expectations are recorded only after adapter mapping is verified
