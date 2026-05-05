defmodule DisclosureAutomation.SourceHealthPollAuditRuntimeTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.SourceHealthPollRuntime
  alias DisclosureAutomation.Sources

  @source_key "source_health_poll_audit_runtime_fixture"
  @missing_source_key "source_health_poll_audit_runtime_missing"
  @audit_table "source_health_poll_audit_events"
  @rate_limit_table "source_health_poll_rate_limits"

  setup do
    {:ok, _source} =
      Sources.upsert_source(%{
        "source_key" => @source_key,
        "display_name" => "Source Health Poll Audit Runtime Fixture",
        "source_type" => "api",
        "adapter_key" => "test_adapter",
        "region_code" => "US",
        "discovery_mode" => "fixture",
        "hydrate_mode" => "fixture",
        "default_home_market_region_code" => "US",
        "source_class" => "operator_test",
        "default_source_tier" => "official",
        "base_url" => "https://example.test/source-health-poll-audit-runtime",
        "healthcheck_url" => "https://example.test/source-health-poll-audit-runtime/health",
        "parser_key" => "test_parser",
        "poll_cron" => "0 * * * *",
        "coverage_tags" => ["source_health", "poll", "audit_runtime"],
        "active" => true,
        "config" => %{},
        "health_status" => "unknown"
      })

    :ok
  end

  test "accepted poll preparation writes bounded audit event" do
    assert {:ok, %{"poll_status" => "accepted"}} =
             SourceHealthPollRuntime.prepare_poll(@source_key, poll_actor_payload("accepted"))

    audit = latest_audit_event(@source_key)
    assert audit["route_operation"] == "source_health:poll"
    assert audit["result_status"] == "accepted"
    assert audit["idempotency_status"] == "accepted"
    assert audit["rate_limit_status"] == "allowed"
    assert audit["actor_id_hash"] == "sha256:operator-poll-audit-runtime-001"
    assert audit["request_id_hash"] == "sha256:request-poll-audit-runtime-accepted"
    assert audit["idempotency_key_hash"] == "sha256:idempotency-poll-audit-runtime-accepted"
    refute_private_material(audit)
  end

  test "reused poll response writes bounded audit event and exposes no audit id", %{conn: conn} do
    assert {:ok, %{"poll_status" => "accepted"}} =
             SourceHealthPollRuntime.prepare_poll(@source_key, poll_actor_payload("reused"))

    response =
      conn
      |> post("/api/admin/sources/#{@source_key}/poll", poll_actor_payload("reused"))
      |> json_response(202)

    assert response["poll_status"] == "reused"
    refute_audit_response_fields(response)

    audit = latest_audit_event(@source_key)
    assert audit["result_status"] == "reused"
    assert audit["idempotency_status"] == "reused"
    assert audit["rate_limit_status"] == "allowed"
    refute_private_material(audit)
  end

  test "missing idempotency key writes bounded audit event and exposes no audit id", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/sources/#{@source_key}/poll", poll_actor_payload_without_idempotency())
      |> json_response(409)

    assert response["error"]["code"] == "missing_idempotency_key"
    refute_audit_response_fields(response)

    audit = latest_audit_event(@source_key)
    assert audit["result_status"] == "missing_key_denied"
    assert audit["idempotency_status"] == "missing_key_denied"
    assert audit["rate_limit_status"] == "none"
    refute_private_material(audit)
  end

  test "rate-limited poll writes bounded audit event and exposes no audit id", %{conn: conn} do
    prefill_rate_limit!("source_key", @source_key, 5)

    response =
      conn
      |> post("/api/admin/sources/#{@source_key}/poll", poll_actor_payload("rate-limited"))
      |> json_response(429)

    assert response["error"]["code"] == "rate_limited"
    assert response["error"]["rate_limit_status"] == "rate_limited_source"
    refute_audit_response_fields(response)

    audit = latest_audit_event(@source_key)
    assert audit["result_status"] == "rate_limited"
    assert audit["idempotency_status"] == "none"
    assert audit["rate_limit_status"] == "rate_limited_source"
    refute_private_material(audit)
  end

  test "forbidden poll writes bounded audit event and exposes no audit id", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/sources/#{@source_key}/poll", read_only_payload())
      |> json_response(403)

    assert response["error"]["code"] == "forbidden"
    assert response["error"]["message"] == "source poll not allowed"
    refute_audit_response_fields(response)

    audit = latest_audit_event(@source_key)
    assert audit["result_status"] == "forbidden"
    assert audit["idempotency_status"] == "none"
    assert audit["rate_limit_status"] == "none"
    refute_private_material(audit)
  end

  test "unknown source poll writes bounded audit event and exposes no audit id", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/sources/#{@missing_source_key}/poll", poll_actor_payload("not-found"))
      |> json_response(404)

    assert response["error"]["code"] == "not_found"
    assert response["error"]["message"] == "source not found"
    refute_audit_response_fields(response)

    audit = latest_audit_event(@missing_source_key)
    assert audit["result_status"] == "not_found"
    assert audit["idempotency_status"] == "none"
    assert audit["rate_limit_status"] == "none"
    refute_private_material(audit)
  end

  test "body overrides cannot alter server-derived audit route or statuses", %{conn: conn} do
    response =
      conn
      |> post("/api/admin/sources/#{@source_key}/poll", unsafe_override_payload_without_idempotency())
      |> json_response(409)

    assert response["error"]["code"] == "missing_idempotency_key"
    refute_audit_response_fields(response)

    audit = latest_audit_event(@source_key)
    assert audit["route_operation"] == "source_health:poll"
    assert audit["result_status"] == "missing_key_denied"
    assert audit["idempotency_status"] == "missing_key_denied"
    assert audit["rate_limit_status"] == "none"
    refute_private_material(audit)
    refute_poll_runtime_material(audit)
  end

  defp poll_actor_payload(idempotency_suffix) do
    %{
      "actor_id_hash" => "sha256:operator-poll-audit-runtime-001",
      "actor_permissions" => ["source_health:poll"],
      "request_id_hash" => "sha256:request-poll-audit-runtime-#{idempotency_suffix}",
      "idempotency_key_hash" => "sha256:idempotency-poll-audit-runtime-#{idempotency_suffix}",
      "reason_redacted" => "REDACTED_SOURCE_HEALTH_POLL_REASON",
      "redaction_status" => "passed",
      "created_at" => "2026-05-04T00:00:00Z"
    }
  end

  defp read_only_payload do
    poll_actor_payload("forbidden")
    |> Map.put("actor_permissions", ["source_health:read"])
  end

  defp poll_actor_payload_without_idempotency do
    poll_actor_payload("missing")
    |> Map.delete("idempotency_key_hash")
  end

  defp unsafe_override_payload_without_idempotency do
    poll_actor_payload_without_idempotency()
    |> Map.merge(%{
      "route_operation" => "body_override_must_not_win",
      "result_status" => "accepted",
      "idempotency_status" => "accepted",
      "rate_limit_status" => "allowed",
      "audit_event_id" => "raw-audit-event-id",
      "operation" => "poll",
      "action_operation" => "provider_fetch",
      "provider_fetch" => true,
      "materialize" => true,
      "canonicalize" => true,
      "inline_feed" => true,
      "use_live_fetch" => true
    })
  end

  defp prefill_rate_limit!(scope, scope_key, request_count) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    # Keep the setup stable if the request crosses a second boundary between
    # prefill and the controller's rate-limit window calculation.
    audit_windows = [
      DateTime.add(now, -1, :second),
      now,
      DateTime.add(now, 1, :second)
    ]

    rows =
      Enum.map(audit_windows, fn window_start_at ->
        %{
          id: Ecto.UUID.generate() |> Ecto.UUID.dump!(),
          scope: scope,
          scope_key: scope_key,
          source_key: @source_key,
          actor_id_hash: "sha256:operator-poll-audit-runtime-001",
          status: "allowed",
          request_count: request_count,
          limit_count: request_count,
          window_start_at: window_start_at,
          window_expires_at: DateTime.add(window_start_at, 60, :second),
          metadata: %{},
          inserted_at: now,
          updated_at: now
        }
      end)

    Repo.insert_all(@rate_limit_table, rows)
  end

  defp latest_audit_event(source_key) do
    {:ok, result} =
      Repo.query(
        """
        select source_key, route_operation, result_status, idempotency_status, rate_limit_status,
               actor_id_hash, request_id_hash, idempotency_key_hash, reason_redacted, redaction_status
        from #{@audit_table}
        where source_key = $1
        order by inserted_at desc
        limit 1
        """,
        [source_key]
      )

    [row] = result.rows

    result.columns
    |> Enum.zip(row)
    |> Map.new()
  end

  defp refute_audit_response_fields(response) do
    encoded = inspect(response)

    refute encoded =~ "audit_event"
    refute encoded =~ "audit_event_id"
    refute encoded =~ "audit_primary_key"
    refute encoded =~ "idempotency_key_id"
    refute encoded =~ "rate_limit_key_id"
  end

  defp refute_private_material(response) do
    encoded = inspect(response)

    refute encoded =~ "raw_provider_payload"
    refute encoded =~ "full_article_text"
    refute encoded =~ "headers"
    refute encoded =~ "cookies"
    refute encoded =~ "secrets"
    refute encoded =~ "api_keys"
    refute encoded =~ "raw_transport_response"
    refute encoded =~ "sql_details"
    refute encoded =~ "stack_trace"
    refute encoded =~ "canonical_payload"
    refute encoded =~ "private_actor_context"
    refute encoded =~ "unbounded_diagnostics"
    refute encoded =~ "raw_actor_id"
    refute encoded =~ "raw_request_id"
    refute encoded =~ "raw_idempotency_key"
    refute encoded =~ "unredacted_reason"
  end

  defp refute_poll_runtime_material(response) do
    encoded = inspect(response)

    refute encoded =~ "provider_fetch"
    refute encoded =~ "materialize"
    refute encoded =~ "canonicalize"
    refute encoded =~ "inline_feed"
    refute encoded =~ "use_live_fetch"
  end
end
