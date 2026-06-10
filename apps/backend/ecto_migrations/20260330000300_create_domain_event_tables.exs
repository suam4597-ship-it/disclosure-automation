defmodule DisclosureAutomation.Repo.Migrations.CreateDomainEventTables do
  use Ecto.Migration

  def up do
    create table(:domain_events, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :stream_key, :string, null: false
      add :event_name, :string, null: false
      add :aggregate_type, :string, null: false
      add :aggregate_id, :string, null: false
      add :event_version, :integer, default: 1, null: false
      add :causation_id, :uuid
      add :correlation_id, :uuid
      add :payload, :map, null: false
      add :metadata, :map, default: %{}, null: false
      add :occurred_at, :utc_datetime_usec, null: false, default: fragment("now()")
      add :published_at, :utc_datetime_usec

      timestamps(type: :utc_datetime_usec)
    end

    create index(:domain_events, [:stream_key, :occurred_at])
    create index(:domain_events, [:aggregate_type, :aggregate_id, :occurred_at])
    create index(:domain_events, [:event_name, :occurred_at])

    create table(:domain_event_dispatches, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :domain_event_id, references(:domain_events, type: :uuid, on_delete: :delete_all), null: false
      add :consumer_key, :string, null: false
      add :status, :string, default: "pending", null: false
      add :attempts, :integer, default: 0, null: false
      add :last_attempt_at, :utc_datetime_usec
      add :delivered_at, :utc_datetime_usec
      add :last_error, :text
      add :payload_snapshot, :map, default: %{}, null: false

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:domain_event_dispatches, [:domain_event_id, :consumer_key],
             name: :domain_event_dispatches_event_consumer_uidx
           )

    create index(:domain_event_dispatches, [:status, :inserted_at])

    create constraint(:domain_event_dispatches, :domain_event_dispatches_status_check,
             check: "status in ('pending', 'dispatched', 'failed', 'skipped')"
           )
  end

  def down do
    drop_if_exists table(:domain_event_dispatches)
    drop_if_exists table(:domain_events)
  end
end
