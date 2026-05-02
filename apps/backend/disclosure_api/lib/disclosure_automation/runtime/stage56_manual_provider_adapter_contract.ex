defmodule DisclosureAutomation.Runtime.Stage56ManualProviderAdapterContract do
  @moduledoc false

  @allowed_transport_modes ["fake"]
  @default_timeout_ms 5_000
  @default_retry_count 0
  @max_timeout_ms 5_000
  @max_retry_count 1

  @prohibited_key_fragments [
    "articlebody",
    "fulltext",
    "fullarticletext",
    "rawhtml",
    "rawresponsebody",
    "responsebody",
    "providerresponsebody",
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
    "signed_private_url"
  ]

  def defaults do
    %{
      manual_trigger_required: true,
      manual_trigger: false,
      transport_mode: "fake",
      use_live_fetch: false,
      scheduler_enabled: false,
      network_access: "forbidden",
      timeout_ms: @default_timeout_ms,
      retry_count: @default_retry_count,
      store_full_text: false,
      log_request_headers: false,
      log_response_headers: false,
      log_response_body: false,
      canonical_feed_mutation: false,
      news_only_event_creation: false,
      canonical_fact_override: false
    }
  end

  def validate_request(attrs, opts \\ [])

  def validate_request(attrs, opts) when is_map(attrs) do
    with :ok <- live_fetch_disabled(opts),
         :ok <- scheduler_disabled(opts),
         :ok <- reject_prohibited_fields(attrs),
         :ok <- manual_trigger_present(attrs),
         {:ok, transport_mode} <- validate_transport_mode(get_value(attrs, "transport_mode", "fake")),
         {:ok, timeout_ms} <- bounded_int(get_value(attrs, "timeout_ms", @default_timeout_ms), @max_timeout_ms),
         {:ok, retry_count} <- bounded_int(get_value(attrs, "retry_count", @default_retry_count), @max_retry_count) do
      {:ok,
       Map.merge(defaults(), %{
         manual_trigger: true,
         provider: get_value(attrs, "provider"),
         source_key: get_value(attrs, "source_key"),
         provider_request_id: get_value(attrs, "provider_request_id"),
         transport_mode: transport_mode,
         timeout_ms: timeout_ms,
         retry_count: retry_count
       })}
    end
  end

  def validate_request(_attrs, _opts), do: {:error, :invalid_manual_provider_request}

  def fake_transport_result(request_attrs, result_attrs \\ %{})

  def fake_transport_result(request_attrs, result_attrs) when is_map(result_attrs) do
    with {:ok, request} <- validate_request(request_attrs),
         :ok <- reject_prohibited_fields(result_attrs) do
      {:ok,
       %{
         mode: "manual_provider_fake_transport",
         provider: request.provider,
         source_key: request.source_key,
         provider_request_id: request.provider_request_id,
         transport_mode: "fake",
         use_live_fetch: false,
         scheduler_enabled: false,
         network_access: "forbidden",
         status_code: get_value(result_attrs, "status_code"),
         fetched_at: get_value(result_attrs, "fetched_at"),
         diagnostics: safe_diagnostics(result_attrs),
         canonical_feed_mutation: false,
         news_only_event_creation: false,
         canonical_fact_override: false
       }}
    end
  end

  def fake_transport_result(_request_attrs, _result_attrs), do: {:error, :invalid_fake_transport_result}

  defp live_fetch_disabled(opts) do
    if Keyword.get(opts, :use_live_fetch, false) do
      {:error, :live_fetch_not_allowed_in_stage56_adapter_contract}
    else
      :ok
    end
  end

  defp scheduler_disabled(opts) do
    if Keyword.get(opts, :scheduler_enabled, false) do
      {:error, :scheduler_not_allowed_in_stage56_adapter_contract}
    else
      :ok
    end
  end

  defp manual_trigger_present(attrs) do
    if truthy?(get_value(attrs, "manual_trigger")) or truthy?(get_value(attrs, "operator_triggered")) do
      :ok
    else
      {:error, :manual_trigger_required}
    end
  end

  defp validate_transport_mode(mode) when mode in @allowed_transport_modes, do: {:ok, mode}
  defp validate_transport_mode(mode), do: {:error, {:transport_mode_not_allowed, mode}}

  defp bounded_int(value, max) when is_integer(value) and value >= 0 and value <= max, do: {:ok, value}

  defp bounded_int(value, max) when is_binary(value) do
    case Integer.parse(value) do
      {parsed, ""} -> bounded_int(parsed, max)
      _ -> {:error, {:invalid_bounded_int, value}}
    end
  end

  defp bounded_int(value, max) when is_integer(value) and value > max, do: {:error, {:bounded_int_too_large, value, max}}
  defp bounded_int(value, _max), do: {:error, {:invalid_bounded_int, value}}

  defp safe_diagnostics(attrs) do
    diagnostics = get_value(attrs, "diagnostics", attrs) || %{}

    diagnostics
    |> to_string_key_map()
    |> Enum.filter(fn {_key, value} -> safe_diagnostic_value?(value) end)
    |> Map.new(fn {key, value} -> {String.to_atom(key), value} end)
  end

  defp reject_prohibited_fields(value) do
    case find_prohibited_field(value) do
      nil -> :ok
      path -> {:error, {:prohibited_field, path}}
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
      String.contains?(value, sensitive_header_prefix(:authorization)) or
      String.contains?(value, sensitive_header_prefix(:cookie)) or
      String.contains?(value, sensitive_header_prefix(:subscription_key))
  end

  defp sensitive_header_prefix(:authorization), do: "Author" <> "ization" <> ":"
  defp sensitive_header_prefix(:cookie), do: "Coo" <> "kie" <> ":"
  defp sensitive_header_prefix(:subscription_key), do: "Subscription" <> "-" <> "Key" <> ":"

  defp safe_diagnostic_value?(value) when is_binary(value), do: not prohibited_value?(value)
  defp safe_diagnostic_value?(value), do: is_boolean(value) or is_integer(value) or is_nil(value)

  defp get_value(map, key, default \\ nil)

  defp get_value(map, key, default) when is_map(map) do
    Map.get(map, key) || Map.get(map, String.to_atom(key)) || default
  end

  defp get_value(_value, _key, default), do: default

  defp to_string_key_map(%{} = map), do: Map.new(map, fn {key, value} -> {to_string(key), value} end)
  defp to_string_key_map(_value), do: %{}

  defp truthy?(value), do: value in [true, "true", "yes", "1", 1]

  defp normalize_token(value) do
    value
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]/, "")
  end
end
