defmodule DisclosureAutomation.ParserCapabilities do
  @moduledoc """
  Loads and caches parser capability metadata for the Phase 0 runtime.
  """

  alias DisclosureAutomation.Config.YamlLoader

  @default_path Path.expand("../../config/parser_capabilities.sample.yaml", __DIR__)
  @cache_key :parser_capabilities_cache

  def default_path, do: @default_path

  def load(opts \\ []) do
    path = Keyword.get(opts, :path, @default_path)

    with {:ok, %{parsers: parsers} = payload} <- YamlLoader.load_parser_capabilities(path) do
      normalized =
        Enum.map(parsers, fn parser ->
          parser
          |> Map.put_new("enabled", true)
          |> Map.put_new("parser_key", "unknown")
        end)

      {:ok, Map.put(payload, :by_key, Map.new(normalized, &{Map.fetch!(&1, "parser_key"), &1}))}
    end
  end

  def get(parser_key, opts \\ []) when is_binary(parser_key) do
    capabilities =
      Keyword.get_lazy(opts, :cache, fn ->
        Application.get_env(:disclosure_automation, @cache_key, %{})
      end)

    case capabilities do
      %{by_key: by_key} when is_map(by_key) -> Map.fetch(by_key, parser_key)
      %{"by_key" => by_key} when is_map(by_key) -> Map.fetch(by_key, parser_key)
      _ -> :error
    end
  end
end
