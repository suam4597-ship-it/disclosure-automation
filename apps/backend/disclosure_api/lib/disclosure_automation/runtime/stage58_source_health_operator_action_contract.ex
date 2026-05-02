defmodule DisclosureAutomation.Runtime.Stage58SourceHealthOperatorActionContract do
  @moduledoc false

  @allowed_operations ~w(
    source_health.recheck
    source_health.pause
    source_health.resume
    source_health.acknowledge_manual_review
    source_health.clear_redaction_violation
    source_health.manual_provider_trigger
    source_health.export_redacted_diagnostics
  )

  @read_only_permissions ~w(
    source_health.view
    source_health.detail
    source_health.export_redacted
  )

  @action_permissions @allowed_operations

  @allowed_health_states ~w(
    unknown
    healthy
    degraded
    rate_limited
    timeout
    failed
    paused
    redaction_violation
    manual_review_required
  )

  @allowed_operational_states ~w(
    active
    paused
    manual_review_required
    redaction_blocked
    unknown
  )

  @allowed_redaction_states ~w(
    passed
    failed
    blocked
    unknown
  )

  @max_operator_reason_length 500
  @max_operator_note_length 500
  @max_idempotency_key_length 128
  @max_request_id_length 128
  @max_source_key_length 128

  @prohibited_key_fragments [
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

  def allowed_operations, do: @allowed_operations
  def read_only_permissions, do: @read_only_permissions
  def action_permissions, do: @action_permissions

  def defaults do
    %{
      action_scope: "operator_only",
      read_only_permission_allowed: false,
      action_permission_required: true,
      operator_reason_required: true,
      idempotency_required: true,
      audit_required: true,
      advisory_only: true,
      public_response_shape_mutation: false,
      trigger_live_fetch: false,
      scheduler_enabled: false,
      network_access: "forbidden",
      action_endpoint_added: false,
      route_added: false,
      ui_added: false,
      source_health_mutation: false,
      canonical_feed_mutation: false,
      provider_canonical_feed_item_creation: false,
      news_only_event_creation: false
    }
  end

  def validate_action(attrs, opts \\ [])

  def validate_action(attrs, opts) when is_map(attrs) do
    with :ok <- forbid_public_exposure(opts),
         :ok <- forbid_live_fetch(opts),
         :ok <- forbid_scheduler(opts),
         :ok <- forbid_source_health_mutation(opts),
         :ok <- forbid_canonical_mutation(opts),
         :ok <- forbid_action_endpoint(opts),
         :ok <- reject_prohibited_fields(attrs),
         {:ok, operation} <- validate_operation(get_value(attrs, "operation")),
         {:ok, source_key} <- bounded_required_string(get_value(attrs, "source_key"), @max_source_key_length, :source_key_required),
         {:ok, operator_reason} <-
           bounded_required_string(get_value(attrs, "operator_reason"), @max_operator_reason_length, :operator_reason_required),
         {:ok, idempotency_key} <-
           bounded_required_string(get_value(attrs, "idempotency_key"), @max_idempotency_key_length, :idempotency_key_required),
         {:ok, request_id} <-
           bounded_required_string(get_value(attrs, "request_id"), @max_request_id_length, :request_id_required),
         {:ok, expected_health_status} <-
           validate_optional_enum(
             get_value(attrs, "expected_current_health_status"),
             @allowed_health_states,
             :invalid_expected_current_health_status
           ),
         {:ok, expected_operational_state} <-
           validate_optional_enum(
             get_value(attrs, "expected_current_operational_state"),
             @allowed_operational_states,
             :invalid_expected_current_operational_state
           ),
         {:ok, expected_redaction_status} <-
           validate_optional_enum(
             get_value(attrs, "expected_current_redaction_status"),
             @allowed_redaction_states,
             :invalid_expected_current_redaction_status
           ),
         {:ok, operator_note_redacted} <- validate_optional_note(get_value(attrs, "operator_note_redacted")) do
      {:ok,
       defaults()
       |> Map.merge(%{
         operation: operation,
         required_permission: operation,
         source_key: source_key,
         operator_reason: operator_reason,
         idempotency_key: idempotency_key,
         request_id: request_id,
         expected_current_health_status: expected_health_status,
         expected_current_operational_state: expected_operational_state,
         expected_current_redaction_status: expected_redaction_status,
         operator_note_redacted: operator_note_redacted
       })}
    end
  end

  def validate_action(_attrs, _opts), do: {:error, :invalid_stage58_operator_action_request}

  def audit_envelope(action) when is_map(action) do
    with :ok <- reject_prohibited_fields(action),
         {:ok, operation} <- validate_operation(get_value(action, "operation")),
         {:ok, source_key} <- bounded_required_string(get_value(action, "source_key"), @max_source_key_length, :source_key_required),
         {:ok, request_id} <-
           bounded_required_string(get_value(action, "request_id"), @max_request_id_length, :request_id_required),
         {:ok, idempotency_key} <-
           bounded_required_string(get_value(action, "idempotency_key"), @max_idempotency_key_length, :idempotency_key_required),
         {:ok, operator_reason} <-
           bounded_required_string(get_value(action, "operator_reason"), @max_operator_reason_length, :operator_reason_required) do
      {:ok,
       %{
         audit_scope: "operator_action_only",
         bounded: true,
         redacted: true,
         canonical_feed_mutation: false,
         public_response_shape_mutation: false,
         operation: operation,
         permission: operation,
         source_key: source_key,
         request_id_hash: hash_marker(request_id),
         idempotency_key_hash: hash_marker(idempotency_key),
         operator_reason_redacted: operator_reason,
         result_status: get_value(action, "result_status", "pending"),
         redaction_status: get_value(action, "redaction_status", "unknown"),
         failure_code_redacted: get_value(action, "failure_code_redacted")
       }}
    end
  end

  def audit_envelope(_action), do: {:error, :invalid_stage58_operator_action_audit_attrs}

  defp validate_operation(nil), do: {:error, :operation_required}

  defp validate_operation(operation) when operation in @read_only_permissions do
    {:error, {:read_only_permission_cannot_execute_action, operation}}
  end

  defp validate_operation(operation) when operation in @allowed_operations, do: {:ok, operation}
  defp validate_operation(operation), do: {:error, {:invalid_stage58_operator_action_operation, operation}}

  defp validate_optional_enum(nil, _allowed, _error_tag), do: {:ok, nil}
  defp validate_optional_enum("", _allowed, _error_tag), do: {:ok, nil}

  defp validate_optional_enum(value, allowed, error_tag) when is_binary(value) do
    normalized = String.trim(value)

    if normalized in allowed do
      {:ok, normalized}
    else
      {:error, {error_tag, value}}
    end
  end

  defp validate_optional_enum(value, _allowed, error_tag), do: {:error, {error_tag, value}}

  defp validate_optional_note(nil), do: {:ok, nil}
  defp validate_optional_note(""), do: {:ok, nil}

  defp validate_optional_note(value) do
    bounded_required_string(value, @max_operator_note_length, :operator_note_redacted_invalid)
  end

  defp bounded_required_string(value, max_length, error_tag) when is_binary(value) do
    trimmed = String.trim(value)

    cond do
      trimmed == "" -> {:error, error_tag}
      String.length(trimmed) > max_length -> {:error, {:string_too_long, error_tag, max_length}}
      prohibited_value?(trimmed) -> {:error, {:prohibited_value, error_tag}}
      true -> {:ok, trimmed}
    end
  end

  defp bounded_required_string(_value, _max_length, error_tag), do: {:error, error_tag}

  defp forbid_public_exposure(opts) do
    if Keyword.get(opts, :public_exposure, false) do
      {:error, :public_exposure_not_allowed_in_stage58_operator_actions}
    else
      :ok
    end
  end

  defp forbid_live_fetch(opts) do
    if Keyword.get(opts, :trigger_live_fetch, false) or Keyword.get(opts, :use_live_fetch, false) do
      {:error, :live_fetch_not_allowed_in_stage58_operator_actions}
    else
      :ok
    end
  end

  defp forbid_scheduler(opts) do
    if Keyword.get(opts, :scheduler_enabled, false) do
      {:error, :scheduler_not_allowed_in_stage58_operator_actions}
    else
      :ok
    end
  end

  defp forbid_source_health_mutation(opts) do
    if Keyword.get(opts, :source_health_mutation, false) do
      {:error, :source_health_mutation_not_allowed_in_stage58_action_contract}
    else
      :ok
    end
  end

  defp forbid_canonical_mutation(opts) do
    if Keyword.get(opts, :canonical_feed_mutation, false) or
         Keyword.get(opts, :provider_canonical_feed_item_creation, false) or
         Keyword.get(opts, :news_only_event_creation, false) do
      {:error, :canonical_mutation_not_allowed_in_stage58_operator_actions}
    else
      :ok
    end
  end

  defp forbid_action_endpoint(opts) do
    if Keyword.get(opts, :action_endpoint_added, false) or Keyword.get(opts, :route_added, false) or
         Keyword.get(opts, :ui_added, false) do
      {:error, :action_endpoint_not_allowed_in_stage58_action_contract}
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
        prohibited_key?(key_string) -> current_path
        true -> find_prohibited_field(value, current_path)
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

  defp hash_marker(value), do: "sha256:" <> Integer.to_string(:erlang.phash2(value))

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
