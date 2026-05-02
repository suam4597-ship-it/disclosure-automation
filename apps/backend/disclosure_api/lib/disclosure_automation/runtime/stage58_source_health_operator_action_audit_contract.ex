defmodule DisclosureAutomation.Runtime.Stage58SourceHealthOperatorActionAuditContract do
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

  @allowed_result_statuses ~w(
    pending
    accepted
    denied
    rejected
    failed
    completed
    skipped
  )

  @allowed_redaction_statuses ~w(
    passed
    failed
    blocked
    unknown
  )

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

  @max_source_key_length 128
  @max_hash_length 128
  @max_operator_reason_length 500
  @max_failure_code_length 128
  @max_timestamp_length 64

  @prohibited_exact_keys ~w(
    actorid
    requestid
    idempotencykey
    operatorreason
    operatornote
  )

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
  def allowed_result_statuses, do: @allowed_result_statuses
  def allowed_redaction_statuses, do: @allowed_redaction_statuses

  def defaults do
    %{
      audit_scope: "operator_action_audit_only",
      bounded: true,
      redacted: true,
      action_attempt_recorded: true,
      operator_only: true,
      advisory_only: true,
      public_response_shape_mutation: false,
      trigger_live_fetch: false,
      scheduler_enabled: false,
      network_access: "forbidden",
      audit_write_performed: false,
      source_health_mutation: false,
      canonical_feed_mutation: false,
      provider_canonical_feed_item_creation: false,
      news_only_event_creation: false,
      action_endpoint_added: false,
      route_added: false,
      ui_added: false
    }
  end

  def validate_event(attrs, opts \\ [])

  def validate_event(attrs, opts) when is_map(attrs) do
    with :ok <- forbid_public_exposure(opts),
         :ok <- forbid_live_fetch(opts),
         :ok <- forbid_scheduler(opts),
         :ok <- forbid_runtime_side_effects(opts),
         :ok <- forbid_source_health_mutation(opts),
         :ok <- forbid_canonical_mutation(opts),
         :ok <- forbid_action_endpoint(opts),
         :ok <- reject_prohibited_fields(attrs),
         {:ok, operation} <- validate_operation(get_value(attrs, "operation")),
         {:ok, permission} <- validate_permission(get_value(attrs, "permission"), operation),
         {:ok, source_key} <- bounded_required_string(get_value(attrs, "source_key"), @max_source_key_length, :source_key_required),
         {:ok, actor_id_hash} <- validate_hash(get_value(attrs, "actor_id_hash"), :actor_id_hash_required),
         {:ok, request_id_hash} <- validate_hash(get_value(attrs, "request_id_hash"), :request_id_hash_required),
         {:ok, idempotency_key_hash} <-
           validate_hash(get_value(attrs, "idempotency_key_hash"), :idempotency_key_hash_required),
         {:ok, operator_reason_redacted} <-
           bounded_required_string(
             get_value(attrs, "operator_reason_redacted"),
             @max_operator_reason_length,
             :operator_reason_redacted_required
           ),
         {:ok, result_status} <-
           validate_required_enum(get_value(attrs, "result_status"), @allowed_result_statuses, :invalid_result_status),
         {:ok, redaction_status} <-
           validate_required_enum(
             get_value(attrs, "redaction_status"),
             @allowed_redaction_statuses,
             :invalid_redaction_status
           ),
         {:ok, pre_action_health_status} <-
           validate_optional_enum(
             get_value(attrs, "pre_action_health_status"),
             @allowed_health_states,
             :invalid_pre_action_health_status
           ),
         {:ok, post_action_health_status} <-
           validate_optional_enum(
             get_value(attrs, "post_action_health_status"),
             @allowed_health_states,
             :invalid_post_action_health_status
           ),
         {:ok, pre_action_operational_state} <-
           validate_optional_enum(
             get_value(attrs, "pre_action_operational_state"),
             @allowed_operational_states,
             :invalid_pre_action_operational_state
           ),
         {:ok, post_action_operational_state} <-
           validate_optional_enum(
             get_value(attrs, "post_action_operational_state"),
             @allowed_operational_states,
             :invalid_post_action_operational_state
           ),
         {:ok, failure_code_redacted} <- validate_optional_string(get_value(attrs, "failure_code_redacted"), @max_failure_code_length),
         {:ok, started_at} <- validate_optional_string(get_value(attrs, "started_at"), @max_timestamp_length),
         {:ok, completed_at} <- validate_optional_string(get_value(attrs, "completed_at"), @max_timestamp_length) do
      {:ok,
       defaults()
       |> Map.merge(%{
         operation: operation,
         permission: permission,
         source_key: source_key,
         actor_id_hash: actor_id_hash,
         request_id_hash: request_id_hash,
         idempotency_key_hash: idempotency_key_hash,
         operator_reason_redacted: operator_reason_redacted,
         result_status: result_status,
         redaction_status: redaction_status,
         pre_action_health_status: pre_action_health_status,
         post_action_health_status: post_action_health_status,
         pre_action_operational_state: pre_action_operational_state,
         post_action_operational_state: post_action_operational_state,
         failure_code_redacted: failure_code_redacted,
         started_at: started_at,
         completed_at: completed_at
       })}
    end
  end

  def validate_event(_attrs, _opts), do: {:error, :invalid_stage58_operator_action_audit_event}

  defp validate_operation(nil), do: {:error, :operation_required}

  defp validate_operation(operation) when operation in @read_only_permissions do
    {:error, {:read_only_permission_cannot_be_audited_as_action, operation}}
  end

  defp validate_operation(operation) when operation in @allowed_operations, do: {:ok, operation}
  defp validate_operation(operation), do: {:error, {:invalid_stage58_operator_action_operation, operation}}

  defp validate_permission(nil, _operation), do: {:error, :permission_required}

  defp validate_permission(permission, operation) when permission == operation, do: {:ok, permission}

  defp validate_permission(permission, operation) when permission in @read_only_permissions do
    {:error, {:read_only_permission_cannot_authorize_action_audit, permission, operation}}
  end

  defp validate_permission(permission, operation), do: {:error, {:permission_mismatch, permission, operation}}

  defp validate_required_enum(nil, _allowed, error_tag), do: {:error, error_tag}

  defp validate_required_enum(value, allowed, error_tag) when is_binary(value) do
    normalized = String.trim(value)

    if normalized in allowed do
      {:ok, normalized}
    else
      {:error, {error_tag, value}}
    end
  end

  defp validate_required_enum(value, _allowed, error_tag), do: {:error, {error_tag, value}}

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

  defp validate_hash(value, error_tag) when is_binary(value) do
    trimmed = String.trim(value)

    cond do
      trimmed == "" -> {:error, error_tag}
      String.length(trimmed) > @max_hash_length -> {:error, {:string_too_long, error_tag, @max_hash_length}}
      prohibited_value?(trimmed) -> {:error, {:prohibited_value, error_tag}}
      not String.starts_with?(trimmed, "sha256:") -> {:error, {:invalid_hash, error_tag}}
      true -> {:ok, trimmed}
    end
  end

  defp validate_hash(_value, error_tag), do: {:error, error_tag}

  defp validate_optional_string(nil, _max_length), do: {:ok, nil}
  defp validate_optional_string("", _max_length), do: {:ok, nil}

  defp validate_optional_string(value, max_length) do
    bounded_required_string(value, max_length, :optional_string_invalid)
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
      {:error, :public_exposure_not_allowed_in_stage58_action_audit_contract}
    else
      :ok
    end
  end

  defp forbid_live_fetch(opts) do
    if Keyword.get(opts, :trigger_live_fetch, false) or Keyword.get(opts, :use_live_fetch, false) do
      {:error, :live_fetch_not_allowed_in_stage58_action_audit_contract}
    else
      :ok
    end
  end

  defp forbid_scheduler(opts) do
    if Keyword.get(opts, :scheduler_enabled, false) do
      {:error, :scheduler_not_allowed_in_stage58_action_audit_contract}
    else
      :ok
    end
  end

  defp forbid_runtime_side_effects(opts) do
    if Keyword.get(opts, :db_write, false) or Keyword.get(opts, :audit_write_performed, false) or
         Keyword.get(opts, :network_access, false) do
      {:error, :runtime_side_effect_not_allowed_in_stage58_action_audit_contract}
    else
      :ok
    end
  end

  defp forbid_source_health_mutation(opts) do
    if Keyword.get(opts, :source_health_mutation, false) do
      {:error, :source_health_mutation_not_allowed_in_stage58_action_audit_contract}
    else
      :ok
    end
  end

  defp forbid_canonical_mutation(opts) do
    if Keyword.get(opts, :canonical_feed_mutation, false) or
         Keyword.get(opts, :provider_canonical_feed_item_creation, false) or
         Keyword.get(opts, :news_only_event_creation, false) do
      {:error, :canonical_mutation_not_allowed_in_stage58_action_audit_contract}
    else
      :ok
    end
  end

  defp forbid_action_endpoint(opts) do
    if Keyword.get(opts, :action_endpoint_added, false) or Keyword.get(opts, :route_added, false) or
         Keyword.get(opts, :ui_added, false) do
      {:error, :action_endpoint_not_allowed_in_stage58_action_audit_contract}
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

    normalized in @prohibited_exact_keys or
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
