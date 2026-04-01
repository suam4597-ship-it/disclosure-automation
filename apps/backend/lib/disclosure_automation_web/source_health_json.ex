defmodule DisclosureAutomationWeb.SourceHealthJSON do
  @moduledoc false

  def index(%{page: page}), do: page
  def show(%{source: source}), do: %{data: source}
  def accepted_job(%{job: job}), do: job

  def error(%{code: code, message: message}) do
    %{
      error: %{
        code: code,
        message: message
      }
    }
  end
end
