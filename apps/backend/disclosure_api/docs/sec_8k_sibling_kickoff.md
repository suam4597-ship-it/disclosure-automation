# SEC 8-K sibling expansion kickoff

This branch starts the next program phase after the SEC 6-K lock.

## Position in program
- 6-K lock is complete
- next sibling form is 8-K
- later siblings remain SC TO-T, SC 14D-9, and SC 13D/A

## Scope of this kickoff
- add a dedicated 8-K sample source registry config
- add a minimal 8-K discovery/detail/submission fixture set
- preserve the locked 6-K baseline on the main sec_current_forms sample

## Next implementation steps
1. switch bootstrap or test path to the 8-K sample only for isolated verification
2. add 8-K runtime idempotency and http smoke coverage
3. run the same minimal gate used for 6-K
4. only then promote 8-K into the active sec_current_forms sibling set

## Verification target for the next pass
- one 8-K fixture closes discovery -> hydrate -> parse -> normalize -> store -> read path
- repeated poll keeps stable event_id
- raw_documents, raw_events, canonical_feed_items, and canonical_item_sources stay deduped
