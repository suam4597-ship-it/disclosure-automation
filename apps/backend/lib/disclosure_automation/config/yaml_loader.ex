defmodule DisclosureAutomation.Config.YamlLoader do
  @moduledoc """
  Small Phase 0 YAML loader for sample contracts.

  The loader intentionally keeps validation conservative:
  - parse the sample YAML files when YamlElixir is available
  - interpolate `${VAR}` placeholders before the result is consumed
  - ensure the top-level collection keys expected by the runtime exist

  This keeps bootstrap behaviour deterministic without forcing the rest of the
  app to depend on a full schema-validation framework yet.
  """

  alias DisclosureAutomation.EnvInterpolation

  @type load_result :: {:ok, map()} | {:error, term()}

  def load_source_registry(path), do: load_yaml_file(path, :source_registry, "sources")
  def load_delivery_windows(path), do: load_yaml_file(path, :delivery_windows, "windows")
  def load_parser_capabilities(path), do: load_yaml_file(path, :parser_capabilities, "parsers")

  def load_yaml_file(path, contract_name, collection_key) do
    with :ok <- ensure_loader_available(),
         {:ok, raw} <- File.read(path),
         {:ok, parsed} <- YamlElixir.read_from_string(raw),
         resolved <- EnvInterpolation.resolve(parsed),
         :ok <- ensure_collection_key(resolved, collection_key) do
      {:ok, Map.put(resolved, "_contract", contract_name)}
    else
      {:error, _reason} = error -> error
      {:yaml_error, reason} -> {:error, {:invalid_yaml, reason}}
      other -> {:error, other}
    end
  end

  defp ensure_loader_available do
    if Code.ensure_loaded?(YamlElixir) and function_exported?(YamlElixir, :read_from_string, 1) do
      :ok
    else
      {:error, :yaml_loader_unavailable}
    end
  end

  defp ensure_collection_key(%{} = parsed, key) do
    case Map.fetch(parsed, key) do
      {:ok, value} when is_list(value) -> :ok
      {:ok, _value} -> {:error, {:invalid_contract_shape, key}}
      :error -> {:error, {:missing_collection_key, key}}
    end
  end

  defp ensure_collection_key(_parsed, key), do: {:error, {:invalid_contract_shape, key}}
end
