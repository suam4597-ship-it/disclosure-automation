defmodule DisclosureAutomation.SourceHealthRecheckAuditRuntimeTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Sources

  @audit_table "source_health_recheck_audit_events"
  @source_key "source_health_recheck_audit_runtime_fixture"
  @missing_source_key "source_health_recheck_audit_runtime_missing_source"

  setup do
    {:ok, _source} =
      Sources.upsert_source(%{
        "source_key" => @source_key,
        "display_name" => "Source Health Recheck Audit Runtime Fixture",
        "source_type" => "api",
        "adapter_key" => "test_adapter",
        "region_code" => "US",
        "discovery_mode" => "fixture",
        "hydrate_mode" => "fixture",
        "default_home_market_region_code" => "US",
        "source_class" => "operator_test",
        "default_source_tier" => "official",
        "base_url" => "https://example.test/source-health-recheck-audit-runtime",
        "healthcheck_url" => "https://example.test/source-health-recheck-audit-runtime/health",
        "parser_key" => "test_parser",
        "poll_cron" => "0 * * * *",
        "coverage_tags" => ["source_health", "recheck", "audit_runtime"],
        "active" => true,
        "config" => %{},
        "health_status" => "unknown"
      })

    :ok
  end

  test "accepted and reused recheck write bounded audit events", %{conn: conn} do
    idempotency_key_hash = "sha256:audit-runtime-same-001"

    first_response =
      conn
      |> post("/api/admin/source-health/#{@source_key}/recheck", recheck_actor_payload(idempotency_key_hash))
      |> json_response(202)

    second_response =
      build_conn()
      |> post("/api/admin/source-health/#{@source_key}/recheck", recheck_actor_payload(idempotency_key_hash))
      |> json_response(202)

    assert inspect(first_response) =~ "accepted"
    assert inspect(second_response) =~ "reused"

    assert audit_event_count(@source_key, "accepted", "accepted") == 1
    assert audit_event_count(@source_key, "reused", "reused") == 1
    refute_audit_forbidden_material(@source_key)
  end

  test "untracked recheck writes bounded audit event without response shape change", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/source-health/#{@source_key}/recheck", recheck_actor_payload_without_idempotency())
      |> json_response(202)

    encoded = inspect(response)
    assert encoded =~ "untracked"
    refute encoded =~ "audit"

    assert audit_event_count(@source_key, "untracked", "untracked") == 1
    refute_audit_forbidden_material(@source_key)
  end

  test "forbidden and not-found outcomes write bounded audit events", %{conn: conn} do
    read_only_response =
      conn
      |> post("/api/admin/source-health/#{@source_key}/recheck", read_only_actor_payload())
      |> json_response(403)

    missing_response =
      build_conn()
      |> post("/api/admin/source-health/#{@missing_source_key}/recheck", recheck_actor_payload("sha256:audit-runtime-missing-001"))
      |> json_response(404)

    assert read_only_response["error"]["code"] == "forbidden"
    assert missing_response["error"]["code"] == "not_found"

    assert audit_event_count(@source_key, "forbidden", "none") == 1
    assert audit_event_count(@missing_source_key, "not_found", "none") == 1
    refute_audit_forbidden_material(@source_key)
    refute_audit_forbidden_material(@missing_source_key)
  end

  test "request body route operation override does not alter audit route operation", %{conn: conn} do
    conn
    |> post("/api/admin/source-health/#{@source_key}/recheck", recheck_actor_override_payload())
    |> json_response(202)

    assert audit_route_operation_count(@source_key, "source_health:recheck") == 1
    assert audit_route_operation_count(@source_key, "materialize") == 0
    assert audit_route_operation_count(@source_key, "canonicalize") == 0
    assert audit_route_operation_count(@source_key, "provider_fetch") == 0
    refute_audit_forbidden_material(@source_key)
  end

  defp audit_event_count(source_key, result_status, idempotency_status) do
    {:ok, result} =
      Repo.query(
        """
        select count(*)
        from #{@audit_table}
        where source_key = $1 and result_status = $2 and idempotency_status = $3
        """,
        [source_key, result_status, idempotency_status]
      )

    [[count]] = result.rows
    count
  end

  defp audit_route_operation_count(source_key, route_operation) do
    {:ok, result} =
      Repo.query(
        """
        select count(*)
        from #{@audit_table}
        where source_key = $1 and route_operation = $2
        """,
        [source_key, route_operation]
      )

    [[count]] = result.rows
    count
  end

  defp refute_audit_forbidden_material(source_key) do
    {:ok, result} =
      Repo.query(
        """
        select
          coalesce(actor_id_hash, ''),
          coalesce(request_id_hash, ''),
          coalesce(idempotency_key_hash, ''),
          coalesce(reason_redacted, ''),
          coalesce(metadata::text, '')
        from #{@audit_table}
        where source_key = $1
        """,
        [source_key]
      )

    encoded = inspect(result.rows)

    refute encoded =~ "raw_actor_id"
    refute encoded =~ "raw_request_id"
    refute encoded =~ "raw_idempotency_key"
    refute encoded =~ "unredacted_reason"
    refute encoded =~ "raw_provider_payload"
    refute encoded =~ "full_article_text"
    refute encoded =~ "raw_transport_response"
    refute encoded =~ "sql_details"
    refute encoded =~ "stack_trace"
    refute encoded =~ "canonical_payload"
    refute encoded =~ "private_actor_context"
    refute encoded =~ "unbounded_diagnostics"
  end

  defp recheck_actor_override_payload do
    recheck_actor_payload("sha256:audit-runtime-override-001")
    |> Map.merge(%{
      "operation" => "poll",
      "action_operation" => "materialize",
      "route_operation" => "canonicalize",
      "action" => "provider_fetch",
      "queue" => "operator_override_queue",
      "worker" => "operator_override_worker",
      "payload" => %{"operator_override_payload" => true}
    })
  end

  defp recheck_actor_payload(idempotency_key_hash) do
    %{
      "actor_id_hash" => "sha256:operator-audit-runtime-001",
      "actor_permissions" => ["source_health:recheck"],
      "roles" => ["operator"],
      "request_id_hash" => "sha256:request-audit-runtime-001",
      "idempotency_key_hash" => idempotency_key_hash,
      "reason_redacted" => "REDACTED_SOURCE_HEALTH_REASON",
      "redaction_status" => "passed",
      "created_at" => "2026-05-04T00:00:00Z"
    }
  end

  defp recheck_actor_payload_without_idempotency do
    recheck_actor_payload("sha256:audit-runtime-removed")
    |> Map.delete("idempotency_key_hash")
  end

  defp read_only_actor_payload do
    recheck_actor_payload("sha256:audit-runtime-read-only-001")
    |> Map.put("actor_permissions", ["source_health:read"])
  end
end
