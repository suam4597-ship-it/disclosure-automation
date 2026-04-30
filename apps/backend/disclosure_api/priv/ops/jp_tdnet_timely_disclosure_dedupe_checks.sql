-- JP TDnet timely-disclosure storage-level dedupe verification
-- Run after first poll and again after repeated poll with the same fixture payload.

-- 1) immutable raw document external id dedupe
SELECT
  source_registry_id,
  external_id,
  COUNT(*) AS row_count
FROM raw_documents
GROUP BY source_registry_id, external_id
HAVING COUNT(*) > 1;

-- 2) document identity dedupe
SELECT
  source_registry_id,
  document_identity,
  document_type,
  COUNT(*) AS row_count
FROM raw_documents
GROUP BY source_registry_id, document_identity, document_type
HAVING COUNT(*) > 1;

-- 3) runtime raw event dedupe
SELECT
  source_registry_id,
  event_key,
  COUNT(*) AS row_count
FROM raw_events
GROUP BY source_registry_id, event_key
HAVING COUNT(*) > 1;

-- 4) canonical item dedupe
SELECT
  event_id,
  COUNT(*) AS row_count
FROM canonical_feed_items
GROUP BY event_id
HAVING COUNT(*) > 1;

-- 5) canonical authority mapping dedupe
SELECT
  canonical_feed_item_id,
  raw_event_id,
  source_role,
  COUNT(*) AS row_count
FROM canonical_item_sources
GROUP BY canonical_feed_item_id, raw_event_id, source_role
HAVING COUNT(*) > 1;

-- 6) representative row integrity
SELECT
  canonical_feed_item_id,
  COUNT(*) FILTER (WHERE is_representative = true) AS representative_count
FROM canonical_item_sources
GROUP BY canonical_feed_item_id
HAVING COUNT(*) FILTER (WHERE is_representative = true) > 1;

-- 7) current verified JP TDnet fixture spot check
SELECT
  external_id,
  COUNT(*) AS row_count
FROM raw_documents
WHERE external_id IN (
  'TDNET:4527:20260430:1900:140120260430515474:discovery-row',
  'TDNET:4527:20260430:1900:140120260430515474:pdf:140120260430515474'
)
GROUP BY external_id
ORDER BY external_id;

-- Expected: no rows from queries 1-6, and row_count = 1 for both rows in query 7.
