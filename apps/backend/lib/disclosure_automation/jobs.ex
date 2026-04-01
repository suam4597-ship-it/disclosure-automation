defmodule DisclosureAutomation.Jobs do
  @moduledoc false

  def enqueue(worker_module, queue, args) when is_atom(worker_module) and is_map(args) do
    if Code.ensure_loaded?(Oban) and function_exported?(Oban, :insert, 1) do
      case Oban.insert(worker_module.new(args, queue: queue)) do
        {:ok, oban_job} ->
          {:ok, accepted_job(oban_job.queue, oban_job.worker, args)}

        {:error, reason} ->
          {:error, reason}
      end
    else
      {:ok, accepted_job(queue, inspect(worker_module), args)}
    end
  end

  def accepted_job(queue, worker, args) do
    %{
      status: "accepted",
      job: %{
        queue: to_string(queue),
        worker: worker,
        args: args
      }
    }
  end
end
