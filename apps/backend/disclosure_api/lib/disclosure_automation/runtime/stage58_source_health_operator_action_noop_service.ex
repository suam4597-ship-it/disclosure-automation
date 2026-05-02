defmodule DisclosureAutomation.Runtime.Stage58SourceHealthOperatorActionNoopService do
  @moduledoc false

  alias DisclosureAutomation.Runtime.Stage58SourceHealthOperatorActionAuditContract
  alias DisclosureAutomation.Runtime.Stage58SourceHealthOperatorActionContract

  @max_actor_hash_length 128

  @prohibited_key_fragments [
    "actorid",
    "articlebody",
    "fulltext",
    "fullarticletext",
    "rawhtml",
    "rawresponsebody",
    "responsebody",
    "providerresponsebody",
    "requestheaders",
    "responseheaders",
    "headers",
    "credentials",
    "apikey",
    "api_key",
    "authorization",
    "cookie",
    "subscriptionkey",
    "subscription-key",
    "bearertoken",
    "bearer_token",
    "signedprivateurl",
    "signed_private_url",
    "canonicalfeeditempayload",
    "providercanonicalcreationpayload"
  ]

  def defaults do
    %{
      service_scope: "operator_action_noop_only",
      operator_only: true,
      action_contract_required: true,
      audit_contract_required: true,
      no_op: true,
      fake_side_effects_only: true,
      advisory_only: true,
      public_response_shape_mutation: false,
      trigger_live_fetch: false,
      scheduler_enabled: false,
      network_access: "forbidden",
      db_write: false,
      audit_write_performed: false,
      enqueue_performed: false,
      source_health_mutation: false,
      canonical_feed_mutation: false,
      provider_canonical_feed_item_creation: false,
      news_only_event_creation: false,
      action_endpoint_added: false,
      route_added: false,
      ui_added: false
    }
  end

  def preview_action(action_attrs, audit_context \\ %{}, opts \\ [])

  def preview_action(action_attrs, audit_context, opts) when is_map(audit_context) do
    with :ok <- forbid_runtime_side_effects(opts),
         :ok <- reject_prohibited_fields(audit_context),
         {:ok, actor_id_hash} <- validate_hash(get_value(audit_context, "actor_id_hash"), :actor_id_hash_required),
         {:ok, action} <- Stage58SourceHealthOperatorActionContract.validate_action(action_attrs, opts),
         {:ok, action_audit} <- Stage58SourceHealthOperatorActionContract.audit_envelope(action),
         {:ok, audit_event} <-
           Stage58SourceHealthOperatorActionAuditContract.validate_event(
             build_audit_event(action, action_audit, actor_id_hash, audit_context),
             opts
           ) do
      {:ok,
       defaults()
       |> Map.merge(%{
         operation: action.operation,
         required_permission: action.required_permission,
         source_key: action.source_key,
         actor_id_hash: actor_id_hash,
         action: action,
         audit_event: audit_event,
         action_result: build_action_result(action, audit_event)
       })}
    end
  end

  def preview_action(_action_attrs, _audit_context, _opts), do: {:error, :invalid_stage58_operator_action_noop_request}

  defp build_audit_event(action, action_audit, actor_id_hash, audit_context) do
    %{
      operation: action.operation,
      permission: action.required_permission,
      source_key: action.source_key,
      actor_id_hash: actor_id_hash,
      request_id_hash: action_audit.request_id_hash,
      idempotency_key_hash: action_audit.idempotency_key_hash,
      operator_reason_redacted: action_audit.operator_reason_redacted,
      result_status: get_value(audit_context, "result_status", "accepted"),
      redaction_status: get_value(audit_context, "redaction_status", "passed"),
      pre_action_health_status:
        get_value(audit_context, "pre_action_health_status", action.expected_current_health_status),
      post_action_health_status:
        get_value(audit_context, "post_action_health_status", action.expected_current_health_status),
      pre_action_operational_state:
        get_value(audit_context, "pre_action_operational_state", action.expected_current_operational_state),
      post_action_operational_state:
        get_value(audit_context, "post_action_operational_state", action.expected_current_operational_state),
      failure_code_redacted: get_value(audit_context, "failure_code_redacted"),
      started_at: get_value(audit_context, "started_at"),
      completed_at: get_value(audit_context, "completed_at")
    }
  end

  defp build_action_result(action, audit_event) do
    %{
      mode: "stage58_noop_operator_action",
      operation: action.operation,
      required_permission: action.required_permission,
      source_key: action.source_key,
      accepted: true,
      no_op: true,
      fake_side_effects_only: true,
      audit_event_built: true,
      audit_write_performed: false,
      db_write: false,
      enqueue_performed: false,
      network_access: "forbidden",
      trigger_live_fetch: false,
      scheduler_enabled: false,
      source_health_mutation: false,
      canonical_feed_mutation: false,
      provider_canonical_feed_item_creation: false,
      news_only_event_creation: false,
      public_response_shape_mutation: false,
      action_endpoint_added: false,
      route_added: false,
      ui_added: false,
      result_status: audit_event.result_status,
      redaction_status: audit_event.redaction_status
    }
  end

  defp forbid_runtime_side_effects(opts) do
    if Keyword.get(opts, :db_write, false) or Keyword.get(opts, :audit_write_performed, false) or
         Keyword.get(opts, :enqueue_performed, false) or Keyword.get(opts, :network_access, false) do
      {:error, :runtime_side_effect_not_allowed_in_stage58_noop_action_service}
    else
      :ok
    end
  end

  defp reject_prohibited_fields(value) do
    case find_prohibited_field(value) do
      nil -> :ok
      path -> {:error, {:prohibited_field, path}}
    end
  end

  defp find_prohibited_field(value, path \\ "")

  defp find_prohibited_field(%{} = map, path) do
    Enum.find_value(map, fn {key, value} ->
      key_string = to_string(key)
      current_path = if path == "", do: key_string, else: "#{path}.#{key_string}"

      cond do
        key_string in ["actor_id_hash", "result_status", "redaction_status", "pre_action_health_status",
                       "post_action_health_status", "pre_action_operational_state", "post_action_operational_state",
                       "failure_code_redacted", "started_at", "completed_at"] ->
          find_prohibited_field(value, current_path)

        prohibited_key?(key_string) ->
          current_path

        true ->
          find_prohibited_field(value, current_path)
      end
    end)
  end

  defp find_prohibited_field(values, path) when is_list(values) do
    values
    |> Enum.with_index()
    |> Enum.find_value(fn {value, index} -> find_prohibited_field(value, "#{path}[#{index}]") end)
  end

  defp find_prohibited_field(value, path) when is_binary(value) do
    if prohibited_value?(value), do: path, else: nil
  end

  defp find_prohibited_field(_value, _path), do: nil

  defp validate_hash(value, error_tag) when is_binary(value) do
    trimmed = String.trim(value)

    cond do
      trimmed == "" -> {:error, error_tag}
      String.length(trimmed) > @max_actor_hash_length -> {:error, {:string_too_long, error_tag, @max_actor_hash_length}}
      prohibited_value?(trimmed) -> {:error, {:prohibited_value, error_tag}}
      not String.starts_with?(trimmed, "sha256:") -> {:error, {:invalid_hash, error_tag}}
      true -> {:ok, trimmed}
    end
  end

  defp validate_hash(_value, error_tag), do: {:error, error_tag}

  defp prohibited_key?(key) do
    normalized = normalize_token(key)

    Enum.any?(@prohibited_key_fragments, fn fragment ->
      String.contains?(normalized, normalize_token(fragment))
    end)
  end

  defp prohibited_value?(value) do
    String.contains?(value, "BEGIN PRIVATE KEY") or
      String.contains?(value, sensitive_header_prefix(:authorization)) or
      String.contains?(value, sensitive_header_prefix(:cookie)) or
      String.contains?(value, sensitive_header_prefix(:subscription_key))
  end

  defp sensitive_header_prefix(:authorization), do: "Author" <> "ization" <> ":"
  defp sensitive_header_prefix(:cookie), do: "Coo" <> "kie" <> ":"
  defp sensitive_header_prefix(:subscription_key), do: "Subscription" <> "-" <> "Key" <> ":"

  defp get_value(map, key, default \\ nil)

  defp get_value(map, key, default) when is_map(map) do
    cond do
      Map.has_key?(map, key) -> Map.get(map, key)
      Map.has_key?(map, String.to_atom(key)) -> Map.get(map, String.to_atom(key))
      true -> default
    end
  end

  defp get_value(_value, _key, default), do: default

  defp normalize_token(value) do
    value
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]/, "")
  end
end
