# SEC SC TO-T sibling expansion kickoff

This branch starts the next program phase after the SEC 6-K and 8-K locks.

## Position in program
- 6-K lock is complete
- 8-K lock is complete
- next sibling form is SC TO-T
- later siblings remain SC 14D-9 and SC 13D/A

## Scope of this kickoff
- add a dedicated SC TO-T sample source registry config
- add a minimal SC TO-T discovery/detail/submission fixture set
- preserve the locked 6-K and 8-K baselines while verifying SC TO-T in isolation

## Next implementation steps
1. switch bootstrap or test path to the SC TO-T sample only for isolated verification
2. add SC TO-T runtime idempotency and HTTP smoke coverage
3. run the same minimal gate used for 6-K and 8-K
4. only then decide whether to promote SC TO-T into the active SEC sibling set

## Verification target for the next pass
- one SC TO-T fixture closes discovery -> hydrate -> parse -> normalize -> store -> read path
- repeated poll keeps stable event_id
- raw_documents, raw_events, canonical_feed_items, and canonical_item_sources stay deduped
