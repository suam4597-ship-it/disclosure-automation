defmodule DisclosureAutomation.Workers.DispatchDomainEventWorker do
  @moduledoc false

  use Oban.Worker, queue: :event_dispatch, max_attempts: 10

  alias DisclosureAutomation.Events
  alias DisclosureAutomation.Events.DomainEventDispatch

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"domain_event_id" => domain_event_id, "consumer_key" => consumer_key}}) do
    case Events.get_dispatch_by_event_and_consumer(domain_event_id, consumer_key) do
      %DomainEventDispatch{} = dispatch ->
        case Events.mark_dispatch_status(dispatch, "dispatched", %{
               attempts: dispatch.attempts + 1,
               last_attempt_at: DateTime.utc_now(),
               delivered_at: DateTime.utc_now(),
               last_error: nil
             }) do
          {:ok, _updated} -> :ok
          {:error, reason} -> {:error, inspect(reason)}
        end

      nil ->
        {:cancel, :dispatch_not_found}
    end
  end
end
