defmodule Plug.Conn do
  @moduledoc false

  defstruct method: nil,
            request_path: nil,
            params: %{},
            status: nil,
            resp_body: nil

  def put_status(%__MODULE__{} = conn, status), do: %{conn | status: normalize_status(status)}

  defp normalize_status(status) when is_integer(status), do: status
  defp normalize_status(:ok), do: 200
  defp normalize_status(:accepted), do: 202
  defp normalize_status(:bad_request), do: 400
  defp normalize_status(:not_found), do: 404
  defp normalize_status(:internal_server_error), do: 500
  defp normalize_status(other), do: other
end
