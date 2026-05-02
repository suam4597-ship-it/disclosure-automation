defmodule DisclosureAutomation.Runtime.Stage54OfflineProviderRawStaging do
  @moduledoc false

  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Runtime.Stage54ProviderIngestionBoundary
  alias DisclosureAutomation.Schema.SourceRegistry
  alias DisclosureAutomation.Sources

  @source_key "stage54_offline_provider_fixture"
  @cursor_key "latest_offline_provider_article_seen"

  def source_key, do: @source_key
  def cursor_key, do: @cursor_key

  def stage_once(provider_payload, opts \\ [])

  def stage_once(provider_payload, opts) when is_map(provider_payload) do
    with {:ok, source} <- ensure_source(opts),
         {:ok, normalized} <- Stage54ProviderIngestionBoundary.normalize_result(provider_payload, opts),
         {:ok, article_published_at} <- parse_datetime(normalized.published_at),
         {:ok, ingestion_run_id} <- create_ingestion_run(source, normalized),
         {:ok, _raw_document} <- upsert_raw_document(source, normalized, article_published_at, ingestion_run_id),
         {:ok, _raw_event} <- upsert_raw_event(source, normalized, article_published_at, ingestion_run_id),
         {:ok, _cursor} <- Sources.upsert_source_cursor(source, @cursor_key, cursor_value(normalized), cursor_meta(normalized)),
         {:ok, _source} <- Sources.mark_poll_success(source, article_published_at) do
      {:ok,
       %{
         source_key: @source_key,
         records_seen: 1,
         mode: "offline_provider_raw_staging",
         use_live_fetch: false,
         network_access: "forbidden",
         scheduler_enabled: false,
         canonical_feed_mutation: false,
         news_only_event_creation: false,
         canonical_fact_override: false,
         article_external_id: normalized.article_external_id,
         overlay_id: overlay_id(normalized),
         raw_document_external_id: raw_document_external_id(normalized),
         raw_event_external_id: raw_event_external_id(normalized),
         ingestion_run_id: ingestion_run_id,
         cursor_key: @cursor_key,
         cursor_value: cursor_value(normalized)
       }}
    end
  rescue
    error ->
      maybe_mark_failure(error)
      reraise error, __STACKTRACE__
  end

  def stage_once(_provider_payload, _opts), do: {:error, :invalid_provider_payload}

  defp ensure_source(opts) do
    case Keyword.get(opts, :source) do
      %SourceRegistry{} = source ->
        {:ok, source}

      nil ->
        with {:ok, _source} <- Sources.upsert_source(source_attrs()) do
          Sources.get_source_by_key(@source_key)
        end
    end
  end

  defp source_attrs do
    %{
      "source_key" => @source_key,
      "display_name" => "Stage 5.4 Offline Provider Fixture",
      "source_type" => "api",
      "adapter_key" => "stage54_offline_provider_fixture_v1",
      "region_code" => "jp",
      "discovery_mode" => "fixture",
      "hydrate_mode" => "local_fixture",
      "default_home_market_region_code" => "jp",
      "source_class" => "regulatory_filing_feed",
      "default_source_tier" => "reputable_news_source",
      "base_url" => "https://example.com/offline-provider",
      "healthcheck_url" => "https://example.com/",
      "parser_key" => "stage54_offline_provider_fixture_v1",
      "poll_cron" => "*/15 * * * *",
      "coverage_tags" => ["jp", "news_overlay", "offline_provider", "stage54"],
      "active" => true,
      "config" => %{
        "overlay_mode" => "attach_only",
        "storage_mode" => "raw_staging",
        "use_live_fetch" => false,
        "network_access" => "forbidden",
        "scheduler_enabled" => false,
        "canonical_feed_mutation" => false,
        "news_only_event_creation" => false
      }
    }
  end

  defp create_ingestion_run(%SourceRegistry{} = source, normalized) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    run_id = Ecto.UUID.generate()

    attrs = %{
      "id" => run_id,
      "run_key" => "#{@source_key}:offline_raw_staging:#{run_id}",
      "source_registry_id" => source.id,
      "source_key" => @source_key,
      "trigger_kind" => "manual",
      "edition" => "breaking",
      "status" => allowed_ingestion_run_status(),
      "started_at" => now,
      "completed_at" => now,
      "records_seen" => 1,
      "raw_documents_count" => 1,
      "raw_events_count" => 1,
      "canonical_items_count" => 0,
      "use_live_fetch" => false,
      "inline_feed" => false,
      "metadata" => %{
        "mode" => "offline_provider_raw_staging",
        "source_key" => @source_key,
        "overlay_id" => overlay_id(normalized),
        "article_external_id" => normalized.article_external_id,
        "canonical_event_id" => normalized.canonical_event_id,
        "canonical_feed_mutation" => false,
        "news_only_event_creation" => false,
        "network_access" => "forbidden",
        "scheduler_enabled" => false
      },
      "inserted_at" => now,
      "updated_at" => now
    }

    insert_dynamic("ingestion_runs", attrs)
  end

  defp upsert_raw_document(%SourceRegistry{} = source, normalized, published_at, ingestion_run_id) do
    external_id = raw_document_external_id(normalized)
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    attrs = %{
      "id" => Ecto.UUID.generate(),
      "ingestion_run_id" => ingestion_run_id,
      "source_registry_id" => source.id,
      "external_id" => external_id,
      "document_identity" => external_id,
      "document_type" => "stage54_offline_provider_article_metadata",
      "document_role" => "news_article",
      "mime_type" => "application/json",
      "url" => normalized.url,
      "payload" => raw_document_payload(normalized),
      "content_hash" => raw_document_content_hash(normalized),
      "published_at" => published_at,
      "inserted_at" => now,
      "updated_at" => now
    }

    case lookup_id("raw_documents", source.id, external_id) do
      {:ok, nil} -> insert_dynamic("raw_documents", attrs)
      {:ok, id} -> update_dynamic("raw_documents", id, Map.delete(attrs, "id"))
    end
  end

  defp upsert_raw_event(%SourceRegistry{} = source, normalized, occurred_at, ingestion_run_id) do
    external_id = raw_event_external_id(normalized)
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    payload = %{
      "overlay_id" => overlay_id(normalized),
      "article_external_id" => normalized.article_external_id,
      "canonical_event_id" => normalized.canonical_event_id,
      "source_key" => normalized.source_key,
      "source_tier" => normalized.source_tier,
      "document_role" => normalized.document_role,
      "source_name" => normalized.provider,
      "source_url" => normalized.url,
      "article_title" => normalized.title,
      "article_published_at" => normalized.published_at,
      "article_language" => normalized.language,
      "jurisdiction" => normalized.jurisdiction,
      "overlay_claims" => normalized.overlay_claims,
      "match_evidence" => match_evidence(normalized),
      "citations" => normalized.citations,
      "diagnostics" => normalized.diagnostics,
      "conflict_flags" => [],
      "official_anchor" => official_anchor(normalized),
      "canonical_feed_mutation" => false,
      "news_only_event_creation" => false,
      "canonical_fact_override" => false,
      "network_access" => "forbidden",
      "scheduler_enabled" => false
    }

    attrs = %{
      "id" => Ecto.UUID.generate(),
      "ingestion_run_id" => ingestion_run_id,
      "source_registry_id" => source.id,
      "event_key" => external_id,
      "external_event_key" => external_id,
      "parser_key" => "stage54_offline_provider_fixture_v1",
      "event_family" => "news_overlay_update",
      "occurred_at" => occurred_at,
      "status" => "staged",
      "payload" => payload,
      "metadata" => %{
        "mode" => "offline_provider_raw_staging",
        "source_key" => @source_key,
        "article_external_id" => normalized.article_external_id,
        "overlay_id" => overlay_id(normalized),
        "canonical_event_id" => normalized.canonical_event_id,
        "canonical_feed_mutation" => false,
        "news_only_event_creation" => false,
        "network_access" => "forbidden",
        "scheduler_enabled" => false
      },
      "inserted_at" => now,
      "updated_at" => now
    }

    case lookup_raw_event_id(source.id, external_id) do
      {:ok, nil} -> insert_dynamic("raw_events", attrs)
      {:ok, id} -> update_dynamic("raw_events", id, Map.delete(attrs, "id"))
    end
  end

  defp lookup_id(table, source_registry_id, external_id) when table in ["raw_documents"] do
    result =
      Repo.query!(
        "select id from #{table} where source_registry_id = $1 and external_id = $2 limit 1",
        [uuid_param(source_registry_id), external_id]
      )

    case result.rows do
      [[id]] -> {:ok, id}
      [] -> {:ok, nil}
    end
  end

  defp lookup_raw_event_id(source_registry_id, external_event_key) do
    result =
      Repo.query!(
        "select id from raw_events where source_registry_id = $1 and external_event_key = $2 limit 1",
        [uuid_param(source_registry_id), external_event_key]
      )

    case result.rows do
      [[id]] -> {:ok, id}
      [] -> {:ok, nil}
    end
  end

  defp insert_dynamic(table, attrs) do
    columns = table_columns(table)
    insert_attrs = Enum.filter(attrs, fn {column, _value} -> Map.has_key?(columns, column) end)
    {column_names, _values} = Enum.unzip(insert_attrs)

    placeholders =
      column_names
      |> Enum.with_index(1)
      |> Enum.map(fn {column, idx} -> placeholder(idx, columns[column]) end)

    sql = "insert into #{table} (#{Enum.join(column_names, ", ")}) values (#{Enum.join(placeholders, ", ")}) returning id"

    Repo.query!(sql, encode_values(insert_attrs, columns))
    |> one_id()
  end

  defp update_dynamic(table, id, attrs) do
    columns = table_columns(table)

    update_attrs =
      attrs
      |> Enum.reject(fn {column, _value} -> column == "id" end)
      |> Enum.filter(fn {column, _value} -> Map.has_key?(columns, column) end)

    set_clause =
      update_attrs
      |> Enum.with_index(2)
      |> Enum.map(fn {{column, _value}, idx} -> "#{column} = #{placeholder(idx, columns[column])}" end)
      |> Enum.join(", ")

    sql = "update #{table} set #{set_clause} where id = $1 returning id"

    Repo.query!(sql, [id | encode_values(update_attrs, columns)])
    |> one_id()
  end

  defp table_columns(table) do
    result =
      Repo.query!(
        """
        select column_name, data_type, udt_name
        from information_schema.columns
        where table_schema = 'public' and table_name = $1
        """,
        [table]
      )

    Map.new(result.rows, fn [column_name, data_type, udt_name] ->
      {column_name, %{data_type: data_type, udt_name: udt_name}}
    end)
  end

  defp allowed_ingestion_run_status do
    allowed = ingestion_run_status_values()

    Enum.find(["success", "succeeded", "ok", "ready", "staged", "running", "started", "failed"], fn value ->
      value in allowed
    end) || List.first(allowed) || "success"
  end

  defp ingestion_run_status_values do
    result =
      Repo.query!(
        """
        select pg_get_constraintdef(oid)
        from pg_constraint
        where conrelid = 'ingestion_runs'::regclass
          and conname = 'ingestion_runs_status_check'
        limit 1
        """,
        []
      )

    case result.rows do
      [[definition]] ->
        Regex.scan(~r/'([^']+)'/, definition)
        |> Enum.map(fn [_match, value] -> value end)

      _ ->
        []
    end
  end

  defp placeholder(index, %{data_type: "jsonb"}), do: "$#{index}::jsonb"
  defp placeholder(index, %{data_type: "json"}), do: "$#{index}::json"
  defp placeholder(index, _column), do: "$#{index}"

  defp encode_values(attrs, columns) do
    Enum.map(attrs, fn {column, value} -> encode_value(column, value, columns[column]) end)
  end

  defp encode_value(_column, value, %{udt_name: "uuid"}), do: uuid_param(value)
  defp encode_value(_column, value, %{data_type: data_type}) when data_type in ["json", "jsonb"], do: value
  defp encode_value("content_hash", value, %{data_type: "bytea"}), do: Base.decode16!(String.upcase(value))
  defp encode_value(_column, value, _column_info), do: value

  defp one_id(%Postgrex.Result{rows: [[id]]}), do: {:ok, id}

  defp overlay_id(normalized) do
    suffix =
      normalized.article_external_id
      |> then(&:crypto.hash(:sha256, &1))
      |> Base.encode16(case: :lower)
      |> binary_part(0, 16)

    "news_overlay:#{normalized.canonical_event_id}:stage54-#{suffix}"
  end

  defp raw_document_external_id(normalized), do: "#{normalized.article_external_id}:article-metadata"
  defp raw_event_external_id(normalized), do: "#{overlay_id(normalized)}:overlay-candidate"
  defp cursor_value(normalized), do: "#{normalized.published_at}|#{normalized.article_external_id}"

  defp cursor_meta(normalized) do
    %{
      "overlay_id" => overlay_id(normalized),
      "article_external_id" => normalized.article_external_id,
      "canonical_event_id" => normalized.canonical_event_id,
      "mode" => "offline_provider_raw_staging"
    }
  end

  defp raw_document_payload(normalized) do
    %{
      "mode" => "offline_provider_raw_staging",
      "source_key" => @source_key,
      "provider_source_key" => normalized.source_key,
      "source_tier" => normalized.source_tier,
      "document_role" => normalized.document_role,
      "article_external_id" => normalized.article_external_id,
      "overlay_id" => overlay_id(normalized),
      "canonical_event_id" => normalized.canonical_event_id,
      "source_name" => normalized.provider,
      "source_url" => normalized.url,
      "article_title" => normalized.title,
      "article_published_at" => normalized.published_at,
      "article_language" => normalized.language,
      "canonical_feed_mutation" => false,
      "news_only_event_creation" => false,
      "canonical_fact_override" => false,
      "network_access" => "forbidden",
      "scheduler_enabled" => false
    }
  end

  defp raw_document_content_hash(normalized) do
    %{
      "article_external_id" => normalized.article_external_id,
      "overlay_id" => overlay_id(normalized),
      "canonical_event_id" => normalized.canonical_event_id,
      "source_url" => normalized.url,
      "article_title" => normalized.title,
      "article_published_at" => normalized.published_at
    }
    |> Jason.encode!()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp match_evidence(normalized) do
    %{
      "matchedCanonicalEventId" => normalized.canonical_event_id,
      "matchedOfficialStableExternalId" => normalized.matched_official_stable_external_id,
      "conflictFlags" => []
    }
  end

  defp official_anchor(normalized) do
    %{
      "eventId" => normalized.canonical_event_id,
      "stableExternalId" => normalized.matched_official_stable_external_id,
      "officialSourceKey" => "jp_tdnet_timely_disclosure"
    }
  end

  defp parse_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> {:ok, DateTime.truncate(datetime, :second)}
      {:error, reason} -> {:error, {:invalid_datetime, value, reason}}
    end
  end

  defp uuid_param(value) when is_binary(value) do
    case Ecto.UUID.dump(value) do
      {:ok, dumped} -> dumped
      :error -> value
    end
  end

  defp uuid_param(value), do: value

  defp maybe_mark_failure(reason) do
    case Sources.get_source_by_key(@source_key) do
      {:ok, source} -> Sources.mark_poll_failure(source, reason)
      _ -> :ok
    end
  end
end
