defmodule DisclosureAutomationWeb.AdminDuplicateGroupController do
  @moduledoc false

  use DisclosureAutomationWeb, :controller

  alias DisclosureAutomation.Runtime.Stage59DuplicateGroupInternalReadProjection
  alias DisclosureAutomation.Runtime.Stage61DuplicateGroupActionStateWriter

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

  def confirm(conn, params), do: run_action(conn, params, "confirm_duplicate_group")
  def reject(conn, params), do: run_action(conn, params, "reject_duplicate_group")
  def mark_review(conn, params), do: run_action(conn, params, "mark_duplicate_group_needs_review")
  def clear_review_state(conn, params), do: run_action(conn, params, "clear_duplicate_group_review_state")

  defp run_action(conn, %{"group_id" => group_id} = params, operation) do
    action_attrs = build_action_attrs(group_id, operation, params)
    actor_context = build_actor_context(params)

    case Stage61DuplicateGroupActionStateWriter.record_action(action_attrs, actor_context) do
      {:ok, result} ->
        json(conn, action_result_json(result))

      {:error, reason} ->
        conn
        |> put_status(error_status(reason))
        |> json(%{"error" => error_reason(reason)})
    end
  end

  defp build_action_attrs(group_id, operation, params) do
    %{
      "group_id" => group_id,
      "action_operation" => operation,
      "actor_permissions" => list_param(params, "actor_permissions"),
      "actor_id_hash" => string_param(params, "actor_id_hash"),
      "request_id_hash" => string_param(params, "request_id_hash"),
      "idempotency_key_hash" => string_param(params, "idempotency_key_hash"),
      "operator_reason_redacted" => string_param(params, "operator_reason_redacted"),
      "redaction_status" => string_param(params, "redaction_status", "passed")
    }
  end

  defp build_actor_context(params) do
    %{
      "authenticated" => value_param(params, "authenticated", true),
      "roles" => list_param(params, "roles"),
      "permissions" => list_param(params, "actor_permissions"),
      "actor_id_hash" => string_param(params, "actor_id_hash"),
      "result_status" => string_param(params, "result_status", "completed"),
      "redaction_status" => string_param(params, "redaction_status", "passed"),
      "pre_review_state" => string_param(params, "pre_review_state", "unknown"),
      "post_review_state" => string_param(params, "post_review_state"),
      "failure_code" => string_param(params, "failure_code"),
      "created_at" => string_param(params, "created_at")
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp action_result_json(result) do
    %{
      mode: result.mode,
      group_id: result.group_id,
      action_operation: result.action_operation,
      required_permission: result.required_permission,
      actor_id_hash: result.actor_id_hash,
      request_id_hash: result.request_id_hash,
      idempotency_key_hash: result.idempotency_key_hash,
      result_status: result.result_status,
      redaction_status: result.redaction_status,
      pre_review_state: result.pre_review_state,
      post_review_state: result.post_review_state,
      action_event_id: result.action_event_id,
      action_event_inserted: result.action_event_inserted,
      review_state_id: result.review_state_id,
      review_state: result.review_state,
      authorized: result.authorized,
      authorization_result: result.authorization_result,
      public_response_shape_mutation: result.public_response_shape_mutation,
      public_api_duplicate_group_fields: result.public_api_duplicate_group_fields,
      public_feed_duplicate_group_fields: result.public_feed_duplicate_group_fields,
      canonical_feed_mutation: result.canonical_feed_mutation,
      provider_canonical_feed_item_creation: result.provider_canonical_feed_item_creation,
      news_only_event_creation: result.news_only_event_creation,
      official_event_merge: result.official_event_merge,
      official_fact_override: result.official_fact_override,
      official_citation_override: result.official_citation_override,
      trigger_live_fetch: result.trigger_live_fetch,
      scheduler_enabled: result.scheduler_enabled,
      network_access: result.network_access,
      enqueue_performed: result.enqueue_performed,
      materializer_triggered: result.materializer_triggered,
      route_added: true,
      ui_added: result.ui_added,
      action_endpoint_added: true,
      schema_migration: result.schema_migration
    }
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

  defp list_param(params, key) do
    case value_param(params, key, []) do
      values when is_list(values) -> values
      value when is_binary(value) -> [value]
      _value -> []
    end
  end

  defp string_param(params, key, default \\ nil) do
    case value_param(params, key, default) do
      nil -> nil
      value when is_binary(value) -> value
      value -> to_string(value)
    end
  end

  defp value_param(params, key, default) do
    action_params = Map.get(params, "action", %{})

    cond do
      Map.has_key?(params, key) -> Map.get(params, key)
      is_map(action_params) and Map.has_key?(action_params, key) -> Map.get(action_params, key)
      true -> default
    end
  end

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn {key, value} -> {to_string(key), value} end)
  end

  defp stringify_keys(value), do: value

  defp encode_datetime(nil), do: nil
  defp encode_datetime(%DateTime{} = datetime), do: DateTime.to_iso8601(datetime)
  defp encode_datetime(%NaiveDateTime{} = datetime), do: NaiveDateTime.to_iso8601(datetime)
  defp encode_datetime(value), do: value

  defp error_status(:duplicate_group_not_found), do: :not_found
  defp error_status(:duplicate_group_action_authentication_required), do: :forbidden
  defp error_status(:operator_or_admin_role_required), do: :forbidden
  defp error_status(:actor_hash_mismatch), do: :forbidden
  defp error_status({:missing_action_permission, _permission}), do: :forbidden
  defp error_status({:required_permission_missing, _permission}), do: :forbidden
  defp error_status({:read_only_permission_cannot_authorize_action, _permission}), do: :forbidden
  defp error_status({:read_only_permission_cannot_execute_action, _permission}), do: :forbidden
  defp error_status(_reason), do: :bad_request

  defp error_reason(reason) when is_atom(reason), do: Atom.to_string(reason)
  defp error_reason(reason), do: inspect(reason)
end
