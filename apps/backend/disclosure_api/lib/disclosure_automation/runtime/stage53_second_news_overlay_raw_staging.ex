defmodule DisclosureAutomation.Runtime.Stage53SecondNewsOverlayRawStaging do
  @moduledoc false

  alias DisclosureAutomation.Fixtures
  alias DisclosureAutomation.Ops.Stage53SecondNewsOverlayFixtureSource
  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Schema.SourceRegistry
  alias DisclosureAutomation.Sources

  @source_key "stage53_news_overlay_fixture"
  @cursor_key "latest_article_published_at_and_article_external_id_seen"

  def source_key, do: @source_key
  def cursor_key, do: @cursor_key

  def stage_once(opts \\ []) do
    with {:ok, source} <- ensure_source(opts),
         {:ok, fixture} <- load_fixture(source),
         {:ok, overlay} <- single_overlay(fixture),
         {:ok, article_published_at} <- parse_datetime(overlay["articlePublishedAt"]),
         {:ok, ingestion_run_id} <- create_ingestion_run(source, overlay),
         {:ok, _raw_document} <- upsert_raw_document(source, overlay, article_published_at, ingestion_run_id),
         {:ok, _raw_event} <- upsert_raw_event(source, overlay, article_published_at, ingestion_run_id),
         {:ok, _cursor} <- Sources.upsert_source_cursor(source, @cursor_key, cursor_value(overlay), cursor_meta(overlay)),
         {:ok, _source} <- Sources.mark_poll_success(source, article_published_at) do
      {:ok,
       %{
         source_key: @source_key,
         records_seen: 1,
         mode: "raw_staging",
         canonical_feed_mutation: false,
         article_external_id: overlay["articleExternalId"],
         overlay_id: overlay["overlayId"],
         raw_document_external_id: raw_document_external_id(overlay),
         raw_event_external_id: raw_event_external_id(overlay),
         ingestion_run_id: ingestion_run_id,
         cursor_key: @cursor_key,
         cursor_value: cursor_value(overlay)
       }}
    end
  rescue
    error ->
      maybe_mark_failure(error)
      reraise error, __STACKTRACE__
  end

  defp ensure_source(opts) do
    case Keyword.get(opts, :source) do
      %SourceRegistry{} = source ->
        {:ok, source}

      nil ->
        with {:ok, _source} <- Sources.upsert_source(Stage53SecondNewsOverlayFixtureSource.attrs()) do
          Sources.get_source_by_key(@source_key)
        end
    end
  end

  defp load_fixture(%SourceRegistry{} = source) do
    fixture_path =
      get_in(source.config || %{}, ["fixtures", "overlay_result"]) ||
        get_in(source.config || %{}, [:fixtures, :overlay_result])

    with {:ok, payload} <- Fixtures.load_source_payload(fixture_path),
         {:ok, decoded} <- Jason.decode(payload.raw) do
      {:ok, Map.put(decoded, "_fixture_path", payload.relative_path)}
    end
  end

  defp single_overlay(%{"overlays" => [overlay]}) when is_map(overlay), do: {:ok, overlay}
  defp single_overlay(%{"overlays" => []}), do: {:error, :no_overlays}
  defp single_overlay(%{"overlays" => overlays}) when is_list(overlays), do: {:error, {:expected_one_overlay, length(overlays)}}
  defp single_overlay(_payload), do: {:error, :missing_overlays}

  defp create_ingestion_run(%SourceRegistry{} = source, overlay) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    run_id = Ecto.UUID.generate()

    attrs = %{
      "id" => run_id,
      "run_key" => "#{@source_key}:raw_staging:#{run_id}",
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
        "mode" => "raw_staging",
        "source_key" => @source_key,
        "overlay_id" => overlay["overlayId"],
        "article_external_id" => overlay["articleExternalId"],
        "canonical_event_id" => overlay["canonicalEventId"],
        "canonical_feed_mutation" => false,
        "news_only_event_creation" => false
      },
      "inserted_at" => now,
      "updated_at" => now
    }

    insert_dynamic("ingestion_runs", attrs)
  end

  defp upsert_raw_document(%SourceRegistry{} = source, overlay, published_at, ingestion_run_id) do
    external_id = raw_document_external_id(overlay)
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    attrs = %{
      "id" => Ecto.UUID.generate(),
      "ingestion_run_id" => ingestion_run_id,
      "source_registry_id" => source.id,
      "external_id" => external_id,
      "document_identity" => external_id,
      "document_type" => "stage53_news_overlay_article_metadata_fixture",
      "document_role" => "news_article",
      "mime_type" => "application/json",
      "url" => overlay["sourceUrl"],
      "payload" => raw_document_payload(overlay),
      "content_hash" => raw_document_content_hash(overlay),
      "published_at" => published_at,
      "inserted_at" => now,
      "updated_at" => now
    }

    case lookup_id("raw_documents", source.id, external_id) do
      {:ok, nil} -> insert_dynamic("raw_documents", attrs)
      {:ok, id} -> update_dynamic("raw_documents", id, Map.delete(attrs, "id"))
    end
  end

  defp upsert_raw_event(%SourceRegistry{} = source, overlay, occurred_at, ingestion_run_id) do
    external_id = raw_event_external_id(overlay)
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    payload = %{
      "overlay_id" => overlay["overlayId"],
      "article_external_id" => overlay["articleExternalId"],
      "canonical_event_id" => overlay["canonicalEventId"],
      "source_key" => overlay["sourceKey"],
      "source_tier" => overlay["sourceTier"],
      "document_role" => overlay["documentRole"],
      "source_name" => overlay["sourceName"],
      "source_url" => overlay["sourceUrl"],
      "article_title" => overlay["articleTitle"],
      "article_published_at" => overlay["articlePublishedAt"],
      "article_retrieved_at" => overlay["articleRetrievedAt"],
      "article_language" => overlay["articleLanguage"],
      "claim_supported" => overlay["claimSupported"],
      "overlay_context_type" => overlay["overlayContextType"],
      "overlay_claims" => overlay["overlayClaims"] || [],
      "match_evidence" => overlay["matchEvidence"] || %{},
      "citations" => overlay["citations"] || [],
      "conflict_flags" => overlay["conflictFlags"] || get_in(overlay, ["matchEvidence", "conflictFlags"]) || [],
      "official_facts_preserved" => overlay["officialFactsPreserved"] || %{},
      "official_anchor" => overlay["officialAnchor"] || %{},
      "canonical_feed_mutation" => false,
      "news_only_event_creation" => false
    }

    attrs = %{
      "id" => Ecto.UUID.generate(),
      "ingestion_run_id" => ingestion_run_id,
      "source_registry_id" => source.id,
      "event_key" => external_id,
      "external_event_key" => external_id,
      "parser_key" => "stage53_news_overlay_fixture_v1",
      "event_family" => "news_overlay_update",
      "occurred_at" => occurred_at,
      "status" => "staged",
      "payload" => payload,
      "metadata" => %{
        "mode" => "raw_staging",
        "source_key" => @source_key,
        "article_external_id" => overlay["articleExternalId"],
        "overlay_id" => overlay["overlayId"],
        "canonical_event_id" => overlay["canonicalEventId"],
        "canonical_feed_mutation" => false,
        "news_only_event_creation" => false
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

    insert_attrs =
      attrs
      |> Enum.filter(fn {column, _value} -> Map.has_key?(columns, column) end)

    {column_names, _values} = Enum.unzip(insert_attrs)

    placeholders =
      column_names
      |> Enum.with_index(1)
      |> Enum.map(fn {column, idx} -> placeholder(idx, columns[column]) end)

    sql = "insert into #{table} (#{Enum.join(column_names, ", ")}) values (#{Enum.join(placeholders, ", ")}) returning id"

    encoded_values = encode_values(insert_attrs, columns)

    Repo.query!(sql, encoded_values)
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

    encoded_values = [id | encode_values(update_attrs, columns)]

    Repo.query!(sql, encoded_values)
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

  defp raw_document_external_id(overlay), do: "#{overlay["articleExternalId"]}:article-metadata"
  defp raw_event_external_id(overlay), do: "#{overlay["overlayId"]}:overlay-candidate"

  defp raw_document_payload(overlay) do
    %{
      "mode" => "raw_staging",
      "source_key" => @source_key,
      "source_tier" => overlay["sourceTier"],
      "document_role" => overlay["documentRole"],
      "article_external_id" => overlay["articleExternalId"],
      "overlay_id" => overlay["overlayId"],
      "canonical_event_id" => overlay["canonicalEventId"],
      "source_name" => overlay["sourceName"],
      "source_url" => overlay["sourceUrl"],
      "article_title" => overlay["articleTitle"],
      "article_published_at" => overlay["articlePublishedAt"],
      "article_retrieved_at" => overlay["articleRetrievedAt"],
      "article_language" => overlay["articleLanguage"],
      "canonical_feed_mutation" => false,
      "news_only_event_creation" => false
    }
  end

  defp raw_document_content_hash(overlay) do
    %{
      "article_external_id" => overlay["articleExternalId"],
      "overlay_id" => overlay["overlayId"],
      "canonical_event_id" => overlay["canonicalEventId"],
      "source_url" => overlay["sourceUrl"],
      "article_title" => overlay["articleTitle"],
      "article_published_at" => overlay["articlePublishedAt"]
    }
    |> Jason.encode!()
    |> then(&:crypto.hash(:sha256, &1))
    |> Base.encode16(case: :lower)
  end

  defp cursor_value(overlay), do: "#{overlay["articlePublishedAt"]}|#{overlay["articleExternalId"]}"

  defp cursor_meta(overlay) do
    %{
      "overlay_id" => overlay["overlayId"],
      "article_external_id" => overlay["articleExternalId"],
      "canonical_event_id" => overlay["canonicalEventId"],
      "mode" => "raw_staging"
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
