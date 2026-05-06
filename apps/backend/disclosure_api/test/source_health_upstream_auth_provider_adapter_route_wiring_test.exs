defmodule DisclosureAutomation.SourceHealthUpstreamAuthProviderAdapterRouteWiringTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Sources

  @source_key "source_health_upstream_auth_provider_adapter_route_wiring_fixture"

  setup do
    original_mode =
      Application.get_env(:disclosure_automation, :source_health_permission_param_fallback, :disabled)

    Application.put_env(:disclosure_automation, :source_health_permission_param_fallback, :disabled)

    on_exit(fn ->
      Application.put_env(:disclosure_automation, :source_health_permission_param_fallback, original_mode)
    end)

    {:ok, _source} =
      Sources.upsert_source(%{
        "source_key" => @source_key,
        "display_name" => "Source Health Upstream Auth Provider Adapter Route Wiring Fixture",
        "source_type" => "api",
        "adapter_key" => "test_adapter",
        "region_code" => "US",
        "discovery_mode" => "fixture",
        "hydrate_mode" => "fixture",
        "default_home_market_region_code" => "US",
        "source_class" => "operator_test",
        "default_source_tier" => "official",
        "base_url" => "https://example.test/source-health-upstream-auth-provider-adapter-route-wiring",
        "healthcheck_url" => "https://example.test/source-health-upstream-auth-provider-adapter-route-wiring/health",
        "parser_key" => "test_parser",
        "poll_cron" => "0 * * * *",
        "coverage_tags" => ["source_health", "auth", "provider_adapter_route_wiring"],
        "active" => true,
        "config" => %{},
        "health_status" => "healthy"
      })

    :ok
  end

  test "bounded app auth operator enables UI recheck action", %{conn: conn} do
    response =
      conn
      |> put_app_auth(["source_health_operator"])
      |> get("/admin/source-health/#{@source_key}")
      |> response(200)

    assert response =~ "Source health detail"
    assert response =~ "state=found"
    assert response =~ "source_key=#{@source_key}"
    assert response =~ "recheck_action=enabled"
    assert response =~ "recheck_method=POST"
    assert response =~ "recheck_target=/api/admin/source-health/#{@source_key}/recheck"

    refute response =~ "poll_action=enabled"
    refute response =~ "audit_ui=enabled"
    refute_forbidden_material(response)
  end

  test "bounded app auth viewer keeps UI recheck disabled despite query escalation", %{conn: conn} do
    response =
      conn
      |> put_app_auth(["source_health_viewer"])
      |> get("/admin/source-health/#{@source_key}?actor_permissions=source_health:recheck")
      |> response(200)

    assert response =~ "Source health detail"
    assert response =~ "state=found"
    assert response =~ "source_key=#{@source_key}"
    assert response =~ "recheck_action=disabled"
    assert response =~ "recheck_reason=read_only"

    refute response =~ "recheck_action=enabled"
    refute response =~ "recheck_target=/api/admin/source-health/#{@source_key}/recheck"
    refute_forbidden_material(response)
  end

  test "bounded app auth operator authorizes backend recheck with fallback disabled", %{conn: conn} do
    response =
      conn
      |> put_app_auth(["source_health_operator"])
      |> post("/api/admin/source-health/#{@source_key}/recheck", recheck_payload())
      |> json_response(202)

    assert response["source_key"] == @source_key
    assert response["queue"] == "health_checks"
    assert response["idempotency_status"] in ["accepted", "reused"]

    refute_private_material(response)
  end

  test "missing app auth denies backend recheck despite body actor permissions", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/source-health/#{@source_key}/recheck", recheck_payload())
      |> json_response(403)

    assert response == %{
             "error" => %{
               "code" => "forbidden",
               "message" => "source health recheck not allowed"
             }
           }

    refute_accepted_job_response(response)
    refute_private_material(response)
  end

  test "bounded app auth recheck-only operator does not authorize poll", %{conn: conn} do
    response =
      conn
      |> put_app_auth(["source_health_operator"])
      |> post("/api/admin/sources/#{@source_key}/poll", poll_payload())
      |> json_response(403)

    assert response == %{
             "error" => %{
               "code" => "forbidden",
               "message" => "source poll not allowed"
             }
           }

    refute_private_material(response)
  end

  test "bounded app auth poll operator reaches existing idempotency gate", %{conn: conn} do
    response =
      conn
      |> put_app_auth(["source_health_poll_operator"])
      |> post("/api/admin/sources/#{@source_key}/poll", Map.delete(poll_payload(), "idempotency_key_hash"))
      |> json_response(409)

    assert response == %{
             "error" => %{
               "code" => "missing_idempotency_key",
               "message" => "poll idempotency key required"
             }
           }

    refute_private_material(response)
  end

  defp put_app_auth(conn, role_names) do
    Plug.Conn.assign(conn, :source_health_app_auth, %{
      actor_id_hash: "sha256:app-auth-route-actor-001",
      request_id_hash: "sha256:app-auth-route-request-001",
      session_id_hash: "sha256:app-auth-route-session-001",
      role_names: role_names
    })
  end

  defp recheck_payload do
    %{
      "actor_permissions" => ["source_health:recheck"],
      "actor_id_hash" => "sha256:request-body-actor-001",
      "request_id_hash" => "sha256:request-body-request-001",
      "idempotency_key_hash" => "sha256:provider-adapter-route-recheck-idempotency-001",
      "reason_redacted" => "REDACTED_SOURCE_HEALTH_REASON",
      "redaction_status" => "passed",
      "created_at" => "2026-05-06T00:00:00Z"
    }
  end

  defp poll_payload do
    %{
      "actor_permissions" => ["source_health:poll"],
      "actor_id_hash" => "sha256:request-body-poll-actor-001",
      "request_id_hash" => "sha256:request-body-poll-request-001",
      "idempotency_key_hash" => "sha256:provider-adapter-route-poll-idempotency-001",
      "redaction_status" => "passed",
      "created_at" => "2026-05-06T00:00:00Z"
    }
  end

  defp refute_accepted_job_response(response) do
    refute Map.has_key?(response, "job_id")
    refute Map.has_key?(response, "queue")
    refute Map.has_key?(response, "args")
    refute Map.has_key?(response, "worker")
    refute Map.has_key?(response, "accepted")
    refute Map.has_key?(response, "scheduled_at")
  end

  defp refute_private_material(response) do
    response
    |> inspect()
    |> refute_forbidden_material()
  end

  defp refute_forbidden_material(response) do
    refute response =~ "raw_provider_payload"
    refute response =~ "full_article_text"
    refute response =~ "raw_transport_response"
    refute response =~ "sql_details"
    refute response =~ "stack_trace"
    refute response =~ "canonical_payload"
    refute response =~ "private_actor_context"
    refute response =~ "unbounded_diagnostics"
    refute response =~ "raw_actor_id"
    refute response =~ "raw_request_id"
    refute response =~ "raw_idempotency_key"
    refute response =~ "unredacted_reason"
    refute response =~ "provider_credentials"
    refute response =~ "headers"
    refute response =~ "cookies"
    refute response =~ "tokens"
    refute response =~ "audit_event_id"
  end
end
