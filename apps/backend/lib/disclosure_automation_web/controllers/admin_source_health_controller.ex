defmodule DisclosureAutomationWeb.AdminSourceHealthController do
  @moduledoc false

  import Plug.Conn

  alias DisclosureAutomation.Sources
  alias DisclosureAutomationWeb.SourceHealthJSON
  alias Phoenix.Controller

  def index(conn, params) do
    case Sources.list_source_health(params) do
      {:ok, page} -> Controller.json(conn, SourceHealthJSON.index(%{page: page}))
      {:error, reason} -> render_error(conn, :bad_request, "invalid_filter", inspect(reason))
    end
  end

  def show(conn, %{"sourceKey" => source_key}), do: show(conn, %{"source_key" => source_key})

  def show(conn, %{"source_key" => source_key}) do
    case Sources.get_source_health(source_key) do
      {:ok, %{data: source}} -> Controller.json(conn, SourceHealthJSON.show(%{source: source}))
      {:error, :not_found} -> render_error(conn, :not_found, "not_found", "source not found")
      {:error, reason} -> render_error(conn, :bad_request, "invalid_request", inspect(reason))
    end
  end

  def recheck(conn, %{"sourceKey" => source_key}), do: recheck(conn, %{"source_key" => source_key})

  def recheck(conn, %{"source_key" => source_key}) do
    case Sources.enqueue_source_health_recheck(source_key) do
      {:ok, job} ->
        conn
        |> put_status(:accepted)
        |> Controller.json(SourceHealthJSON.accepted_job(%{job: job}))

      {:error, :not_found} ->
        render_error(conn, :not_found, "not_found", "source not found")

      {:error, reason} ->
        render_error(conn, :bad_request, "enqueue_failed", inspect(reason))
    end
  end

  defp render_error(conn, status, code, message) do
    conn
    |> put_status(status)
    |> Controller.json(SourceHealthJSON.error(%{code: code, message: message}))
  end
end
