defmodule DisclosureAutomation.EnvInterpolation do
  @moduledoc """
  Resolves `${VAR}` and `${VAR:-fallback}` expressions in maps, lists, and
  strings.
  """

  @pattern ~r/\$\{(?<name>[A-Z0-9_]+)(:-(?<default>[^}]*))?\}/

  def resolve(value, env \\ System.get_env())
  def resolve(%{} = map, env), do: map |> Enum.map(fn {k, v} -> {k, resolve(v, env)} end) |> Enum.into(%{})
  def resolve(list, env) when is_list(list), do: Enum.map(list, &resolve(&1, env))

  def resolve(value, env) when is_binary(value) do
    Regex.replace(@pattern, value, fn _full, name, _fallback_group, default ->
      Map.get(env, name, default || "")
    end)
  end

  def resolve(value, _env), do: value
end
