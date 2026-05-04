defmodule DisclosureAutomation.SourceHealthRecheckIdempotencyStorageMigrationTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Repo

  @table "source_health_recheck_idempotency_keys"
  @required_columns [
    "id",
    "source_key",
    "idempotency_key_hash",
    "request_id_hash",
    "actor_id_hash",
    "status",
    "job_reference",
    "expires_at",
    "last_seen_at",
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

  test "source health recheck idempotency table exists with bounded columns" do
    columns = table_columns(@table)

    for column <- @required_columns do
      assert column in columns
    end

    for column <- @forbidden_columns do
      refute column in columns
    end
  end

  test "source health recheck idempotency table has required indexes" do
    indexes = table_indexes(@table)

    assert "source_health_recheck_idem_source_key_hash_uidx" in indexes
    assert "source_health_recheck_idem_source_key_idx" in indexes
    assert "source_health_recheck_idem_expires_at_idx" in indexes
    assert "source_health_recheck_idem_status_idx" in indexes
  end

  test "source key and idempotency hash pair is unique" do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
    expires_at = DateTime.add(now, 15 * 60, :second)

    insert_idempotency_record!(now, expires_at)

    assert_raise Postgrex.Error, fn ->
      insert_idempotency_record!(now, expires_at)
    end
  end

  defp insert_idempotency_record!(now, expires_at) do
    Repo.insert_all(@table, [
      %{
        id: Ecto.UUID.generate(),
        source_key: "source_health_recheck_idem_storage_fixture",
        idempotency_key_hash: "sha256:idempotency-storage-001",
        request_id_hash: "sha256:request-storage-001",
        actor_id_hash: "sha256:operator-storage-001",
        status: "accepted",
        job_reference: %{},
        expires_at: expires_at,
        last_seen_at: now,
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
