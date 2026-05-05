defmodule DisclosureAutomation.SourceHealthPollRuntime do
  @moduledoc false

  import Ecto.Query

  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Schema.SourceRegistry

  @poll_idempotency_table "source_health_poll_idempotency_keys"
  @poll_rate_limit_table "source_health_poll_rate_limits"
  @poll_audit_table "source_health_poll_audit_events"
  @poll_idempotency_window_seconds 15 * 60
  @poll_rate_limit_window_seconds 60

  @rate_limits [
    {"global", "global", 100, "rate_limited_global"},
    {"source_key", :source_key, 5, "rate_limited_source"},
    {"actor_id_hash", :actor_id_hash, 10, "rate_limited_actor"}
  ]

  def prepare_poll(source_key, attrs \\ %{}) when is_binary(source_key) and is_map(attrs) do
    case Repo.get_by(SourceRegistry, source_key: source_key) do
      nil ->
        record_poll_audit(source_key, attrs, "not_found", "none", "none")
        {:error, :not_found}

      _source ->
        attrs = stringify_keys(attrs)

        case Map.get(attrs, "idempotency_key_hash") do
          value when is_binary(value) and value != "" ->
            prepare_poll_with_idempotency(source_key, attrs, value)

          _missing ->
            record_poll_audit(source_key, attrs, "missing_key_denied", "missing_key_denied", "none")
            {:error, :missing_idempotency_key}
        end
    end
  end

  def record_poll_audit(source_key, attrs, result_status, idempotency_status, rate_limit_status)
      when is_binary(source_key) and is_map(attrs) and is_binary(result_status) and
             is_binary(idempotency_status) and is_binary(rate_limit_status) do
    attrs = stringify_keys(attrs)
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    try do
      Repo.insert_all(@poll_audit_table, [
        %{
          id: Ecto.UUID.generate() |> Ecto.UUID.dump!(),
          source_key: source_key,
          route_operation: "source_health:poll",
          result_status: result_status,
          idempotency_status: idempotency_status,
          rate_limit_status: rate_limit_status,
          actor_id_hash: bounded_hash(attrs["actor_id_hash"]),
          request_id_hash: bounded_hash(attrs["request_id_hash"]),
          idempotency_key_hash: bounded_hash(attrs["idempotency_key_hash"]),
          idempotency_key_id: nil,
          rate_limit_key_id: nil,
          reason_redacted: bounded_hash(attrs["reason_redacted"]),
          redaction_status: bounded_hash(attrs["redaction_status"]),
          occurred_at: now,
          metadata: %{},
          inserted_at: now,
          updated_at: now
        }
      ])

      :ok
    rescue
      _error -> :ok
    end
  end

  def record_poll_audit(_source_key, _attrs, _result_status, _idempotency_status, _rate_limit_status),
    do: :ok

  defp prepare_poll_with_idempotency(source_key, attrs, idempotency_key_hash) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    case active_poll_idempotency_record(source_key, idempotency_key_hash, now) do
      nil ->
        case check_and_record_rate_limits(source_key, attrs, now) do
          :ok -> accept_new_poll(source_key, attrs, idempotency_key_hash, now)
          {:error, status} ->
            record_poll_audit(source_key, attrs, "rate_limited", "none", status)
            {:error, {:rate_limited, status}}
        end

      _record ->
        record_poll_audit(source_key, attrs, "reused", "reused", "allowed")
        {:ok, reused_poll_response(source_key)}
    end
  end

  defp check_and_record_rate_limits(source_key, attrs, now) do
    window_start_at = DateTime.truncate(now, :second)
    window_expires_at = DateTime.add(window_start_at, @poll_rate_limit_window_seconds, :second)

    dimensions = rate_limit_dimensions(source_key, attrs)

    case Enum.find(dimensions, fn {scope, scope_key, limit_count, _status} ->
           current_request_count(scope, scope_key, window_start_at) >= limit_count
         end) do
      nil ->
        Enum.each(dimensions, fn {scope, scope_key, limit_count, _status} ->
          upsert_rate_limit_counter!(scope, scope_key, source_key, attrs, limit_count, window_start_at, window_expires_at)
        end)

        :ok

      {_scope, _scope_key, _limit_count, status} ->
        {:error, status}
    end
  end

  defp rate_limit_dimensions(source_key, attrs) do
    Enum.map(@rate_limits, fn
      {scope, :source_key, limit_count, status} ->
        {scope, source_key, limit_count, status}

      {scope, :actor_id_hash, limit_count, status} ->
        {scope, bounded_hash(attrs["actor_id_hash"]) || "unknown", limit_count, status}

      {scope, scope_key, limit_count, status} ->
        {scope, scope_key, limit_count, status}
    end)
  end

  defp current_request_count(scope, scope_key, window_start_at) do
    @poll_rate_limit_table
    |> where([record], field(record, :scope) == ^scope)
    |> where([record], field(record, :scope_key) == ^scope_key)
    |> where([record], field(record, :window_start_at) == ^window_start_at)
    |> select([record], field(record, :request_count))
    |> Repo.one()
    |> case do
      nil -> 0
      count -> count
    end
  end

  defp upsert_rate_limit_counter!(scope, scope_key, source_key, attrs, limit_count, window_start_at, window_expires_at) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    Repo.insert_all(
      @poll_rate_limit_table,
      [
        %{
          id: Ecto.UUID.generate() |> Ecto.UUID.dump!(),
          scope: scope,
          scope_key: scope_key,
          source_key: source_key,
          actor_id_hash: bounded_hash(attrs["actor_id_hash"]),
          status: "allowed",
          request_count: 1,
          limit_count: limit_count,
          window_start_at: window_start_at,
          window_expires_at: window_expires_at,
          metadata: %{},
          inserted_at: now,
          updated_at: now
        }
      ],
      on_conflict: [inc: [request_count: 1], set: [updated_at: now, status: "allowed"]],
      conflict_target: [:scope, :scope_key, :window_start_at]
    )
  end

  defp accept_new_poll(source_key, attrs, idempotency_key_hash, now) do
    expires_at = DateTime.add(now, @poll_idempotency_window_seconds, :second)

    Repo.insert_all(
      @poll_idempotency_table,
      [
        %{
          id: Ecto.UUID.generate() |> Ecto.UUID.dump!(),
          source_key: source_key,
          idempotency_key_hash: idempotency_key_hash,
          request_id_hash: bounded_hash(attrs["request_id_hash"]),
          actor_id_hash: bounded_hash(attrs["actor_id_hash"]),
          status: "accepted",
          rate_limit_status: "allowed",
          expires_at: expires_at,
          last_seen_at: now,
          metadata: %{},
          inserted_at: now,
          updated_at: now
        }
      ],
      on_conflict:
        {:replace,
         [
           :request_id_hash,
           :actor_id_hash,
           :status,
           :rate_limit_status,
           :expires_at,
           :last_seen_at,
           :metadata,
           :updated_at
         ]},
      conflict_target: [:source_key, :idempotency_key_hash]
    )

    record_poll_audit(source_key, attrs, "accepted", "accepted", "allowed")
    {:ok, accepted_poll_response(source_key)}
  end

  defp active_poll_idempotency_record(source_key, idempotency_key_hash, now) do
    @poll_idempotency_table
    |> where([record], field(record, :source_key) == ^source_key)
    |> where([record], field(record, :idempotency_key_hash) == ^idempotency_key_hash)
    |> where([record], field(record, :expires_at) > ^now)
    |> select([record], %{
      source_key: field(record, :source_key),
      idempotency_key_hash: field(record, :idempotency_key_hash),
      status: field(record, :status),
      rate_limit_status: field(record, :rate_limit_status)
    })
    |> Repo.one()
  end

  defp accepted_poll_response(source_key) do
    %{
      "source_key" => source_key,
      "poll_status" => "accepted",
      "idempotency_status" => "accepted",
      "rate_limit_status" => "allowed"
    }
  end

  defp reused_poll_response(source_key) do
    %{
      "source_key" => source_key,
      "poll_status" => "reused",
      "idempotency_status" => "reused",
      "rate_limit_status" => "allowed"
    }
  end

  defp bounded_hash(value) when is_binary(value), do: value
  defp bounded_hash(_value), do: nil

  defp stringify_keys(map) do
    Enum.into(map, %{}, fn {key, value} -> {to_string(key), value} end)
  end
end
