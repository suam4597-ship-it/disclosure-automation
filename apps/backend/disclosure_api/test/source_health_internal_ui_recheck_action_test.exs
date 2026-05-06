defmodule DisclosureAutomation.SourceHealthInternalUiRecheckActionTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Sources
  alias DisclosureAutomationWeb.SourceHealthAuthContext

  @source_key "source_health_ui_recheck_action_fixture"
  @missing_source_key "source_health_ui_recheck_action_missing"

  setup do
    {:ok, _source} =
      Sources.upsert_source(%{
        "source_key" => @source_key,
        "display_name" => "Source Health UI Recheck Action Fixture",
        "source_type" => "api",
        "adapter_key" => "test_adapter",
        "region_code" => "US",
        "discovery_mode" => "fixture",
        "hydrate_mode" => "fixture",
        "default_home_market_region_code" => "US",
        "source_class" => "operator_test",
        "default_source_tier" => "official",
        "base_url" => "https://example.test/source-health-ui-recheck-action",
        "healthcheck_url" => "https://example.test/source-health-ui-recheck-action/health",
        "parser_key" => "test_parser",
        "poll_cron" => "0 * * * *",
        "coverage_tags" => ["source_health", "ui", "recheck_action"],
        "active" => true,
        "config" => %{},
        "health_status" => "healthy"
      })

    :ok
  end

  test "read-only auth context sees disabled recheck action", %{conn: conn} do
    response =
      conn
      |> SourceHealthAuthContext.put_test_source_health_permissions(["source_health:read"])
      |> get("/admin/source-health/#{@source_key}")
      |> response(200)

    assert response =~ "Source health detail"
    assert response =~ "state=found"
    assert response =~ "source_key=#{@source_key}"
    assert response =~ "recheck_action=disabled"
    assert response =~ "recheck_reason=read_only"

    refute response =~ "recheck_action=enabled"
    refute response =~ "POST /api/admin/source-health"
    refute response =~ "button"
    refute response =~ "poll_action"
    refute response =~ "audit_ui"
    refute_forbidden_material(response)
  end

  test "recheck auth context sees enabled bounded action", %{conn: conn} do
    response =
      conn
      |> SourceHealthAuthContext.put_test_source_health_permissions(["source_health:recheck"])
      |> get("/admin/source-health/#{@source_key}")
      |> response(200)

    assert response =~ "Source health detail"
    assert response =~ "state=found"
    assert response =~ "source_key=#{@source_key}"
    assert response =~ "recheck_action=enabled"
    assert response =~ "recheck_target=/api/admin/source-health/#{@source_key}/recheck"
    assert response =~ "idempotency=required"

    refute response =~ "operation="
    refute response =~ "queue="
    refute response =~ "worker="
    refute response =~ "payload="
    refute response =~ "poll"
    refute response =~ "materialize"
    refute response =~ "canonicalize"
    refute response =~ "provider_fetch"
    refute response =~ "audit_event"
    refute response =~ "audit_event_id"
    refute response =~ "button"
    refute_forbidden_material(response)
  end

  test "query actor_permissions cannot escalate explicit read-only auth context", %{conn: conn} do
    response =
      conn
      |> SourceHealthAuthContext.put_test_source_health_permissions(["source_health:read"])
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

  test "unknown source has no enabled recheck action", %{conn: conn} do
    response =
      conn
      |> SourceHealthAuthContext.put_test_source_health_permissions(["source_health:recheck"])
      |> get("/admin/source-health/#{@missing_source_key}")
      |> response(404)

    assert response =~ "Source health detail"
    assert response =~ "state=not_found"
    assert response =~ "source_key=#{@missing_source_key}"
    assert response =~ "recheck_action=not_available"
    assert response =~ "back=/admin/source-health"

    refute response =~ "recheck_action=enabled"
    refute response =~ "recheck_target="
    refute_forbidden_material(response)
  end

  test "recheck action state does not expose forbidden material", %{conn: conn} do
    response =
      conn
      |> SourceHealthAuthContext.put_test_source_health_permissions(["source_health:recheck"])
      |> get("/admin/source-health/#{@source_key}")
      |> response(200)

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
  end
end
