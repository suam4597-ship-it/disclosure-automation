defmodule DisclosureAutomation.SourceHealthUpstreamAuthProviderAdapterTest do
  use DisclosureAutomationWeb.ConnCase, async: true

  alias DisclosureAutomationWeb.SourceHealthUpstreamAuthProviderAdapter

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

  test "copies bounded app auth struct into upstream handoff assigns", %{conn: conn} do
    conn =
      conn
      |> Plug.Conn.assign(:source_health_app_auth, %{
        actor_id_hash: "sha256:adapter-actor-001",
        request_id_hash: "sha256:adapter-request-001",
        session_id_hash: "sha256:adapter-session-001",
        role_names: ["source_health_operator"],
        source_health_permissions: ["source_health:recheck"]
      })
      |> SourceHealthUpstreamAuthProviderAdapter.call([])

    assert conn.assigns.upstream_actor_id_hash == "sha256:adapter-actor-001"
    assert conn.assigns.upstream_request_id_hash == "sha256:adapter-request-001"
    assert conn.assigns.upstream_session_id_hash == "sha256:adapter-session-001"
    assert conn.assigns.upstream_role_names == ["source_health_operator"]
    assert conn.assigns.upstream_source_health_permissions == ["source_health:recheck"]

    conn.assigns
    |> inspect()
    |> refute_forbidden_fragments()
  end

  test "normalizes role and permission strings into upstream lists", %{conn: conn} do
    conn =
      conn
      |> Plug.Conn.assign(:source_health_app_auth, %{
        role_names: "source_health_viewer",
        source_health_permissions: "source_health:read"
      })
      |> SourceHealthUpstreamAuthProviderAdapter.call([])

    assert conn.assigns.upstream_role_names == ["source_health_viewer"]
    assert conn.assigns.upstream_source_health_permissions == ["source_health:read"]
  end

  test "passes through unchanged without bounded app auth assign", %{conn: conn} do
    conn = SourceHealthUpstreamAuthProviderAdapter.call(conn, [])

    refute Map.has_key?(conn.assigns, :upstream_actor_id_hash)
    refute Map.has_key?(conn.assigns, :upstream_request_id_hash)
    refute Map.has_key?(conn.assigns, :upstream_session_id_hash)
    refute Map.has_key?(conn.assigns, :upstream_role_names)
    refute Map.has_key?(conn.assigns, :upstream_source_health_permissions)
  end

  test "ignores raw identity material in app auth assign", %{conn: conn} do
    conn =
      conn
      |> Plug.Conn.assign(:source_health_app_auth, %{
        raw_actor_id: "raw-actor-001",
        raw_user_id: "raw-user-001",
        raw_session_id: "raw-session-001",
        email: "operator@example.test",
        headers: %{"authorization" => "Bearer secret"},
        cookies: %{"session" => "secret"},
        tokens: ["secret"]
      })
      |> SourceHealthUpstreamAuthProviderAdapter.call([])

    refute Map.has_key?(conn.assigns, :upstream_actor_id_hash)
    refute Map.has_key?(conn.assigns, :upstream_request_id_hash)
    refute Map.has_key?(conn.assigns, :upstream_session_id_hash)
    refute Map.has_key?(conn.assigns, :upstream_role_names)
    refute Map.has_key?(conn.assigns, :upstream_source_health_permissions)
  end

  test "does not read request body or query actor fields as app auth", %{conn: conn} do
    conn =
      %{conn | params: %{"actor_permissions" => ["source_health:recheck"], "actor_id_hash" => "request-param-actor"}}
      |> SourceHealthUpstreamAuthProviderAdapter.call([])

    refute Map.has_key?(conn.assigns, :upstream_actor_id_hash)
    refute Map.has_key?(conn.assigns, :upstream_source_health_permissions)
  end

  defp refute_forbidden_fragments(value) do
    for forbidden <- @forbidden_fragments do
      refute String.contains?(value, forbidden),
             "expected #{inspect(value)} not to include forbidden fragment #{inspect(forbidden)}"
    end
  end
end
