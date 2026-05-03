defmodule DisclosureAutomation.Repo.Migrations.CreateStage61DuplicateGroupActionTables do
  use Ecto.Migration

  def change do
    create table(:source_duplicate_group_review_states, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :group_id, :string, null: false
      add :review_state, :string, null: false
      add :last_action_operation, :string
      add :last_action_request_id_hash, :string
      add :last_action_idempotency_key_hash, :string
      add :reviewed_by_actor_id_hash, :string
      add :reviewed_at, :utc_datetime_usec
      add :review_reason_redacted, :text
      add :redaction_status, :string, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:source_duplicate_group_review_states, [:group_id],
             name: :source_duplicate_group_review_states_group_id_unique_idx
           )

    create index(:source_duplicate_group_review_states, [:review_state],
             name: :source_duplicate_group_review_states_review_state_idx
           )

    create index(:source_duplicate_group_review_states, [:last_action_operation],
             name: :source_duplicate_group_review_states_last_action_operation_idx
           )

    create index(:source_duplicate_group_review_states, [:reviewed_by_actor_id_hash],
             name: :source_duplicate_group_review_states_actor_hash_idx
           )

    create index(:source_duplicate_group_review_states, [:redaction_status],
             name: :source_duplicate_group_review_states_redaction_status_idx
           )

    create table(:source_duplicate_group_action_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :group_id, :string, null: false
      add :action_operation, :string, null: false
      add :required_permission, :string, null: false
      add :actor_id_hash, :string, null: false
      add :request_id_hash, :string, null: false
      add :idempotency_key_hash, :string, null: false
      add :operator_reason_redacted, :text, null: false
      add :result_status, :string, null: false
      add :pre_review_state, :string
      add :post_review_state, :string
      add :failure_code, :string
      add :redaction_status, :string, null: false

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create unique_index(
             :source_duplicate_group_action_events,
             [:group_id, :action_operation, :actor_id_hash, :idempotency_key_hash],
             name: :source_duplicate_group_action_events_idempotency_unique_idx
           )

    create index(:source_duplicate_group_action_events, [:group_id],
             name: :source_duplicate_group_action_events_group_id_idx
           )

    create index(:source_duplicate_group_action_events, [:action_operation],
             name: :source_duplicate_group_action_events_action_operation_idx
           )

    create index(:source_duplicate_group_action_events, [:actor_id_hash],
             name: :source_duplicate_group_action_events_actor_hash_idx
           )

    create index(:source_duplicate_group_action_events, [:request_id_hash],
             name: :source_duplicate_group_action_events_request_hash_idx
           )

    create index(:source_duplicate_group_action_events, [:result_status],
             name: :source_duplicate_group_action_events_result_status_idx
           )

    create index(:source_duplicate_group_action_events, [:redaction_status],
             name: :source_duplicate_group_action_events_redaction_status_idx
           )
  end
end
