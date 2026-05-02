defmodule DisclosureAutomation.Runtime.Stage54ProviderIngestionBoundary do
  @moduledoc false

  @required_fields [
    "provider",
    "source_key",
    "article_external_id",
    "canonical_event_id",
    "title",
    "published_at",
    "url"
  ]

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
    "signed_private_url"
  ]

  @diagnostic_allowlist [
    "provider",
    "status_code",
    "retry_count",
    "timeout",
    "error_class",
    "fetched_at",
    "request_id_hash"
  ]

  def defaults do
    %{
      use_live_fetch: false,
      network_access: "forbidden",
      scheduler_enabled: false,
      overlay_mode: "attach_only",
      canonical_feed_mutation: false,
      news_only_event_creation: false,
      canonical_fact_override: false,
      storage_mode: "metadata_only"
    }
  end

  def normalize_result(payload, opts \\ []) when is_map(payload) do
    with :ok <- live_fetch_disabled(opts),
         :ok <- reject_prohibited_fields(payload),
         :ok <- require_fields(payload) do
      {:ok,
       %{
         mode: "stage54_provider_ingestion_boundary",
         use_live_fetch: false,
         network_access: "forbidden",
         scheduler_enabled: false,
         storage_mode: "metadata_only",
         overlay_mode: "attach_only",
         canonical_feed_mutation: false,
         news_only_event_creation: false,
         canonical_fact_override: false,
         provider: payload["provider"],
         source_key: payload["source_key"],
         source_tier: first_present([payload["source_tier"], "reputable_news_source"]),
         document_role: first_present([payload["document_role"], "news_article"]),
         article_external_id: payload["article_external_id"],
         canonical_event_id: payload["canonical_event_id"],
         matched_official_stable_external_id: payload["matched_official_stable_external_id"],
         title: payload["title"],
         published_at: payload["published_at"],
         url: payload["url"],
         language: payload["language"],
         jurisdiction: payload["jurisdiction"],
         citations: safe_list(payload["citations"]),
         overlay_claims: safe_list(payload["overlay_claims"]),
         diagnostics: redacted_diagnostics(payload["diagnostics"] || %{})
       }}
    end
  end

  def normalize_result(_payload, _opts), do: {:error, :invalid_provider_payload}

  defp live_fetch_disabled(opts) do
    if Keyword.get(opts, :use_live_fetch, false) do
      {:error, :live_fetch_not_allowed_in_stage54_boundary}
    else
      :ok
    end
  end

  defp require_fields(payload) do
    missing =
      @required_fields
      |> Enum.reject(fn field -> present?(payload[field]) end)

    case missing do
      [] -> :ok
      fields -> {:error, {:missing_required_fields, fields}}
    end
  end

  defp reject_prohibited_fields(payload) do
    case find_prohibited_field(payload) do
      nil -> :ok
      path -> {:error, {:prohibited_field, path}}
    end
  end

  defp find_prohibited_field(value, path \\ "")

  defp find_prohibited_field(%{} = map, path) do
    Enum.find_value(map, fn {key, value} ->
      key_string = to_string(key)
      current_path = if path == "", do: key_string, else: "#{path}.#{key_string}"

      if prohibited_key?(key_string) do
        current_path
      else
        find_prohibited_field(value, current_path)
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

  defp redacted_diagnostics(%{} = diagnostics) do
    diagnostics
    |> Enum.filter(fn {key, value} -> to_string(key) in @diagnostic_allowlist and safe_diagnostic_value?(value) end)
    |> Map.new(fn {key, value} -> {String.to_atom(to_string(key)), value} end)
  end

  defp redacted_diagnostics(_diagnostics), do: %{}

  defp safe_diagnostic_value?(value) when is_binary(value), do: not prohibited_value?(value)
  defp safe_diagnostic_value?(value), do: is_boolean(value) or is_integer(value) or is_nil(value)

  defp safe_list(value) when is_list(value), do: value
  defp safe_list(_value), do: []

  defp first_present(values), do: Enum.find(values, &present?/1)

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(nil), do: false
  defp present?(_value), do: true

  defp normalize_token(value) do
    value
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]/, "")
  end
end
