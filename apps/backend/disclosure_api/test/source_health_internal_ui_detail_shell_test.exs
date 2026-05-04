defmodule DisclosureAutomation.SourceHealthInternalUiDetailShellTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Sources

  @source_key "source_health_ui_detail_shell_fixture"
  @missing_source_key "source_health_ui_detail_shell_missing"

  setup do
    {:ok, _source} =
      Sources.upsert_source(%{
        "source_key" => @source_key,
        "display_name" => "Source Health UI Detail Shell Fixture",
        "source_type" => "api",
        "adapter_key" => "test_adapter",
        "region_code" => "US",
        "discovery_mode" => "fixture",
        "hydrate_mode" => "fixture",
        "default_home_market_region_code" => "US",
        "source_class" => "operator_test",
        "default_source_tier" => "official",
        "base_url" => "https://example.test/source-health-ui-detail-shell",
        "healthcheck_url" => "https://example.test/source-health-ui-detail-shell/health",
        "parser_key" => "test_parser",
        "poll_cron" => "0 * * * *",
        "coverage_tags" => ["source_health", "ui", "detail_shell"],
        "active" => true,
        "config" => %{},
        "health_status" => "healthy"
      })

    :ok
  end

  test "GET /admin/source-health/:source_key renders bounded detail shell", %{conn: conn} do
    response =
      conn
      |> get("/admin/source-health/#{@source_key}")
      |> response(200)

    assert response =~ "Source health detail"
    assert response =~ "state=found"
    assert response =~ "source_key=#{@source_key}"
    assert response =~ "display_name=Source Health UI Detail Shell Fixture"
    assert response =~ "source_type=api"
    assert response =~ "region_code=US"
    assert response =~ "health_status=healthy"
    assert response =~ "active=true"
    assert response =~ "cursor_count=0"
    assert response =~ "back=/admin/source-health"
  end

  test "GET /admin/source-health/:source_key renders bounded not found state", %{conn: conn} do
    response =
      conn
      |> get("/admin/source-health/#{@missing_source_key}")
      |> response(404)

    assert response =~ "Source health detail"
    assert response =~ "state=not_found"
    assert response =~ "source_key=#{@missing_source_key}"
    assert response =~ "back=/admin/source-health"
    refute_forbidden_material(response)
  end

  test "GET /admin/source-health/:source_key detail shell does not render action controls", %{conn: conn} do
    response =
      conn
      |> get("/admin/source-health/#{@source_key}")
      |> response(200)

    assert response =~ "recheck_action=not_rendered"
    assert response =~ "poll_action=not_rendered"
    assert response =~ "audit_ui=not_rendered"

    refute response =~ "button"
    refute response =~ "POST /api/admin/source-health"
    refute response =~ "POST /api/admin/sources"
    refute response =~ "poll_source"
  end

  test "GET /admin/source-health/:source_key detail shell does not expose forbidden material", %{conn: conn} do
    response =
      conn
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
  end
end
