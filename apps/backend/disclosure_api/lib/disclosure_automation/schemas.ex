defmodule DisclosureAutomation.Schema.SourceRegistry do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "source_registry" do
    field :source_key, :string
    field :display_name, :string
    field :source_type, :string
    field :base_url, :string
    field :healthcheck_url, :string
    field :parser_key, :string
    field :ranking_weight, :decimal
    field :poll_cron, :string
    field :coverage_tags, {:array, :string}, default: []
    field :active, :boolean, default: true
    field :config, :map, default: %{}
    field :health_status, :string, default: "unknown"
    field :last_seen_published_at, :utc_datetime_usec
    field :last_success_at, :utc_datetime_usec
    field :last_failure_at, :utc_datetime_usec
    field :last_error, :string

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(source, attrs) do
    source
    |> cast(attrs, [
      :source_key,
      :display_name,
      :source_type,
      :base_url,
      :healthcheck_url,
      :parser_key,
      :ranking_weight,
      :poll_cron,
      :coverage_tags,
      :active,
      :config,
      :health_status,
      :last_seen_published_at,
      :last_success_at,
      :last_failure_at,
      :last_error
    ])
    |> validate_required([
      :source_key,
      :display_name,
      :source_type,
      :base_url,
      :parser_key,
      :poll_cron
    ])
    |> unique_constraint(:source_key)
  end
end

defmodule DisclosureAutomation.Schema.DeliveryWindow do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "delivery_windows" do
    field :window_key, :string
    field :edition, :string
    field :channel, :string
    field :timezone, :string
    field :weekdays, {:array, :integer}, default: [1, 2, 3, 4, 5]
    field :opens_at_local, :time
    field :closes_at_local, :time
    field :cutoff_minutes, :integer, default: 30
    field :active, :boolean, default: true
    field :config, :map, default: %{}

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(window, attrs) do
    window
    |> cast(attrs, [
      :window_key,
      :edition,
      :channel,
      :timezone,
      :weekdays,
      :opens_at_local,
      :closes_at_local,
      :cutoff_minutes,
      :active,
      :config
    ])
    |> validate_required([
      :window_key,
      :edition,
      :channel,
      :timezone,
      :weekdays,
      :opens_at_local,
      :closes_at_local
    ])
    |> unique_constraint(:window_key)
  end
end

defmodule DisclosureAutomation.Schema.IngestionRun do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias DisclosureAutomation.Schema.SourceRegistry

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "ingestion_runs" do
    belongs_to :source, SourceRegistry, foreign_key: :source_registry_id
    field :run_key, :string
    field :trigger_kind, :string
    field :status, :string
    field :request_url, :string
    field :source_cursor, :string
    field :queued_at, :utc_datetime_usec
    field :started_at, :utc_datetime_usec
    field :finished_at, :utc_datetime_usec
    field :http_status, :integer
    field :records_seen, :integer, default: 0
    field :records_inserted, :integer, default: 0
    field :records_updated, :integer, default: 0
    field :records_rejected, :integer, default: 0
    field :checksum, :string
    field :error_code, :string
    field :error_message, :string
    field :meta, :map, default: %{}

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(run, attrs) do
    run
    |> cast(attrs, [
      :source_registry_id,
      :run_key,
      :trigger_kind,
      :status,
      :request_url,
      :source_cursor,
      :queued_at,
      :started_at,
      :finished_at,
      :http_status,
      :records_seen,
      :records_inserted,
      :records_updated,
      :records_rejected,
      :checksum,
      :error_code,
      :error_message,
      :meta
    ])
    |> validate_required([:source_registry_id, :run_key, :trigger_kind, :status])
    |> unique_constraint(:run_key)
  end
end

defmodule DisclosureAutomation.Schema.RawDocument do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias DisclosureAutomation.Schema.IngestionRun
  alias DisclosureAutomation.Schema.SourceRegistry

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "raw_documents" do
    belongs_to :ingestion_run, IngestionRun
    belongs_to :source, SourceRegistry, foreign_key: :source_registry_id
    field :external_id, :string
    field :content_hash, :string
    field :fetched_at, :utc_datetime_usec
    field :published_at, :utc_datetime_usec
    field :url, :string
    field :title, :string
    field :author, :string
    field :language, :string
    field :raw_text, :string
    field :payload, :map, default: %{}
    field :status, :string, default: "captured"

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(document, attrs) do
    document
    |> cast(attrs, [
      :ingestion_run_id,
      :source_registry_id,
      :external_id,
      :content_hash,
      :fetched_at,
      :published_at,
      :url,
      :title,
      :author,
      :language,
      :raw_text,
      :payload,
      :status
    ])
    |> validate_required([
      :ingestion_run_id,
      :source_registry_id,
      :external_id,
      :content_hash,
      :url,
      :payload
    ])
    |> unique_constraint(:external_id, name: :raw_documents_source_external_id_uidx)
    |> unique_constraint(:content_hash, name: :raw_documents_source_content_hash_uidx)
  end
end

defmodule DisclosureAutomation.Schema.CanonicalFeedItem do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias DisclosureAutomation.Schema.RawDocument
  alias DisclosureAutomation.Schema.SourceRegistry

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "canonical_feed_items" do
    belongs_to :raw_document, RawDocument
    belongs_to :source, SourceRegistry, foreign_key: :source_registry_id
    field :digest_date, :date
    field :edition, :string
    field :story_key, :string
    field :headline, :string
    field :summary, :string
    field :canonical_url, :string
    field :published_at, :utc_datetime_usec
    field :tickers, {:array, :string}, default: []
    field :regions, {:array, :string}, default: []
    field :sectors, {:array, :string}, default: []
    field :sentiment_label, :string, default: "neutral"
    field :relevance_score, :decimal
    field :priority_rank, :integer
    field :duplicate_group_key, :string
    field :status, :string, default: "draft"
    field :metadata, :map, default: %{}

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [
      :raw_document_id,
      :source_registry_id,
      :digest_date,
      :edition,
      :story_key,
      :headline,
      :summary,
      :canonical_url,
      :published_at,
      :tickers,
      :regions,
      :sectors,
      :sentiment_label,
      :relevance_score,
      :priority_rank,
      :duplicate_group_key,
      :status,
      :metadata
    ])
    |> validate_required([
      :source_registry_id,
      :digest_date,
      :edition,
      :story_key,
      :headline,
      :summary,
      :canonical_url,
      :published_at
    ])
    |> unique_constraint(:story_key)
  end
end
