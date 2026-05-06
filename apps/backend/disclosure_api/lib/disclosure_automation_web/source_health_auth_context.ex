defmodule DisclosureAutomationWeb.SourceHealthAuthContext do
  @moduledoc false

  import Plug.Conn

  @allowed_permissions [
    "source_health:read",
    "source_health:recheck",
    "source_health:poll"
  ]

  @role_permission_map %{
    "source_health_viewer" => ["source_health:read"],
    "source_health_operator" => ["source_health:read", "source_health:recheck"],
    "source_health_poll_operator" => ["source_health:read", "source_health:poll"],
    "source_health_admin" => ["source_health:read", "source_health:recheck", "source_health:poll"]
  }

  @test_permissions_assign :source_health_test_permissions
  @production_context_assign :source_health_auth_context
  @production_actor_assign :source_health_actor_id_hash
  @production_request_assign :source_health_request_id_hash
  @production_session_assign :source_health_session_id_hash
  @production_roles_assign :source_health_role_names
  @production_permissions_assign :source_health_permissions

  @test_private_keys [
    @test_permissions_assign,
    :source_health_test_actor_id_hash,
    :source_health_test_request_id_hash,
    :source_health_test_session_id_hash,
    :source_health_test_role_names
  ]

  @permission_param_fallback_config_key :source_health_permission_param_fallback
  @allowed_fallback_modes [:disabled, :test_only, :legacy_compat]

  def allowed_permissions, do: @allowed_permissions
  def role_permission_map, do: @role_permission_map

  def source_health_auth_context_available?(conn) do
    production_source_health_auth_context_available?(conn) ||
      Enum.any?(@test_private_keys, &Map.has_key?(conn.private, &1))
  end

  def production_source_health_auth_context_available?(conn) do
    Map.has_key?(conn.private, @production_context_assign) ||
      Map.has_key?(conn.assigns, @production_context_assign)
  end

  def request_param_fallback_mode do
    mode = Application.get_env(:disclosure_automation, @permission_param_fallback_config_key, :disabled)

    if mode in @allowed_fallback_modes do
      mode
    else
      :disabled
    end
  end

  def request_param_fallback_enabled? do
    request_param_fallback_mode() in [:test_only, :legacy_compat]
  end

  def permission_state_requested?(conn, params) do
    source_health_auth_context_available?(conn) ||
      (request_param_fallback_enabled?() && Map.has_key?(params, "actor_permissions"))
  end

  def permissions_for_authorization(conn, params) do
    if source_health_auth_context_available?(conn) do
      conn
      |> fetch_source_health_auth_context()
      |> Map.get(:actor_permissions, [])
    else
      legacy_request_param_permissions(params)
    end
  end

  def legacy_request_param_permissions(params) do
    if request_param_fallback_enabled?() do
      params
      |> request_param_actor_permissions()
      |> Enum.filter(&(&1 in @allowed_permissions))
    else
      []
    end
  end

  def auth_param_map_for_request(conn) do
    cond do
      source_health_auth_context_available?(conn) ->
        conn
        |> fetch_source_health_auth_context()
        |> to_param_map()

      request_param_fallback_enabled?() ->
        conn.params

      true ->
        %{
          "actor_permissions" => [],
          "redaction_status" => "missing_source_health_auth_context"
        }
    end
  end

  def fetch_source_health_auth_context(conn) do
    cond do
      Map.has_key?(conn.private, @production_context_assign) ->
        conn.private[@production_context_assign]

      Map.has_key?(conn.assigns, @production_context_assign) ->
        conn.assigns[@production_context_assign]

      true ->
        fetch_test_source_health_auth_context(conn)
    end
  end

  def build_production_source_health_auth_context(conn) do
    role_names = assigned_list(conn, @production_roles_assign)
    explicit_permissions = assigned_list(conn, @production_permissions_assign)

    permissions =
      role_names
      |> permissions_from_roles()
      |> Kernel.++(explicit_permissions)
      |> Enum.uniq()
      |> Enum.filter(&(&1 in @allowed_permissions))

    %{
      actor_id_hash: assigned_value(conn, @production_actor_assign),
      actor_permissions: permissions,
      request_id_hash: assigned_value(conn, @production_request_assign),
      session_id_hash: assigned_value(conn, @production_session_assign),
      role_names: role_names,
      redaction_status: "passed",
      created_at: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
    }
  end

  def put_source_health_auth_context(conn, %{} = context) do
    context = normalize_context(context)
    put_private(conn, @production_context_assign, context)
  end

  def put_production_source_health_auth_context(conn) do
    put_source_health_auth_context(conn, build_production_source_health_auth_context(conn))
  end

  def has_permission?(%{actor_permissions: permissions}, permission) when is_list(permissions),
    do: permission in permissions

  def has_permission?(_context, _permission), do: false

  def put_test_source_health_permissions(conn, permissions) when is_list(permissions) do
    put_private(conn, @test_permissions_assign, permissions)
  end

  def put_test_source_health_permissions(conn, permission) when is_binary(permission) do
    put_test_source_health_permissions(conn, [permission])
  end

  def put_test_source_health_actor(conn, actor_id_hash) when is_binary(actor_id_hash) do
    put_private(conn, :source_health_test_actor_id_hash, actor_id_hash)
  end

  def put_test_source_health_request(conn, request_id_hash) when is_binary(request_id_hash) do
    put_private(conn, :source_health_test_request_id_hash, request_id_hash)
  end

  def put_test_source_health_session(conn, session_id_hash) when is_binary(session_id_hash) do
    put_private(conn, :source_health_test_session_id_hash, session_id_hash)
  end

  def put_test_source_health_roles(conn, role_names) when is_list(role_names) do
    put_private(conn, :source_health_test_role_names, role_names)
  end

  def to_param_map(%{} = context) do
    %{
      "actor_id_hash" => context.actor_id_hash,
      "actor_permissions" => context.actor_permissions,
      "request_id_hash" => context.request_id_hash,
      "session_id_hash" => context.session_id_hash,
      "role_names" => context.role_names,
      "redaction_status" => context.redaction_status,
      "created_at" => context.created_at
    }
  end

  defp fetch_test_source_health_auth_context(conn) do
    permissions =
      conn
      |> assigned_test_permissions()
      |> Enum.filter(&(&1 in @allowed_permissions))

    %{
      actor_id_hash: assigned_hash(conn, :source_health_test_actor_id_hash),
      actor_permissions: permissions,
      request_id_hash: assigned_hash(conn, :source_health_test_request_id_hash),
      session_id_hash: assigned_hash(conn, :source_health_test_session_id_hash),
      role_names: assigned_roles(conn),
      redaction_status: "passed",
      created_at: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
    }
  end

  defp normalize_context(%{} = context) do
    %{
      actor_id_hash: Map.get(context, :actor_id_hash),
      actor_permissions: Map.get(context, :actor_permissions, []) |> Enum.filter(&(&1 in @allowed_permissions)),
      request_id_hash: Map.get(context, :request_id_hash),
      session_id_hash: Map.get(context, :session_id_hash),
      role_names: Map.get(context, :role_names, []),
      redaction_status: Map.get(context, :redaction_status, "passed"),
      created_at: Map.get(context, :created_at) || DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
    }
  end

  defp permissions_from_roles(role_names) do
    role_names
    |> Enum.flat_map(&Map.get(@role_permission_map, &1, []))
    |> Enum.filter(&(&1 in @allowed_permissions))
  end

  defp assigned_list(conn, key) do
    case assigned_value(conn, key) do
      values when is_list(values) -> values
      value when is_binary(value) -> [value]
      _ -> []
    end
  end

  defp assigned_value(conn, key) do
    Map.get(conn.assigns, key) || Map.get(conn.private, key)
  end

  defp request_param_actor_permissions(params) do
    case Map.get(params, "actor_permissions") do
      permissions when is_list(permissions) -> permissions
      permission when is_binary(permission) -> [permission]
      _ -> []
    end
  end

  defp assigned_test_permissions(conn) do
    conn.private[@test_permissions_assign] || []
  end

  defp assigned_roles(conn) do
    conn.private[:source_health_test_role_names] || []
  end

  defp assigned_hash(conn, key) do
    conn.private[key]
  end
end
