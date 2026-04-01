defmodule DisclosureAutomation.Digest do
  @moduledoc """
  Fixture-backed digest reader for the Phase 0 reference runtime.
  """

  alias DisclosureAutomation.Fixtures

  def get_latest_digest(edition, opts \\ []) when is_binary(edition) do
    timezone = Keyword.get(opts, :timezone, "UTC")

    with {:ok, digest} <- load_digest(opts),
         :ok <- ensure_matching_edition(digest, edition) do
      {:ok, digest |> Map.put("edition", edition) |> Map.put("timezone", timezone)}
    end
  end

  def get_digest_by_date_and_edition(digest_date, edition, opts \\ [])
      when is_binary(digest_date) and is_binary(edition) do
    with {:ok, digest} <- load_digest(opts),
         :ok <- ensure_matching_edition(digest, edition),
         :ok <- ensure_matching_digest_date(digest, digest_date) do
      {:ok, digest}
    end
  end

  defp load_digest(opts) do
    if Keyword.get(opts, :fallback_to_fixture, false) do
      Fixtures.load_daily_digest()
    else
      Fixtures.load_daily_digest()
    end
  end

  defp ensure_matching_edition(%{"edition" => edition}, edition), do: :ok
  defp ensure_matching_edition(_digest, _edition), do: {:error, :not_found}

  defp ensure_matching_digest_date(%{"digest_date" => digest_date}, digest_date), do: :ok
  defp ensure_matching_digest_date(_digest, _digest_date), do: {:error, :not_found}
end
