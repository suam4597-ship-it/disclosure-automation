defmodule DisclosureAutomation.Repo.Migrations.CreateStage59DuplicateGroupTables do
  use Ecto.Migration

  def change do
    create table(:source_duplicate_groups, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :group_id, :string, null: false
      add :confidence, :string, null: false
      add :source_keys, :map, null: false
      add :match_reasons, :map, null: false
      add :member_count, :integer, null: false
      add :has_official_tdnet_event, :boolean, null: false, default: false
      add :has_provider_overlay, :boolean, null: false, default: false
      add :redaction_status, :string, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:source_duplicate_groups, [:group_id], name: :source_duplicate_groups_group_id_unique_idx)
    create index(:source_duplicate_groups, [:confidence], name: :source_duplicate_groups_confidence_idx)
    create index(:source_duplicate_groups, [:redaction_status], name: :source_duplicate_groups_redaction_status_idx)

    create table(:source_duplicate_group_members, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :group_id, :string, null: false
      add :member_id, :string, null: false
      add :member_kind, :string, null: false
      add :source_key, :string, null: false
      add :provider, :string
      add :external_id_hash, :string
      add :official_event_id, :string
      add :overlay_id, :string
      add :confidence, :string, null: false
      add :match_reasons, :map, null: false
      add :redaction_status, :string, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:source_duplicate_group_members, [:group_id, :member_id],
             name: :source_duplicate_group_members_group_member_unique_idx
           )

    create index(:source_duplicate_group_members, [:group_id], name: :source_duplicate_group_members_group_id_idx)
    create index(:source_duplicate_group_members, [:member_kind], name: :source_duplicate_group_members_member_kind_idx)
    create index(:source_duplicate_group_members, [:source_key], name: :source_duplicate_group_members_source_key_idx)
    create index(:source_duplicate_group_members, [:official_event_id], name: :source_duplicate_group_members_official_event_id_idx)
    create index(:source_duplicate_group_members, [:overlay_id], name: :source_duplicate_group_members_overlay_id_idx)
    create index(:source_duplicate_group_members, [:redaction_status], name: :source_duplicate_group_members_redaction_status_idx)
  end
end
