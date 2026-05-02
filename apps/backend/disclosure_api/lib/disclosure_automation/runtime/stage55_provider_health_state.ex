defmodule DisclosureAutomation.Runtime.Stage55ProviderHealthState do
  @moduledoc false

  @allowed_states ~w(
    unknown
    healthy
    degraded
    rate_limited
    timeout
    failed
    paused
    redaction_violation
    manual_review_required
  )

  @diagnostic_allowlist ~w(
    provider
    source_key
    status
    status_code
    retry_count
    timeout
    error_class
    last_checked_at
    last_success_at
    last_failure_at
    request_id_hash
    redaction_status
    manual_review_reason
  )

  @safe_default_state "unknown"

  @prohibited_key_fragments [
    "articlebody",
    "fulltext",
    "rawhtml",
    "providerresponsebody",
    "scrapedtext",
    "paywalledarticletext",
    "requestheaders",
    "responseheaders",
    "headers",
    "credentials",
    "apikey",
    "api_key",
    "authorization",
    "cookie",
    "subscriptionkey",
    "subscription-key",
    "bearertoken",
    "bearer_token",
    "signedprivateurl",
    "signed_private_url",
    "rawresponsebody",
    "fullarticletext"
  ]

  def allowed_states, do: @allowed_states
  def diagnostic_allowlist, do: @diagnostic_allowlist
  def default_state, do: @safe_default_state

  def defaults do
    %{
      status: @safe_default_state,
      advisory_only: true,
      use_live_fetch: false,
      scheduler_enabled: false,
      canonical_feed_mutation: false,
      news_only_event_creation: false,
      canonical_fact_override: false
    }
  end

  def normalize(attrs, opts \\ [])

  def normalize(attrs, opts) when is_map(attrs) do
    with :ok <- live_fetch_disabled(opts),
         :ok <- scheduler_disabled(opts),
         :ok <- reject_prohibited_fields(attrs),
         {:ok, status} <- normalize_status(get_value(attrs, "status", @safe_default_state)),
         {:ok, diagnostics} <- normalize_diagnostics(attrs) do
      {:ok,
       Map.merge(defaults(), %{
         status: status,
         provider: get_value(attrs, "provider"),
         source_key: get_value(attrs, "source_key"),
         diagnostics: diagnostics
       })}
    end
  end

  def normalize(_attrs, _opts), do: {:error, :invalid_provider_health_attrs}

  def redaction_violation(path) when is_binary(path) do
    %{
      status: "redaction_violation",
      advisory_only: true,
      use_live_fetch: false,
      scheduler_enabled: false,
      canonical_feed_mutation: false,
      news_only_event_creation: false,
      canonical_fact_override: false,
      diagnostics: %{
        redaction_status: "failed",
        manual_review_reason: "redaction_violation",
        violation_path: path
      }
    }
  end

  defp live_fetch_disabled(opts) do
    if Keyword.get(opts, :use_live_fetch, false) do
      {:error, :live_fetch_not_allowed_in_stage55_health_state}
    else
      :ok
    end
  end

  defp scheduler_disabled(opts) do
    if Keyword.get(opts, :scheduler_enabled, false) do
      {:error, :scheduler_not_allowed_in_stage55_health_state}
    else
      :ok
    end
  end

  defp normalize_status(nil), do: {:ok, @safe_default_state}

  defp normalize_status(status) when is_binary(status) do
    normalized = String.trim(status)

    if normalized in @allowed_states do
      {:ok, normalized}
    else
      {:error, {:invalid_provider_health_state, status}}
    end
  end

  defp normalize_status(status), do: {:error, {:invalid_provider_health_state, status}}

  defp normalize_diagnostics(attrs) do
    diagnostics = get_value(attrs, "diagnostics", attrs)

    with :ok <- reject_prohibited_fields(diagnostics) do
      {:ok,
       diagnostics
       |> to_string_key_map()
       |> Enum.filter(fn {key, value} -> key in @diagnostic_allowlist and safe_diagnostic_value?(value) end)
       |> Map.new(fn {key, value} -> {String.to_atom(key), value} end)}
    end
  end

  defp reject_prohibited_fields(value) do
    case find_prohibited_field(value) do
      nil -> :ok
      path -> {:error, {:redaction_violation, path}}
    end
  end

  defp find_prohibited_field(value, path \\ "")

  defp find_prohibited_field(%{} = map, path) do
    Enum.find_value(map, fn {key, value} ->
      key_string = to_string(key)
      current_path = if path == "", do: key_string, else: "#{path}.#{key_string}"

      cond do
        prohibited_key?(key_string) -> current_path
        true -> find_prohibited_field(value, current_path)
      end
    end)
  end

  defp find_prohibited_field(values, path) when is_list(values) do
    values
    |> Enum.with_index()
    |> Enum.find_value(fn {value, index} -> find_prohibited_field(value, "#{path}[#{index}]") end)
  end

  defp find_prohibited_field(value, path) when is_binary(value) do
    if prohibited_value?(value), do: path, else: nil
  end

  defp find_prohibited_field(_value, _path), do: nil

  defp prohibited_key?(key) do
    normalized = normalize_token(key)

    Enum.any?(@prohibited_key_fragments, fn fragment ->
      String.contains?(normalized, normalize_token(fragment))
    end)
  end

  defp prohibited_value?(value) do
    String.contains?(value, "BEGIN PRIVATE KEY") or
      String.contains?(value, "Authorization:") or
      String.contains?(value, "Cookie:") or
      String.contains?(value, "Subscription-Key:")
  end

  defp safe_diagnostic_value?(value) when is_binary(value), do: not prohibited_value?(value)
  defp safe_diagnostic_value?(value), do: is_boolean(value) or is_integer(value) or is_nil(value)

  defp get_value(map, key, default \\ nil) when is_map(map) do
    Map.get(map, key) || Map.get(map, String.to_atom(key)) || default
  end

  defp to_string_key_map(%{} = map), do: Map.new(map, fn {key, value} -> {to_string(key), value} end)
  defp to_string_key_map(_value), do: %{}

  defp normalize_token(value) do
    value
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]/, "")
  end
end
