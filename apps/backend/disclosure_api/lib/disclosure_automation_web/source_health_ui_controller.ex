defmodule DisclosureAutomationWeb.AdminSourceHealthUiController do
  @moduledoc false

  use DisclosureAutomationWeb, :controller

  def index(conn, _params) do
    text(conn, "Source health")
  end

  def show(conn, %{"source_key" => source_key}) do
    text(conn, "Source health: #{source_key}")
  end
end
