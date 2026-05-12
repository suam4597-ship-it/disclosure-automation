defmodule DisclosureAutomationWeb.FeedDigestController do
  @moduledoc false

  import Plug.Conn

  alias DisclosureAutomation.Digest
  alias DisclosureAutomationWeb.FeedDigestJSON
  alias Phoenix.Controller

  def latest(conn, %{"edition" => edition} = params) do
    timezone = Map.get(params, "timezone", "UTC")

    case Digest.get_latest_digest(edition, timezone: timezone, fallback_to_fixture: true) do
      {:ok, digest} -> Controller.json(conn, FeedDigestJSON.show(%{digest: digest}))
      {:error, :not_found} -> render_error(conn, :not_found, "not_found", "digest not found")
      {:error, reason} -> render_error(conn, :bad_request, "invalid_request", inspect(reason))
    end
  end

  def latest(conn, _params), do: render_error(conn, :bad_request, "missing_edition", "edition is required")

  def show(conn, %{"digestDate" => digest_date, "edition" => edition}),
    do: show(conn, %{"digest_date" => digest_date, "edition" => edition})

  def show(conn, %{"digest_date" => digest_date, "edition" => edition}) do
    case Digest.get_digest_by_date_and_edition(digest_date, edition, fallback_to_fixture: true) do
      {:ok, digest} -> Controller.json(conn, FeedDigestJSON.show(%{digest: digest}))
      {:error, :not_found} -> render_error(conn, :not_found, "not_found", "digest not found")
      {:error, reason} -> render_error(conn, :bad_request, "invalid_request", inspect(reason))
    end
  end

  defp render_error(conn, status, code, message) do
    conn
    |> put_status(status)
    |> Controller.json(FeedDigestJSON.error(%{code: code, message: message}))
  end
end
