defmodule DisclosureAutomation.Ops.SECSC14D9Source do
  @moduledoc false

  alias DisclosureAutomation.Support.YamlLoader

  @sample_path "../../../priv/config_samples/source_registry.sec_current_forms_sc_14d_9.sample.yaml"

  def attrs do
    case load_attrs() do
      {:ok, attrs} -> attrs
      {:error, reason} -> raise "unable to load SEC SC 14D-9 source sample: #{inspect(reason)}"
    end
  end

  def load_attrs do
    with {:ok, %{"sources" => [source | _]}} <- YamlLoader.load_source_registry(sample_path()) do
      {:ok, source}
    else
      {:ok, %{"sources" => []}} -> {:error, :no_sources}
      {:error, reason} -> {:error, reason}
      other -> {:error, other}
    end
  end

  def sample_path, do: Path.expand(@sample_path, __DIR__)
end
