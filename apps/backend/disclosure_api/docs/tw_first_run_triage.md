# TW first-run triage

Use this after the first TW runtime implementation path exists.

## If source bootstrap fails

Check:

- source helper module name
- isolated sample YAML path
- chosen source key uniqueness
- chosen adapter key resolver path

## If discovery returns zero items unexpectedly

Check:

- whether discovery mode matches the verified official source shape
- whether the fixture mirrors the frozen discovery contract
- whether the cursor logic filtered out the only fixture item
- whether category/source filters are too broad or too narrow

## If runtime cursor crashes

Check whether the discovery item exposes the chosen cursor field consistently.
Do not assume SEC accession, AFM notification id, or UK NSM artefact semantics for TW.

## If canonical item source names look wrong

Check whether the runtime pipeline is still hard-coding another source family.
Keep source names document-type aware when runtime sources are heterogeneous.

## If timestamps drift

Check:

- official local timezone
- daylight saving assumptions, if any
- source-provided local time vs UTC conversion
- whether publication date and filing date are distinct

## If dedupe drifts

Check:

- raw document external id rule
- document identity rule
- raw event key seed
- canonical event id seed
- canonical item source uniqueness keys

## Windows note

Use `mix.bat` instead of `mix` on Windows PowerShell when script execution policy blocks `mix.ps1`.
