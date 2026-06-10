defmodule DisclosureAutomation.Events.DomainEventDispatch do
  @moduledoc false

  @enforce_keys [:domain_event_id, :consumer_key]
  defstruct [
    :id,
    :domain_event_id,
    :consumer_key,
    :status,
    :attempts,
    :last_attempt_at,
    :delivered_at,
    :last_error,
    :payload_snapshot
  ]
end
