-- Roll back the application-owned Phase 0 schema in dependency order.
DROP TABLE IF EXISTS domain_event_dispatches;
DROP TABLE IF EXISTS domain_events;
DROP TABLE IF EXISTS canonical_feed_items;
DROP TABLE IF EXISTS raw_documents;
DROP TABLE IF EXISTS ingestion_runs;
DROP TABLE IF EXISTS delivery_windows;
DROP TABLE IF EXISTS source_registry;
