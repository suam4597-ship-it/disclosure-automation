defmodule DisclosureAutomation.SourceHealthAuthContextBridgeTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Sources
  alias DisclosureAutomationWeb.SourceHealthAuthContext
  alias DisclosureAutomationWeb.SourceHealthPollAuthorization
  alias DisclosureAutomationWeb.SourceHealthRecheckAuthorization

  @source_key "source_health_auth_context_bridge_fixture"

  setup do
    {:ok, _source} =
      Sources.upsert_source(%{
        "source_key" => @source_key,
        "display_name" => "Source Health Auth Context Bridge Fixture",
        "source_type" => "api",
        "adapter_key" => "test_adapter",
        "region_code" => "US",
        "discovery_mode" => "fixture",
        "hydrate_mode" => "fixture",
        "default_home_market_region_code" => "US",
        "source_class" => "operator_test",
        "default_source_tier" => "official",
        "base_url" => "https://example.test/source-health-auth-context-bridge",
        "healthcheck_url" => "https://example.test/source-health-auth-context-bridge/health",
        "parser_key" => "test_parser",
        "poll_cron" => "0 * * * *",
        "coverage_tags" => ["source_health", "auth_context_bridge"],
        "active" => true,
        "config" => %{},
        "health_status" => "unknown"
      })

    :ok
  end

  test "recheck authorization prefers bounded auth context over request params", %{conn: conn} do
    conn =
      conn
      |> put_params(%{
        "source_key" => @source_key,
        "actor_permissions" => ["source_health:read"]
      })
      |> SourceHealthAuthContext.put_test_source_health_permissions("source_health:recheck")
      |> SourceHealthAuthContext.put_test_source_health_actor("sha256:operator-auth-bridge-001")
      |> SourceHealthRecheckAuthorization.call([])

    refute conn.halted
  end

  test "recheck authorization rejects request param escalation when auth context exists", %{conn: conn} do
    conn =
      conn
      |> put_params(%{
        "source_key" => @source_key,
        "actor_permissions" => ["source_health:recheck"]
      })
      |> SourceHealthAuthContext.put_test_source_health_permissions("source_health:read")
      |> SourceHealthAuthContext.put_test_source_health_actor("sha256:operator-auth-bridge-002")
      |> SourceHealthRecheckAuthorization.call([])

    assert conn.halted
    assert json_response(conn, 403) == %{
             "error" => %{
               "code" => "forbidden",
               "message" => "source health recheck not allowed"
             }
           }

    refute_private_material(conn.resp_body)
  end

  test "poll authorization prefers bounded auth context over request params", %{conn: conn} do
    conn =
      conn
      |> put_params(%{
        "source_key" => @source_key,
        "actor_permissions" => ["source_health:read"]
      })
      |> SourceHealthAuthContext.put_test_source_health_permissions("source_health:poll")
      |> SourceHealthAuthContext.put_test_source_health_actor("sha256:operator-auth-bridge-003")
      |> SourceHealthPollAuthorization.call([])

    refute conn.halted
  end

  test "poll authorization rejects request param escalation when auth context exists", %{conn: conn} do
    conn =
      conn
      |> put_params(%{
        "source_key" => @source_key,
        "actor_permissions" => ["source_health:poll"]
      })
      |> SourceHealthAuthContext.put_test_source_health_permissions("source_health:read")
      |> SourceHealthAuthContext.put_test_source_health_actor("sha256:operator-auth-bridge-004")
      |> SourceHealthPollAuthorization.call([])

    assert conn.halted
    assert json_response(conn, 403) == %{
             "error" => %{
               "code" => "forbidden",
               "message" => "source poll not allowed"
             }
           }

    refute_private_material(conn.resp_body)
  end

  test "legacy request param fallback remains available when no auth context exists", %{conn: conn} do
    recheck_conn =
      conn
      |> put_params(%{
        "source_key" => @source_key,
        "actor_permissions" => ["source_health:recheck"]
      })
      |> SourceHealthRecheckAuthorization.call([])

    refute recheck_conn.halted

    poll_conn =
      build_conn()
      |> put_params(%{
        "source_key" => @source_key,
        "actor_permissions" => ["source_health:poll"]
      })
      |> SourceHealthPollAuthorization.call([])

    refute poll_conn.halted
  end

  test "unknown source responses use bounded auth context audit params", %{conn: conn} do
    missing_source_key = "source_health_auth_context_bridge_missing"

    conn =
      conn
      |> put_params(%{
        "source_key" => missing_source_key,
        "actor_permissions" => ["source_health:poll"]
      })
      |> SourceHealthAuthContext.put_test_source_health_permissions("source_health:poll")
      |> SourceHealthAuthContext.put_test_source_health_actor("sha256:operator-auth-bridge-005")
      |> SourceHealthPollAuthorization.call([])

    assert conn.halted
    assert json_response(conn, 404) == %{
             "error" => %{
               "code" => "not_found",
               "message" => "source not found"
             }
           }

    refute_private_material(conn.resp_body)
  end

  defp put_params(conn, params) do
    %{conn | params: params}
  end

  defp refute_private_material(value) do
    encoded = inspect(value)

    refute encoded =~ "raw_actor_id"
    refute encoded =~ "raw_user_id"
    refute encoded =~ "raw_session_id"
    refute encoded =~ "raw_request_id"
    refute encoded =~ "raw_idempotency_key"
    refute encoded =~ "unredacted_reason"
    refute encoded =~ "email"
    refute encoded =~ "headers"
    refute encoded =~ "cookies"
    refute encoded =~ "tokens"
    refute encoded =~ "provider_credentials"
    refute encoded =~ "raw_provider_payload"
    refute encoded =~ "full_article_text"
    refute encoded =~ "raw_transport_response"
    refute encoded =~ "sql_details"
    refute encoded =~ "stack_trace"
    refute encoded =~ "canonical_payload"
    refute encoded =~ "private_actor_context"
    refute encoded =~ "unbounded_diagnostics"
    refute encoded =~ "audit_event_id"
  end
end
