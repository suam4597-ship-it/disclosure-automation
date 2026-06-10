defmodule DisclosureAutomation.Events.Publisher do
  @moduledoc """
  Reference publisher that materializes pending dispatch records in memory.
  """

  alias DisclosureAutomation.Events
  alias DisclosureAutomation.Events.DomainEventDispatch

  def publish(event_name, aggregate_type, aggregate_id, payload, metadata, opts \\ []) do
    consumers = Keyword.get(opts, :consumers, [])
    domain_event_id = build_event_id(event_name, aggregate_type, aggregate_id)

    Enum.each(consumers, fn consumer_key ->
      dispatch = %DomainEventDispatch{
        id: domain_event_id <> ":" <> consumer_key,
        domain_event_id: domain_event_id,
        consumer_key: consumer_key,
        status: "pending",
        attempts: 0,
        last_attempt_at: nil,
        delivered_at: nil,
        last_error: nil,
        payload_snapshot: %{
          event_name: event_name,
          aggregate_type: aggregate_type,
          aggregate_id: aggregate_id,
          payload: payload,
          metadata: metadata
        }
      }

      _ = Events.put_dispatch(dispatch)
    end)

    {:ok,
     %{
       domain_event_id: domain_event_id,
       event_name: event_name,
       aggregate_type: aggregate_type,
       aggregate_id: aggregate_id,
       consumers: consumers,
       payload: payload,
       metadata: metadata
     }}
  end

  defp build_event_id(event_name, aggregate_type, aggregate_id) do
    Enum.join([event_name, aggregate_type, aggregate_id], ":")
  end
end
