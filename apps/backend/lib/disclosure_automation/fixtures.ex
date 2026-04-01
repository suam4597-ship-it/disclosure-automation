defmodule DisclosureAutomation.Fixtures do
  @moduledoc """
  Reads fixture assets used by the Phase 0 reference runtime.
  """

  @daily_digest_fixture Path.expand("../../fixtures/daily_feed.sample.json", __DIR__)
  @source_payload_root Path.expand("../../fixtures/source_payloads", __DIR__)

  def daily_digest_fixture_path, do: @daily_digest_fixture
  def source_payload_root, do: @source_payload_root

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

  def resolve_source_payload_path(relative_path) when is_binary(relative_path) do
    Path.expand(relative_path, @source_payload_root)
  end

  def load_source_payload(relative_path) when is_binary(relative_path) do
    path = resolve_source_payload_path(relative_path)

    with {:ok, raw} <- File.read(path) do
      {:ok,
       %{
         relative_path: relative_path,
         path: path,
         raw: raw,
         bytes: byte_size(raw)
       }}
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
