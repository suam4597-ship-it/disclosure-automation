defmodule DisclosureAutomationWeb.EventNewsOverlayController do
  @moduledoc false

  use DisclosureAutomationWeb, :controller

  alias DisclosureAutomation.Runtime.Stage5NewsOverlayReadModel

  def show(conn, %{"event_id" => event_id}) do
    case Stage5NewsOverlayReadModel.get_by_event_id(event_id) do
      {:ok, response} ->
        json(conn, json_safe(response))

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

  defp json_safe(%{} = map) do
    Map.new(map, fn {key, value} -> {json_key(key), json_safe(value)} end)
  end

  defp json_safe(values) when is_list(values), do: Enum.map(values, &json_safe/1)

  defp json_safe(value) when is_binary(value) do
    cond do
      String.valid?(value) ->
        value

      byte_size(value) == 16 ->
        case Ecto.UUID.load(value) do
          {:ok, uuid} -> uuid
          :error -> Base.encode16(value, case: :lower)
        end

      true ->
        Base.encode16(value, case: :lower)
    end
  end

  defp json_safe(value), do: value

  defp json_key(key) when is_atom(key), do: key
  defp json_key(key), do: key
end
