defmodule DisclosureAutomation.SourceHealthAuthContextHelperTest do
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

  test "allowed permissions stay bounded and source health scoped" do
    assert SourceHealthAuthContext.allowed_permissions() == [
             "source_health:read",
             "source_health:recheck",
             "source_health:poll"
           ]

    refute "source_health:*" in SourceHealthAuthContext.allowed_permissions()
    refute "source_health:all" in SourceHealthAuthContext.allowed_permissions()
    refute "admin" in SourceHealthAuthContext.allowed_permissions()

    for permission <- SourceHealthAuthContext.allowed_permissions() do
      assert String.starts_with?(permission, "source_health:")
      refute_forbidden_fragments(permission)
    end
  end

  test "test source health permissions are filtered to the allowlist", %{conn: conn} do
    context =
      conn
      |> SourceHealthAuthContext.put_test_source_health_permissions([
        "source_health:read",
        "source_health:poll",
        "admin",
        "source_health:all",
        "source_health:*"
      ])
      |> SourceHealthAuthContext.fetch_source_health_auth_context()

    assert context.actor_permissions == ["source_health:read", "source_health:poll"]
    assert SourceHealthAuthContext.has_permission?(context, "source_health:read")
    assert SourceHealthAuthContext.has_permission?(context, "source_health:poll")
    refute SourceHealthAuthContext.has_permission?(context, "source_health:recheck")
    refute SourceHealthAuthContext.has_permission?(context, "admin")
  end

  test "auth context exposes bounded hash and role fields", %{conn: conn} do
    context =
      conn
      |> SourceHealthAuthContext.put_test_source_health_permissions("source_health:recheck")
      |> SourceHealthAuthContext.put_test_source_health_actor("sha256:operator-prod-auth-001")
      |> SourceHealthAuthContext.put_test_source_health_request("sha256:request-prod-auth-001")
      |> SourceHealthAuthContext.put_test_source_health_session("sha256:session-prod-auth-001")
      |> SourceHealthAuthContext.put_test_source_health_roles(["source_health_operator"])
      |> SourceHealthAuthContext.fetch_source_health_auth_context()

    assert context.actor_id_hash == "sha256:operator-prod-auth-001"
    assert context.request_id_hash == "sha256:request-prod-auth-001"
    assert context.session_id_hash == "sha256:session-prod-auth-001"
    assert context.role_names == ["source_health_operator"]
    assert context.actor_permissions == ["source_health:recheck"]
    assert context.redaction_status == "passed"
    assert is_binary(context.created_at)

    context
    |> inspect()
    |> refute_forbidden_fragments()
  end

  test "auth context can be rendered as bounded params for legacy gates", %{conn: conn} do
    param_map =
      conn
      |> SourceHealthAuthContext.put_test_source_health_permissions([
        "source_health:read",
        "source_health:recheck"
      ])
      |> SourceHealthAuthContext.put_test_source_health_actor("sha256:operator-param-map-001")
      |> SourceHealthAuthContext.put_test_source_health_request("sha256:request-param-map-001")
      |> SourceHealthAuthContext.put_test_source_health_session("sha256:session-param-map-001")
      |> SourceHealthAuthContext.put_test_source_health_roles(["source_health_operator"])
      |> SourceHealthAuthContext.fetch_source_health_auth_context()
      |> SourceHealthAuthContext.to_param_map()

    assert param_map["actor_id_hash"] == "sha256:operator-param-map-001"
    assert param_map["request_id_hash"] == "sha256:request-param-map-001"
    assert param_map["session_id_hash"] == "sha256:session-param-map-001"
    assert param_map["actor_permissions"] == ["source_health:read", "source_health:recheck"]
    assert param_map["role_names"] == ["source_health_operator"]
    assert param_map["redaction_status"] == "passed"
    assert is_binary(param_map["created_at"])

    param_map
    |> inspect()
    |> refute_forbidden_fragments()
  end

  test "missing permissions default to an empty bounded context", %{conn: conn} do
    context = SourceHealthAuthContext.fetch_source_health_auth_context(conn)

    assert context.actor_permissions == []
    assert context.role_names == []
    refute SourceHealthAuthContext.has_permission?(context, "source_health:read")
    refute SourceHealthAuthContext.has_permission?(context, "source_health:recheck")
    refute SourceHealthAuthContext.has_permission?(context, "source_health:poll")
  end

  test "auth context does not include downstream poll controls", %{conn: conn} do
    context_text =
      conn
      |> SourceHealthAuthContext.put_test_source_health_permissions(SourceHealthAuthContext.allowed_permissions())
      |> SourceHealthAuthContext.fetch_source_health_auth_context()
      |> inspect()

    refute context_text =~ "provider_fetch"
    refute context_text =~ "materialize"
    refute context_text =~ "canonicalize"
    refute context_text =~ "inline_feed"
    refute context_text =~ "use_live_fetch"
    refute context_text =~ "canonical_mutation"
  end

  defp refute_forbidden_fragments(value) do
    for forbidden <- @forbidden_fragments do
      refute String.contains?(value, forbidden),
             "expected #{inspect(value)} not to include forbidden fragment #{inspect(forbidden)}"
    end
  end
end
