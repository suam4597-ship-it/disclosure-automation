defmodule DisclosureAutomation.Repo.Migrations.ExtendRuntimeSpineForSecVerticalSlice do
  use Ecto.Migration

  def change do
    alter table(:source_registry) do
      add :adapter_key, :text
      add :region_code, :text
      add :discovery_mode, :text
      add :hydrate_mode, :text
      add :default_home_market_region_code, :text
      add :source_class, :text
      add :default_source_tier, :text
    end

    create_if_not_exists index(:source_registry, [:region_code])
    create_if_not_exists index(:source_registry, [:adapter_key])

    alter table(:raw_documents) do
      add :document_identity, :text
      add :document_type, :text
      add :document_role, :text
      add :mime_type, :text
      add :source_metadata, :map, null: false, default: %{}
    end

    create_if_not_exists index(:raw_documents, [:source_registry_id, :document_role])
    create_if_not_exists index(:raw_documents, [:source_registry_id, :document_identity])

    create unique_index(:raw_documents, [:source_registry_id, :external_id],
             where: "external_id IS NOT NULL",
             name: :raw_documents_source_external_id_partial_uidx
           )

    create unique_index(:raw_documents, [:source_registry_id, :document_identity, :document_type],
             where: "document_identity IS NOT NULL",
             name: :raw_documents_source_event_doc_kind_uidx
           )

    create table(:source_cursors, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")

      add :source_registry_id, references(:source_registry, type: :uuid, on_delete: :delete_all),
        null: false

      add :cursor_key, :text, null: false
      add :cursor_value, :text
      add :cursor_meta, :map, null: false, default: %{}
      add :last_polled_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:source_cursors, [:source_registry_id, :cursor_key],
             name: :source_cursors_source_key_uidx
           )

    create table(:raw_events, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")

      add :source_registry_id, references(:source_registry, type: :uuid, on_delete: :restrict),
        null: false

      add :raw_document_id, references(:raw_documents, type: :uuid, on_delete: :nilify_all)
      add :event_key, :text, null: false
      add :external_event_key, :text
      add :parser_key, :text, null: false
      add :event_family, :text
      add :occurred_at, :utc_datetime_usec
      add :parsed_at, :utc_datetime_usec
      add :status, :text, null: false, default: "parsed"
      add :payload, :map, null: false, default: %{}
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:raw_events, [:source_registry_id, :event_key],
             name: :raw_events_source_event_key_uidx
           )

    alter table(:canonical_feed_items) do
      add :event_id, :text
      add :region_code, :text
      add :home_market_region_code, :text
      add :canonical_event_type, :text
      add :event_family, :text
      add :contract_v1, :map, null: false, default: %{}
    end

    create unique_index(:canonical_feed_items, [:event_id])
    create_if_not_exists index(:canonical_feed_items, [:region_code, :published_at])

    create table(:canonical_item_sources, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")

      add :canonical_feed_item_id,
          references(:canonical_feed_items, type: :uuid, on_delete: :delete_all),
          null: false

      add :raw_event_id, references(:raw_events, type: :uuid, on_delete: :nilify_all)
      add :raw_document_id, references(:raw_documents, type: :uuid, on_delete: :nilify_all)

      add :source_registry_id, references(:source_registry, type: :uuid, on_delete: :restrict),
        null: false

      add :source_name, :text
      add :source_tier, :text
      add :source_role, :text, null: false
      add :authority_rank, :integer
      add :is_representative, :boolean, null: false, default: false
      add :linked_at, :utc_datetime_usec
      add :promoted_at, :utc_datetime_usec
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(
             :canonical_item_sources,
             [:canonical_feed_item_id, :raw_event_id, :source_role],
             name: :canonical_item_sources_item_event_role_uidx
           )

    create unique_index(:canonical_item_sources, [:canonical_feed_item_id],
             where: "is_representative = true",
             name: :canonical_item_sources_single_representative_uidx
           )

    create table(:feed_snapshots, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :ingestion_run_id, references(:ingestion_runs, type: :uuid, on_delete: :nilify_all)
      add :snapshot_key, :text, null: false
      add :slot_id, :text, null: false
      add :region_code, :text, null: false
      add :generated_at, :utc_datetime_usec, null: false
      add :item_event_ids, {:array, :text}, null: false, default: []
      add :payload, :map, null: false, default: %{}
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:feed_snapshots, [:snapshot_key])
    create_if_not_exists index(:feed_snapshots, [:slot_id, :generated_at])
  end
end
