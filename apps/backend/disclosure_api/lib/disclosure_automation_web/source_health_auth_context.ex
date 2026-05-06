defmodule DisclosureAutomationWeb.SourceHealthAuthContext do
  @moduledoc false

  import Plug.Conn

  @allowed_permissions [
    "source_health:read",
    "source_health:recheck",
    "source_health:poll"
  ]

  @test_permissions_assign :source_health_test_permissions
  @test_private_keys [
    @test_permissions_assign,
    :source_health_test_actor_id_hash,
    :source_health_test_request_id_hash,
    :source_health_test_session_id_hash,
    :source_health_test_role_names
  ]

  def allowed_permissions, do: @allowed_permissions

  def source_health_auth_context_available?(conn) do
    Enum.any?(@test_private_keys, &Map.has_key?(conn.private, &1))
  end

  def fetch_source_health_auth_context(conn) do
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
