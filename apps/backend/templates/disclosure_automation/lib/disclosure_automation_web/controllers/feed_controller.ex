defmodule DisclosureAutomationWeb.FeedController do
  use DisclosureAutomationWeb, :controller

  alias DisclosureAutomation.Feed

  def daily(conn, _params) do
    case Feed.daily_digest() do
      {:ok, digest} -> json(conn, digest)
      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: %{code: "fixture_read_failed", message: inspect(reason)}})
    end
  end
end
