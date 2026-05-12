defmodule DisclosureAutomation.Repo.Migrations.CreateSourceRegistryAndDeliveryWindows do
  use Ecto.Migration

  def change do
    create table(:source_registry, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :source_key, :text, null: false
      add :display_name, :text, null: false
      add :source_type, :text, null: false
      add :base_url, :text, null: false
      add :healthcheck_url, :text
      add :parser_key, :text, null: false
      add :ranking_weight, :decimal, null: false, default: 1.0
      add :poll_cron, :text, null: false
      add :coverage_tags, {:array, :text}, null: false, default: []
      add :active, :boolean, null: false, default: true
      add :config, :map, null: false, default: %{}
      add :health_status, :text, null: false, default: "unknown"
      add :last_seen_published_at, :utc_datetime_usec
      add :last_success_at, :utc_datetime_usec
      add :last_failure_at, :utc_datetime_usec
      add :last_error, :text

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:source_registry, [:source_key])
    create index(:source_registry, [:active, :health_status])
    create index(:source_registry, [:source_type])

    create constraint(:source_registry, :source_registry_source_type_check,
             check: "source_type IN ('rss', 'atom', 'json_feed', 'html', 'api', 'email')"
           )

    create constraint(:source_registry, :source_registry_health_status_check,
             check: "health_status IN ('healthy', 'degraded', 'failed', 'paused', 'unknown')"
           )

    create table(:delivery_windows, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :window_key, :text, null: false
      add :edition, :text, null: false
      add :channel, :text, null: false
      add :timezone, :text, null: false
      add :weekdays, {:array, :integer}, null: false, default: [1, 2, 3, 4, 5]
      add :opens_at_local, :time, null: false
      add :closes_at_local, :time, null: false
      add :cutoff_minutes, :integer, null: false, default: 30
      add :active, :boolean, null: false, default: true
      add :config, :map, null: false, default: %{}

      timestamps(type: :utc_datetime_usec)
    end

    create unique_index(:delivery_windows, [:window_key])
    create index(:delivery_windows, [:active, :edition, :channel])

    create constraint(:delivery_windows, :delivery_windows_edition_check,
             check: "edition IN ('apac-open', 'europe-midday', 'us-close', 'breaking')"
           )

    create constraint(:delivery_windows, :delivery_windows_channel_check,
             check: "channel IN ('dashboard', 'email', 'slack', 'webhook')"
           )

    create constraint(:delivery_windows, :delivery_windows_cutoff_minutes_check,
             check: "cutoff_minutes >= 0"
           )

    create constraint(:delivery_windows, :delivery_windows_open_close_check,
             check: "opens_at_local < closes_at_local"
           )
  end
end
