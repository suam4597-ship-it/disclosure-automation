defmodule DisclosureAutomation.Feed do
  @moduledoc false

  import Ecto.Query

  alias DisclosureAutomation.Jobs
  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Runtime.Stage5NewsOverlayReadModel
  alias DisclosureAutomation.Schema.CanonicalFeedItem
  alias DisclosureAutomation.Schema.FeedSnapshot
  alias DisclosureAutomation.Workers.BuildFeedSnapshotWorker

  def get_hero(opts \\ []) do
    get_slot("hero.global_priority", "global", opts)
  end

  def get_region(region_code, opts \\ []) when is_binary(region_code) do
    get_slot("lane.#{region_code}", region_code, opts)
  end

  def get_event(event_id) when is_binary(event_id) do
    case Repo.get_by(CanonicalFeedItem, event_id: event_id) do
      nil -> {:error, :not_found}
      item -> {:ok, present_item(item)}
    end
  end

  def enqueue_rebuild(region_codes, opts \\ []) when is_list(region_codes) do
    Jobs.enqueue(
      BuildFeedSnapshotWorker,
      %{
        "region_codes" => region_codes,
        "ingestion_run_id" => Keyword.get(opts, :ingestion_run_id)
      },
      queue: :feed
    )
  end

  def rebuild_snapshots(region_codes, opts \\ []) when is_list(region_codes) do
    ingestion_run_id = Keyword.get(opts, :ingestion_run_id)

    Enum.reduce_while(region_codes, {:ok, []}, fn region_code, {:ok, acc} ->
      case build_region_snapshot(region_code, ingestion_run_id) do
        {:ok, snapshot} -> {:cont, {:ok, [snapshot | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
    |> case do
      {:ok, snapshots} ->
        case build_hero_snapshot(ingestion_run_id) do
          {:ok, hero_snapshot} -> {:ok, Enum.reverse([hero_snapshot | snapshots])}
          {:error, reason} -> {:error, reason}
        end

      error ->
        error
    end
  end

  defp get_slot(slot_id, region_code, opts) do
    case latest_snapshot(slot_id) do
      nil -> build_ephemeral_slot(slot_id, region_code, opts)
      snapshot -> {:ok, present_snapshot_payload(snapshot.payload)}
    end
  end

  defp latest_snapshot(slot_id) do
    from(snapshot in FeedSnapshot,
      where: snapshot.slot_id == ^slot_id,
      order_by: [desc: snapshot.generated_at, desc: snapshot.inserted_at],
      limit: 1
    )
    |> Repo.one()
  end

  defp build_ephemeral_slot("hero.global_priority", _region_code, _opts) do
    items =
      from(item in CanonicalFeedItem,
        where: item.status in ["ready", "published"],
        order_by: [desc: item.published_at],
        limit: 9
      )
      |> Repo.all()

    {:ok, snapshot_payload("hero.global_priority", "global", items, DateTime.utc_now())}
  end

  defp build_ephemeral_slot(slot_id, region_code, _opts) do
    items =
      from(item in CanonicalFeedItem,
        where: item.region_code == ^region_code and item.status in ["ready", "published"],
        order_by: [desc: item.published_at],
        limit: 20
      )
      |> Repo.all()

    {:ok, snapshot_payload(slot_id, region_code, items, DateTime.utc_now())}
  end

  defp build_region_snapshot(region_code, ingestion_run_id) do
    slot_id = "lane.#{region_code}"

    items =
      from(item in CanonicalFeedItem,
        where: item.region_code == ^region_code and item.status in ["ready", "published"],
        order_by: [desc: item.published_at],
        limit: 20
      )
      |> Repo.all()

    upsert_snapshot(slot_id, region_code, items, ingestion_run_id)
  end

  defp build_hero_snapshot(ingestion_run_id) do
    items =
      from(item in CanonicalFeedItem,
        where: item.status in ["ready", "published"],
        order_by: [desc: item.published_at],
        limit: 9
      )
      |> Repo.all()

    upsert_snapshot("hero.global_priority", "global", items, ingestion_run_id)
  end

  defp upsert_snapshot(slot_id, region_code, items, ingestion_run_id) do
    generated_at = DateTime.utc_now()

    snapshot_key =
      [slot_id, DateTime.to_unix(generated_at, :microsecond), ingestion_run_id || Ecto.UUID.generate()]
      |> Enum.map(&to_string/1)
      |> Enum.join(":")

    attrs = %{
      ingestion_run_id: ingestion_run_id,
      snapshot_key: snapshot_key,
      slot_id: slot_id,
      region_code: region_code,
      generated_at: generated_at,
      item_event_ids: Enum.map(items, &(&1.event_id || &1.story_key)),
      payload: snapshot_payload(slot_id, region_code, items, generated_at),
      metadata: %{"item_count" => length(items)}
    }

    %FeedSnapshot{}
    |> FeedSnapshot.changeset(attrs)
    |> Repo.insert()
  end

  defp snapshot_payload(slot_id, region_code, items, generated_at) do
    %{
      "slot_id" => slot_id,
      "region_code" => region_code,
      "generated_at_utc" => DateTime.to_iso8601(generated_at),
      "item_event_ids" => Enum.map(items, &(&1.event_id || &1.story_key)),
      "items" => Enum.map(items, &present_item/1)
    }
  end

  defp present_snapshot_payload(%{} = payload) do
    Map.update(payload, "items", [], fn items -> Enum.map(items || [], &present_snapshot_item/1) end)
  end

  defp present_snapshot_payload(payload), do: payload

  defp present_snapshot_item(%{} = item_payload) do
    Map.put(item_payload, "news_overlays", news_overlays_for(item_payload["event_id"] || item_payload["story_key"]))
  end

  defp present_snapshot_item(item_payload), do: item_payload

  defp present_item(item) do
    item_payload =
      if map_size(item.contract_v1 || %{}) > 0 do
        item.contract_v1
      else
        %{
          "event_id" => item.event_id,
          "story_key" => item.story_key,
          "headline_local" => item.headline,
          "fact_summary_ko" => item.summary,
          "canonical_url" => item.canonical_url,
          "published_at_utc" => item.published_at && DateTime.to_iso8601(item.published_at),
          "canonical_event_type" => item.canonical_event_type,
          "event_family" => item.event_family,
          "region_code" => item.region_code,
          "home_market_region_code" => item.home_market_region_code,
          "metadata" => item.metadata || %{}
        }
      end

    Map.put(item_payload, "news_overlays", news_overlays_for(item.event_id || item.story_key))
  end

  defp news_overlays_for(nil), do: []

  defp news_overlays_for(event_id) when is_binary(event_id) do
    case Stage5NewsOverlayReadModel.get_by_event_id(event_id) do
      {:ok, %{item: %{overlays: overlays}}} -> Enum.map(overlays, &present_overlay/1)
      _ -> []
    end
  end

  defp present_overlay(overlay) do
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
      "canonical_fact_override" => overlay.canonicalFactOverride,
      "overlay_claims" => Enum.map(overlay.overlayClaims || [], &present_overlay_claim/1),
      "conflict_flags" => overlay.conflictFlags || [],
      "citations" => Enum.map(overlay.citations || [], &present_overlay_citation/1)
    }
  end

  defp present_overlay_claim(claim) do
    %{
      "claim_id" => claim.claimId,
      "claim_type" => claim.claimType,
      "text" => claim.text,
      "source_key" => claim.sourceKey,
      "source_tier" => claim.sourceTier,
      "document_role" => claim.documentRole,
      "citation_id" => claim.citationId,
      "canonical_fact_override" => claim.canonicalFactOverride
    }
  end

  defp present_overlay_citation(citation) do
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
end
