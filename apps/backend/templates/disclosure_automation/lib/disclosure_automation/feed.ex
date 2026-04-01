defmodule DisclosureAutomation.Feed do
  @moduledoc """
  Minimal Phase 1 feed context used by the API-only Phoenix bootstrap.

  This context reads the checked-in Phase 0 fixture so the generated Phoenix app
  can expose `/api/feed/daily` before the full canonical storage path is wired.
  """

  @fixture_path Application.compile_env(
                  :disclosure_automation,
                  :daily_feed_fixture_path,
                  Path.expand("../../priv/fixtures/daily_feed.sample.json", __DIR__)
                )

  def daily_digest do
    with {:ok, raw} <- File.read(@fixture_path),
         {:ok, decoded} <- Jason.decode(raw) do
      {:ok, decoded}
    end
  end
end
