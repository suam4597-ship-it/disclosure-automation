defmodule DisclosureAutomationWeb.CORS do
  @moduledoc false

  import Plug.Conn

  @allowed_methods "GET,POST,OPTIONS"
  @allowed_headers "accept,content-type"

  def init(opts), do: opts

  def call(conn, _opts) do
    origin = conn |> get_req_header("origin") |> List.first()

    if allowed_origin?(origin) do
      conn
      |> put_resp_header("access-control-allow-origin", origin)
      |> put_resp_header("access-control-allow-methods", @allowed_methods)
      |> put_resp_header("access-control-allow-headers", @allowed_headers)
      |> maybe_preflight()
    else
      conn
    end
  end

  defp maybe_preflight(%Plug.Conn{method: "OPTIONS"} = conn) do
    conn
    |> send_resp(204, "")
    |> halt()
  end

  defp maybe_preflight(conn), do: conn

  defp allowed_origin?(nil), do: false

  defp allowed_origin?(origin) do
    allowed_origins()
    |> Enum.any?(&(&1 == "*" or &1 == origin))
  end

  defp allowed_origins do
    "CORS_ALLOWED_ORIGINS"
    |> System.get_env("")
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
  end
end
