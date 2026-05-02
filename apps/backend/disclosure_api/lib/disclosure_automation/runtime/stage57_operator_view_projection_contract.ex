defmodule DisclosureAutomation.Runtime.Stage57OperatorViewProjectionContract do
  @moduledoc false

  @allowed_health_states ~w(
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

  @allowed_fields ~w(
    source_key
    display_name
    provider
    source_type
    active
    health_status
    last_success_at
    last_failure_at
    last_seen_published_at
    error_class
    redaction_status
    manual_review_reason
    request_id_hash
    cursor_keys
    has_recent_safe_overlay
    has_visible_overlays
  )

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

  def allowed_fields, do: @allowed_fields
  def allowed_health_states, do: @allowed_health_states

  def defaults do
    %{
      view_scope: "operator_only",
      read_only: true,
      advisory_only: true,
      public_response_shape_mutation: false,
      trigger_live_fetch: false,
      scheduler_enabled: false,
      source_health_mutation: false,
      canonical_feed_mutation: false,
      provider_canonical_feed_item_creation: false,
      news_only_event_creation: false
    }
  end

  def project(attrs, opts \\ [])

  def project(attrs, opts) when is_map(attrs) do
    with :ok <- forbid_public_exposure(opts),
         :ok <- forbid_live_fetch(opts),
         :ok <- forbid_scheduler(opts),
         :ok <- reject_prohibited_fields(attrs),
         {:ok, health_status} <- normalize_health_status(get_value(attrs, "health_status", "unknown")) do
      {:ok,
       defaults()
       |> Map.merge(%{
         health_status: health_status,
         fields: project_allowed_fields(attrs, health_status)
       })}
    end
  end

  def project(_attrs, _opts), do: {:error, :invalid_operator_view_projection_attrs}

  defp project_allowed_fields(attrs, health_status) do
    @allowed_fields
    |> Enum.reduce(%{}, fn field, acc ->
      cond do
        field == "health_status" ->
          Map.put(acc, :health_status, health_status)

        has_value?(attrs, field) ->
          Map.put(acc, String.to_atom(field), get_value(attrs, field))

        true ->
          acc
      end
    end)
  end

  defp normalize_health_status(nil), do: {:ok, "unknown"}

  defp normalize_health_status(status) when is_binary(status) do
    normalized = String.trim(status)

    if normalized in @allowed_health_states do
      {:ok, normalized}
    else
      {:error, {:invalid_operator_view_health_status, status}}
    end
  end

  defp normalize_health_status(status), do: {:error, {:invalid_operator_view_health_status, status}}

  defp forbid_public_exposure(opts) do
    if Keyword.get(opts, :public_exposure, false) do
      {:error, :public_exposure_not_allowed_in_stage57_operator_view}
    else
      :ok
    end
  end

  defp forbid_live_fetch(opts) do
    if Keyword.get(opts, :trigger_live_fetch, false) or Keyword.get(opts, :use_live_fetch, false) do
      {:error, :live_fetch_not_allowed_in_stage57_operator_view}
    else
      :ok
    end
  end

  defp forbid_scheduler(opts) do
    if Keyword.get(opts, :scheduler_enabled, false) do
      {:error, :scheduler_not_allowed_in_stage57_operator_view}
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

  defp has_value?(map, key) when is_map(map) do
    Map.has_key?(map, key) or Map.has_key?(map, String.to_atom(key))
  end

  defp get_value(map, key, default \\ nil)

  defp get_value(map, key, default) when is_map(map) do
    cond do
      Map.has_key?(map, key) -> Map.get(map, key)
      Map.has_key?(map, String.to_atom(key)) -> Map.get(map, String.to_atom(key))
      true -> default
    end
  end

  defp get_value(_value, _key, default), do: default

  defp normalize_token(value) do
    value
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]/, "")
  end
end
