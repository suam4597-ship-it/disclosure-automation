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
    field :adapter_key, :string
    field :region_code, :string
    field :discovery_mode, :string
    field :hydrate_mode, :string
    field :default_home_market_region_code, :string
    field :source_class, :string
    field :default_source_tier, :string
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
      :adapter_key,
      :region_code,
      :discovery_mode,
      :hydrate_mode,
      :default_home_market_region_code,
      :source_class,
      :default_source_tier,
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

defmodule DisclosureAutomation.Schema.SourceCursor do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias DisclosureAutomation.Schema.SourceRegistry

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "source_cursors" do
    belongs_to :source, SourceRegistry, foreign_key: :source_registry_id
    field :cursor_key, :string
    field :cursor_value, :string
    field :cursor_meta, :map, default: %{}
    field :last_polled_at, :utc_datetime_usec

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(cursor, attrs) do
    cursor
    |> cast(attrs, [
      :source_registry_id,
      :cursor_key,
      :cursor_value,
      :cursor_meta,
      :last_polled_at
    ])
    |> validate_required([:source_registry_id, :cursor_key])
    |> unique_constraint(:cursor_key, name: :source_cursors_source_key_uidx)
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
    field :document_identity, :string
    field :document_type, :string
    field :document_role, :string
    field :mime_type, :string
    field :content_hash, :string
    field :fetched_at, :utc_datetime_usec
    field :published_at, :utc_datetime_usec
    field :url, :string
    field :title, :string
    field :author, :string
    field :language, :string
    field :raw_text, :string
    field :payload, :map, default: %{}
    field :source_metadata, :map, default: %{}
    field :status, :string, default: "captured"

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(document, attrs) do
    document
    |> cast(attrs, [
      :ingestion_run_id,
      :source_registry_id,
      :external_id,
      :document_identity,
      :document_type,
      :document_role,
      :mime_type,
      :content_hash,
      :fetched_at,
      :published_at,
      :url,
      :title,
      :author,
      :language,
      :raw_text,
      :payload,
      :source_metadata,
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
    |> unique_constraint(:external_id, name: :raw_documents_source_external_id_partial_uidx)
    |> unique_constraint(:content_hash, name: :raw_documents_source_content_hash_uidx)
  end
end

defmodule DisclosureAutomation.Schema.RawEvent do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias DisclosureAutomation.Schema.RawDocument
  alias DisclosureAutomation.Schema.SourceRegistry

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "raw_events" do
    belongs_to :source, SourceRegistry, foreign_key: :source_registry_id
    belongs_to :raw_document, RawDocument
    field :event_key, :string
    field :external_event_key, :string
    field :parser_key, :string
    field :event_family, :string
    field :occurred_at, :utc_datetime_usec
    field :parsed_at, :utc_datetime_usec
    field :status, :string, default: "parsed"
    field :payload, :map, default: %{}
    field :metadata, :map, default: %{}

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :source_registry_id,
      :raw_document_id,
      :event_key,
      :external_event_key,
      :parser_key,
      :event_family,
      :occurred_at,
      :parsed_at,
      :status,
      :payload,
      :metadata
    ])
    |> validate_required([:source_registry_id, :event_key, :parser_key, :payload])
    |> unique_constraint(:event_key, name: :raw_events_source_event_key_uidx)
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
    field :event_id, :string
    field :region_code, :string
    field :home_market_region_code, :string
    field :canonical_event_type, :string
    field :event_family, :string
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
    field :contract_v1, :map, default: %{}

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [
      :raw_document_id,
      :source_registry_id,
      :event_id,
      :region_code,
      :home_market_region_code,
      :canonical_event_type,
      :event_family,
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
      :metadata,
      :contract_v1
    ])
    |> validate_required([
      :source_registry_id,
      :digest_date,
      :edition,
      :story_key,
      :headline,
      :summary,
      :canonical_url,
      :published_at,
      :contract_v1
    ])
    |> unique_constraint(:story_key)
    |> unique_constraint(:event_id)
  end
end

defmodule DisclosureAutomation.Schema.CanonicalItemSource do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias DisclosureAutomation.Schema.CanonicalFeedItem
  alias DisclosureAutomation.Schema.RawDocument
  alias DisclosureAutomation.Schema.RawEvent
  alias DisclosureAutomation.Schema.SourceRegistry

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "canonical_item_sources" do
    belongs_to :canonical_item, CanonicalFeedItem, foreign_key: :canonical_feed_item_id
    belongs_to :raw_event, RawEvent
    belongs_to :raw_document, RawDocument
    belongs_to :source, SourceRegistry, foreign_key: :source_registry_id
    field :source_name, :string
    field :source_tier, :string
    field :source_role, :string
    field :authority_rank, :integer
    field :is_representative, :boolean, default: false
    field :linked_at, :utc_datetime_usec
    field :promoted_at, :utc_datetime_usec
    field :metadata, :map, default: %{}

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(item_source, attrs) do
    item_source
    |> cast(attrs, [
      :canonical_feed_item_id,
      :raw_event_id,
      :raw_document_id,
      :source_registry_id,
      :source_name,
      :source_tier,
      :source_role,
      :authority_rank,
      :is_representative,
      :linked_at,
      :promoted_at,
      :metadata
    ])
    |> validate_required([
      :canonical_feed_item_id,
      :source_registry_id,
      :source_role
    ])
    |> unique_constraint(:canonical_feed_item_id,
      name: :canonical_item_sources_item_event_role_uidx
    )
    |> unique_constraint(:canonical_feed_item_id,
      name: :canonical_item_sources_single_representative_uidx
    )
  end
end

defmodule DisclosureAutomation.Schema.FeedSnapshot do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias DisclosureAutomation.Schema.IngestionRun

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "feed_snapshots" do
    belongs_to :ingestion_run, IngestionRun
    field :snapshot_key, :string
    field :slot_id, :string
    field :region_code, :string
    field :generated_at, :utc_datetime_usec
    field :item_event_ids, {:array, :string}, default: []
    field :payload, :map, default: %{}
    field :metadata, :map, default: %{}

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(snapshot, attrs) do
    snapshot
    |> cast(attrs, [
      :ingestion_run_id,
      :snapshot_key,
      :slot_id,
      :region_code,
      :generated_at,
      :item_event_ids,
      :payload,
      :metadata
    ])
    |> validate_required([:snapshot_key, :slot_id, :region_code, :generated_at, :payload])
    |> unique_constraint(:snapshot_key)
  end
end
