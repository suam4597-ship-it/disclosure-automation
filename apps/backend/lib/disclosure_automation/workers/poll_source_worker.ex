defmodule DisclosureAutomation.Workers.PollSourceWorker do
  @moduledoc false

  use Oban.Worker, queue: :source_polling, max_attempts: 5

  alias DisclosureAutomation.SourcePoller

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"source_key" => source_key} = args}) do
    trigger_kind = Map.get(args, "trigger_kind", "scheduled")

    case SourcePoller.poll_source(source_key, trigger_kind: trigger_kind) do
      {:ok, _result} -> :ok
      {:error, :source_not_found} -> {:cancel, :source_not_found}
      {:error, reason} -> {:error, inspect(reason)}
    end
  end
end
