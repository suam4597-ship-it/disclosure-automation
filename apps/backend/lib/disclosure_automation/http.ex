defmodule DisclosureAutomation.Http do
  @moduledoc """
  Minimal HTTP helper for the Phase 0 reference runtime.

  The default runtime path remains fixture-first. This helper exists so the
  poller can optionally attempt a real fetch when explicitly requested.
  """

  @default_headers [{'user-agent', 'disclosure-automation-phase0'}]

  def fetch(url, opts \\ []) when is_binary(url) do
    timeout = Keyword.get(opts, :timeout, 8_000)
    headers = Keyword.get(opts, :headers, @default_headers)
    request = {String.to_charlist(url), headers}
    http_opts = [timeout: timeout, connect_timeout: timeout, ssl: [verify: :verify_none]]
    request_opts = [body_format: :binary]

    case :httpc.request(:get, request, http_opts, request_opts) do
      {:ok, {{_http_version, status_code, _reason_phrase}, response_headers, body}} ->
        {:ok,
         %{
           status_code: status_code,
           headers: normalize_headers(response_headers),
           body: body,
           bytes: byte_size(body)
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp normalize_headers(headers) do
    Enum.map(headers, fn {key, value} ->
      {to_string(key), to_string(value)}
    end)
  end
end
