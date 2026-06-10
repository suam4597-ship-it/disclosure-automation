# GlobalPulse Banja Luka BLSE Issuer News Candidate Notes

This document records the bounded candidate decision for the Banja Luka Stock Exchange issuer-news source.

The source is a listed-company exchange announcement surface. It is not a central-bank feed, macro-statistics feed, parliament feed, broad policy-news feed, or third-party aggregator.

## Candidate

```text
source_key: ba_blse_issuer_news_multi_code
display_name: Banja Luka Stock Exchange Issuer News Multi-Code
authority: Banja Luka Stock Exchange
supporting documentation: https://www3.blberza.com/Pages/docview.aspx?page=sp99
ticker URL: https://services.blberza.com/blse/ticker.ashx?LangId=3&TickerTypeId=1&filter=all&ct=xml
issuer RSS template: https://www.blberza.com/pages/IssuerNewsRss.aspx?Code={code}&LangId=3
parser_key: blse_multi_issuer_news_rss_v1
candidate_status: manual_staging_only
active: false
```

## Observed Endpoint Shape

The public BLSE documentation describes issuer announcement export endpoints and an issuer RSS endpoint using a security code parameter.

```text
GET /blse/ticker.ashx?LangId=3&TickerTypeId=1&filter=all&ct=xml
status: 200
content-type: application/xml; charset=utf-8
shape: TickerData / Items / TickerItem with Code, Issuer, and Url
```

```text
GET /pages/IssuerNewsRss.aspx?Code=TLKM-R-A&LangId=3
status: 200
content-type: application/rss+xml; charset=utf-8
shape: RSS channel item records with title, link, pubDate, and description
```

## Bounded Fetch Design

```text
fetch strategy: blse_multi_issuer_news_rss_v1
universe source: BLSE ticker XML
universe filter: listed equity security codes ending in -R-A
issuer window: deterministic static offset
default issuer window size: 5
default max RSS items per issuer: 5
detail fetch: disabled
attachment fetch: disabled
live fixture fallback: disabled
scheduled polling: disabled
```

The first implementation keeps the candidate manual-only. It proves that the official BLSE ticker XML can seed a bounded issuer-code window and that official per-issuer RSS feeds can produce canonical public digest records.

## Guardrails

```text
source active=true: no
scheduled polling enabled: no
production promotion: no
backend digest JSON shape changed: no
frontend framework added: no
public poll UI added: no
audit UI added: no
public Source Health UI added: no
raw/private material exposed: no
```

## Next Steps

```text
1. Run local parser smoke for fixture payload.
2. Run live endpoint smoke against ticker XML and at least one issuer RSS feed.
3. Deploy to Fly staging.
4. Poll ba_blse_issuer_news_multi_code with use_live_fetch=true.
5. Record staging live poll and digest visibility before any broader Europe promotion.
```
