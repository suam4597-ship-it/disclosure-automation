defmodule DisclosureAutomation.Workers.BuildFeedSnapshotWorker do
  @moduledoc false

  use Oban.Worker, queue: :feed, max_attempts: 5

  alias DisclosureAutomation.Feed

  @impl Oban.Worker
  def perform(job) do
    case job.args do
      %{"region_codes" => region_codes} = args when is_list(region_codes) ->
        ingestion_run_id = Map.get(args, "ingestion_run_id")

        case Feed.rebuild_snapshots(region_codes, ingestion_run_id: ingestion_run_id) do
          {:ok, _snapshots} -> :ok
          {:error, reason} -> {:error, inspect(reason)}
        end

      _ ->
        {:error, "invalid_args"}
    end
  end
end
