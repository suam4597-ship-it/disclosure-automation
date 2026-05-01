defmodule DisclosureAutomation.Runtime.Stage5NewsOverlayReadModel do
  @moduledoc false

  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Sources

  @source_key "stage5_news_overlay_fixture"
  @official_source_key "jp_tdnet_timely_disclosure"
  @official_source_tier "official_exchange_storage"
  @official_document_role "official_exchange_disclosure"
  @overlay_source_tier "reputable_news_source"
  @overlay_document_role "news_article"

  def source_key, do: @source_key

  def get_by_event_id(event_id, opts \\ []) when is_binary(event_id) do
    with {:ok, official} <- official_item_by_event_id(event_id) do
      {:ok, build_response(official, opts)}
    end
  end

  def get_by_stable_external_id(stable_external_id, opts \\ []) when is_binary(stable_external_id) do
    with {:ok, official} <- official_item_by_stable_external_id(stable_external_id) do
      {:ok, build_response(official, opts)}
    end
  end

  def flattened_citations(%{item: %{citations: official_citations, overlays: overlays}}) do
    official_citations ++ Enum.flat_map(overlays, & &1.citations)
  end

  def flattened_citations(_response), do: []

  defp build_response(%{contract: contract} = official, opts) do
    overlays = overlays_for(official, opts)
    citations = official_citations(contract, overlays)

    item =
      official
      |> Map.drop([:contract])
      |> Map.put(:citations, citations)
      |> Map.put(:overlays, overlays)

    %{item: item}
  end

  defp official_item_by_event_id(event_id) do
    result =
      Repo.query!(
        """
        select id, event_id, contract_v1
        from canonical_feed_items
        where event_id = $1
        limit 1
        """,
        [event_id]
      )

    case result.rows do
      [[id, row_event_id, contract]] -> {:ok, official_item(id, row_event_id, contract || %{})}
      [] -> {:error, :official_canonical_item_not_found}
    end
  end

  defp official_item_by_stable_external_id(stable_external_id) do
    result =
      Repo.query!(
        """
        select id, event_id, contract_v1
        from canonical_feed_items
        where contract_v1 #>> '{source_meta,stable_external_id}' = $1
        limit 1
        """,
        [stable_external_id]
      )

    case result.rows do
      [[id, event_id, contract]] -> {:ok, official_item(id, event_id, contract || %{})}
      [] -> {:error, :official_canonical_item_not_found}
    end
  end

  defp official_item(id, event_id, contract) do
    %{
      id: id,
      eventId: event_id,
      stableExternalId: first_present([get_in(contract, ["source_meta", "stable_external_id"]), contract["stable_external_id"]]),
      sourceKey: first_present([contract["source_key"], get_in(contract, ["source_meta", "source_key"]), @official_source_key]),
      sourceTier: first_present([contract["source_tier"], get_in(contract, ["source_meta", "source_tier"]), @official_source_tier]),
      documentRole:
        first_present([contract["document_role"], get_in(contract, ["source_meta", "document_role"]), @official_document_role]),
      issuerName:
        first_present([
          contract["issuer_name_local"],
          contract["issuer_name"],
          get_in(contract, ["source_meta", "issuer_name"]),
          get_in(contract, ["issuer", "name"])
        ]),
      securityCode:
        first_present([
          get_in(contract, ["issuer_ids", "security_code"]),
          get_in(contract, ["source_meta", "normalized_security_code"]),
          contract["security_code"]
        ]),
      title: first_present([contract["headline_local"], contract["title"], contract["headline"], get_in(contract, ["source_meta", "title"])]),
      publishedAt: first_present([contract["published_at_utc"], contract["published_at"], get_in(contract, ["source_meta", "published_at_utc"])]),
      canonicalUrl:
        first_present([
          contract["official_source_url"],
          contract["canonical_url"],
          get_in(contract, ["source_meta", "attachment_url"]),
          get_in(contract, ["source_meta", "canonical_url"])
        ]),
      canonicalEventType: first_present([contract["canonical_event_type"], get_in(contract, ["source_meta", "canonical_event_type"])]),
      contract: contract
    }
  end

  defp overlays_for(official, opts) do
    prefer_materialized? = Keyword.get(opts, :prefer_materialized, true)

    materialized_overlays =
      if prefer_materialized? do
        materialized_overlays_for(official, opts)
      else
        []
      end

    case materialized_overlays do
      [] -> raw_staging_overlays_for(official, opts)
      overlays -> overlays
    end
  end

  defp raw_staging_overlays_for(official, opts) do
    include_hidden? = Keyword.get(opts, :include_hidden, false)

    official.eventId
    |> raw_overlay_rows()
    |> Enum.map(fn {external_event_key, payload} -> overlay_from_payload(official, external_event_key, payload || %{}) end)
    |> Enum.filter(fn overlay -> include_hidden? or overlay.displayState == "visible" end)
    |> Enum.sort_by(fn overlay -> {overlay.displayState, overlay.publishedAt || "", overlay.articleExternalId || ""} end)
  end

  defp materialized_overlays_for(official, opts) do
    include_hidden? = Keyword.get(opts, :include_hidden, false)

    display_filter =
      if include_hidden? do
        ""
      else
        "and display_state = 'visible'"
      end

    result =
      Repo.query!(
        """
        select
          overlay_id,
          overlay_provider,
          overlay_source_key,
          source_tier,
          document_role,
          overlay_external_id,
          overlay_mode,
          display_state,
          title,
          published_at,
          url,
          language,
          jurisdiction,
          canonical_fact_override,
          overlay_payload,
          conflict_flags,
          overlay_claims,
          citations
        from news_overlay_attachments
        where official_canonical_feed_item_id = $1
          #{display_filter}
        order by display_state, published_at, overlay_external_id
        """,
        [uuid_param(official.id)]
      )

    Enum.map(result.rows, &materialized_overlay_from_row/1)
  end

  defp materialized_overlay_from_row([
         overlay_id,
         overlay_provider,
         overlay_source_key,
         source_tier,
         document_role,
         overlay_external_id,
         overlay_mode,
         display_state,
         title,
         published_at,
         url,
         language,
         jurisdiction,
         canonical_fact_override,
         overlay_payload,
         conflict_flags,
         overlay_claims,
         citations
       ]) do
    overlay_payload = overlay_payload || %{}

    %{
      overlayId: overlay_id,
      overlayType: overlay_payload["overlay_type"] || "news_article_context",
      overlayMode: overlay_mode,
      displayState: display_state,
      sourceKey: overlay_source_key,
      provider: overlay_provider,
      sourceTier: source_tier,
      documentRole: document_role,
      articleExternalId: overlay_external_id,
      rawDocumentExternalId: overlay_payload["raw_document_external_id"],
      rawEventExternalId: overlay_payload["raw_event_external_id"],
      title: title,
      publishedAt: first_present([overlay_payload["published_at"], datetime_iso8601(published_at)]),
      url: url,
      language: language,
      jurisdiction: jurisdiction,
      canonicalFactOverride: canonical_fact_override || false,
      overlayClaims: materialized_overlay_claims(overlay_claims),
      conflictFlags: json_items(conflict_flags),
      citations: materialized_citations(citations)
    }
  end

  defp raw_overlay_rows(event_id) do
    case Sources.get_source_by_key(@source_key) do
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
            [uuid_param(source.id), event_id]
          )

        Enum.map(result.rows, fn [external_event_key, payload] -> {external_event_key, payload} end)

      _ ->
        []
    end
  end

  defp overlay_from_payload(official, external_event_key, payload) do
    reuters_citations = overlay_citations(payload)
    official_url = official.canonicalUrl
    overlay_url = overlay_url(payload, reuters_citations)
    conflict_flags = conflict_flags(payload, official_url, overlay_url)
    display_state = display_state(official, payload)

    %{
      overlayId: payload["overlay_id"],
      overlayType: "news_article_context",
      overlayMode: "attach_only",
      displayState: display_state,
      sourceKey: first_present([payload["source_key"], @source_key]),
      provider: provider_name(payload, reuters_citations),
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
      conflictFlags: conflict_flags,
      citations: reuters_citations
    }
  end

  defp display_state(official, payload) do
    cond do
      payload["source_tier"] != @overlay_source_tier ->
        "hidden_source_not_allowed"

      payload["document_role"] != @overlay_document_role ->
        "hidden_source_not_allowed"

      payload["canonical_feed_mutation"] != false ->
        "hidden_conflict_requires_review"

      payload["news_only_event_creation"] != false ->
        "hidden_conflict_requires_review"

      not direct_official_identifier_match?(official, payload) ->
        "hidden_missing_direct_official_identifier"

      true ->
        "visible"
    end
  end

  defp direct_official_identifier_match?(official, payload) do
    payload["canonical_event_id"] == official.eventId or
      get_in(payload, ["match_evidence", "matchedCanonicalEventId"]) == official.eventId or
      stable_external_id_match?(official, payload)
  end

  defp stable_external_id_match?(%{stableExternalId: nil}, _payload), do: false

  defp stable_external_id_match?(official, payload) do
    get_in(payload, ["match_evidence", "matchedOfficialStableExternalId"]) == official.stableExternalId or
      get_in(payload, ["official_anchor", "stableExternalId"]) == official.stableExternalId
  end

  defp official_citations(contract, overlays) do
    from_contract = normalize_contract_official_citations(contract)

    from_overlays =
      overlays
      |> Enum.flat_map(fn overlay -> official_citations_from_overlay_event(overlay.rawEventExternalId) end)
      |> Enum.uniq_by(& &1.citationId)

    case from_contract do
      [] -> from_overlays
      citations -> citations
    end
  end

  defp normalize_contract_official_citations(contract) do
    contract
    |> Map.get("portable_citations", [])
    |> Enum.with_index(1)
    |> Enum.map(fn {citation, idx} ->
      %{
        citationId: "tdnet-official-#{idx}",
        sourceKey: @official_source_key,
        sourceTier: first_present([contract["source_tier"], @official_source_tier]),
        documentRole: @official_document_role,
        url: citation["note"],
        label: first_present([citation["source_name"], "TDnet official disclosure"]),
        isCanonicalSource: true
      }
    end)
  end

  defp official_citations_from_overlay_event(nil), do: []

  defp official_citations_from_overlay_event(raw_event_external_id) do
    case Sources.get_source_by_key(@source_key) do
      {:ok, source} ->
        result =
          Repo.query!(
            """
            select payload
            from raw_events
            where source_registry_id = $1
              and external_event_key = $2
            limit 1
            """,
            [uuid_param(source.id), raw_event_external_id]
          )

        case result.rows do
          [[payload]] -> official_citations_from_payload(payload || %{})
          [] -> []
        end

      _ ->
        []
    end
  end

  defp official_citations_from_payload(payload) do
    payload
    |> Map.get("citations", [])
    |> Enum.filter(&(&1["sourceKey"] == @official_source_key))
    |> Enum.map(&normalize_citation(&1, true))
  end

  defp overlay_citations(payload) do
    payload
    |> Map.get("citations", [])
    |> Enum.filter(&(&1["sourceKey"] == @source_key))
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

  defp materialized_overlay_claims(claims) do
    claims
    |> json_items()
    |> Enum.map(fn claim ->
      %{
        claimId: claim["claim_id"],
        claimType: claim["claim_type"],
        text: claim["text"],
        sourceKey: claim["source_key"],
        sourceTier: claim["source_tier"],
        documentRole: claim["document_role"],
        citationId: claim["citation_id"],
        canonicalFactOverride: false
      }
    end)
  end

  defp materialized_citations(citations) do
    citations
    |> json_items()
    |> Enum.map(fn citation ->
      %{
        citationId: citation["citation_id"],
        sourceKey: citation["source_key"],
        sourceTier: citation["source_tier"],
        documentRole: citation["document_role"],
        provider: citation["provider"],
        url: citation["url"],
        label: citation["label"],
        isCanonicalSource: citation["is_canonical_source"]
      }
    end)
  end

  defp overlay_claims(payload) do
    payload
    |> Map.get("overlay_claims", [])
    |> Enum.map(fn claim ->
      %{
        claimId: claim["claimId"],
        claimType: claim_type(claim),
        text: claim["summary"],
        sourceKey: @source_key,
        sourceTier: payload["source_tier"],
        documentRole: payload["document_role"],
        citationId: claim["sourceCitationRef"],
        canonicalFactOverride: false
      }
    end)
  end

  defp claim_type(%{"claimKind" => "secondary_confirmation"}), do: "article_metadata"
  defp claim_type(%{"claimKind" => "news_only_context"}), do: "context_summary"
  defp claim_type(_claim), do: "context_summary"

  defp overlay_url(payload, citations) do
    first_present([
      payload["source_url"],
      payload["sourceUrl"],
      get_in(List.first(citations) || %{}, [:url])
    ])
  end

  defp provider_name(payload, citations) do
    first_present([
      provider_from_source_name(payload["source_name"]),
      provider_from_source_name(payload["sourceName"]),
      get_in(List.first(citations) || %{}, [:provider]),
      "Reuters"
    ])
  end

  defp provider_from_source_name(nil), do: nil

  defp provider_from_source_name(source_name) do
    if String.contains?(to_string(source_name), "Reuters") or String.contains?(to_string(source_name), "ロイター") do
      "Reuters"
    else
      source_name
    end
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

  defp raw_document_external_id(%{"article_external_id" => article_external_id}) when is_binary(article_external_id) do
    "#{article_external_id}:article-metadata"
  end

  defp raw_document_external_id(_payload), do: nil

  defp json_items(%{"items" => items}) when is_list(items), do: items
  defp json_items(items) when is_list(items), do: items
  defp json_items(_value), do: []

  defp datetime_iso8601(nil), do: nil
  defp datetime_iso8601(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp datetime_iso8601(value), do: value

  defp first_present(values) do
    Enum.find(values, &present?/1)
  end

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(nil), do: false
  defp present?(_value), do: true

  defp uuid_param(value) when is_binary(value) do
    case Ecto.UUID.dump(value) do
      {:ok, dumped} -> dumped
      :error -> value
    end
  end

  defp uuid_param(value), do: value
end
