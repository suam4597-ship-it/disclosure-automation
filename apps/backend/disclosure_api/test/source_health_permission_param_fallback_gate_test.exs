defmodule DisclosureAutomation.SourceHealthPermissionParamFallbackGateTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Sources
  alias DisclosureAutomationWeb.SourceHealthAuthContext

  @source_key "source_health_permission_param_fallback_gate_fixture"

  setup do
    original_mode =
      Application.get_env(:disclosure_automation, :source_health_permission_param_fallback, :disabled)

    on_exit(fn ->
      Application.put_env(:disclosure_automation, :source_health_permission_param_fallback, original_mode)
    end)

    {:ok, _source} =
      Sources.upsert_source(%{
        "source_key" => @source_key,
        "display_name" => "Source Health Permission Param Fallback Gate Fixture",
        "source_type" => "api",
        "adapter_key" => "test_adapter",
        "region_code" => "US",
        "discovery_mode" => "fixture",
        "hydrate_mode" => "fixture",
        "default_home_market_region_code" => "US",
        "source_class" => "operator_test",
        "default_source_tier" => "official",
        "base_url" => "https://example.test/source-health-permission-param-fallback-gate",
        "healthcheck_url" => "https://example.test/source-health-permission-param-fallback-gate/health",
        "parser_key" => "test_parser",
        "poll_cron" => "0 * * * *",
        "coverage_tags" => ["source_health", "auth", "fallback_gate"],
        "active" => true,
        "config" => %{},
        "health_status" => "healthy"
      })

    :ok
  end

  test "test config keeps legacy request-param fallback available for compatibility when read context exists", %{conn: conn} do
    Application.put_env(:disclosure_automation, :source_health_permission_param_fallback, :test_only)

    response =
      conn
      |> SourceHealthAuthContext.put_test_source_health_permissions(["source_health:read"])
      |> get("/admin/source-health/#{@source_key}?actor_permissions=source_health:recheck")
      |> response(200)

    assert SourceHealthAuthContext.request_param_fallback_mode() == :test_only
    assert SourceHealthAuthContext.request_param_fallback_enabled?()
    assert response =~ "recheck_action=disabled"
    assert response =~ "recheck_reason=read_only"
    refute response =~ "recheck_action=enabled"
  end

  test "disabled fallback ignores query actor_permissions before UI access guard", %{conn: conn} do
    Application.put_env(:disclosure_automation, :source_health_permission_param_fallback, :disabled)

    response =
      conn
      |> get("/admin/source-health/#{@source_key}?actor_permissions=source_health:recheck")
      |> response(403)

    assert SourceHealthAuthContext.request_param_fallback_mode() == :disabled
    refute SourceHealthAuthContext.request_param_fallback_enabled?()
    assert response == Enum.join([
             "Source health access denied",
             "state=forbidden",
             "reason=missing_source_health_auth_context"
           ], "\n")

    refute response =~ "recheck_action=enabled"
    refute response =~ "recheck_target=/api/admin/source-health/#{@source_key}/recheck"
  end

  test "disabled fallback prevents request body actor_permissions from authorizing recheck", %{conn: conn} do
    Application.put_env(:disclosure_automation, :source_health_permission_param_fallback, :disabled)

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

  test "disabled fallback prevents request body actor_permissions from authorizing poll", %{conn: conn} do
    Application.put_env(:disclosure_automation, :source_health_permission_param_fallback, :disabled)

    response =
      conn
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

  test "explicit auth context still authorizes when request-param fallback is disabled", %{conn: conn} do
    Application.put_env(:disclosure_automation, :source_health_permission_param_fallback, :disabled)

    response =
      conn
      |> SourceHealthAuthContext.put_test_source_health_permissions(["source_health:recheck"])
      |> post("/api/admin/source-health/#{@source_key}/recheck", recheck_payload())
      |> json_response(202)

    assert response["source_key"] == @source_key
    assert response["queue"] == "health_checks"
    assert response["idempotency_status"] in ["accepted", "reused"]
    refute_private_material(response)
  end

  test "unknown fallback mode fails closed before UI access guard", %{conn: conn} do
    Application.put_env(:disclosure_automation, :source_health_permission_param_fallback, :unknown_mode)

    response =
      conn
      |> get("/admin/source-health/#{@source_key}?actor_permissions=source_health:recheck")
      |> response(403)

    assert SourceHealthAuthContext.request_param_fallback_mode() == :disabled
    refute SourceHealthAuthContext.request_param_fallback_enabled?()
    assert response =~ "reason=missing_source_health_auth_context"
    refute response =~ "recheck_action=enabled"
  end

  defp recheck_payload do
    %{
      "actor_permissions" => ["source_health:recheck"],
      "actor_id_hash" => "sha256:request-param-actor-001",
      "request_id_hash" => "sha256:request-param-request-001",
      "idempotency_key_hash" => "sha256:request-param-idempotency-001",
      "reason_redacted" => "REDACTED_SOURCE_HEALTH_REASON",
      "redaction_status" => "passed",
      "created_at" => "2026-05-06T00:00:00Z"
    }
  end

  defp poll_payload do
    %{
      "actor_permissions" => ["source_health:poll"],
      "actor_id_hash" => "sha256:request-param-actor-poll-001",
      "request_id_hash" => "sha256:request-param-request-poll-001",
      "idempotency_key_hash" => "sha256:request-param-idempotency-poll-001",
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
    response = inspect(response)

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
