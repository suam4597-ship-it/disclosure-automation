-- Stage 5 news overlay raw-staging dedupe checks.
-- Run against the dev database after staging the Reuters overlay fixture.

-- 1. No duplicate Reuters article metadata raw document.
select
  external_id,
  count(*) as row_count
from raw_documents
where external_id = 'NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001:article-metadata'
group by external_id
having count(*) <> 1;

-- 2. No duplicate Reuters overlay candidate raw event.
select
  external_event_key,
  count(*) as row_count
from raw_events
where external_event_key = 'news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57:overlay-candidate'
group by external_event_key
having count(*) <> 1;

-- 3. No canonical Reuters overlay event was created.
select
  event_id,
  count(*) as row_count
from canonical_feed_items
where event_id = 'news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57'
group by event_id;

-- 4. The locked official TDnet canonical event still exists exactly once.
select
  event_id,
  count(*) as row_count
from canonical_feed_items
where event_id = 'jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474'
group by event_id
having count(*) <> 1;

-- 5. The Reuters overlay source cursor exists exactly once.
select
  cursor_key,
  cursor_value,
  count(*) as row_count
from source_cursors c
join source_registries s on s.id = c.source_registry_id
where s.source_key = 'stage5_news_overlay_fixture'
  and c.cursor_key = 'latest_article_published_at_and_article_external_id_seen'
  and c.cursor_value = '2026-04-30T10:30:00Z|NEWS-FIXTURE:jp:jp_tdnet_timely_disclosure:140120260430515474:reuters-jp-article-001'
group by cursor_key, cursor_value
having count(*) <> 1;

-- 6. Inspect the staged overlay payload flags.
select
  payload->>'overlay_id' as overlay_id,
  payload->>'canonical_event_id' as canonical_event_id,
  payload->>'source_tier' as source_tier,
  payload->>'document_role' as document_role,
  payload->>'canonical_feed_mutation' as canonical_feed_mutation,
  payload->>'news_only_event_creation' as news_only_event_creation
from raw_events
where external_event_key = 'news_overlay:jp.tdnet.4527.20260430.material_information_update.material_information_update.140120260430515474:ba9e08fb9a92ac57:overlay-candidate';
