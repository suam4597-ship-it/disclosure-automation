defmodule DisclosureAutomation.Repo.Migrations.CreateSourceHealthRecheckIdempotencyKeys do
  use Ecto.Migration

  def change do
    create table(:source_health_recheck_idempotency_keys, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :source_key, :string, null: false
      add :idempotency_key_hash, :string, null: false
      add :request_id_hash, :string
      add :actor_id_hash, :string
      add :status, :string, null: false, default: "accepted"
      add :job_reference, :map, null: false, default: %{}
      add :expires_at, :utc_datetime_usec, null: false
      add :last_seen_at, :utc_datetime_usec
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:source_health_recheck_idempotency_keys, [
             :source_key,
             :idempotency_key_hash
           ],
             name: :source_health_recheck_idem_source_key_hash_uidx
           )

    create index(:source_health_recheck_idempotency_keys, [:source_key],
             name: :source_health_recheck_idem_source_key_idx
           )

    create index(:source_health_recheck_idempotency_keys, [:expires_at],
             name: :source_health_recheck_idem_expires_at_idx
           )

    create index(:source_health_recheck_idempotency_keys, [:status],
             name: :source_health_recheck_idem_status_idx
           )
  end
end
