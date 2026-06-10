defmodule DisclosureAutomation.Config.Sync do
  @moduledoc """
  Runtime helpers that import the sample YAML contracts into the Phase 0 tables.
  """

  alias DisclosureAutomation.Config.YamlLoader
  alias DisclosureAutomation.Sources

  @default_sources_path Path.expand("../../../config/source_registry.sample.yaml", __DIR__)
  @default_windows_path Path.expand("../../../config/delivery_windows.sample.yaml", __DIR__)

  def default_sources_path, do: @default_sources_path
  def default_windows_path, do: @default_windows_path

  def sync_all(opts \\ []) do
    source_path = Keyword.get(opts, :sources_path, @default_sources_path)
    windows_path = Keyword.get(opts, :windows_path, @default_windows_path)

    with {:ok, source_result} <- sync_sources_from_file(source_path),
         {:ok, window_result} <- sync_delivery_windows_from_file(windows_path) do
      {:ok, %{sources: source_result, delivery_windows: window_result}}
    end
  end

  def sync_sources_from_file(path \\ @default_sources_path) do
    with {:ok, %{sources: sources}} <- YamlLoader.load_source_registry(path) do
      upsert_many(sources, &Sources.upsert_source/1, :sources)
    end
  end

  def sync_delivery_windows_from_file(path \\ @default_windows_path) do
    with {:ok, %{windows: windows}} <- YamlLoader.load_delivery_windows(path) do
      upsert_many(windows, &Sources.upsert_delivery_window/1, :delivery_windows)
    end
  end

  defp upsert_many(records, fun, label) do
    records
    |> Enum.reduce(%{ok: 0, errors: []}, fn attrs, acc ->
      case fun.(attrs) do
        {:ok, _record} -> %{acc | ok: acc.ok + 1}
        {:error, reason} -> %{acc | errors: [format_error(attrs, reason) | acc.errors]}
      end
    end)
    |> then(fn result ->
      {:ok,
       %{
         label: label,
         success_count: result.ok,
         error_count: length(result.errors),
         errors: Enum.reverse(result.errors)
       }}
    end)
  end

  defp format_error(attrs, reason) do
    %{
      key: Map.get(attrs, "source_key") || Map.get(attrs, "window_key") || "unknown",
      reason: inspect(reason)
    }
  end
end
