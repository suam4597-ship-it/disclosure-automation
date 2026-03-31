defmodule DisclosureAutomation.Store do
  @moduledoc """
  Minimal in-memory store used by the Phase 0 reference runtime.

  The goal is not durable persistence. The goal is to let bootstrap/config sync
  and fixture-backed reads operate behind a stable module boundary until the
  full Phoenix/Ecto runtime is generated and wired.
  """

  use Agent

  @initial_state %{
    sources: %{},
    delivery_windows: %{},
    domain_event_dispatches: %{}
  }

  def ensure_started do
    case start_link([]) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
      other -> other
    end
  end

  def start_link(_opts) do
    Agent.start_link(fn -> @initial_state end, name: __MODULE__)
  end

  def put(bucket, key, value) when is_atom(bucket) do
    Agent.update(__MODULE__, fn state -> update_in(state[bucket], &Map.put(&1, key, value)) end)
    {:ok, value}
  end

  def get(bucket, key) when is_atom(bucket) do
    Agent.get(__MODULE__, fn state -> get_in(state, [bucket, key]) end)
  end

  def list(bucket) when is_atom(bucket) do
    Agent.get(__MODULE__, fn state -> state |> Map.get(bucket, %{}) |> Map.values() end)
  end
end
