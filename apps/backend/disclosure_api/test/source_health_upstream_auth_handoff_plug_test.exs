defmodule DisclosureAutomation.SourceHealthUpstreamAuthHandoffPlugTest do
  use DisclosureAutomationWeb.ConnCase, async: true

  alias DisclosureAutomationWeb.SourceHealthUpstreamAuthHandoff

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

  test "copies bounded upstream auth assigns into source health handoff assigns", %{conn: conn} do
    conn =
      conn
      |> Plug.Conn.assign(:upstream_actor_id_hash, "sha256:upstream-actor-001")
      |> Plug.Conn.assign(:upstream_request_id_hash, "sha256:upstream-request-001")
      |> Plug.Conn.assign(:upstream_session_id_hash, "sha256:upstream-session-001")
      |> Plug.Conn.assign(:upstream_role_names, ["source_health_operator"])
      |> Plug.Conn.assign(:upstream_source_health_permissions, ["source_health:recheck"])
      |> SourceHealthUpstreamAuthHandoff.call([])

    assert conn.assigns.source_health_actor_id_hash == "sha256:upstream-actor-001"
    assert conn.assigns.source_health_request_id_hash == "sha256:upstream-request-001"
    assert conn.assigns.source_health_session_id_hash == "sha256:upstream-session-001"
    assert conn.assigns.source_health_role_names == ["source_health_operator"]
    assert conn.assigns.source_health_permissions == ["source_health:recheck"]

    conn.assigns
    |> inspect()
    |> refute_forbidden_fragments()
  end

  test "normalizes single upstream role and permission strings into lists", %{conn: conn} do
    conn =
      conn
      |> Plug.Conn.assign(:upstream_role_names, "source_health_viewer")
      |> Plug.Conn.assign(:upstream_source_health_permissions, "source_health:read")
      |> SourceHealthUpstreamAuthHandoff.call([])

    assert conn.assigns.source_health_role_names == ["source_health_viewer"]
    assert conn.assigns.source_health_permissions == ["source_health:read"]
  end

  test "passes through unchanged when no upstream bounded assigns exist", %{conn: conn} do
    conn = SourceHealthUpstreamAuthHandoff.call(conn, [])

    refute Map.has_key?(conn.assigns, :source_health_actor_id_hash)
    refute Map.has_key?(conn.assigns, :source_health_request_id_hash)
    refute Map.has_key?(conn.assigns, :source_health_session_id_hash)
    refute Map.has_key?(conn.assigns, :source_health_role_names)
    refute Map.has_key?(conn.assigns, :source_health_permissions)
  end

  test "ignores raw upstream identity material", %{conn: conn} do
    conn =
      conn
      |> Plug.Conn.assign(:raw_actor_id, "raw-actor-001")
      |> Plug.Conn.assign(:raw_user_id, "raw-user-001")
      |> Plug.Conn.assign(:raw_session_id, "raw-session-001")
      |> Plug.Conn.assign(:email, "operator@example.test")
      |> Plug.Conn.assign(:headers, %{"authorization" => "Bearer secret"})
      |> Plug.Conn.assign(:cookies, %{"session" => "secret"})
      |> Plug.Conn.assign(:tokens, ["secret"])
      |> SourceHealthUpstreamAuthHandoff.call([])

    refute Map.has_key?(conn.assigns, :source_health_actor_id_hash)
    refute Map.has_key?(conn.assigns, :source_health_request_id_hash)
    refute Map.has_key?(conn.assigns, :source_health_session_id_hash)
    refute Map.has_key?(conn.assigns, :source_health_role_names)
    refute Map.has_key?(conn.assigns, :source_health_permissions)
  end

  test "does not read request body or query actor fields as handoff authority", %{conn: conn} do
    conn =
      %{conn | params: %{"actor_permissions" => ["source_health:recheck"], "actor_id_hash" => "request-param-actor"}}
      |> SourceHealthUpstreamAuthHandoff.call([])

    refute Map.has_key?(conn.assigns, :source_health_actor_id_hash)
    refute Map.has_key?(conn.assigns, :source_health_permissions)
  end

  defp refute_forbidden_fragments(value) do
    for forbidden <- @forbidden_fragments do
      refute String.contains?(value, forbidden),
             "expected #{inspect(value)} not to include forbidden fragment #{inspect(forbidden)}"
    end
  end
end
