# AFM substantial holdings first-run triage

## If the source does not upsert

Check the isolated sample path:

- `apps/backend/disclosure_api/priv/config_samples/source_registry.afm_substantial_holdings.sample.yaml`

Check the helper:

- `DisclosureAutomation.Ops.AFMSubstantialHoldingsSource.sample_path/0`

## If the poll fails before persistence

Check adapter resolution in:

- `apps/backend/disclosure_api/lib/disclosure_automation/runtime/adapter.ex`

The AFM source must resolve `adapter_key = "afm_substantial_holdings_v1"`.

## If the fixture does not load

Check:

- `config.fixtures.register_export`
- `priv/fixtures/source_payloads/afm_substantial_holdings_export.xml`

## If the event shape drifts

Lock these fields first after the first successful run:

- `event_id`
- `published_at_local`
- `published_at_utc`
- `filing_date_local`
- `event_family`
- `canonical_event_type`

## If Windows PowerShell blocks mix

Use `mix.bat` instead of `mix`.
