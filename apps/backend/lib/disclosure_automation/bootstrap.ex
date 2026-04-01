defmodule DisclosureAutomation.Bootstrap do
  @moduledoc false

  require Logger

  alias DisclosureAutomation.Config.Sync
  alias DisclosureAutomation.ParserCapabilities

  def bootstrap do
    if Application.get_env(:disclosure_automation, :bootstrap_reference_runtime?, true) do
      :ok = DisclosureAutomation.Store.ensure_started()
      maybe_sync_phase0_config()
      maybe_load_parser_capabilities()
    else
      :ok
    end
  end

  defp maybe_sync_phase0_config do
    case Sync.sync_all() do
      {:ok, _result} -> :ok
      {:error, reason} -> Logger.warning("phase0 config bootstrap skipped: #{inspect(reason)}")
    end
  end

  defp maybe_load_parser_capabilities do
    case ParserCapabilities.load() do
      {:ok, capabilities} ->
        Application.put_env(:disclosure_automation, :parser_capabilities_cache, capabilities)
        :ok

      {:error, reason} ->
        Logger.warning("parser capabilities bootstrap skipped: #{inspect(reason)}")
    end
  end
end
