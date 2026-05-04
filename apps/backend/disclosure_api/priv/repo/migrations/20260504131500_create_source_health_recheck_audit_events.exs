defmodule DisclosureAutomation.Repo.Migrations.CreateSourceHealthRecheckAuditEvents do
  use Ecto.Migration

  def change do
    create table(:source_health_recheck_audit_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :source_key, :string, null: false
      add :route_operation, :string, null: false
      add :result_status, :string, null: false
      add :idempotency_status, :string, null: false
      add :actor_id_hash, :string
      add :request_id_hash, :string
      add :idempotency_key_hash, :string

      add :idempotency_key_id,
          references(:source_health_recheck_idempotency_keys,
            type: :binary_id,
            on_delete: :nilify_all
          )

      add :reason_redacted, :string
      add :redaction_status, :string
      add :occurred_at, :utc_datetime_usec, null: false
      add :metadata, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create index(:source_health_recheck_audit_events, [:source_key],
             name: :source_health_recheck_audit_source_key_idx
           )

    create index(:source_health_recheck_audit_events, [:route_operation],
             name: :source_health_recheck_audit_route_operation_idx
           )

    create index(:source_health_recheck_audit_events, [:result_status],
             name: :source_health_recheck_audit_result_status_idx
           )

    create index(:source_health_recheck_audit_events, [:idempotency_status],
             name: :source_health_recheck_audit_idem_status_idx
           )

    create index(:source_health_recheck_audit_events, [:occurred_at],
             name: :source_health_recheck_audit_occurred_at_idx
           )

    create index(:source_health_recheck_audit_events, [:idempotency_key_id],
             name: :source_health_recheck_audit_idem_key_id_idx
           )
  end
end
