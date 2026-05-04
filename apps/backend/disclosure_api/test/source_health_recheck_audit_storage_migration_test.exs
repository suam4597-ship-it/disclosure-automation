defmodule DisclosureAutomation.SourceHealthRecheckAuditStorageMigrationTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Repo

  @table "source_health_recheck_audit_events"
  @required_columns [
    "id",
    "source_key",
    "route_operation",
    "result_status",
    "idempotency_status",
    "actor_id_hash",
    "request_id_hash",
    "idempotency_key_hash",
    "idempotency_key_id",
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
    "sql_details",
    "stack_trace",
    "canonical_payload",
    "private_actor_context",
    "unbounded_diagnostics"
  ]

  test "source health recheck audit table exists with bounded columns" do
    columns = table_columns(@table)

    for column <- @required_columns do
      assert column in columns
    end

    for column <- @forbidden_columns do
      refute column in columns
    end
  end

  test "source health recheck audit table has required indexes" do
    indexes = table_indexes(@table)

    assert "source_health_recheck_audit_source_key_idx" in indexes
    assert "source_health_recheck_audit_route_operation_idx" in indexes
    assert "source_health_recheck_audit_result_status_idx" in indexes
    assert "source_health_recheck_audit_idem_status_idx" in indexes
    assert "source_health_recheck_audit_occurred_at_idx" in indexes
    assert "source_health_recheck_audit_idem_key_id_idx" in indexes
  end

  test "source health recheck audit table can store bounded audit event" do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    {1, _rows} =
      Repo.insert_all(@table, [
        %{
          id: Ecto.UUID.generate() |> Ecto.UUID.dump!(),
          source_key: "source_health_recheck_audit_storage_fixture",
          route_operation: "source_health:recheck",
          result_status: "accepted",
          idempotency_status: "accepted",
          actor_id_hash: "sha256:operator-audit-001",
          request_id_hash: "sha256:request-audit-001",
          idempotency_key_hash: "sha256:idempotency-audit-001",
          idempotency_key_id: nil,
          reason_redacted: "REDACTED_SOURCE_HEALTH_REASON",
          redaction_status: "passed",
          occurred_at: now,
          metadata: %{},
          inserted_at: now,
          updated_at: now
        }
      ])
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
