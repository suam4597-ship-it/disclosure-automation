defmodule DisclosureAutomation.Bootstrap do
  @moduledoc false

  require Logger

  alias DisclosureAutomation.ParserCapabilities
  alias DisclosureAutomation.Sources
  alias DisclosureAutomation.Support.YamlLoader

  def bootstrap do
    with :ok <- sync_sources(),
         :ok <- sync_delivery_windows(),
         {:ok, capabilities} <- ParserCapabilities.load() do
      Application.put_env(:disclosure_automation, :parser_capabilities_cache, capabilities)
      :ok
    else
      {:error, reason} ->
        Logger.warning("phase1 bootstrap incomplete: #{inspect(reason)}")
        :ok
    end
  end

  defp sync_sources do
    path = Application.fetch_env!(:disclosure_automation, :source_registry_path)

    with {:ok, %{"sources" => sources}} <- YamlLoader.load_source_registry(path) do
      Enum.each(sources, &Sources.upsert_source/1)
      :ok
    end
  end

  defp sync_delivery_windows do
    path = Application.fetch_env!(:disclosure_automation, :delivery_windows_path)

    with {:ok, %{"windows" => windows}} <- YamlLoader.load_delivery_windows(path) do
      Enum.each(windows, &Sources.upsert_delivery_window/1)
      :ok
    end
  end
end
