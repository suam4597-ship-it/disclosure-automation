defmodule Phoenix.Controller do
  @moduledoc false

  def json(conn, body), do: %{conn | resp_body: body}
end
