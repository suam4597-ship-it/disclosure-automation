defmodule DisclosureAutomation.Runtime.Stage52NewsOverlayAttachmentMaterializer do
  @moduledoc false

  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Runtime.Stage5NewsOverlayReadModel
  alias DisclosureAutomation.Schema.NewsOverlayAttachment
  alias DisclosureAutomation.Sources

  @stage5_source_key "stage5_news_overlay_fixture"
  @stage53_source_key "stage53_news_overlay_fixture"

  def materialize_once(event_id) when is_binary(event_id) do
    with {:ok, %{item: item}} <- Stage5NewsOverlayReadModel.get_by_event_id(event_id, prefer_materialized: false) do
      visible_overlays =
        item.overlays
        |> Enum.filter(&(&1.displayState == "visible"))
        |> Kernel.++(stage53_visible_overlays_for(item))
        |> Enum.uniq_by(&{&1.sourceKey, &1.articleExternalId})
        |> Enum.sort_by(fn overlay -> {overlay.displayState, overlay.publishedAt || "", overlay.provider || "", overlay.articleExternalId || ""} end)

      attachments = Enum.map(visible_overlays, &upsert_attachment!(item, &1))

      {:ok,
       %{
         event_id: event_id,
         source_keys: visible_overlays |> Enum.map(& &1.sourceKey) |> Enum.uniq(),
         mode: "materialized_attachment",
         attachments_seen: length(visible_overlays),
         attachments_upserted: length(attachments),
         attachment_ids: Enum.map(attachments, & &1.id),
         canonical_feed_mutation: false,
         news_only_event_creation: false
       }}
    end
  end

  defp stage53_visible_overlays_for(item) do
    case Sources.get_source_by_key(@stage53_source_key) do
      {:ok, source} ->
        result =
          Repo.query!(
            """
            select external_event_key, payload
            from raw_events
            where source_registry_id = $1
              and payload->>'canonical_event_id' = $2
            order by occurred_at, external_event_key
            """,
            [uuid_param(source.id), item.eventId]
          )

        result.rows
        |> Enum.map(fn [external_event_key, payload] -> stage53_overlay_from_payload(item, external_event_key, payload || %{}) end)
        |> Enum.filter(&(&1.displayState == "visible"))

      _ ->
        []
    end
  end

  defp stage53_overlay_from_payload(item, external_event_key, payload) do
    citations = overlay_citations(payload)
    overlay_url = first_present([payload["source_url"], get_in(List.first(citations) || %{}, [:url])])

    %{
      overlayId: payload["overlay_id"],
      overlayType: "news_article_context",
      overlayMode: "attach_only",
      displayState: display_state(item, payload),
      sourceKey: first_present([payload["source_key"], @stage53_source_key]),
      provider: provider_name(payload, citations),
      sourceTier: payload["source_tier"],
      documentRole: payload["document_role"],
      articleExternalId: payload["article_external_id"],
      rawDocumentExternalId: raw_document_external_id(payload),
      rawEventExternalId: external_event_key,
      title: payload["article_title"],
      publishedAt: payload["article_published_at"],
      url: overlay_url,
      language: payload["article_language"],
      jurisdiction: "JP",
      canonicalFactOverride: false,
      overlayClaims: overlay_claims(payload),
      conflictFlags: conflict_flags(payload, item.canonicalUrl, overlay_url),
      citations: citations
    }
  end

  defp display_state(item, payload) do
    cond do
      payload["source_tier"] != "reputable_news_source" ->
        "hidden_source_not_allowed"

      payload["document_role"] != "news_article" ->
        "hidden_source_not_allowed"

      payload["canonical_feed_mutation"] != false ->
        "hidden_conflict_requires_review"

      payload["news_only_event_creation"] != false ->
        "hidden_conflict_requires_review"

      not direct_official_identifier_match?(item, payload) ->
        "hidden_missing_direct_official_identifier"

      true ->
        "visible"
    end
  end

  defp direct_official_identifier_match?(item, payload) do
    payload["canonical_event_id"] == item.eventId or
      get_in(payload, ["match_evidence", "matchedCanonicalEventId"]) == item.eventId or
      get_in(payload, ["match_evidence", "matchedOfficialStableExternalId"]) == item.stableExternalId or
      get_in(payload, ["official_anchor", "stableExternalId"]) == item.stableExternalId
  end

  defp upsert_attachment!(item, overlay) do
    source = source_by_key(overlay.sourceKey)

    attrs = %{
      official_canonical_feed_item_id: uuid_string(item.id),
      official_event_id: item.eventId,
      official_stable_external_id: item.stableExternalId,
      overlay_source_registry_id: source && uuid_string(source.id),
      overlay_source_key: overlay.sourceKey,
      overlay_provider: overlay.provider,
      overlay_external_id: overlay.articleExternalId,
      overlay_raw_document_id: source && raw_document_id(source.id, overlay.rawDocumentExternalId),
      overlay_raw_event_id: source && raw_event_id(source.id, overlay.rawEventExternalId),
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

  defp overlay_claims(payload) do
    payload
    |> Map.get("overlay_claims", [])
    |> Enum.map(fn claim ->
      %{
        claimId: claim["claimId"],
        claimType: claim_type(claim),
        text: claim["summary"],
        sourceKey: payload["source_key"],
        sourceTier: payload["source_tier"],
        documentRole: payload["document_role"],
        citationId: claim["sourceCitationRef"],
        canonicalFactOverride: false
      }
    end)
  end

  defp overlay_citations(payload) do
    source_key = payload["source_key"]

    payload
    |> Map.get("citations", [])
    |> Enum.filter(&(&1["sourceKey"] == source_key))
    |> Enum.map(&normalize_citation(&1, false))
  end

  defp normalize_citation(citation, canonical?) do
    %{
      citationId: citation["citationId"],
      sourceKey: citation["sourceKey"],
      sourceTier: citation["sourceTier"],
      documentRole: citation["documentRole"],
      provider: provider_from_source_name(citation["sourceName"]),
      url: citation["sourceUrl"],
      label: citation["sourceName"],
      isCanonicalSource: canonical?
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

  defp conflict_flags(payload, official_url, overlay_url) do
    base_flags = payload["conflict_flags"] || get_in(payload, ["match_evidence", "conflictFlags"]) || []

    provider_url_flag =
      if present?(official_url) and present?(overlay_url) and official_url != overlay_url do
        ["provider_url_not_official_url"]
      else
        []
      end

    (base_flags ++ provider_url_flag)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
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

  defp raw_document_external_id(%{"article_external_id" => article_external_id}) when is_binary(article_external_id) do
    "#{article_external_id}:article-metadata"
  end

  defp raw_document_external_id(_payload), do: nil

  defp source_by_key(source_key) do
    case Sources.get_source_by_key(source_key) do
      {:ok, source} -> source
      _ -> nil
    end
  end

  defp provider_name(payload, citations) do
    first_present([
      provider_from_source_name(payload["source_name"]),
      get_in(List.first(citations) || %{}, [:provider]),
      provider_from_source_name(payload["sourceKey"]),
      "Unknown"
    ])
  end

  defp provider_from_source_name(nil), do: nil

  defp provider_from_source_name(source_name) do
    source_name = to_string(source_name)

    cond do
      String.contains?(source_name, "Reuters") or String.contains?(source_name, "ロイター") -> "Reuters"
      String.contains?(source_name, "Bloomberg") or String.contains?(source_name, "stage53_news_overlay_fixture") -> "Bloomberg"
      true -> source_name
    end
  end

  defp claim_type(%{"claimKind" => "secondary_confirmation"}), do: "article_metadata"
  defp claim_type(%{"claimKind" => "article_metadata"}), do: "article_metadata"
  defp claim_type(%{"claimKind" => "news_only_context"}), do: "context_summary"
  defp claim_type(_claim), do: "context_summary"

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

  defp first_present(values) do
    Enum.find(values, &present?/1)
  end

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(nil), do: false
  defp present?(_value), do: true
end
