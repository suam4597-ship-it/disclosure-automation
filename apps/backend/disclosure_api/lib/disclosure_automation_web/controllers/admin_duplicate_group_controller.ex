defmodule DisclosureAutomationWeb.AdminDuplicateGroupController do
  @moduledoc false

  use DisclosureAutomationWeb, :controller

  alias DisclosureAutomation.Runtime.Stage59DuplicateGroupInternalReadProjection

  def index(conn, params) do
    case Stage59DuplicateGroupInternalReadProjection.list(params) do
      {:ok, page} ->
        json(conn, %{
          view_scope: page.view_scope,
          read_only: page.read_only,
          advisory_only: page.advisory_only,
          operator_only: page.operator_only,
          non_canonical: page.non_canonical,
          bounded: page.bounded,
          redacted: page.redacted,
          mode: page.mode,
          filters: stringify_keys(page.filters),
          item_count: page.item_count,
          limit: page.limit,
          items: Enum.map(page.items, &group_json/1),
          public_response_shape_mutation: page.public_response_shape_mutation,
          public_api_duplicate_group_fields: page.public_api_duplicate_group_fields,
          public_feed_duplicate_group_fields: page.public_feed_duplicate_group_fields,
          item_overlays_shape_mutation: page.item_overlays_shape_mutation,
          news_overlays_shape_mutation: page.news_overlays_shape_mutation,
          materializer_output_mutation: page.materializer_output_mutation,
          canonical_feed_mutation: page.canonical_feed_mutation,
          provider_canonical_feed_item_creation: page.provider_canonical_feed_item_creation,
          news_only_event_creation: page.news_only_event_creation,
          official_event_merge: page.official_event_merge,
          official_fact_override: page.official_fact_override,
          official_citation_override: page.official_citation_override,
          trigger_live_fetch: page.trigger_live_fetch,
          scheduler_enabled: page.scheduler_enabled,
          network_access: page.network_access,
          route_added: true,
          ui_added: page.ui_added,
          action_endpoint_added: page.action_endpoint_added,
          materializer_triggered: page.materializer_triggered
        })

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{"error" => error_reason(reason)})
    end
  end

  def show(conn, %{"group_id" => group_id}) do
    case Stage59DuplicateGroupInternalReadProjection.get(group_id) do
      {:ok, projection} ->
        json(conn, %{
          view_scope: projection.view_scope,
          read_only: projection.read_only,
          advisory_only: projection.advisory_only,
          operator_only: projection.operator_only,
          non_canonical: projection.non_canonical,
          bounded: projection.bounded,
          redacted: projection.redacted,
          mode: projection.mode,
          item: group_json(projection.item),
          public_response_shape_mutation: projection.public_response_shape_mutation,
          public_api_duplicate_group_fields: projection.public_api_duplicate_group_fields,
          public_feed_duplicate_group_fields: projection.public_feed_duplicate_group_fields,
          item_overlays_shape_mutation: projection.item_overlays_shape_mutation,
          news_overlays_shape_mutation: projection.news_overlays_shape_mutation,
          materializer_output_mutation: projection.materializer_output_mutation,
          canonical_feed_mutation: projection.canonical_feed_mutation,
          provider_canonical_feed_item_creation: projection.provider_canonical_feed_item_creation,
          news_only_event_creation: projection.news_only_event_creation,
          official_event_merge: projection.official_event_merge,
          official_fact_override: projection.official_fact_override,
          official_citation_override: projection.official_citation_override,
          trigger_live_fetch: projection.trigger_live_fetch,
          scheduler_enabled: projection.scheduler_enabled,
          network_access: projection.network_access,
          route_added: true,
          ui_added: projection.ui_added,
          action_endpoint_added: projection.action_endpoint_added,
          materializer_triggered: projection.materializer_triggered
        })

      {:error, :duplicate_group_not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{"error" => "duplicate_group_not_found"})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{"error" => error_reason(reason)})
    end
  end

  defp group_json(group) do
    %{
      group_id: group.group_id,
      confidence: group.confidence,
      source_keys: group.source_keys,
      match_reasons: group.match_reasons,
      member_count: group.member_count,
      has_official_tdnet_event: group.has_official_tdnet_event,
      has_provider_overlay: group.has_provider_overlay,
      redaction_status: group.redaction_status,
      inserted_at: encode_datetime(group.inserted_at),
      updated_at: encode_datetime(group.updated_at),
      members: Enum.map(group.members, &member_json/1)
    }
  end

  defp member_json(member) do
    %{
      member_id: member.member_id,
      member_kind: member.member_kind,
      source_key: member.source_key,
      provider: member.provider,
      external_id_hash: member.external_id_hash,
      official_event_id: member.official_event_id,
      overlay_id: member.overlay_id,
      confidence: member.confidence,
      match_reasons: member.match_reasons,
      redaction_status: member.redaction_status,
      inserted_at: encode_datetime(member.inserted_at),
      updated_at: encode_datetime(member.updated_at)
    }
  end

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn {key, value} -> {to_string(key), value} end)
  end

  defp stringify_keys(value), do: value

  defp encode_datetime(nil), do: nil
  defp encode_datetime(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
  defp encode_datetime(%NaiveDateTime{} = datetime), do: NaiveDateTime.to_iso8601(datetime)
  defp encode_datetime(value), do: value

  defp error_reason(reason) when is_atom(reason), do: Atom.to_string(reason)
  defp error_reason(reason), do: inspect(reason)
end
