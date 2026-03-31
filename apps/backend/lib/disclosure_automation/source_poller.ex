defmodule DisclosureAutomation.SourcePoller do
  @moduledoc """
  Phase 0 polling facade.

  The runtime is intentionally fixture-friendly:
  - source metadata comes from `Sources`
  - parser capabilities are consulted when available
  - source fixture payloads can be loaded from the checked-in sample assets
  - the returned map is shaped so future ingestion persistence can slot in
    without changing worker/controller contracts
  """

  alias DisclosureAutomation.Fixtures
  alias DisclosureAutomation.Parser
  alias DisclosureAutomation.ParserCapabilities
  alias DisclosureAutomation.Sources

  def poll_source(source_key, opts \\ []) when is_binary(source_key) do
    trigger_kind = Keyword.get(opts, :trigger_kind, "scheduled")

    with {:ok, source} <- fetch_source(source_key),
         :ok <- ensure_parser_known(source),
         {:ok, parse_input, fixture_info} <- load_parse_input(source, opts),
         {:ok, parse_result} <-
           Parser.parse(source["parser_key"] || source[:parser_key], parse_input, cache: parser_cache()) do
      {:ok,
       %{
         source_key: source_key,
         trigger_kind: trigger_kind,
         status: "accepted",
         parser_key: source["parser_key"] || source[:parser_key],
         request_url: source["base_url"] || source[:base_url],
         polled_at: DateTime.utc_now(),
         fixture: fixture_info,
         parse_result: parse_result
       }}
    end
  end

  defp fetch_source(source_key) do
    cond do
      function_exported?(Sources, :get_source_by_key, 1) ->
        case Sources.get_source_by_key(source_key) do
          nil -> {:error, :source_not_found}
          {:ok, source} -> {:ok, source}
          source -> {:ok, source}
        end

      function_exported?(Sources, :get_source_health, 1) ->
        case Sources.get_source_health(source_key) do
          {:ok, %{data: source}} -> {:ok, source}
          {:error, :not_found} -> {:error, :source_not_found}
          other -> other
        end

      true ->
        {:error, :source_lookup_unavailable}
    end
  end

  defp ensure_parser_known(source) do
    parser_key = source["parser_key"] || source[:parser_key]

    case ParserCapabilities.get(parser_key, cache: parser_cache()) do
      {:ok, _capability} -> :ok
      :error -> {:error, {:unknown_parser_key, parser_key}}
    end
  end

  defp load_parse_input(source, opts) do
    fixture_override = Keyword.get(opts, :fixture_path)
    fixture_path = fixture_override || source_fixture_path(source)

    if is_binary(fixture_path) and fixture_path != "" do
      with {:ok, payload} <- Fixtures.load_source_payload(fixture_path) do
        parse_input = [build_fixture_record(source, payload)]

        {:ok,
         parse_input,
         %{
           relative_path: payload.relative_path,
           path: payload.path,
           bytes: payload.bytes,
           loaded: true
         }}
      end
    else
      {:ok, [], %{loaded: false}}
    end
  end

  defp source_fixture_path(source) do
    config = source["config"] || source[:config] || %{}
    config["fixture_path"] || config[:fixture_path]
  end

  defp build_fixture_record(source, payload) do
    %{
      source_key: source["source_key"] || source[:source_key],
      parser_key: source["parser_key"] || source[:parser_key],
      fixture_path: payload.relative_path,
      raw_payload: payload.raw,
      bytes: payload.bytes
    }
  end

  defp parser_cache do
    Application.get_env(:disclosure_automation, :parser_capabilities_cache, %{})
  end
end
