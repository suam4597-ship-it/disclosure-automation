defmodule DisclosureAutomation.Repo.Migrations.CreateSourceHealthPollAuditEvents do
  use Ecto.Migration

  def change do
    create table(:source_health_poll_audit_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :source_key, :string, null: false
      add :route_operation, :string, null: false
      add :result_status, :string, null: false
      add :idempotency_status, :string, null: false, default: "none"
      add :rate_limit_status, :string, null: false, default: "none"
      add :actor_id_hash, :string
      add :request_id_hash, :string
      add :idempotency_key_hash, :string
      add :idempotency_key_id, :binary_id
      add :rate_limit_key_id, :binary_id
      add :reason_redacted, :string
      add :redaction_status, :string
      add :occurred_at, :utc_datetime_usec, null: false
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create index(:source_health_poll_audit_events, [:source_key],
             name: :sh_poll_audit_source_key_idx
           )

    create index(:source_health_poll_audit_events, [:route_operation],
             name: :sh_poll_audit_route_operation_idx
           )

    create index(:source_health_poll_audit_events, [:result_status],
             name: :sh_poll_audit_result_status_idx
           )

    create index(:source_health_poll_audit_events, [:idempotency_status],
             name: :sh_poll_audit_idem_status_idx
           )

    create index(:source_health_poll_audit_events, [:rate_limit_status],
             name: :sh_poll_audit_rate_status_idx
           )

    create index(:source_health_poll_audit_events, [:occurred_at],
             name: :sh_poll_audit_occurred_at_idx
           )

    create index(:source_health_poll_audit_events, [:idempotency_key_id],
             name: :sh_poll_audit_idem_key_id_idx
           )

    create index(:source_health_poll_audit_events, [:rate_limit_key_id],
             name: :sh_poll_audit_rate_key_id_idx
           )
  end
end
