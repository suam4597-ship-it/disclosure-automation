defmodule DisclosureAutomation.SourceHealthPollRuntime do
  @moduledoc false

  import Ecto.Query

  alias DisclosureAutomation.Repo
  alias DisclosureAutomation.Schema.SourceRegistry

  @poll_idempotency_table "source_health_poll_idempotency_keys"
  @poll_idempotency_window_seconds 15 * 60

  def prepare_poll(source_key, attrs \\ %{}) when is_binary(source_key) and is_map(attrs) do
    case Repo.get_by(SourceRegistry, source_key: source_key) do
      nil ->
        {:error, :not_found}

      _source ->
        attrs = stringify_keys(attrs)

        case Map.get(attrs, "idempotency_key_hash") do
          value when is_binary(value) and value != "" ->
            prepare_poll_with_idempotency(source_key, attrs, value)

          _missing ->
            {:error, :missing_idempotency_key}
        end
    end
  end

  defp prepare_poll_with_idempotency(source_key, attrs, idempotency_key_hash) do
    now = DateTime.utc_now() |> DateTime.truncate(:microsecond)

    case active_poll_idempotency_record(source_key, idempotency_key_hash, now) do
      nil ->
        accept_new_poll(source_key, attrs, idempotency_key_hash, now)

      _record ->
        {:ok, reused_poll_response(source_key)}
    end
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
