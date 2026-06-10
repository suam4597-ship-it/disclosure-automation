# GlobalPulse Albania ALSE Issuer News Endpoint Scan

Date: 2026-05-11 KST

## Conclusion

```text
ALBANIA_ALSE_OFFICIAL_EXCHANGE_SURFACE_CONFIRMED
ALBANIA_ALSE_WORDPRESS_API_CONFIRMED
ALBANIA_ALSE_ISSUER_NEWS_CATEGORY_OBSERVED
ALBANIA_TSE_WORDPRESS_NEWS_NOT_A_DISCLOSURE_SOURCE
ALBANIA_ALSE_SOURCE_REGISTRATION_PENDING_CONTRACT
ALBANIA_ALSE_NO_LIVE_SOURCE_ENABLED
```

## Scope

This scan evaluates Albania as a future listed-company disclosure source.

It does not register a source, does not add a parser, does not add a fixture, does not enable scheduled polling, and does not change backend or frontend runtime behavior.

```text
target country: Albania
candidate exchange surface: Albanian Securities Exchange / ALSE
candidate API family: WordPress REST API
candidate issuer-news category: Lajme nga Emetuesit
candidate English issuer-news category: News from Issuers
secondary surface checked: Tirana Stock Exchange / TSE
status before this scan: not_scanned
status after this scan: endpoint_candidate_needs_contract
```

## Endpoint Probes

```text
GET https://www.tse.com.al/
GET https://www.tse.com.al/wp-json/wp/v2/posts?per_page=10
GET https://alse.al/
GET https://alse.al/wp-json/wp/v2/categories?per_page=100
GET https://alse.al/wp-json/wp/v2/posts?per_page=10
GET https://alse.al/wp-json/wp/v2/posts?categories=42&per_page=5
GET https://alse.al/wp-json/wp/v2/posts?categories=44&per_page=5
```

Observed local result:

```text
TSE homepage: HTTP 200 text/html
TSE WordPress API: HTTP 200 JSON, but latest posts are institutional/market-development items from 2012-2019
ALSE homepage: HTTP 200 text/html
ALSE WordPress categories: HTTP 200 JSON
ALSE latest posts: HTTP 200 JSON
ALSE category 42: HTTP 200 JSON, issuer-specific Albanian-language posts observed
ALSE category 44: HTTP 200 JSON, English "News from Issuers" category observed but sparse/stale and mixed with market/news items
```

## Relevant ALSE Categories

```text
id=42, name=Lajme nga Emetuesit, slug=lajme-nga-emetuesit, count=56
id=44, name=News from Issuers, slug=news-from-issuers, count=13
id=31, name=Njoftimet e ALSE, slug=njoftimet-e-alse, count=789
id=45, name=ALSE News, slug=alse-news, count=740
id=613, name=Lajmet me te fundit, slug=lajmet-me-te-fundit, count=547
id=615, name=Latest news, slug=latest-news, count=457
```

Category 42 is the strongest source candidate because it contains issuer-specific disclosure-style posts.

Examples observed from `categories=42`:

```text
2026-04-30: Audited 2025 financial statements for ABI Bank sh.a. / NOA sh.a.
2025-11-27: Official notice on merger by absorption between American Bank of Investments SHA and NOA SHA
2025-06-25: Consolidated audited 2024 financial statements for NOA sh.a.
2025-04-30: Audited 2024 financial statements for NOA sh.a.
2025-03-21: Notice on privileged information for NOA sh.a.
```

These are plausibly issuer disclosures, not central-bank, macro, policy, or generic market commentary feeds.

## TSE Decision

Tirana Stock Exchange was checked as a secondary official market surface.

```text
site: https://www.tse.com.al/
WordPress API: https://www.tse.com.al/wp-json/wp/v2/posts?per_page=10
latest observed posts: institutional cooperation, corporate governance, training, FEAS, historical TSE activity
```

TSE is not a source-registration candidate in this pass because the observed machine-readable posts are not a current listed-company issuer-announcement feed.

## ALSE Source Registration Blocker

Do not register an Albania source yet.

The ALSE WordPress API is promising, but a parser/source PR needs a tighter contract first:

```text
confirm category 42 is the authoritative issuer-disclosure category
decide whether category 44 should be ignored, merged, or used only as an English auxiliary feed
avoid duplicate Albanian/English posts if both category trees are used
filter out exchange operational notices, market data posts, and generic ALSE news categories
define bounded fields from WordPress JSON: id, date, link, title.rendered, content/excerpt, categories
handle HTML stripping safely without exposing raw full content as digest text
decide whether PDF attachment links stay in source_url only or are parsed as detail metadata
prove local parser fixture before any Fly staging live poll
keep active=false and candidate_status=manual_staging_only
```

## Guardrails

```text
do not register TSE WordPress news as a disclosure source
do not include Bank of Albania macro/policy feeds
do not use ALSE latest/all-news categories as a broad market-news source
do not enable scheduled polling
do not set any source active=true
do not change backend digest JSON response shape
do not add public poll UI, audit UI, or public Source Health UI
do not add frontend framework dependencies
```

## Candidate State

```text
candidate_status: endpoint_candidate_needs_contract
authority: official exchange surface confirmed
machine_readable_endpoint: WordPress REST API confirmed
issuer_news_category: category 42 observed
parser: not_added
source_registration: pending
scheduled_polling: blocked
```

## Next Step

The next safe implementation step is a small parser/source PR for `al_alse_issuer_news` only after category 42 is accepted as the source boundary.

Recommended first slice:

```text
source_key: al_alse_issuer_news
base_url: https://alse.al/wp-json/wp/v2/posts?categories=42&per_page=25
parser_key: alse_issuer_news_wordpress_json_v1
active=false
candidate_status=manual_staging_only
disable_live_fixture_fallback=true
scheduled polling disabled
```

