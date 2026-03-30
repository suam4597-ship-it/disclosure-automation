-- Phase 0 core schema bootstrap
-- Application-owned tables only. Oban is created by a separate migration.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS source_registry (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  source_key text NOT NULL UNIQUE,
  display_name text NOT NULL,
  source_type text NOT NULL,
  base_url text NOT NULL,
  healthcheck_url text,
  parser_key text NOT NULL,
  ranking_weight numeric(5,2) NOT NULL DEFAULT 1.00,
  poll_cron text NOT NULL,
  coverage_tags text[] NOT NULL DEFAULT '{}',
  active boolean NOT NULL DEFAULT true,
  config jsonb NOT NULL DEFAULT '{}'::jsonb,
  health_status text NOT NULL DEFAULT 'unknown',
  last_seen_published_at timestamptz,
  last_success_at timestamptz,
  last_failure_at timestamptz,
  last_error text,
  inserted_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT source_registry_source_type_check
    CHECK (source_type IN ('rss', 'atom', 'json_feed', 'html', 'api', 'email')),
  CONSTRAINT source_registry_health_status_check
    CHECK (health_status IN ('healthy', 'degraded', 'failed', 'paused', 'unknown'))
);

CREATE INDEX IF NOT EXISTS source_registry_active_health_status_idx
  ON source_registry (active, health_status);

CREATE INDEX IF NOT EXISTS source_registry_source_type_idx
  ON source_registry (source_type);

CREATE TABLE IF NOT EXISTS delivery_windows (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  window_key text NOT NULL UNIQUE,
  edition text NOT NULL,
  channel text NOT NULL,
  timezone text NOT NULL,
  weekdays integer[] NOT NULL DEFAULT '{1,2,3,4,5}',
  opens_at_local time NOT NULL,
  closes_at_local time NOT NULL,
  cutoff_minutes integer NOT NULL DEFAULT 30,
  active boolean NOT NULL DEFAULT true,
  config jsonb NOT NULL DEFAULT '{}'::jsonb,
  inserted_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT delivery_windows_edition_check
    CHECK (edition IN ('apac-open', 'europe-midday', 'us-close', 'breaking')),
  CONSTRAINT delivery_windows_channel_check
    CHECK (channel IN ('dashboard', 'email', 'slack', 'webhook')),
  CONSTRAINT delivery_windows_cutoff_minutes_check
    CHECK (cutoff_minutes >= 0),
  CONSTRAINT delivery_windows_open_close_check
    CHECK (opens_at_local < closes_at_local)
);

CREATE INDEX IF NOT EXISTS delivery_windows_active_edition_idx
  ON delivery_windows (active, edition, channel);

CREATE TABLE IF NOT EXISTS ingestion_runs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  source_registry_id uuid NOT NULL REFERENCES source_registry(id) ON DELETE RESTRICT,
  run_key text NOT NULL UNIQUE,
  trigger_kind text NOT NULL,
  status text NOT NULL,
  request_url text,
  source_cursor text,
  queued_at timestamptz NOT NULL DEFAULT now(),
  started_at timestamptz,
  finished_at timestamptz,
  http_status integer,
  records_seen integer NOT NULL DEFAULT 0,
  records_inserted integer NOT NULL DEFAULT 0,
  records_updated integer NOT NULL DEFAULT 0,
  records_rejected integer NOT NULL DEFAULT 0,
  checksum text,
  error_code text,
  error_message text,
  meta jsonb NOT NULL DEFAULT '{}'::jsonb,
  inserted_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ingestion_runs_trigger_kind_check
    CHECK (trigger_kind IN ('scheduled', 'manual', 'replay', 'backfill')),
  CONSTRAINT ingestion_runs_status_check
    CHECK (status IN ('queued', 'running', 'succeeded', 'failed', 'partial', 'cancelled'))
);

CREATE INDEX IF NOT EXISTS ingestion_runs_source_registry_id_inserted_at_idx
  ON ingestion_runs (source_registry_id, inserted_at DESC);

CREATE INDEX IF NOT EXISTS ingestion_runs_status_inserted_at_idx
  ON ingestion_runs (status, inserted_at DESC);

CREATE TABLE IF NOT EXISTS raw_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ingestion_run_id uuid NOT NULL REFERENCES ingestion_runs(id) ON DELETE CASCADE,
  source_registry_id uuid NOT NULL REFERENCES source_registry(id) ON DELETE RESTRICT,
  external_id text NOT NULL,
  content_hash text NOT NULL,
  fetched_at timestamptz NOT NULL DEFAULT now(),
  published_at timestamptz,
  url text NOT NULL,
  title text,
  author text,
  language text,
  raw_text text,
  payload jsonb NOT NULL,
  status text NOT NULL DEFAULT 'captured',
  inserted_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT raw_documents_status_check
    CHECK (status IN ('captured', 'parsed', 'rejected', 'archived'))
);

CREATE UNIQUE INDEX IF NOT EXISTS raw_documents_source_external_id_uidx
  ON raw_documents (source_registry_id, external_id);

CREATE UNIQUE INDEX IF NOT EXISTS raw_documents_source_content_hash_uidx
  ON raw_documents (source_registry_id, content_hash);

CREATE INDEX IF NOT EXISTS raw_documents_run_id_inserted_at_idx
  ON raw_documents (ingestion_run_id, inserted_at DESC);

CREATE INDEX IF NOT EXISTS raw_documents_published_at_idx
  ON raw_documents (published_at DESC);

CREATE TABLE IF NOT EXISTS canonical_feed_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  raw_document_id uuid REFERENCES raw_documents(id) ON DELETE SET NULL,
  source_registry_id uuid NOT NULL REFERENCES source_registry(id) ON DELETE RESTRICT,
  digest_date date NOT NULL,
  edition text NOT NULL,
  story_key text NOT NULL UNIQUE,
  headline text NOT NULL,
  summary text NOT NULL,
  canonical_url text NOT NULL,
  published_at timestamptz NOT NULL,
  tickers text[] NOT NULL DEFAULT '{}',
  regions text[] NOT NULL DEFAULT '{}',
  sectors text[] NOT NULL DEFAULT '{}',
  sentiment_label text NOT NULL DEFAULT 'neutral',
  relevance_score numeric(6,3),
  priority_rank integer,
  duplicate_group_key text,
  status text NOT NULL DEFAULT 'draft',
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  inserted_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT canonical_feed_items_edition_check
    CHECK (edition IN ('apac-open', 'europe-midday', 'us-close', 'breaking')),
  CONSTRAINT canonical_feed_items_sentiment_label_check
    CHECK (sentiment_label IN ('positive', 'neutral', 'negative', 'mixed')),
  CONSTRAINT canonical_feed_items_status_check
    CHECK (status IN ('draft', 'ready', 'published', 'suppressed'))
);

CREATE INDEX IF NOT EXISTS canonical_feed_items_digest_edition_rank_idx
  ON canonical_feed_items (digest_date, edition, priority_rank);

CREATE INDEX IF NOT EXISTS canonical_feed_items_source_published_at_idx
  ON canonical_feed_items (source_registry_id, published_at DESC);

CREATE INDEX IF NOT EXISTS canonical_feed_items_status_digest_idx
  ON canonical_feed_items (status, digest_date, edition);

CREATE TABLE IF NOT EXISTS domain_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  stream_key text NOT NULL,
  event_name text NOT NULL,
  aggregate_type text NOT NULL,
  aggregate_id text NOT NULL,
  event_version integer NOT NULL DEFAULT 1,
  causation_id uuid,
  correlation_id uuid,
  payload jsonb NOT NULL,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  published_at timestamptz,
  inserted_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS domain_events_stream_key_occurred_at_idx
  ON domain_events (stream_key, occurred_at DESC);

CREATE INDEX IF NOT EXISTS domain_events_aggregate_idx
  ON domain_events (aggregate_type, aggregate_id, occurred_at DESC);

CREATE INDEX IF NOT EXISTS domain_events_event_name_idx
  ON domain_events (event_name, occurred_at DESC);

CREATE TABLE IF NOT EXISTS domain_event_dispatches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  domain_event_id uuid NOT NULL REFERENCES domain_events(id) ON DELETE CASCADE,
  consumer_key text NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  attempts integer NOT NULL DEFAULT 0,
  last_attempt_at timestamptz,
  delivered_at timestamptz,
  last_error text,
  payload_snapshot jsonb NOT NULL DEFAULT '{}'::jsonb,
  inserted_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT domain_event_dispatches_status_check
    CHECK (status IN ('pending', 'dispatched', 'failed', 'skipped'))
);

CREATE UNIQUE INDEX IF NOT EXISTS domain_event_dispatches_event_consumer_uidx
  ON domain_event_dispatches (domain_event_id, consumer_key);

CREATE INDEX IF NOT EXISTS domain_event_dispatches_status_inserted_at_idx
  ON domain_event_dispatches (status, inserted_at DESC);
