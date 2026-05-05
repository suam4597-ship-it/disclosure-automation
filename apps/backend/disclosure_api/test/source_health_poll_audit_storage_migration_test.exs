defmodule DisclosureAutomation.SourceHealthPollAuditStorageMigrationTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Repo

  @table "source_health_poll_audit_events"

  @required_columns [
    "id",
    "source_key",
    "route_operation",
    "result_status",
    "idempotency_status",
    "rate_limit_status",
    "actor_id_hash",
    "request_id_hash",
    "idempotency_key_hash",
    "idempotency_key_id",
    "rate_limit_key_id",
    "reason_redacted",
    "redaction_status",
    "occurred_at",
    "metadata",
    "inserted_at",
    "updated_at"
  ]

  @forbidden_columns [
    "raw_actor_id",
    "raw_request_id",
    "raw_idempotency_key",
    "unredacted_reason",
    "headers",
    "cookies",
    "tokens",
    "provider_credentials",
    "raw_provider_payload",
    "full_article_text",
    "raw_transport_response",
    "sql_details",
    "stack_trace",
    "canonical_payload",
    "private_actor_context",
    "unbounded_diagnostics",
    "audit_event_id"
  ]

  test "source health poll audit table exists with bounded columns" do
    columns = table_columns(@table)

    for column <- @required_columns do
      assert column in columns
    end

    for column <- @forbidden_columns do
      refute column in columns
    end
  end

  test "source health poll audit table has required indexes" do
    indexes = table_indexes(@table)

    assert "sh_poll_audit_source_key_idx" in indexes
    assert "sh_poll_audit_route_operation_idx" in indexes
    assert "sh_poll_audit_result_status_idx" in indexes
    assert "sh_poll_audit_idem_status_idx" in indexes
    assert "sh_poll_audit_rate_status_idx" in indexes
    assert "sh_poll_audit_occurred_at_idx" in indexes
    assert "sh_poll_audit_idem_key_id_idx" in indexes
    assert "sh_poll_audit_rate_key_id_idx" in indexes
  end

  test "source health poll audit table can store accepted bounded audit event" do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    {1, _rows} =
      Repo.insert_all(@table, [
        bounded_audit_event(%{
          result_status: "accepted",
          idempotency_status: "accepted",
          rate_limit_status: "allowed",
          occurred_at: now,
          inserted_at: now,
          updated_at: now
        })
      ])
  end

  test "source health poll audit table can store reused and rate-limited bounded audit events" do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    {2, _rows} =
      Repo.insert_all(@table, [
        bounded_audit_event(%{
          result_status: "reused",
          idempotency_status: "reused",
          rate_limit_status: "allowed",
          occurred_at: now,
          inserted_at: now,
          updated_at: now
        }),
        bounded_audit_event(%{
          result_status: "rate_limited",
          idempotency_status: "none",
          rate_limit_status: "rate_limited_source",
          occurred_at: now,
          inserted_at: now,
          updated_at: now
        })
      ])
  end

  test "source health poll audit table can store denial bounded audit events" do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    {3, _rows} =
      Repo.insert_all(@table, [
        bounded_audit_event(%{
          result_status: "missing_key_denied",
          idempotency_status: "missing_key_denied",
          rate_limit_status: "none",
          occurred_at: now,
          inserted_at: now,
          updated_at: now
        }),
        bounded_audit_event(%{
          result_status: "forbidden",
          idempotency_status: "none",
          rate_limit_status: "none",
          occurred_at: now,
          inserted_at: now,
          updated_at: now
        }),
        bounded_audit_event(%{
          result_status: "not_found",
          idempotency_status: "none",
          rate_limit_status: "none",
          occurred_at: now,
          inserted_at: now,
          updated_at: now
        })
      ])
  end

  defp bounded_audit_event(overrides) do
    %{
      id: Ecto.UUID.generate() |> Ecto.UUID.dump!(),
      source_key: "source_health_poll_audit_storage_fixture",
      route_operation: "source_health:poll",
      result_status: "accepted",
      idempotency_status: "accepted",
      rate_limit_status: "allowed",
      actor_id_hash: "sha256:operator-poll-audit-001",
      request_id_hash: "sha256:request-poll-audit-001",
      idempotency_key_hash: "sha256:idempotency-poll-audit-001",
      idempotency_key_id: nil,
      rate_limit_key_id: nil,
      reason_redacted: "REDACTED_SOURCE_HEALTH_POLL_REASON",
      redaction_status: "passed",
      occurred_at: DateTime.utc_now() |> DateTime.truncate(:microsecond),
      metadata: %{},
      inserted_at: DateTime.utc_now() |> DateTime.truncate(:microsecond),
      updated_at: DateTime.utc_now() |> DateTime.truncate(:microsecond)
    }
    |> Map.merge(overrides)
  end

  defp table_columns(table_name) do
    {:ok, result} =
      Repo.query("""
      select column_name
      from information_schema.columns
      where table_name = $1
      order by ordinal_position
      """, [table_name])

    Enum.map(result.rows, fn [column_name] -> column_name end)
  end

  defp table_indexes(table_name) do
    {:ok, result} =
      Repo.query("""
      select indexname
      from pg_indexes
      where tablename = $1
      order by indexname
      """, [table_name])

    Enum.map(result.rows, fn [index_name] -> index_name end)
  end
end
