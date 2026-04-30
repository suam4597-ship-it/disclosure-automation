defmodule DisclosureAutomation.Ops.JPTDnetTimelyDisclosureSource do
  @moduledoc false

  alias DisclosureAutomation.Support.YamlLoader

  @sample_path "../../../priv/config_samples/source_registry.jp_tdnet_timely_disclosure.sample.yaml"

  def attrs do
    case load_attrs() do
      {:ok, attrs} -> attrs
      {:error, reason} -> raise "unable to load JP TDnet timely disclosure source sample: #{inspect(reason)}"
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
