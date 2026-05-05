defmodule DisclosureAutomation.SourceHealthOperatorSmokeTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Sources

  @source_key "source_health_operator_smoke_fixture"
  @missing_source_key "source_health_operator_smoke_missing"

  setup do
    {:ok, _source} =
      Sources.upsert_source(%{
        "source_key" => @source_key,
        "display_name" => "Source Health Operator Smoke Fixture",
        "source_type" => "api",
        "adapter_key" => "test_adapter",
        "region_code" => "US",
        "discovery_mode" => "fixture",
        "hydrate_mode" => "fixture",
        "default_home_market_region_code" => "US",
        "source_class" => "operator_test",
        "default_source_tier" => "official",
        "base_url" => "https://example.test/source-health-operator-smoke",
        "healthcheck_url" => "https://example.test/source-health-operator-smoke/health",
        "parser_key" => "test_parser",
        "poll_cron" => "0 * * * *",
        "coverage_tags" => ["source_health", "operator", "smoke"],
        "active" => true,
        "config" => %{},
        "health_status" => "unknown"
      })

    :ok
  end

  test "operator can triage source health from the bounded list shell", %{conn: conn} do
    response =
      conn
      |> get("/admin/source-health")
      |> response(200)

    assert response =~ "Source health"
    assert response =~
             "fields=source_key,display_name,source_type,region_code,health_status,last_success_at,last_failure_at,active"

    assert response =~ "source_key=#{@source_key}"
    assert response =~ "display_name=Source Health Operator Smoke Fixture"
    assert response =~ "health_status=unknown"
    assert response =~ "recheck_action=not_rendered"
    assert response =~ "poll_action=not_rendered"
    assert response =~ "audit_ui=not_rendered"

    refute response =~ "button"
    refute response =~ "POST /api/admin/source-health"
    refute response =~ "POST /api/admin/sources"
    refute response =~ "poll_source"
    refute_forbidden_material(response)
  end

  test "operator with recheck permission sees bounded detail recheck contract", %{conn: conn} do
    response =
      conn
      |> get("/admin/source-health/#{@source_key}?actor_permissions=source_health:recheck")
      |> response(200)

    assert response =~ "Source health detail"
    assert response =~ "state=found"
    assert response =~ "source_key=#{@source_key}"
    assert response =~ "recheck_action=enabled"
    assert response =~ "recheck_method=POST"
    assert response =~ "recheck_target=/api/admin/source-health/#{@source_key}/recheck"
    assert response =~ "idempotency=required"
    assert response =~ "recheck_context=bounded"

    assert response =~ "actor_id_hash"
    assert response =~ "actor_permissions"
    assert response =~ "request_id_hash"
    assert response =~ "idempotency_key_hash"
    assert response =~ "reason_redacted"
    assert response =~ "redaction_status"
    assert response =~ "created_at"

    refute response =~ "operation"
    refute response =~ "action_operation"
    refute response =~ "route_operation"
    refute response =~ "queue="
    refute response =~ "worker="
    refute response =~ "payload="
    refute response =~ "provider_fetch"
    refute response =~ "materialize"
    refute response =~ "canonicalize"
    refute response =~ "poll"
    refute_forbidden_material(response)
  end

  test "operator with recheck permission can submit bounded backend recheck", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/source-health/#{@source_key}/recheck", recheck_payload())
      |> json_response(202)

    assert response["source_key"] == @source_key
    assert response["queue"] == "health_checks"
    assert response["idempotency_status"] in ["accepted", "reused"]

    refute_private_material(response)
  end

  test "read-only operator sees disabled detail recheck action", %{conn: conn} do
    response =
      conn
      |> get("/admin/source-health/#{@source_key}?actor_permissions=source_health:read")
      |> response(200)

    assert response =~ "Source health detail"
    assert response =~ "state=found"
    assert response =~ "source_key=#{@source_key}"
    assert response =~ "recheck_action=disabled"
    assert response =~ "recheck_reason=read_only"

    refute response =~ "recheck_action=enabled"
    refute response =~ "recheck_target="
    refute response =~ "recheck_method=POST"
    refute response =~ "button"
    refute response =~ "poll"
    refute response =~ "audit_ui"
    refute_forbidden_material(response)
  end

  test "read-only backend recheck attempt returns bounded forbidden response", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/source-health/#{@source_key}/recheck", read_only_payload())
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

  test "unknown source detail and backend recheck attempt stay bounded", %{conn: conn} do
    detail_response =
      conn
      |> get("/admin/source-health/#{@missing_source_key}?actor_permissions=source_health:recheck")
      |> response(404)

    assert detail_response =~ "Source health detail"
    assert detail_response =~ "state=not_found"
    assert detail_response =~ "source_key=#{@missing_source_key}"
    assert detail_response =~ "recheck_action=not_available"
    assert detail_response =~ "back=/admin/source-health"

    refute detail_response =~ "recheck_action=enabled"
    refute detail_response =~ "recheck_target="
    refute_forbidden_material(detail_response)

    backend_response =
      build_conn()
      |> post("/api/admin/source-health/#{@missing_source_key}/recheck", recheck_payload())
      |> json_response(404)

    assert backend_response == %{
             "error" => %{
               "code" => "not_found",
               "message" => "source not found"
             }
           }

    refute_accepted_job_response(backend_response)
    refute_private_material(backend_response)
  end

  defp recheck_payload do
    %{
      "actor_id_hash" => "sha256:operator-smoke-001",
      "actor_permissions" => ["source_health:recheck"],
      "request_id_hash" => "sha256:request-smoke-001",
      "idempotency_key_hash" => "sha256:idempotency-smoke-001",
      "reason_redacted" => "REDACTED_SOURCE_HEALTH_REASON",
      "redaction_status" => "passed",
      "created_at" => "2026-05-04T00:00:00Z"
    }
  end

  defp read_only_payload do
    recheck_payload()
    |> Map.put("actor_id_hash", "sha256:operator-smoke-read-only-001")
    |> Map.put("actor_permissions", ["source_health:read"])
    |> Map.put("request_id_hash", "sha256:request-smoke-read-only-001")
    |> Map.put("idempotency_key_hash", "sha256:idempotency-smoke-read-only-001")
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
    refute response =~ "audit_event"
    refute response =~ "audit_event_id"
  end
end
