defmodule DisclosureAutomation.MixProject do
  use Mix.Project

  def project do
    [
      app: :disclosure_automation,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: []
    ]
  end

  def application do
    [
      extra_applications: [:logger, :crypto, :inets, :ssl, :xmerl],
      mod: {DisclosureAutomation.Application, []}
    ]
  end

  defp aliases do
    [
      validate: ["test", &validate_phase0/1]
    ]
  end

  defp validate_phase0(_args) do
    root = Path.expand("../..", __DIR__)
    script = Path.join(root, "scripts/validate_phase0_artifacts.py")

    case System.cmd("python3", [script], cd: root, stderr_to_stdout: true) do
      {output, 0} ->
        Mix.shell().info(output)

      {output, status} ->
        Mix.raise("phase0 artifact validation failed (#{status})\n#{output}")
    end
  end
end
