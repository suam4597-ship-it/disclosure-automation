# UK FCA NSM takeover/scheme first-run triage

## If the source does not upsert

Check:

- `apps/backend/disclosure_api/lib/disclosure_automation/ops/uk_fca_nsm_takeover_scheme_updates_source.ex`
- `apps/backend/disclosure_api/priv/config_samples/source_registry.uk_fca_nsm_takeover_scheme_updates.sample.yaml`
- `source_key = uk_fca_nsm_takeover_scheme_updates`

## If adapter resolution fails

Check:

- `apps/backend/disclosure_api/lib/disclosure_automation/runtime/adapter.ex`

The source must resolve:

- `adapter_key = uk_fca_nsm_takeover_scheme_updates_v1`

## If discovery returns zero rows

Check the CSV fixture:

- `apps/backend/disclosure_api/priv/fixtures/source_payloads/uk_fca_nsm_takeover_scheme_search_results.csv`

The v0 adapter expects exactly one row where:

- `Category = Scheme of Arrangement`
- `Source = Regulatory News Services (RNS)`
- `Download Link` contains `/artefacts/NSM/RNS/`

## If cursor is missing

Check that the discovery row exposes both:

- `Filing Date/Time`
- `Download Link`

Expected cursor value:

```text
2026-04-20T06:13:00|RNS|5c9e4a51-b4c6-4977-86d3-ac8567261289
```

## If published time is wrong

The fixture uses UK local time in April, so the expected local offset is BST:

- local: `2026-04-20T06:00:00+01:00`
- UTC: `2026-04-20T05:00:00Z`

## If exact event_id drifts

Expected v0 event id:

```text
uk.fca_nsm.british_land_company_public_limited_company_the.20260420.tender_offer_or_go_private.takeover_or_scheme_update.5c9e4a51_b4c6_4977_86d3_ac8567261289
```

If this changes, inspect:

- issuer slug generation
- filing date source
- canonical event type
- event family
- artefact token slugging

## If raw document counts are wrong

Expected minimum raw-document set:

- `NSM:RNS:5c9e4a51-b4c6-4977-86d3-ac8567261289:artefact-html`
- `NSM:RNS:5c9e4a51-b4c6-4977-86d3-ac8567261289:discovery-row`

## If Windows PowerShell blocks mix

Use `mix.bat` instead of `mix`.
