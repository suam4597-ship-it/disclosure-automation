defmodule DisclosureAutomation.SourceHealthProductionAuthContextBuilderTest do
  use DisclosureAutomationWeb.ConnCase, async: true

  alias DisclosureAutomationWeb.SourceHealthAuthContext

  @forbidden_fragments [
    "raw_actor_id",
    "raw_user_id",
    "raw_session_id",
    "raw_request_id",
    "raw_idempotency_key",
    "unredacted_reason",
    "email",
    "headers",
    "cookies",
    "tokens",
    "provider_credentials",
    "raw_provider_payload",
    "full_article_text",
    "raw_transport_response",
    "sql_details",
    "stack_trace",
    "canonical_payload",
    "private_actor_context",
    "unbounded_diagnostics",
    "audit_event_id"
  ]

  test "role permission map keeps production roles bounded and source health scoped" do
    assert SourceHealthAuthContext.role_permission_map() == %{
             "source_health_viewer" => ["source_health:read"],
             "source_health_operator" => ["source_health:read", "source_health:recheck"],
             "source_health_poll_operator" => ["source_health:read", "source_health:poll"],
             "source_health_admin" => ["source_health:read", "source_health:recheck", "source_health:poll"]
           }

    for {_role, permissions} <- SourceHealthAuthContext.role_permission_map() do
      for permission <- permissions do
        assert permission in SourceHealthAuthContext.allowed_permissions()
        refute_forbidden_fragments(permission)
      end
    end
  end

  test "builds production source health auth context from server-derived assigns", %{conn: conn} do
    context =
      conn
      |> put_production_assigns(["source_health_operator"])
      |> SourceHealthAuthContext.build_production_source_health_auth_context()

    assert context.actor_id_hash == "sha256:production-actor-001"
    assert context.request_id_hash == "sha256:production-request-001"
    assert context.session_id_hash == "sha256:production-session-001"
    assert context.role_names == ["source_health_operator"]
    assert context.actor_permissions == ["source_health:read", "source_health:recheck"]
    assert context.redaction_status == "passed"
    assert is_binary(context.created_at)

    context
    |> inspect()
    |> refute_forbidden_fragments()
  end

  test "production builder combines allowlisted explicit permissions with role permissions", %{conn: conn} do
    context =
      conn
      |> put_production_assigns(["source_health_viewer"])
      |> Plug.Conn.assign(:source_health_permissions, [
        "source_health:poll",
        "admin",
        "source_health:*",
        "source_health:all"
      ])
      |> SourceHealthAuthContext.build_production_source_health_auth_context()

    assert context.actor_permissions == ["source_health:read", "source_health:poll"]
    refute "admin" in context.actor_permissions
    refute "source_health:*" in context.actor_permissions
    refute "source_health:all" in context.actor_permissions
  end

  test "put production auth context makes SourceHealthAuthContext authoritative", %{conn: conn} do
    conn =
      conn
      |> put_production_assigns(["source_health_poll_operator"])
      |> SourceHealthAuthContext.put_production_source_health_auth_context()

    assert SourceHealthAuthContext.source_health_auth_context_available?(conn)
    assert SourceHealthAuthContext.production_source_health_auth_context_available?(conn)

    context = SourceHealthAuthContext.fetch_source_health_auth_context(conn)

    assert context.actor_permissions == ["source_health:read", "source_health:poll"]
    assert SourceHealthAuthContext.has_permission?(context, "source_health:read")
    assert SourceHealthAuthContext.has_permission?(context, "source_health:poll")
    refute SourceHealthAuthContext.has_permission?(context, "source_health:recheck")
  end

  test "explicit production context wins over request-param permissions", %{conn: conn} do
    conn =
      conn
      |> put_production_assigns(["source_health_viewer"])
      |> SourceHealthAuthContext.put_production_source_health_auth_context()

    params = %{"actor_permissions" => ["source_health:recheck", "source_health:poll"]}

    assert SourceHealthAuthContext.permissions_for_authorization(conn, params) == ["source_health:read"]
  end

  test "explicit production context wins over test helper context", %{conn: conn} do
    conn =
      conn
      |> SourceHealthAuthContext.put_test_source_health_permissions(["source_health:recheck"])
      |> put_production_assigns(["source_health_viewer"])
      |> SourceHealthAuthContext.put_production_source_health_auth_context()

    context = SourceHealthAuthContext.fetch_source_health_auth_context(conn)

    assert context.actor_permissions == ["source_health:read"]
    refute SourceHealthAuthContext.has_permission?(context, "source_health:recheck")
  end

  test "manual production context setter filters non-allowlisted permissions", %{conn: conn} do
    context = %{
      actor_id_hash: "sha256:manual-production-actor-001",
      actor_permissions: ["source_health:read", "admin", "source_health:*", "source_health:poll"],
      request_id_hash: "sha256:manual-production-request-001",
      session_id_hash: "sha256:manual-production-session-001",
      role_names: ["source_health_admin"],
      redaction_status: "passed",
      created_at: "2026-05-06T00:00:00Z"
    }

    fetched_context =
      conn
      |> SourceHealthAuthContext.put_source_health_auth_context(context)
      |> SourceHealthAuthContext.fetch_source_health_auth_context()

    assert fetched_context.actor_permissions == ["source_health:read", "source_health:poll"]
    refute "admin" in fetched_context.actor_permissions
    refute "source_health:*" in fetched_context.actor_permissions
  end

  test "production auth context renders as bounded auth param map", %{conn: conn} do
    param_map =
      conn
      |> put_production_assigns(["source_health_admin"])
      |> SourceHealthAuthContext.put_production_source_health_auth_context()
      |> SourceHealthAuthContext.fetch_source_health_auth_context()
      |> SourceHealthAuthContext.to_param_map()

    assert param_map["actor_id_hash"] == "sha256:production-actor-001"
    assert param_map["request_id_hash"] == "sha256:production-request-001"
    assert param_map["session_id_hash"] == "sha256:production-session-001"
    assert param_map["role_names"] == ["source_health_admin"]
    assert param_map["actor_permissions"] == ["source_health:read", "source_health:recheck", "source_health:poll"]
    assert param_map["redaction_status"] == "passed"
    assert is_binary(param_map["created_at"])

    param_map
    |> inspect()
    |> refute_forbidden_fragments()
  end

  defp put_production_assigns(conn, role_names) do
    conn
    |> Plug.Conn.assign(:source_health_actor_id_hash, "sha256:production-actor-001")
    |> Plug.Conn.assign(:source_health_request_id_hash, "sha256:production-request-001")
    |> Plug.Conn.assign(:source_health_session_id_hash, "sha256:production-session-001")
    |> Plug.Conn.assign(:source_health_role_names, role_names)
  end

  defp refute_forbidden_fragments(value) do
    for forbidden <- @forbidden_fragments do
      refute String.contains?(value, forbidden),
             "expected #{inspect(value)} not to include forbidden fragment #{inspect(forbidden)}"
    end
  end
end
