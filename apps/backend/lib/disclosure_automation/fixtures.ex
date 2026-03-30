defmodule DisclosureAutomation.Fixtures do
  @moduledoc """
  Reads JSON fixtures used by the Phase 0 reference runtime.
  """

  @daily_digest_fixture Path.expand("../../fixtures/daily_feed.sample.json", __DIR__)

  def daily_digest_fixture_path, do: @daily_digest_fixture

  def load_daily_digest(opts \\ []) do
    path = Keyword.get(opts, :path, @daily_digest_fixture)

    with {:ok, raw} <- File.read(path),
         :ok <- ensure_json_decoder_available(),
         {:ok, decoded} <- Jason.decode(raw) do
      {:ok, decoded}
    else
      {:error, _reason} = error -> error
      other -> {:error, other}
    end
  end

  defp ensure_json_decoder_available do
    if Code.ensure_loaded?(Jason) and function_exported?(Jason, :decode, 1) do
      :ok
    else
      {:error, :json_decoder_unavailable}
    end
  end
end
