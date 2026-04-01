defmodule DisclosureAutomation.Repo.Migrations.CreateIngestionPipelineTables do
  use Ecto.Migration

  def up do
    create table(:ingestion_runs, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")

      add :source_registry_id, references(:source_registry, type: :uuid, on_delete: :restrict),
        null: false

      add :run_key, :string, null: false
      add :trigger_kind, :string, null: false
      add :status, :string, null: false
      add :request_url, :text
      add :source_cursor, :text
      add :queued_at, :utc_datetime_usec, null: false, default: fragment("now()")
      add :started_at, :utc_datetime_usec
      add :finished_at, :utc_datetime_usec
      add :http_status, :integer
      add :records_seen, :integer, default: 0, null: false
      add :records_inserted, :integer, default: 0, null: false
      add :records_updated, :integer, default: 0, null: false
      add :records_rejected, :integer, default: 0, null: false
      add :checksum, :string
      add :error_code, :string
      add :error_message, :text
      add :meta, :map, default: %{}, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:ingestion_runs, [:run_key])
    create index(:ingestion_runs, [:source_registry_id, :inserted_at])
    create index(:ingestion_runs, [:status, :inserted_at])

    create constraint(:ingestion_runs, :ingestion_runs_trigger_kind_check,
             check: "trigger_kind in ('scheduled', 'manual', 'replay', 'backfill')"
           )

    create constraint(:ingestion_runs, :ingestion_runs_status_check,
             check:
               "status in ('queued', 'running', 'succeeded', 'failed', 'partial', 'cancelled')"
           )

    create table(:raw_documents, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")

      add :ingestion_run_id, references(:ingestion_runs, type: :uuid, on_delete: :delete_all),
        null: false

      add :source_registry_id, references(:source_registry, type: :uuid, on_delete: :restrict),
        null: false

      add :external_id, :string, null: false
      add :content_hash, :string, null: false
      add :fetched_at, :utc_datetime_usec, null: false, default: fragment("now()")
      add :published_at, :utc_datetime_usec
      add :url, :text, null: false
      add :title, :text
      add :author, :string
      add :language, :string
      add :raw_text, :text
      add :payload, :map, null: false
      add :status, :string, default: "captured", null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:raw_documents, [:source_registry_id, :external_id],
             name: :raw_documents_source_external_id_uidx
           )

    create unique_index(:raw_documents, [:source_registry_id, :content_hash],
             name: :raw_documents_source_content_hash_uidx
           )

    create index(:raw_documents, [:ingestion_run_id, :inserted_at])
    create index(:raw_documents, [:published_at])

    create constraint(:raw_documents, :raw_documents_status_check,
             check: "status in ('captured', 'parsed', 'rejected', 'archived')"
           )

    create table(:canonical_feed_items, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :raw_document_id, references(:raw_documents, type: :uuid, on_delete: :nilify_all)

      add :source_registry_id, references(:source_registry, type: :uuid, on_delete: :restrict),
        null: false

      add :digest_date, :date, null: false
      add :edition, :string, null: false
      add :story_key, :string, null: false
      add :headline, :text, null: false
      add :summary, :text, null: false
      add :canonical_url, :text, null: false
      add :published_at, :utc_datetime_usec, null: false
      add :tickers, {:array, :string}, default: [], null: false
      add :regions, {:array, :string}, default: [], null: false
      add :sectors, {:array, :string}, default: [], null: false
      add :sentiment_label, :string, default: "neutral", null: false
      add :relevance_score, :decimal, precision: 6, scale: 3
      add :priority_rank, :integer
      add :duplicate_group_key, :string
      add :status, :string, default: "draft", null: false
      add :metadata, :map, default: %{}, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:canonical_feed_items, [:story_key])
    create index(:canonical_feed_items, [:digest_date, :edition, :priority_rank])
    create index(:canonical_feed_items, [:source_registry_id, :published_at])
    create index(:canonical_feed_items, [:status, :digest_date, :edition])

    create constraint(:canonical_feed_items, :canonical_feed_items_edition_check,
             check: "edition in ('apac-open', 'europe-midday', 'us-close', 'breaking')"
           )

    create constraint(:canonical_feed_items, :canonical_feed_items_sentiment_label_check,
             check: "sentiment_label in ('positive', 'neutral', 'negative', 'mixed')"
           )

    create constraint(:canonical_feed_items, :canonical_feed_items_status_check,
             check: "status in ('draft', 'ready', 'published', 'suppressed')"
           )
  end

  def down do
    drop_if_exists table(:canonical_feed_items)
    drop_if_exists table(:raw_documents)
    drop_if_exists table(:ingestion_runs)
  end
end
