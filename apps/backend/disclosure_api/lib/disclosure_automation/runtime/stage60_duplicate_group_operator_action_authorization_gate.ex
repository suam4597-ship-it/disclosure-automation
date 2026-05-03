defmodule DisclosureAutomation.Runtime.Stage60DuplicateGroupOperatorActionAuthorizationGate do
  @moduledoc false

  alias DisclosureAutomation.Runtime.Stage60DuplicateGroupOperatorActionContract
  alias DisclosureAutomation.Runtime.Stage60DuplicateGroupOperatorActionNoopService

  @operator_roles ~w(operator admin)

  @allowed_context_keys ~w(
    authenticated
    roles
    permissions
    actor_id_hash
    result_status
    redaction_status
    pre_review_state
    post_review_state
    failure_code
    created_at
  )

  @max_actor_hash_length 128

  @prohibited_key_fragments [
    "actorid",
    "actorname",
    "actoremail",
    "requestid",
    "idempotencykey",
    "operatorreason",
    "operatornote",
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

  def defaults do
    %{
      authorization_scope: "operator_only_duplicate_group_action_authorization_gate",
      authenticated_required: true,
      operator_role_required: true,
      action_permission_required: true,
      read_only_permissions_allowed_for_actions: false,
      actor_hash_required: true,
      no_op_preview_only: true,
      operator_only: true,
      advisory_only: true,
      non_canonical: true,
      bounded: true,
      redacted: true,
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
      db_write: false,
      audit_write_performed: false,
      enqueue_performed: false,
      materializer_triggered: false,
      route_added: false,
      ui_added: false,
      action_endpoint_added: false,
      schema_migration: false
    }
  end

  def authorize_noop_preview(action_attrs, actor_context, opts \\ [])

  def authorize_noop_preview(action_attrs, actor_context, opts) when is_map(action_attrs) and is_map(actor_context) do
    with :ok <- forbid_gate_escape(opts),
         :ok <- reject_prohibited_fields(actor_context),
         :ok <- reject_unknown_context_keys(actor_context),
         {:ok, action} <- Stage60DuplicateGroupOperatorActionContract.validate_action(action_attrs, opts),
         {:ok, actor_id_hash} <- validate_hash(get_value(actor_context, "actor_id_hash"), :actor_id_hash_required),
         :ok <- validate_matching_actor_hash(actor_id_hash, action.actor_id_hash),
         :ok <- validate_authenticated(get_value(actor_context, "authenticated")),
         :ok <- validate_operator_role(get_value(actor_context, "roles")),
         :ok <- validate_action_permission(get_value(actor_context, "permissions"), action.required_permission),
         {:ok, preview} <-
           Stage60DuplicateGroupOperatorActionNoopService.preview_action(
             action_attrs,
             build_audit_context(actor_context),
             opts
           ) do
      {:ok,
       defaults()
       |> Map.merge(%{
         action_operation: action.action_operation,
         required_permission: action.required_permission,
         group_id: action.group_id,
         actor_id_hash: actor_id_hash,
         authorized: true,
         authorization_result: "allowed_noop_preview",
         preview: preview
       })}
    end
  end

  def authorize_noop_preview(_action_attrs, _actor_context, _opts), do: {:error, :invalid_stage60_authorization_context}

  defp build_audit_context(actor_context) do
    actor_context
    |> Enum.filter(fn {key, _value} -> to_string(key) in audit_context_keys() end)
    |> Map.new(fn {key, value} -> {to_string(key), value} end)
  end

  defp audit_context_keys do
    @allowed_context_keys -- ~w(authenticated roles permissions actor_id_hash)
  end

  defp validate_authenticated(true), do: :ok
  defp validate_authenticated("true"), do: :ok
  defp validate_authenticated(_value), do: {:error, :duplicate_group_action_authentication_required}

  defp validate_operator_role(roles) when is_list(roles) do
    if Enum.any?(roles, &(&1 in @operator_roles)) do
      :ok
    else
      {:error, :operator_or_admin_role_required}
    end
  end

  defp validate_operator_role(_roles), do: {:error, :operator_or_admin_role_required}

  defp validate_action_permission(permissions, required_permission) when is_list(permissions) do
    cond do
      required_permission in permissions ->
        :ok

      Enum.any?(permissions, &(&1 in Stage60DuplicateGroupOperatorActionContract.read_only_permissions())) ->
        {:error, {:read_only_permission_cannot_authorize_action, required_permission}}

      true ->
        {:error, {:missing_action_permission, required_permission}}
    end
  end

  defp validate_action_permission(_permissions, required_permission), do: {:error, {:missing_action_permission, required_permission}}

  defp validate_matching_actor_hash(actor_id_hash, actor_id_hash), do: :ok

  defp validate_matching_actor_hash(_context_hash, _action_hash) do
    {:error, :actor_hash_mismatch}
  end

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

  defp reject_unknown_context_keys(actor_context) do
    case actor_context |> Map.keys() |> Enum.map(&to_string/1) |> Enum.reject(&(&1 in @allowed_context_keys)) do
      [] -> :ok
      [key | _] -> {:error, {:unknown_authorization_context_key, key}}
    end
  end

  defp forbid_gate_escape(opts) do
    cond do
      Keyword.get(opts, :public_exposure, false) or
          Keyword.get(opts, :public_response_shape_mutation, false) or
          Keyword.get(opts, :public_api_duplicate_group_fields, false) or
          Keyword.get(opts, :public_feed_duplicate_group_fields, false) ->
        {:error, :public_response_shape_mutation_not_allowed_in_stage60_duplicate_group_authorization_gate}

      Keyword.get(opts, :canonical_feed_mutation, false) or
          Keyword.get(opts, :provider_canonical_feed_item_creation, false) or
          Keyword.get(opts, :news_only_event_creation, false) or
          Keyword.get(opts, :official_event_merge, false) or
          Keyword.get(opts, :official_fact_override, false) or
          Keyword.get(opts, :official_citation_override, false) ->
        {:error, :canonical_mutation_not_allowed_in_stage60_duplicate_group_authorization_gate}

      Keyword.get(opts, :trigger_live_fetch, false) or Keyword.get(opts, :use_live_fetch, false) ->
        {:error, :live_fetch_not_allowed_in_stage60_duplicate_group_authorization_gate}

      Keyword.get(opts, :scheduler_enabled, false) ->
        {:error, :scheduler_not_allowed_in_stage60_duplicate_group_authorization_gate}

      Keyword.get(opts, :network_access, false) or Keyword.get(opts, :db_write, false) or
          Keyword.get(opts, :audit_write_performed, false) or Keyword.get(opts, :audit_write, false) or
          Keyword.get(opts, :enqueue_performed, false) ->
        {:error, :runtime_side_effect_not_allowed_in_stage60_duplicate_group_authorization_gate}

      Keyword.get(opts, :materializer_triggered, false) ->
        {:error, :materializer_not_allowed_in_stage60_duplicate_group_authorization_gate}

      Keyword.get(opts, :route_added, false) or Keyword.get(opts, :ui_added, false) or
          Keyword.get(opts, :action_endpoint_added, false) or Keyword.get(opts, :schema_migration, false) ->
        {:error, :route_ui_action_or_schema_not_allowed_in_stage60_duplicate_group_authorization_gate}

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
        key_string in @allowed_context_keys -> find_prohibited_field(value, current_path)
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

  defp get_value(map, key, default \\ nil) when is_map(map) do
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
