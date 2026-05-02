defmodule DisclosureAutomation.Runtime.Stage55OfflineProviderHealthEvaluator do
  @moduledoc false

  alias DisclosureAutomation.Runtime.Stage55ProviderHealthState

  def evaluate(attrs, opts \\ [])

  def evaluate(attrs, opts) when is_map(attrs) do
    case Stage55ProviderHealthState.normalize(attrs, opts) do
      {:ok, normalized} ->
        {:ok,
         normalized
         |> Map.put(:status, status_for(attrs, normalized))
         |> Map.put(:evaluation_mode, "offline_provider_health_evaluator")}

      {:error, {:redaction_violation, path}} ->
        {:ok,
         path
         |> Stage55ProviderHealthState.redaction_violation()
         |> Map.put(:evaluation_mode, "offline_provider_health_evaluator")}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def evaluate(_attrs, _opts), do: {:error, :invalid_provider_health_attrs}

  defp status_for(attrs, normalized) do
    cond do
      paused?(attrs, normalized) ->
        "paused"

      manual_review_required?(attrs) ->
        "manual_review_required"

      truthy?(get_value(attrs, "timeout")) or truthy?(get_value(diagnostics(attrs), "timeout")) ->
        "timeout"

      rate_limited?(attrs) ->
        "rate_limited"

      present?(get_value(attrs, "error_class")) or present?(get_value(diagnostics(attrs), "error_class")) ->
        "failed"

      partial_metadata?(attrs) ->
        "degraded"

      success?(attrs) or normalized.status == "healthy" ->
        "healthy"

      normalized.status in Stage55ProviderHealthState.allowed_states() and normalized.status != "unknown" ->
        normalized.status

      true ->
        Stage55ProviderHealthState.default_state()
    end
  end

  defp paused?(attrs, normalized) do
    truthy?(get_value(attrs, "paused")) or
      truthy?(get_value(diagnostics(attrs), "paused")) or
      normalized.status == "paused"
  end

  defp manual_review_required?(attrs) do
    truthy?(get_value(attrs, "manual_review_required")) or
      truthy?(get_value(diagnostics(attrs), "manual_review_required")) or
      get_value(attrs, "match_status") in ["ambiguous", "missing", "conflict"] or
      get_value(diagnostics(attrs), "match_status") in ["ambiguous", "missing", "conflict"] or
      get_value(diagnostics(attrs), "manual_review_reason") in ["ambiguous_match", "missing_match", "conflict"]
  end

  defp rate_limited?(attrs) do
    get_value(attrs, "status_code") in [429, "429"] or
      get_value(diagnostics(attrs), "status_code") in [429, "429"] or
      get_value(attrs, "error_class") == "rate_limited" or
      get_value(diagnostics(attrs), "error_class") == "rate_limited"
  end

  defp partial_metadata?(attrs) do
    truthy?(get_value(attrs, "partial_metadata")) or
      truthy?(get_value(diagnostics(attrs), "partial_metadata")) or
      get_value(attrs, "metadata_quality") in ["partial", "stale"] or
      get_value(diagnostics(attrs), "metadata_quality") in ["partial", "stale"] or
      get_value(diagnostics(attrs), "manual_review_reason") == "partial_metadata"
  end

  defp success?(attrs) do
    get_value(attrs, "status_code") in [200, "200", 204, "204"] or
      get_value(diagnostics(attrs), "status_code") in [200, "200", 204, "204"] or
      get_value(attrs, "result") == "success" or
      get_value(diagnostics(attrs), "result") == "success" or
      get_value(attrs, "status") == "healthy"
  end

  defp diagnostics(attrs), do: get_value(attrs, "diagnostics", %{}) || %{}

  defp get_value(map, key, default \\ nil)

  defp get_value(map, key, default) when is_map(map) do
    Map.get(map, key) || Map.get(map, String.to_atom(key)) || default
  end

  defp get_value(_value, _key, default), do: default

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(nil), do: false
  defp present?(_value), do: true

  defp truthy?(value), do: value in [true, "true", "yes", "1", 1]
end
