defmodule DisclosureAutomation.Runtime.Stage56RedactedProviderResultAdapter do
  @moduledoc false

  alias DisclosureAutomation.Runtime.Stage54ProviderIngestionBoundary

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

  def to_boundary_payload(transport_result, article_attrs, opts \\ [])

  def to_boundary_payload(%{} = transport_result, %{} = article_attrs, opts) do
    with :ok <- live_fetch_disabled(opts),
         :ok <- scheduler_disabled(opts),
         :ok <- reject_prohibited_fields(transport_result),
         :ok <- reject_prohibited_fields(article_attrs),
         :ok <- require_fake_transport(transport_result),
         payload <- build_payload(transport_result, article_attrs),
         {:ok, normalized} <- Stage54ProviderIngestionBoundary.normalize_result(payload, opts) do
      {:ok,
       normalized
       |> Map.put(:adapter_mode, "stage56_redacted_provider_result_adapter")
       |> Map.put(:transport_mode, get_value(transport_result, "transport_mode", "fake"))}
    end
  end

  def to_boundary_payload(_transport_result, _article_attrs, _opts), do: {:error, :invalid_provider_result_adapter_input}

  defp build_payload(transport_result, article_attrs) do
    %{
      "provider" => first_present([get_value(article_attrs, "provider"), get_value(transport_result, "provider")]),
      "source_key" => first_present([get_value(article_attrs, "source_key"), get_value(transport_result, "source_key")]),
      "source_tier" => first_present([get_value(article_attrs, "source_tier"), "reputable_news_source"]),
      "document_role" => first_present([get_value(article_attrs, "document_role"), "news_article"]),
      "article_external_id" => get_value(article_attrs, "article_external_id"),
      "canonical_event_id" => get_value(article_attrs, "canonical_event_id"),
      "matched_official_stable_external_id" => get_value(article_attrs, "matched_official_stable_external_id"),
      "title" => get_value(article_attrs, "title"),
      "published_at" => get_value(article_attrs, "published_at"),
      "url" => get_value(article_attrs, "url"),
      "language" => get_value(article_attrs, "language"),
      "jurisdiction" => get_value(article_attrs, "jurisdiction"),
      "citations" => safe_list(get_value(article_attrs, "citations")),
      "overlay_claims" => safe_list(get_value(article_attrs, "overlay_claims")),
      "diagnostics" => diagnostics(transport_result)
    }
  end

  defp diagnostics(transport_result) do
    transport_diagnostics = get_value(transport_result, "diagnostics", %{}) || %{}

    %{
      "provider" => get_value(transport_result, "provider"),
      "status_code" => get_value(transport_result, "status_code"),
      "retry_count" => get_value(transport_diagnostics, "retry_count"),
      "timeout" => get_value(transport_diagnostics, "timeout"),
      "error_class" => get_value(transport_diagnostics, "error_class"),
      "fetched_at" => first_present([get_value(transport_result, "fetched_at"), get_value(transport_diagnostics, "fetched_at")]),
      "request_id_hash" => get_value(transport_diagnostics, "request_id_hash")
    }
    |> Enum.reject(fn {_key, value} -> is_nil(value) end)
    |> Map.new()
  end

  defp require_fake_transport(transport_result) do
    cond do
      get_value(transport_result, "transport_mode", "fake") != "fake" ->
        {:error, {:transport_mode_not_allowed, get_value(transport_result, "transport_mode")}}

      get_value(transport_result, "mode") not in [nil, "manual_provider_fake_transport"] ->
        {:error, {:transport_result_mode_not_allowed, get_value(transport_result, "mode")}}

      true ->
        :ok
    end
  end

  defp live_fetch_disabled(opts) do
    if Keyword.get(opts, :use_live_fetch, false) do
      {:error, :live_fetch_not_allowed_in_stage56_result_adapter}
    else
      :ok
    end
  end

  defp scheduler_disabled(opts) do
    if Keyword.get(opts, :scheduler_enabled, false) do
      {:error, :scheduler_not_allowed_in_stage56_result_adapter}
    else
      :ok
    end
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

  defp safe_list(value) when is_list(value), do: value
  defp safe_list(_value), do: []

  defp first_present(values), do: Enum.find(values, &present?/1)

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(nil), do: false
  defp present?(_value), do: true

  defp get_value(map, key, default \\ nil)

  defp get_value(map, key, default) when is_map(map) do
    Map.get(map, key) || Map.get(map, String.to_atom(key)) || default
  end

  defp get_value(_value, _key, default), do: default

  defp normalize_token(value) do
    value
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]/, "")
  end
end
