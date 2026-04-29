# UK discovery + NSM first-run triage

Use this only after the UK discovery shape is frozen and the first runtime path exists.

## If source bootstrap fails

Check:

- source helper module name
- isolated sample YAML path
- chosen source key uniqueness
- chosen adapter key resolver path

## If discovery returns zero items unexpectedly

Check:

- whether discovery mode matches the real source shape
- whether the fixture actually mirrors the frozen discovery contract
- whether the cursor logic is filtering out the only fixture item

## If runtime cursor crashes

Check whether the discovery item exposes the chosen cursor field consistently.
Do not assume SEC accession semantics for a UK source.

## If canonical item source names look wrong

Check whether the runtime pipeline is still hard-coding another source family.
Keep source names document-type aware when runtime sources are heterogeneous.

## If dedupe drifts

Check:

- raw document external id rule
- document identity rule
- raw event key seed
- canonical event id seed
- canonical item source uniqueness keys
