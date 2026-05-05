defmodule DisclosureAutomation.Repo.Migrations.CreateSourceHealthPollIdempotencyAndRateLimits do
  use Ecto.Migration

  def change do
    create table(:source_health_poll_idempotency_keys, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :source_key, :string, null: false
      add :idempotency_key_hash, :string, null: false
      add :request_id_hash, :string
      add :actor_id_hash, :string
      add :status, :string, null: false, default: "accepted"
      add :rate_limit_status, :string, null: false, default: "allowed"
      add :expires_at, :utc_datetime_usec, null: false
      add :last_seen_at, :utc_datetime_usec
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:source_health_poll_idempotency_keys, [
             :source_key,
             :idempotency_key_hash
           ],
             name: :sh_poll_idem_source_key_hash_uidx
           )

    create index(:source_health_poll_idempotency_keys, [:source_key],
             name: :sh_poll_idem_source_key_idx
           )

    create index(:source_health_poll_idempotency_keys, [:expires_at],
             name: :sh_poll_idem_expires_at_idx
           )

    create index(:source_health_poll_idempotency_keys, [:status],
             name: :sh_poll_idem_status_idx
           )

    create index(:source_health_poll_idempotency_keys, [:rate_limit_status],
             name: :sh_poll_idem_rate_status_idx
           )

    create table(:source_health_poll_rate_limits, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :scope, :string, null: false
      add :scope_key, :string, null: false
      add :source_key, :string
      add :actor_id_hash, :string
      add :status, :string, null: false, default: "allowed"
      add :request_count, :integer, null: false, default: 0
      add :limit_count, :integer, null: false
      add :window_start_at, :utc_datetime_usec, null: false
      add :window_expires_at, :utc_datetime_usec, null: false
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:source_health_poll_rate_limits, [
             :scope,
             :scope_key,
             :window_start_at
           ],
             name: :sh_poll_rate_scope_key_window_uidx
           )

    create index(:source_health_poll_rate_limits, [:scope],
             name: :sh_poll_rate_scope_idx
           )

    create index(:source_health_poll_rate_limits, [:scope_key],
             name: :sh_poll_rate_scope_key_idx
           )

    create index(:source_health_poll_rate_limits, [:window_expires_at],
             name: :sh_poll_rate_window_expires_idx
           )

    create index(:source_health_poll_rate_limits, [:status],
             name: :sh_poll_rate_status_idx
           )
  end
end
