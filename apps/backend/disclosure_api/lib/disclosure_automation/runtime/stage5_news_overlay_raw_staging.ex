defmodule DisclosureAutomation.Runtime.Stage5NewsOverlayRawStaging do
  @moduledoc false

  alias DisclosureAutomation.Fixtures
  alias DisclosureAutomation.Ops.Stage5NewsOverlayFixtureSource
  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Schema.SourceRegistry
  alias DisclosureAutomation.Sources

  @source_key "stage5_news_overlay_fixture"
  @cursor_key "latest_article_published_at_and_article_external_id_seen"

  def source_key, do: @source_key
  def cursor_key, do: @cursor_key

  def stage_once(opts \\ []) do
    with {:ok, source} <- ensure_source(opts),
         {:ok, fixture} <- load_fixture(source),
         {:ok, overlay} <- single_overlay(fixture),
         {:ok, article_published_at} <- parse_datetime(overlay["articlePublishedAt"]),
         {:ok, _raw_document} <- upsert_raw_document(source, fixture, overlay, article_published_at),
         {:ok, _raw_event} <- upsert_raw_event(source, overlay, article_published_at),
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
        with {:ok, _source} <- Sources.upsert_source(Stage5NewsOverlayFixtureSource.attrs()) do
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

  defp upsert_raw_document(%SourceRegistry{} = source, fixture, overlay, published_at) do
    external_id = raw_document_external_id(overlay)
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    attrs = %{
      "external_id" => external_id,
      "document_identity" => external_id,
      "document_type" => "stage5_news_overlay_article_metadata_fixture",
      "document_role" => "news_article",
      "mime_type" => "application/json",
      "url" => overlay["sourceUrl"],
      "body_text" => Jason.encode!(fixture),
      "published_at" => published_at,
      "metadata" => %{
        "mode" => "raw_staging",
        "fixture" => fixture["_fixture_path"],
        "article_external_id" => overlay["articleExternalId"],
        "overlay_id" => overlay["overlayId"],
        "canonical_event_id" => overlay["canonicalEventId"],
        "canonical_feed_mutation" => false,
        "news_only_event_creation" => false
      }
    }

    case lookup_id("raw_documents", source.id, external_id) do
      {:ok, nil} -> insert_raw_document(source.id, attrs, now)
      {:ok, id} -> update_raw_document(id, attrs, now)
    end
  end

  defp upsert_raw_event(%SourceRegistry{} = source, overlay, occurred_at) do
    external_id = raw_event_external_id(overlay)
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    payload = %{
      "overlay_id" => overlay["overlayId"],
      "article_external_id" => overlay["articleExternalId"],
      "canonical_event_id" => overlay["canonicalEventId"],
      "source_key" => overlay["sourceKey"],
      "source_tier" => overlay["sourceTier"],
      "document_role" => overlay["documentRole"],
      "article_title" => overlay["articleTitle"],
      "article_published_at" => overlay["articlePublishedAt"],
      "article_retrieved_at" => overlay["articleRetrievedAt"],
      "claim_supported" => overlay["claimSupported"],
      "overlay_context_type" => overlay["overlayContextType"],
      "overlay_claims" => overlay["overlayClaims"] || [],
      "match_evidence" => overlay["matchEvidence"] || %{},
      "citations" => overlay["citations"] || [],
      "conflict_flags" => overlay["conflictFlags"] || [],
      "official_facts_preserved" => overlay["officialFactsPreserved"] || %{},
      "canonical_feed_mutation" => false,
      "news_only_event_creation" => false
    }

    attrs = %{
      "event_key" => external_id,
      "external_event_key" => external_id,
      "parser_key" => "stage5_news_overlay_fixture_v1",
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
      }
    }

    case lookup_raw_event_id(source.id, external_id) do
      {:ok, nil} -> insert_raw_event(source.id, attrs, now)
      {:ok, id} -> update_raw_event(id, attrs, now)
    end
  end

  defp lookup_id(table, source_registry_id, external_id) when table in ["raw_documents"] do
    result =
      Repo.query!(
        "select id from #{table} where source_registry_id = $1 and external_id = $2 limit 1",
        [source_registry_id, external_id]
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
        [source_registry_id, external_event_key]
      )

    case result.rows do
      [[id]] -> {:ok, id}
      [] -> {:ok, nil}
    end
  end

  defp insert_raw_document(source_registry_id, attrs, now) do
    Repo.query!(
      """
      insert into raw_documents
        (source_registry_id, external_id, document_identity, document_type, document_role, mime_type, url, body_text, published_at, metadata, inserted_at, updated_at)
      values
        ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10::jsonb, $11, $12)
      returning id
      """,
      [
        source_registry_id,
        attrs["external_id"],
        attrs["document_identity"],
        attrs["document_type"],
        attrs["document_role"],
        attrs["mime_type"],
        attrs["url"],
        attrs["body_text"],
        attrs["published_at"],
        Jason.encode!(attrs["metadata"]),
        now,
        now
      ]
    )
    |> one_id()
  end

  defp update_raw_document(id, attrs, now) do
    Repo.query!(
      """
      update raw_documents
      set document_identity = $2,
          document_type = $3,
          document_role = $4,
          mime_type = $5,
          url = $6,
          body_text = $7,
          published_at = $8,
          metadata = $9::jsonb,
          updated_at = $10
      where id = $1
      returning id
      """,
      [
        id,
        attrs["document_identity"],
        attrs["document_type"],
        attrs["document_role"],
        attrs["mime_type"],
        attrs["url"],
        attrs["body_text"],
        attrs["published_at"],
        Jason.encode!(attrs["metadata"]),
        now
      ]
    )
    |> one_id()
  end

  defp insert_raw_event(source_registry_id, attrs, now) do
    Repo.query!(
      """
      insert into raw_events
        (source_registry_id, event_key, external_event_key, parser_key, event_family, occurred_at, status, payload, metadata, inserted_at, updated_at)
      values
        ($1, $2, $3, $4, $5, $6, $7, $8::jsonb, $9::jsonb, $10, $11)
      returning id
      """,
      [
        source_registry_id,
        attrs["event_key"],
        attrs["external_event_key"],
        attrs["parser_key"],
        attrs["event_family"],
        attrs["occurred_at"],
        attrs["status"],
        Jason.encode!(attrs["payload"]),
        Jason.encode!(attrs["metadata"]),
        now,
        now
      ]
    )
    |> one_id()
  end

  defp update_raw_event(id, attrs, now) do
    Repo.query!(
      """
      update raw_events
      set event_key = $2,
          parser_key = $3,
          event_family = $4,
          occurred_at = $5,
          status = $6,
          payload = $7::jsonb,
          metadata = $8::jsonb,
          updated_at = $9
      where id = $1
      returning id
      """,
      [
        id,
        attrs["event_key"],
        attrs["parser_key"],
        attrs["event_family"],
        attrs["occurred_at"],
        attrs["status"],
        Jason.encode!(attrs["payload"]),
        Jason.encode!(attrs["metadata"]),
        now
      ]
    )
    |> one_id()
  end

  defp one_id(%Postgrex.Result{rows: [[id]]}), do: {:ok, id}

  defp raw_document_external_id(overlay), do: "#{overlay["articleExternalId"]}:article-metadata"
  defp raw_event_external_id(overlay), do: "#{overlay["overlayId"]}:overlay-candidate"

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

  defp maybe_mark_failure(reason) do
    case Sources.get_source_by_key(@source_key) do
      {:ok, source} -> Sources.mark_poll_failure(source, reason)
      _ -> :ok
    end
  end
end
