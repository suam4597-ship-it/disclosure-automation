defmodule DisclosureAutomationWeb.FeedJSON do
  @moduledoc false

  def show(%{payload: payload}), do: payload

  def error(%{code: code, message: message}) do
    %{error: %{code: code, message: message}}
  end
end

defmodule DisclosureAutomationWeb.FeedController do
  use DisclosureAutomationWeb, :controller

  alias DisclosureAutomation.Feed
  alias DisclosureAutomationWeb.FeedJSON

  def hero(conn, _params) do
    case Feed.get_hero() do
      {:ok, payload} -> json(conn, FeedJSON.show(%{payload: payload}))
      {:error, :not_found} -> render_error(conn, :not_found, "not_found", "feed slot not found")
      {:error, reason} -> render_error(conn, :bad_request, "invalid_request", inspect(reason))
    end
  end

  def region(conn, %{"region_code" => region_code}) do
    case Feed.get_region(region_code) do
      {:ok, payload} -> json(conn, FeedJSON.show(%{payload: payload}))
      {:error, :not_found} -> render_error(conn, :not_found, "not_found", "feed slot not found")
      {:error, reason} -> render_error(conn, :bad_request, "invalid_request", inspect(reason))
    end
  end

  defp render_error(conn, status, code, message) do
    conn
    |> put_status(status)
    |> json(FeedJSON.error(%{code: code, message: message}))
  end
end

defmodule DisclosureAutomationWeb.EventController do
  use DisclosureAutomationWeb, :controller

  alias DisclosureAutomation.Feed
  alias DisclosureAutomationWeb.FeedJSON

  def show(conn, %{"event_id" => event_id}) do
    case Feed.get_event(event_id) do
      {:ok, payload} -> json(conn, FeedJSON.show(%{payload: payload}))
      {:error, :not_found} -> render_error(conn, :not_found, "not_found", "event not found")
      {:error, reason} -> render_error(conn, :bad_request, "invalid_request", inspect(reason))
    end
  end

  defp render_error(conn, status, code, message) do
    conn
    |> put_status(status)
    |> json(FeedJSON.error(%{code: code, message: message}))
  end
end
