defmodule DisclosureAutomation.SourceHealthInternalUiRecheckSubmitFlowTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Sources

  @source_key "source_health_ui_recheck_submit_fixture"
  @missing_source_key "source_health_ui_recheck_submit_missing"

  setup do
    {:ok, _source} =
      Sources.upsert_source(%{
        "source_key" => @source_key,
        "display_name" => "Source Health UI Recheck Submit Fixture",
        "source_type" => "api",
        "adapter_key" => "test_adapter",
        "region_code" => "US",
        "discovery_mode" => "fixture",
        "hydrate_mode" => "fixture",
        "default_home_market_region_code" => "US",
        "source_class" => "operator_test",
        "default_source_tier" => "official",
        "base_url" => "https://example.test/source-health-ui-recheck-submit",
        "healthcheck_url" => "https://example.test/source-health-ui-recheck-submit/health",
        "parser_key" => "test_parser",
        "poll_cron" => "0 * * * *",
        "coverage_tags" => ["source_health", "ui", "recheck_submit"],
        "active" => true,
        "config" => %{},
        "health_status" => "unknown"
      })

    :ok
  end

  test "enabled detail state advertises only the bounded backend recheck submit contract", %{conn: conn} do
    response =
      conn
      |> get("/admin/source-health/#{@source_key}?actor_permissions=source_health:recheck")
      |> response(200)

    assert response =~ "recheck_action=enabled"
    assert response =~ "recheck_method=POST"
    assert response =~ "recheck_target=/api/admin/source-health/#{@source_key}/recheck"
    assert response =~ "recheck_context=bounded"

    assert response =~
             "recheck_context_fields=actor_id_hash,actor_permissions,request_id_hash,idempotency_key_hash,reason_redacted,redaction_status,created_at"

    assert response =~ "recheck_result_accepted_message=Recheck request accepted."
    assert response =~
             "recheck_result_reused_message=A similar recent recheck request was reused."

    assert response =~
             "recheck_result_untracked_message=Recheck request accepted without tracking."

    assert response =~
             "recheck_result_forbidden_message=You do not have permission to recheck this source."

    assert response =~ "recheck_result_not_found_message=Source not found."

    refute response =~ "operation"
    refute response =~ "action_operation"
    refute response =~ "route_operation"
    refute response =~ "\naction="
    refute response =~ "queue="
    refute response =~ "worker="
    refute response =~ "payload="
    refute response =~ "provider_fetch"
    refute response =~ "materialize"
    refute response =~ "canonicalize"
    refute response =~ "poll"
    refute response =~ "audit_event"
    refute response =~ "audit_event_id"
    refute_forbidden_material(response)
  end

  test "bounded UI payload can submit to the locked backend recheck route", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/source-health/#{@source_key}/recheck", bounded_recheck_payload())
      |> json_response(202)

    assert response["source_key"] == @source_key
    assert response["queue"] == "health_checks"
    assert response["idempotency_status"] in ["accepted", "reused"]

    refute_private_material(response)
  end

  test "bounded UI payload receives bounded forbidden result for read-only actors", %{conn: conn} do
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

  test "bounded UI payload receives bounded not-found result for unknown sources", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/source-health/#{@missing_source_key}/recheck", bounded_recheck_payload())
      |> json_response(404)

    assert response == %{
             "error" => %{
               "code" => "not_found",
               "message" => "source not found"
             }
           }

    refute_accepted_job_response(response)
    refute_private_material(response)
  end

  defp bounded_recheck_payload do
    %{
      "actor_id_hash" => "sha256:operator-ui-submit-001",
      "actor_permissions" => ["source_health:recheck"],
      "request_id_hash" => "sha256:request-ui-submit-001",
      "idempotency_key_hash" => "sha256:idempotency-ui-submit-001",
      "reason_redacted" => "REDACTED_SOURCE_HEALTH_REASON",
      "redaction_status" => "passed",
      "created_at" => "2026-05-04T00:00:00Z"
    }
  end

  defp read_only_payload do
    bounded_recheck_payload()
    |> Map.put("actor_permissions", ["source_health:read"])
    |> Map.put("idempotency_key_hash", "sha256:idempotency-ui-submit-read-only-001")
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
  end
end
