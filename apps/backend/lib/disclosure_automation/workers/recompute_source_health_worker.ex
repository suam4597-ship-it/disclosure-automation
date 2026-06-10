defmodule DisclosureAutomation.Workers.RecomputeSourceHealthWorker do
  @moduledoc false

  use Oban.Worker, queue: :health_checks, max_attempts: 5

  alias DisclosureAutomation.Sources

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"source_key" => source_key}}) do
    case Sources.recompute_source_health(source_key) do
      {:ok, _source} -> :ok
      {:error, :not_found} -> {:cancel, :source_not_found}
      {:error, reason} -> {:error, inspect(reason)}
    end
  end
end
