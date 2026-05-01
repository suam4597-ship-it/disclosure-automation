defmodule DisclosureAutomationWeb.EventNewsOverlayController do
  @moduledoc false

  use DisclosureAutomationWeb, :controller

  alias DisclosureAutomation.Runtime.Stage5NewsOverlayReadModel

  def show(conn, %{"event_id" => event_id}) do
    case Stage5NewsOverlayReadModel.get_by_event_id(event_id) do
      {:ok, response} ->
        json(conn, response)

      {:error, :official_canonical_item_not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: %{code: "official_event_not_found", message: "Official event was not found."}})

      {:error, _reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: %{code: "news_overlay_read_model_error", message: "Unable to load news overlay read model."}})
    end
  end
end
