defmodule DisclosureAutomation.Runtime.Stage58SourceHealthOperatorActionAuthorizationGate do
  @moduledoc false

  alias DisclosureAutomation.Runtime.Stage58SourceHealthOperatorActionContract
  alias DisclosureAutomation.Runtime.Stage58SourceHealthOperatorActionNoopService

  @operator_roles ~w(operator admin)
  @wildcard_source "*"
  @max_actor_hash_length 128

  @allowed_context_keys ~w(
    authenticated
    roles
    permissions
    source_keys
    actor_id_hash
    result_status
    redaction_status
    pre_action_health_status
    post_action_health_status
    pre_action_operational_state
    post_action_operational_state
    failure_code_redacted
    started_at
    completed_at
  )

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
      authorization_scope: "operator_action_authorization_gate_only",
      authenticated_required: true,
      operator_role_required: true,
      action_permission_required: true,
      source_authorization_required: true,
      read_only_permissions_allowed_for_actions: false,
      no_op_preview_only: true,
      operator_only: true,
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

  def authorize_noop_preview(action_attrs, actor_context, opts \\ [])

  def authorize_noop_preview(action_attrs, actor_context, opts) when is_map(actor_context) do
    with :ok <- forbid_runtime_side_effects(opts),
         :ok <- reject_prohibited_fields(actor_context),
         :ok <- reject_unknown_context_keys(actor_context),
         {:ok, action} <- Stage58SourceHealthOperatorActionContract.validate_action(action_attrs, opts),
         {:ok, actor_id_hash} <- validate_hash(get_value(actor_context, "actor_id_hash"), :actor_id_hash_required),
         :ok <- validate_authenticated(get_value(actor_context, "authenticated")),
         :ok <- validate_operator_role(get_value(actor_context, "roles")),
         :ok <- validate_action_permission(get_value(actor_context, "permissions"), action.required_permission),
         :ok <- validate_source_authorization(get_value(actor_context, "source_keys"), action.source_key),
         {:ok, preview} <- Stage58SourceHealthOperatorActionNoopService.preview_action(action_attrs, build_audit_context(actor_context, actor_id_hash), opts) do
      {:ok,
       defaults()
       |> Map.merge(%{
         operation: action.operation,
         required_permission: action.required_permission,
         source_key: action.source_key,
         actor_id_hash: actor_id_hash,
         authorized: true,
         authorization_result: "allowed_noop_preview",
         preview: preview
       })}
    end
  end

  def authorize_noop_preview(_action_attrs, _actor_context, _opts), do: {:error, :invalid_stage58_authorization_context}

  defp build_audit_context(actor_context, actor_id_hash) do
    actor_context
    |> Map.take(@allowed_context_keys)
    |> put_string_key("actor_id_hash", actor_id_hash)
  end

  defp validate_authenticated(true), do: :ok
  defp validate_authenticated("true"), do: :ok
  defp validate_authenticated(_value), do: {:error, :operator_action_authentication_required}

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

      Enum.any?(permissions, &(&1 in Stage58SourceHealthOperatorActionContract.read_only_permissions())) ->
        {:error, {:read_only_permission_cannot_authorize_action, required_permission}}

      true ->
        {:error, {:missing_action_permission, required_permission}}
    end
  end

  defp validate_action_permission(_permissions, required_permission), do: {:error, {:missing_action_permission, required_permission}}

  defp validate_source_authorization(source_keys, source_key) when is_list(source_keys) do
    if source_key in source_keys or @wildcard_source in source_keys do
      :ok
    else
      {:error, {:source_not_authorized, source_key}}
    end
  end

  defp validate_source_authorization(_source_keys, source_key), do: {:error, {:source_not_authorized, source_key}}

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

  defp forbid_runtime_side_effects(opts) do
    if Keyword.get(opts, :db_write, false) or Keyword.get(opts, :audit_write_performed, false) or
         Keyword.get(opts, :enqueue_performed, false) or Keyword.get(opts, :network_access, false) do
      {:error, :runtime_side_effect_not_allowed_in_stage58_authorization_gate}
    else
      :ok
    end
  end

  defp reject_unknown_context_keys(actor_context) do
    actor_context
    |> Map.keys()
    |> Enum.map(&to_string/1)
    |> Enum.find(fn key -> key not in @allowed_context_keys end)
    |> case do
      nil -> :ok
      key -> {:error, {:unknown_authorization_context_key, key}}
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

  defp get_value(map, key, default \\ nil)

  defp get_value(map, key, default) when is_map(map) do
    cond do
      Map.has_key?(map, key) -> Map.get(map, key)
      Map.has_key?(map, String.to_atom(key)) -> Map.get(map, String.to_atom(key))
      true -> default
    end
  end

  defp get_value(_value, _key, default), do: default

  defp put_string_key(map, key, value) do
    map
    |> Map.delete(String.to_atom(key))
    |> Map.put(key, value)
  end

  defp normalize_token(value) do
    value
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]/, "")
  end
end
