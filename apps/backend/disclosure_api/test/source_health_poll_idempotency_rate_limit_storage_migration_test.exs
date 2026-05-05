defmodule DisclosureAutomation.SourceHealthPollIdempotencyRateLimitStorageMigrationTest do
  use DisclosureAutomationWeb.ConnCase, async: false

  alias DisclosureAutomation.Repo

  @idempotency_table "source_health_poll_idempotency_keys"
  @rate_limit_table "source_health_poll_rate_limits"

  @idempotency_required_columns [
    "id",
    "source_key",
    "idempotency_key_hash",
    "request_id_hash",
    "actor_id_hash",
    "status",
    "rate_limit_status",
    "expires_at",
    "last_seen_at",
    "metadata",
    "inserted_at",
    "updated_at"
  ]

  @rate_limit_required_columns [
    "id",
    "scope",
    "scope_key",
    "source_key",
    "actor_id_hash",
    "status",
    "request_count",
    "limit_count",
    "window_start_at",
    "window_expires_at",
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

  test "source health poll idempotency table exists with bounded columns" do
    columns = table_columns(@idempotency_table)

    for column <- @idempotency_required_columns do
      assert column in columns
    end

    for column <- @forbidden_columns do
      refute column in columns
    end
  end

  test "source health poll idempotency table has required indexes" do
    indexes = table_indexes(@idempotency_table)

    assert "sh_poll_idem_source_key_hash_uidx" in indexes
    assert "sh_poll_idem_source_key_idx" in indexes
    assert "sh_poll_idem_expires_at_idx" in indexes
    assert "sh_poll_idem_status_idx" in indexes
    assert "sh_poll_idem_rate_status_idx" in indexes
  end

  test "source health poll idempotency source key and idempotency hash pair is unique" do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
    expires_at = DateTime.add(now, 15 * 60, :second)

    insert_idempotency_record!(now, expires_at)

    assert_raise Postgrex.Error, fn ->
      insert_idempotency_record!(now, expires_at)
    end
  end

  test "source health poll rate limit table exists with bounded columns" do
    columns = table_columns(@rate_limit_table)

    for column <- @rate_limit_required_columns do
      assert column in columns
    end

    for column <- @forbidden_columns do
      refute column in columns
    end
  end

  test "source health poll rate limit table has required indexes" do
    indexes = table_indexes(@rate_limit_table)

    assert "sh_poll_rate_scope_key_window_uidx" in indexes
    assert "sh_poll_rate_scope_idx" in indexes
    assert "sh_poll_rate_scope_key_idx" in indexes
    assert "sh_poll_rate_window_expires_idx" in indexes
    assert "sh_poll_rate_status_idx" in indexes
  end

  test "source health poll rate limit scope key and window start tuple is unique" do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)
    window_expires_at = DateTime.add(now, 60, :second)

    insert_rate_limit_record!(now, window_expires_at)

    assert_raise Postgrex.Error, fn ->
      insert_rate_limit_record!(now, window_expires_at)
    end
  end

  defp insert_idempotency_record!(now, expires_at) do
    Repo.insert_all(@idempotency_table, [
      %{
        id: Ecto.UUID.generate() |> Ecto.UUID.dump!(),
        source_key: "source_health_poll_idem_storage_fixture",
        idempotency_key_hash: "sha256:idempotency-poll-storage-001",
        request_id_hash: "sha256:request-poll-storage-001",
        actor_id_hash: "sha256:operator-poll-storage-001",
        status: "accepted",
        rate_limit_status: "allowed",
        expires_at: expires_at,
        last_seen_at: now,
        metadata: %{},
        inserted_at: now,
        updated_at: now
      }
    ])
  end

  defp insert_rate_limit_record!(now, window_expires_at) do
    Repo.insert_all(@rate_limit_table, [
      %{
        id: Ecto.UUID.generate() |> Ecto.UUID.dump!(),
        scope: "source_key",
        scope_key: "source_health_poll_rate_storage_fixture",
        source_key: "source_health_poll_rate_storage_fixture",
        actor_id_hash: "sha256:operator-poll-rate-storage-001",
        status: "allowed",
        request_count: 1,
        limit_count: 5,
        window_start_at: now,
        window_expires_at: window_expires_at,
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
