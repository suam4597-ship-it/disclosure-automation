defmodule DisclosureAutomation.Runtime.Stage52NewsOverlayAttachmentMaterializer do
  @moduledoc false

  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Runtime.Stage5NewsOverlayReadModel
  alias DisclosureAutomation.Schema.NewsOverlayAttachment
  alias DisclosureAutomation.Sources

  @source_key "stage5_news_overlay_fixture"

  def materialize_once(event_id) when is_binary(event_id) do
    with {:ok, source} <- Sources.get_source_by_key(@source_key),
         {:ok, %{item: item}} <- Stage5NewsOverlayReadModel.get_by_event_id(event_id) do
      visible_overlays = Enum.filter(item.overlays || [], &(&1.displayState == "visible"))

      attachments = Enum.map(visible_overlays, &upsert_attachment!(item, source, &1))

      {:ok,
       %{
         event_id: event_id,
         source_key: @source_key,
         mode: "materialized_attachment",
         attachments_seen: length(visible_overlays),
         attachments_upserted: length(attachments),
         attachment_ids: Enum.map(attachments, & &1.id),
         canonical_feed_mutation: false,
         news_only_event_creation: false
       }}
    end
  end

  defp upsert_attachment!(item, source, overlay) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    attrs = %{
      official_canonical_feed_item_id: uuid_string(item.id),
      official_event_id: item.eventId,
      official_stable_external_id: item.stableExternalId,
      overlay_source_registry_id: uuid_string(source.id),
      overlay_source_key: overlay.sourceKey,
      overlay_provider: overlay.provider,
      overlay_external_id: overlay.articleExternalId,
      overlay_raw_document_id: raw_document_id(source.id, overlay.rawDocumentExternalId),
      overlay_raw_event_id: raw_event_id(source.id, overlay.rawEventExternalId),
      overlay_id: overlay.overlayId,
      overlay_mode: overlay.overlayMode,
      display_state: overlay.displayState,
      canonical_fact_override: false,
      source_tier: overlay.sourceTier,
      document_role: overlay.documentRole,
      published_at: parse_datetime(overlay.publishedAt),
      url: overlay.url,
      title: overlay.title,
      language: overlay.language,
      jurisdiction: overlay.jurisdiction,
      overlay_payload: overlay_payload(overlay),
      conflict_flags: %{"items" => overlay.conflictFlags || []},
      overlay_claims: %{"items" => Enum.map(overlay.overlayClaims || [], &overlay_claim_to_map/1)},
      citations: %{"items" => Enum.map(overlay.citations || [], &citation_to_map/1)}
    }

    %NewsOverlayAttachment{}
    |> NewsOverlayAttachment.changeset(attrs)
    |> Repo.insert!(
      on_conflict: {:replace_all_except, [:id, :inserted_at]},
      conflict_target: [:official_canonical_feed_item_id, :overlay_source_key, :overlay_external_id],
      returning: true
    )
    |> Map.put(:updated_at, now)
  end

  defp overlay_payload(overlay) do
    %{
      "overlay_id" => overlay.overlayId,
      "overlay_type" => overlay.overlayType,
      "overlay_mode" => overlay.overlayMode,
      "display_state" => overlay.displayState,
      "source_key" => overlay.sourceKey,
      "provider" => overlay.provider,
      "source_tier" => overlay.sourceTier,
      "document_role" => overlay.documentRole,
      "article_external_id" => overlay.articleExternalId,
      "raw_document_external_id" => overlay.rawDocumentExternalId,
      "raw_event_external_id" => overlay.rawEventExternalId,
      "title" => overlay.title,
      "published_at" => overlay.publishedAt,
      "url" => overlay.url,
      "language" => overlay.language,
      "jurisdiction" => overlay.jurisdiction,
      "canonical_fact_override" => false
    }
  end

  defp overlay_claim_to_map(claim) do
    %{
      "claim_id" => claim.claimId,
      "claim_type" => claim.claimType,
      "text" => claim.text,
      "source_key" => claim.sourceKey,
      "source_tier" => claim.sourceTier,
      "document_role" => claim.documentRole,
      "citation_id" => claim.citationId,
      "canonical_fact_override" => false
    }
  end

  defp citation_to_map(citation) do
    %{
      "citation_id" => citation.citationId,
      "source_key" => citation.sourceKey,
      "source_tier" => citation.sourceTier,
      "document_role" => citation.documentRole,
      "provider" => citation.provider,
      "url" => citation.url,
      "label" => citation.label,
      "is_canonical_source" => citation.isCanonicalSource
    }
  end

  defp raw_document_id(_source_registry_id, nil), do: nil

  defp raw_document_id(source_registry_id, external_id) do
    result =
      Repo.query!(
        """
        select id
        from raw_documents
        where source_registry_id = $1 and external_id = $2
        limit 1
        """,
        [uuid_param(source_registry_id), external_id]
      )

    case result.rows do
      [[id]] -> uuid_string(id)
      [] -> nil
    end
  end

  defp raw_event_id(_source_registry_id, nil), do: nil

  defp raw_event_id(source_registry_id, external_event_key) do
    result =
      Repo.query!(
        """
        select id
        from raw_events
        where source_registry_id = $1 and external_event_key = $2
        limit 1
        """,
        [uuid_param(source_registry_id), external_event_key]
      )

    case result.rows do
      [[id]] -> uuid_string(id)
      [] -> nil
    end
  end

  defp parse_datetime(nil), do: nil

  defp parse_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> DateTime.truncate(datetime, :microsecond)
      {:error, _reason} -> nil
    end
  end

  defp uuid_string(nil), do: nil

  defp uuid_string(value) when is_binary(value) and byte_size(value) == 16 do
    case Ecto.UUID.load(value) do
      {:ok, uuid} -> uuid
      :error -> value
    end
  end

  defp uuid_string(value), do: value

  defp uuid_param(value) when is_binary(value) do
    case Ecto.UUID.dump(value) do
      {:ok, dumped} -> dumped
      :error -> value
    end
  end

  defp uuid_param(value), do: value
end
