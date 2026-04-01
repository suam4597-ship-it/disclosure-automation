defmodule DisclosureAutomation.Parser do
  @moduledoc """
  Minimal parser contract used by the Phase 0 poller.

  This module does not attempt to fully parse RSS/HTML/API payloads yet.
  Instead it returns a normalized parser execution envelope so the bootstrap
  and documentation remain aligned while richer parsing logic is added later.
  """

  alias DisclosureAutomation.ParserCapabilities

  def parse(parser_key, payload, opts \\ []) when is_binary(parser_key) do
    case ParserCapabilities.get(parser_key, opts) do
      {:ok, capability} ->
        {:ok,
         %{
           parser_key: parser_key,
           status: "accepted",
           capability: capability,
           records: List.wrap(payload),
           record_count: payload |> List.wrap() |> length()
         }}

      :error ->
        {:error, {:unknown_parser_key, parser_key}}
    end
  end
end
