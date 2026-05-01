# Stage 5 news overlay match evidence contract

This document freezes the match evidence contract for the first Stage 5 news overlay source.

This is a docs-only contract-freeze. It does not add runtime code, source adapters, fixtures, tests, database migrations, schedulers, scraping, or changes to locked regional runtimes.

## Baseline

This contract follows:

```text
base branch: sec-thin-slice-reconcile-v1
base commit: f62847aec3213830023bfd7de3a0587d02dafc36
base commit source: PR #62 Stage 5 news overlay and cross-source merge design
source contract: stage5_news_overlay_source_contract_freeze.md
```

## Purpose

A news overlay may attach to an official canonical event only when explicit match evidence exists.

Match evidence is separate from:

```text
event_id
stable_external_id
raw_document_external_id
duplicate_group_key
citation object
LLM-generated summary
```

Match evidence must not mutate any locked official identifier.

## Required match evidence object

Future overlay fixture rows and runtime output must carry a match evidence object.

Required fields:

```text
matched_canonical_event_id
matched_official_source_key
matched_official_stable_external_id
matched_official_event_family
matched_official_canonical_event_type
matched_issuer_evidence
matched_publication_window
match_rule
match_inputs
match_decision_source
```

Optional fields:

```text
matched_official_url
matched_transaction_identifier
matched_filing_identifier
matched_security_identifier
matched_named_parties
matched_amounts
matched_effective_date
matched_filing_date
ambiguity_flags
conflict_flags
manual_review_note
```

## Match decision source

Allowed match_decision_source values:

```text
deterministic_rule
manual_fixture_author
manual_verification
```

Forbidden match_decision_source values for finalized matches:

```text
llm_only
semantic_similarity_only
publication_window_only
headline_similarity_only
```

LLM output may be stored only as a suggestion or note in later stages. It must not finalize a match.

## Match rule values

Initial allowed match_rule values:

```text
official_url_reference
stable_external_id_reference
issuer_identifier_and_event_family_and_date
issuer_identifier_and_transaction_identifier
issuer_identifier_and_filing_identifier
manual_fixture_pair
```

A future runtime PR may narrow this list, but it must not broaden matching without a new policy PR.

## Issuer evidence

matched_issuer_evidence must include at least one of:

```text
issuer_identifier
security_code
ticker
edinet_code
cik
cninfo_security_code
mops_company_code
issuer_name_exact_from_official_source
```

Issuer name similarity alone is weak evidence and must not finalize a match.

## Publication window evidence

matched_publication_window must include:

```text
official_published_at
article_published_at
window_relation
window_days
```

Allowed window_relation values:

```text
article_after_official
article_before_official
same_day
outside_default_window
```

Publication window evidence is supporting evidence only. It must not finalize a match without another deterministic or explicit evidence field.

## Match inputs

match_inputs must list the concrete values used to reach the match.

Suggested shape:

```text
match_inputs:
  official:
    event_id
    source_key
    stable_external_id
    issuer_identifier
    event_family
    canonical_event_type
    published_at
    filing_date
  overlay:
    article_external_id
    source_key
    article_title
    article_published_at
    mentioned_issuer_identifier
    mentioned_event_family
    referenced_official_url
```

Do not store secrets in match_inputs.

## Ambiguity policy

If a candidate overlay matches multiple official events, do not finalize the overlay attachment.

Candidate ambiguity flags:

```text
multiple_possible_official_matches
issuer_identifier_missing
only_title_similarity
publication_window_only
conflicting_transaction_identifiers
conflicting_parties
conflicting_amounts
conflicting_dates
```

An ambiguous candidate may be documented for manual review in a later stage, but this contract does not enable ambiguous runtime merge behavior.

## Conflict policy

Conflict flags should be attached when overlay claims disagree with official facts.

Initial conflict_flags values:

```text
news_official_timestamp_conflict
news_official_amount_conflict
news_official_parties_conflict
news_unconfirmed_claim
official_update_supersedes_news
```

Conflict flags must not overwrite official values.

## Duplicate group boundary

This contract does not finalize a duplicate_group_key format.

A future fixture or runtime PR may add duplicate_group_key only after preserving:

```text
official event_id
official stable_external_id
official raw_document_external_id
official raw document identity
official citation
source-specific provenance
```

## Citation boundary

Match evidence is not a citation.

A future overlay attachment must include both:

```text
match_evidence:
  explains why the overlay attaches to an official event

citation:
  explains which source supports which claim
```

Official filing facts must cite official sources. News-derived context must cite news sources separately.

## Redaction policy

Match evidence must never persist secret-bearing values.

Forbidden:

```text
API keys
Authorization headers
Subscription keys
cookies
session tokens
signed private URLs
unredacted EDINET Subscription-Key values
```

Any EDINET request shape must remain:

```text
Subscription-Key=<redacted>
```

## Acceptance criteria for future fixture PR

The next fixture PR must include match evidence that satisfies this contract.

Required checks:

```text
each overlay fixture row references one locked official canonical event
each overlay fixture row includes match_evidence
each match_evidence has at least one deterministic or explicit evidence field
each match_evidence includes match_decision_source
each match_evidence avoids LLM-only finalization
each match_evidence avoids publication-window-only finalization
each match_evidence avoids secrets
```

## Acceptance criteria for this docs-only PR

```text
changed files are limited to Stage 5 docs
no runtime code is added
no source adapter is added
no fixture is added
no test is added
no migration is added
no scheduler change is added
locked official runtime identifiers remain immutable
```
