defmodule DisclosureAutomation.Events do
  @moduledoc """
  In-memory domain-event dispatch boundary for the Phase 0 reference runtime.
  """

  alias DisclosureAutomation.Events.DomainEventDispatch
  alias DisclosureAutomation.Store

  def put_dispatch(%DomainEventDispatch{} = dispatch) do
    key = dispatch_key(dispatch.domain_event_id, dispatch.consumer_key)
    Store.put(:domain_event_dispatches, key, dispatch)
  end

  def get_dispatch_by_event_and_consumer(domain_event_id, consumer_key)
      when is_binary(domain_event_id) and is_binary(consumer_key) do
    Store.get(:domain_event_dispatches, dispatch_key(domain_event_id, consumer_key))
  end

  def mark_dispatch_status(%DomainEventDispatch{} = dispatch, status, attrs \\ %{}) when is_binary(status) do
    updated =
      dispatch
      |> Map.from_struct()
      |> Map.merge(normalize_attrs(attrs))
      |> Map.put(:status, status)
      |> then(&struct(DomainEventDispatch, &1))

    put_dispatch(updated)
  end

  defp dispatch_key(domain_event_id, consumer_key), do: domain_event_id <> ":" <> consumer_key

  defp normalize_attrs(attrs) do
    attrs
    |> Enum.map(fn {k, v} -> {normalize_key(k), v} end)
    |> Enum.into(%{})
  end

  defp normalize_key(key) when is_atom(key), do: key
  defp normalize_key(key) when is_binary(key), do: String.to_existing_atom(key)
end
