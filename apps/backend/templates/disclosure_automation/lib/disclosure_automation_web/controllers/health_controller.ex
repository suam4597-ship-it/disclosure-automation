defmodule DisclosureAutomationWeb.HealthController do
  use DisclosureAutomationWeb, :controller

  def show(conn, _params) do
    json(conn, %{
      status: "ok",
      service: "disclosure_automation",
      phase: "phase1-bootstrap"
    })
  end
end
