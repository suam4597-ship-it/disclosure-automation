defmodule DisclosureAutomation.SourceHealthInternalUiAccessGuardTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Sources
  alias DisclosureAutomationWeb.SourceHealthAuthContext

  @source_key "source_health_internal_ui_access_guard_fixture"

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
        "display_name" => "Source Health Internal UI Access Guard Fixture",
        "source_type" => "api",
        "adapter_key" => "test_adapter",
        "region_code" => "US",
        "discovery_mode" => "fixture",
        "hydrate_mode" => "fixture",
        "default_home_market_region_code" => "US",
        "source_class" => "operator_test",
        "default_source_tier" => "official",
        "base_url" => "https://example.test/source-health-internal-ui-access-guard",
        "healthcheck_url" => "https://example.test/source-health-internal-ui-access-guard/health",
        "parser_key" => "test_parser",
        "poll_cron" => "0 * * * *",
        "coverage_tags" => ["source_health", "ui", "access_guard"],
        "active" => true,
        "config" => %{},
        "health_status" => "healthy"
      })

    :ok
  end

  test "missing auth context receives bounded forbidden list response", %{conn: conn} do
    response =
      conn
      |> get("/admin/source-health")
      |> response(403)

    assert response == Enum.join([
             "Source health access denied",
             "state=forbidden",
             "reason=missing_source_health_auth_context"
           ], "\n")

    refute_forbidden_material(response)
  end

  test "missing auth context receives bounded forbidden detail response", %{conn: conn} do
    response =
      conn
      |> get("/admin/source-health/#{@source_key}")
      |> response(403)

    assert response == Enum.join([
             "Source health access denied",
             "state=forbidden",
             "reason=missing_source_health_auth_context"
           ], "\n")

    refute_forbidden_material(response)
  end

  test "context without read permission receives bounded forbidden detail response", %{conn: conn} do
    response =
      conn
      |> SourceHealthAuthContext.put_test_source_health_permissions(["source_health:poll"])
      |> get("/admin/source-health/#{@source_key}")
      |> response(403)

    assert response == Enum.join([
             "Source health access denied",
             "state=forbidden",
             "reason=missing_source_health_read_permission"
           ], "\n")

    refute_forbidden_material(response)
  end

  test "query actor permissions cannot bypass missing auth context", %{conn: conn} do
    response =
      conn
      |> get("/admin/source-health/#{@source_key}?actor_permissions=source_health:read")
      |> response(403)

    assert response =~ "reason=missing_source_health_auth_context"
    refute response =~ "Source health detail"
    refute response =~ "state=found"
    refute_forbidden_material(response)
  end

  test "read context can view bounded list shell", %{conn: conn} do
    response =
      conn
      |> SourceHealthAuthContext.put_test_source_health_permissions(["source_health:read"])
      |> get("/admin/source-health")
      |> response(200)

    assert response =~ "Source health"
    assert response =~ "source_key=#{@source_key}"
    assert response =~ "recheck_action=not_rendered"
    refute_forbidden_material(response)
  end

  test "read plus recheck context can view bounded enabled detail shell", %{conn: conn} do
    response =
      conn
      |> SourceHealthAuthContext.put_test_source_health_permissions([
        "source_health:read",
        "source_health:recheck"
      ])
      |> get("/admin/source-health/#{@source_key}")
      |> response(200)

    assert response =~ "Source health detail"
    assert response =~ "state=found"
    assert response =~ "recheck_action=enabled"
    assert response =~ "recheck_target=/api/admin/source-health/#{@source_key}/recheck"
    refute_forbidden_material(response)
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
