# JP sample capture instructions

These instructions define how to capture one deterministic public JP disclosure sample after the source-surface inspection is complete.

This discovery-only PR must not add the sample YAML, fixtures, runtime adapter, tests, ops runner, or dedupe SQL.

## Capture goal

Capture exactly one public disclosure sample that can support a later isolated runtime lock.

The sample should prove:

- official source identity
- stable external identity
- cursor semantics
- publication timestamp semantics
- minimum raw-document set
- first event family mapping
- first canonical event type mapping

## Before capturing

Confirm the following:

- chosen source candidate: `TODO`
- chosen source tier: `TODO`
- chosen first family: `TODO`
- chosen issuer/security code: `TODO`
- chosen sample title: `TODO`
- chosen publication date/time: `TODO`

Do not capture a sample from a broad search result until it is clear that one family can be isolated.

## Capture checklist

For the chosen sample, record:

- source home/search URL
- exact query URL or request parameters
- discovery row HTML or JSON excerpt
- detail page URL
- detail page HTML or JSON excerpt
- attachment/PDF URL, if required
- attachment filename and source document id, if visible
- local publication datetime exactly as displayed
- UTC publication datetime conversion
- source category/family label exactly as displayed
- issuer/company name exactly as displayed
- issuer/security code exactly as displayed
- visible stable id fields
- cursor field candidates

## Stable identity evidence

Record the source field that will become the stable external identity.

Preferred evidence:

```text
source field name: TODO
source field value: TODO
stable_external_id rule: TODO
stable_external_id sample: TODO
```

Acceptable candidates include:

- disclosure number
- disclosure history number
- document id
- TDnet/JPX artefact id
- stable PDF URL token
- security code + disclosure date/time + sequence number

Do not use title text as the stable external identity.

## Cursor evidence

Record the source fields that will become the cursor.

Preferred evidence:

```text
cursor_key: TODO
cursor_value shape: TODO
cursor sample value: TODO
```

The cursor should be monotonic or deterministic across repeated discovery calls.

Do not use title text as the cursor.

## Raw-document set decision

Record the minimum raw-document set needed for the later runtime PR.

Options:

```text
1. discovery row only: not enough unless it includes all canonical facts
2. discovery row + detail page: acceptable if detail page includes canonical facts
3. discovery row + detail page + attachment/PDF: use only if canonical facts require attachment parsing
4. discovery row + attachment/PDF: acceptable if the attachment is the primary regulatory disclosure document
```

For each raw document, record:

- raw document external id rule
- document identity rule
- document role
- MIME type
- source URL

## Timestamp conversion

Record:

- source timezone assumption
- local timestamp field
- local timestamp sample value
- UTC conversion rule
- UTC sample value
- date-only fallback rule, if the source lacks time of day

JP timestamp assumption should default to Japan Standard Time (`Asia/Tokyo`, UTC+09:00) unless the source states otherwise.

## Family and canonical mapping

Record:

- source category label
- event family candidate
- canonical event type candidate
- why this mapping is narrower than broad all-disclosures ingestion
- whether the source category includes unrelated subtypes

## Save instructions for later runtime PR

After contract freeze, the later runtime PR may save fixtures under paths shaped like:

```text
apps/backend/disclosure_api/priv/fixtures/source_payloads/jp_<chosen_source>_discovery_<sample>.json
apps/backend/disclosure_api/priv/fixtures/source_payloads/jp_<chosen_source>_detail_<sample>.html
apps/backend/disclosure_api/priv/fixtures/source_payloads/jp_<chosen_source>_attachment_<sample>.pdf
```

Do not create those files in this discovery-only PR.

## Capture rejection rules

Reject the sample if:

- it comes from a non-official mirror without official-source backing
- it lacks stable public identity
- it lacks deterministic cursor fields
- it requires broad all-disclosures ingestion to find again
- it requires multiple unrelated disclosure families
- it cannot be reduced to a small raw-document set

## Completion criteria

The sample capture phase is complete only when the contract template can be filled without `TODO` for:

- chosen source
- chosen source tier
- chosen family
- chosen sample
- stable external identity rule and sample
- cursor key and sample value
- local/UTC timestamp rule
- minimum raw-document set
- first event family
- first canonical event type
