defmodule DisclosureAutomation.Repo.Migrations.CreateNewsOverlayAttachments do
  use Ecto.Migration

  def change do
    create table(:news_overlay_attachments, primary_key: false) do
      add :id, :uuid, primary_key: true

      add :official_canonical_feed_item_id,
          references(:canonical_feed_items, type: :uuid, on_delete: :restrict),
          null: false

      add :official_event_id, :text, null: false
      add :official_stable_external_id, :text

      add :overlay_source_registry_id,
          references(:source_registry, type: :uuid, on_delete: :nilify_all)

      add :overlay_source_key, :text, null: false
      add :overlay_provider, :text, null: false
      add :overlay_external_id, :text, null: false

      add :overlay_raw_document_id,
          references(:raw_documents, type: :uuid, on_delete: :nilify_all)

      add :overlay_raw_event_id,
          references(:raw_events, type: :uuid, on_delete: :nilify_all)

      add :overlay_id, :text, null: false
      add :overlay_mode, :text, null: false
      add :display_state, :text, null: false
      add :canonical_fact_override, :boolean, null: false, default: false
      add :source_tier, :text, null: false
      add :document_role, :text, null: false
      add :published_at, :utc_datetime_usec
      add :url, :text
      add :title, :text
      add :language, :text
      add :jurisdiction, :text
      add :overlay_payload, :map, null: false, default: fragment("'{}'::jsonb")
      add :conflict_flags, :map, null: false, default: fragment("'{\"items\": []}'::jsonb")
      add :overlay_claims, :map, null: false, default: fragment("'{\"items\": []}'::jsonb")
      add :citations, :map, null: false, default: fragment("'{\"items\": []}'::jsonb")

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(
             :news_overlay_attachments,
             [:official_canonical_feed_item_id, :overlay_source_key, :overlay_external_id],
             name: :news_overlay_attachments_official_overlay_external_id_uidx
           )

    create unique_index(
             :news_overlay_attachments,
             [:official_event_id, :overlay_id],
             name: :news_overlay_attachments_official_event_overlay_id_uidx
           )

    create index(:news_overlay_attachments, [:official_canonical_feed_item_id],
             name: :news_overlay_attachments_official_item_idx
           )

    create index(:news_overlay_attachments, [:official_event_id],
             name: :news_overlay_attachments_official_event_idx
           )

    create index(:news_overlay_attachments, [:overlay_source_key, :overlay_external_id],
             name: :news_overlay_attachments_overlay_identity_idx
           )

    create index(:news_overlay_attachments, [:official_canonical_feed_item_id, :display_state],
             name: :news_overlay_attachments_display_idx
           )

    create index(:news_overlay_attachments, [:published_at],
             name: :news_overlay_attachments_published_at_idx
           )

    create constraint(:news_overlay_attachments, :news_overlay_attachments_no_canonical_override,
             check: "canonical_fact_override = false"
           )

    create constraint(:news_overlay_attachments, :news_overlay_attachments_attach_only,
             check: "overlay_mode = 'attach_only'"
           )

    create constraint(:news_overlay_attachments, :news_overlay_attachments_display_state_allowed,
             check:
               "display_state in ('visible', 'hidden_missing_direct_official_identifier', 'hidden_conflict_requires_review', 'hidden_full_text_policy', 'hidden_source_not_allowed')"
           )

    create constraint(:news_overlay_attachments, :news_overlay_attachments_source_tier_allowed,
             check: "source_tier = 'reputable_news_source'"
           )

    create constraint(:news_overlay_attachments, :news_overlay_attachments_document_role_allowed,
             check: "document_role = 'news_article'"
           )

    create constraint(:news_overlay_attachments, :news_overlay_attachments_required_text_present,
             check:
               "official_event_id <> '' and overlay_source_key <> '' and overlay_provider <> '' and overlay_external_id <> '' and overlay_id <> ''"
           )
  end
end
