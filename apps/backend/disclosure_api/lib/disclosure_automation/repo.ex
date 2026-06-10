defmodule DisclosureAutomation.Repo do
  use Ecto.Repo,
    otp_app: :disclosure_automation,
    adapter: Ecto.Adapters.Postgres
end
