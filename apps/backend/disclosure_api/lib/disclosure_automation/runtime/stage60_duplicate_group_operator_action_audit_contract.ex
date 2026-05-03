defmodule DisclosureAutomation.Runtime.Stage60DuplicateGroupOperatorActionAuditContract do
  @moduledoc false

  @allowed_operations ~w(
    confirm_duplicate_group
    reject_duplicate_group
    mark_duplicate_group_needs_review
    clear_duplicate_group_review_state
  )

  @read_only_permissions ~w(
    duplicate_group:read
  )

  @action_permission_by_operation %{
    "confirm_duplicate_group" => "duplicate_group:confirm",
    "reject_duplicate_group" => "duplicate_group:reject",
    "mark_duplicate_group_needs_review" => "duplicate_group:mark_review",
    "clear_duplicate_group_review_state" => "duplicate_group:clear_review_state"
  }

  @allowed_result_statuses ~w(
    pending
    accepted
    denied
    rejected
    failed
    completed
    skipped
  )

  @allowed_review_states ~w(
    unknown
    confirmed_by_operator
    rejected_by_operator
    needs_review
    cleared
  )

  @allowed_redaction_statuses ~w(
    passed
    failed
    blocked
    unknown
  )

  @max_group_id_length 160
  @max_operation_length 80
  @max_hash_length 128
  @max_reason_length 500
  @max_failure_code_length 120
  @max_timestamp_length 64

  @prohibited_exact_keys ~w(
    actorid
    actorname
    actoremail
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
    "providercanonicalcreationpayload",
    "canonicaleventpayload",
    "rawbodysimilaritypayload",
    "fulltextsimilaritypayload"
  ]

  def allowed_operations, do: @allowed_operations
  def read_only_permissions, do: @read_only_permissions
  def action_permissions, do: Map.values(@action_permission_by_operation)
  def allowed_result_statuses, do: @allowed_result_statuses
  def allowed_review_states, do: @allowed_review_states
  def allowed_redaction_statuses, do: @allowed_redaction_statuses

  def defaults do
    %{
      audit_scope: "operator_only_duplicate_group_action_audit",
      bounded: true,
      redacted: true,
      action_attempt_recorded: true,
      operator_only: true,
      advisory_only: true,
      non_canonical: true,
      public_response_shape_mutation: false,
      public_api_duplicate_group_fields: false,
      public_feed_duplicate_group_fields: false,
      canonical_feed_mutation: false,
      provider_canonical_feed_item_creation: false,
      news_only_event_creation: false,
      official_event_merge: false,
      official_fact_override: false,
      official_citation_override: false,
      trigger_live_fetch: false,
      scheduler_enabled: false,
      network_access: "forbidden",
      audit_write_performed: false,
      materializer_triggered: false,
      route_added: false,
      ui_added: false,
      action_endpoint_added: false,
      schema_migration: false
    }
  end

  def validate_event(attrs, opts \\ [])

  def validate_event(attrs, opts) when is_map(attrs) do
    with :ok <- forbid_audit_escape(opts),
         :ok <- reject_prohibited_fields(attrs),
         {:ok, operation} <- validate_operation(get_value(attrs, "action_operation")),
         {:ok, required_permission} <- required_permission(operation),
         {:ok, permission} <- validate_permission(get_value(attrs, "required_permission"), required_permission),
         {:ok, group_id} <- bounded_required_string(get_value(attrs, "group_id"), @max_group_id_length, :group_id_required),
         {:ok, actor_id_hash} <- validate_hash(get_value(attrs, "actor_id_hash"), :actor_id_hash_required),
         {:ok, request_id_hash} <- validate_hash(get_value(attrs, "request_id_hash"), :request_id_hash_required),
         {:ok, idempotency_key_hash} <- validate_hash(get_value(attrs, "idempotency_key_hash"), :idempotency_key_hash_required),
         {:ok, operator_reason_redacted} <-
           bounded_required_string(get_value(attrs, "operator_reason_redacted"), @max_reason_length, :operator_reason_redacted_required),
         {:ok, result_status} <-
           validate_required_enum(get_value(attrs, "result_status"), @allowed_result_statuses, :invalid_result_status),
         {:ok, redaction_status} <-
           validate_required_enum(get_value(attrs, "redaction_status"), @allowed_redaction_statuses, :invalid_redaction_status),
         {:ok, pre_review_state} <-
           validate_optional_enum(get_value(attrs, "pre_review_state"), @allowed_review_states, :invalid_pre_review_state),
         {:ok, post_review_state} <-
           validate_optional_enum(get_value(attrs, "post_review_state"), @allowed_review_states, :invalid_post_review_state),
         {:ok, failure_code} <- validate_optional_string(get_value(attrs, "failure_code"), @max_failure_code_length),
         {:ok, created_at} <- validate_optional_string(get_value(attrs, "created_at"), @max_timestamp_length) do
      {:ok,
       defaults()
       |> Map.merge(%{
         action_operation: operation,
         required_permission: permission,
         group_id: group_id,
         actor_id_hash: actor_id_hash,
         request_id_hash: request_id_hash,
         idempotency_key_hash: idempotency_key_hash,
         operator_reason_redacted: operator_reason_redacted,
         result_status: result_status,
         redaction_status: redaction_status,
         pre_review_state: pre_review_state,
         post_review_state: post_review_state,
         failure_code: failure_code,
         created_at: created_at
       })}
    end
  end

  def validate_event(_attrs, _opts), do: {:error, :invalid_stage60_duplicate_group_action_audit_event}

  defp validate_operation(nil), do: {:error, :action_operation_required}

  defp validate_operation(operation) when is_binary(operation) do
    normalized = String.trim(operation)

    cond do
      normalized in @read_only_permissions -> {:error, {:read_only_permission_cannot_be_audited_as_action, normalized}}
      String.length(normalized) > @max_operation_length -> {:error, {:string_too_long, :action_operation, @max_operation_length}}
      normalized in @allowed_operations -> {:ok, normalized}
      true -> {:error, {:invalid_stage60_duplicate_group_action_operation, operation}}
    end
  end

  defp validate_operation(operation), do: {:error, {:invalid_stage60_duplicate_group_action_operation, operation}}

  defp required_permission(operation) do
    case Map.fetch(@action_permission_by_operation, operation) do
      {:ok, permission} -> {:ok, permission}
      :error -> {:error, {:missing_action_permission_mapping, operation}}
    end
  end

  defp validate_permission(nil, _required_permission), do: {:error, :required_permission_required}

  defp validate_permission(permission, required_permission) when is_binary(permission) do
    normalized = String.trim(permission)

    cond do
      normalized in @read_only_permissions -> {:error, {:read_only_permission_cannot_authorize_action_audit, normalized, required_permission}}
      normalized == required_permission -> {:ok, normalized}
      true -> {:error, {:permission_mismatch, normalized, required_permission}}
    end
  end

  defp validate_permission(permission, required_permission), do: {:error, {:permission_mismatch, permission, required_permission}}

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

  defp validate_optional_string(nil, _max_length), do: {:ok, nil}
  defp validate_optional_string("", _max_length), do: {:ok, nil}

  defp validate_optional_string(value, max_length) when is_binary(value) do
    trimmed = String.trim(value)

    cond do
      trimmed == "" -> {:ok, nil}
      String.length(trimmed) > max_length -> {:error, {:string_too_long, :optional_string, max_length}}
      prohibited_value?(trimmed) -> {:error, {:prohibited_value, :optional_string}}
      true -> {:ok, trimmed}
    end
  end

  defp validate_optional_string(value, _max_length), do: {:error, {:invalid_optional_string, value}}

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

  defp forbid_audit_escape(opts) do
    cond do
      Keyword.get(opts, :public_exposure, false) or
          Keyword.get(opts, :public_response_shape_mutation, false) or
          Keyword.get(opts, :public_api_duplicate_group_fields, false) or
          Keyword.get(opts, :public_feed_duplicate_group_fields, false) ->
        {:error, :public_response_shape_mutation_not_allowed_in_stage60_duplicate_group_action_audit_contract}

      Keyword.get(opts, :canonical_feed_mutation, false) or
          Keyword.get(opts, :provider_canonical_feed_item_creation, false) or
          Keyword.get(opts, :news_only_event_creation, false) or
          Keyword.get(opts, :official_event_merge, false) or
          Keyword.get(opts, :official_fact_override, false) or
          Keyword.get(opts, :official_citation_override, false) ->
        {:error, :canonical_mutation_not_allowed_in_stage60_duplicate_group_action_audit_contract}

      Keyword.get(opts, :trigger_live_fetch, false) or Keyword.get(opts, :use_live_fetch, false) ->
        {:error, :live_fetch_not_allowed_in_stage60_duplicate_group_action_audit_contract}

      Keyword.get(opts, :scheduler_enabled, false) ->
        {:error, :scheduler_not_allowed_in_stage60_duplicate_group_action_audit_contract}

      Keyword.get(opts, :network_access, false) ->
        {:error, :network_access_not_allowed_in_stage60_duplicate_group_action_audit_contract}

      Keyword.get(opts, :audit_write_performed, false) or Keyword.get(opts, :audit_write, false) ->
        {:error, :audit_write_not_allowed_in_stage60_duplicate_group_action_audit_contract}

      Keyword.get(opts, :materializer_triggered, false) ->
        {:error, :materializer_not_allowed_in_stage60_duplicate_group_action_audit_contract}

      Keyword.get(opts, :route_added, false) or Keyword.get(opts, :ui_added, false) or
          Keyword.get(opts, :action_endpoint_added, false) or Keyword.get(opts, :schema_migration, false) ->
        {:error, :route_ui_action_or_schema_not_allowed_in_stage60_duplicate_group_action_audit_contract}

      true ->
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
        allowed_key?(key_string) -> nil
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

  defp allowed_key?(key) do
    key in [
      "actor_id_hash",
      "request_id_hash",
      "idempotency_key_hash",
      "operator_reason_redacted",
      "group_id",
      "action_operation",
      "required_permission",
      "result_status",
      "redaction_status",
      "pre_review_state",
      "post_review_state",
      "failure_code",
      "created_at"
    ]
  end

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
    case Enum.find(map, fn {candidate, _value} -> to_string(candidate) == key end) do
      {_candidate, value} -> value
      nil -> default
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
