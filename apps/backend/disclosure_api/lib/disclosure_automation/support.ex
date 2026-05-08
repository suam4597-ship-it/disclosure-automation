defmodule DisclosureAutomation.EnvInterpolation do
  @moduledoc false

  @pattern ~r/\$\{(?<name>[A-Z0-9_]+)(:-(?<default>[^}]*))?\}/

  def resolve(value, env \\ System.get_env())

  def resolve(%{} = map, env),
    do: map |> Enum.map(fn {k, v} -> {k, resolve(v, env)} end) |> Enum.into(%{})

  def resolve(list, env) when is_list(list), do: Enum.map(list, &resolve(&1, env))

  def resolve(value, env) when is_binary(value) do
    Regex.replace(@pattern, value, fn _full, name, _fallback_group, default ->
      Map.get(env, name, default || "")
    end)
  end

  def resolve(value, _env), do: value
end

defmodule DisclosureAutomation.Support.YamlLoader do
  @moduledoc false

  alias DisclosureAutomation.EnvInterpolation

  def load_source_registry(path), do: load_yaml_file(path, "sources")
  def load_delivery_windows(path), do: load_yaml_file(path, "windows")
  def load_parser_capabilities(path), do: load_yaml_file(path, "parsers")

  def load_yaml_file(path, collection_key) do
    with :ok <- ensure_loader_available(),
         {:ok, raw} <- File.read(path),
         {:ok, parsed} <- YamlElixir.read_from_string(raw),
         resolved <- EnvInterpolation.resolve(parsed),
         :ok <- ensure_collection_key(resolved, collection_key) do
      {:ok, resolved}
    else
      {:error, _reason} = error -> error
      {:yaml_error, reason} -> {:error, {:invalid_yaml, reason}}
      other -> {:error, other}
    end
  end

  defp ensure_loader_available do
    if Code.ensure_loaded?(YamlElixir) and function_exported?(YamlElixir, :read_from_string, 1) do
      :ok
    else
      {:error, :yaml_loader_unavailable}
    end
  end

  defp ensure_collection_key(%{} = parsed, key) do
    case Map.fetch(parsed, key) do
      {:ok, value} when is_list(value) -> :ok
      {:ok, _value} -> {:error, {:invalid_contract_shape, key}}
      :error -> {:error, {:missing_collection_key, key}}
    end
  end

  defp ensure_collection_key(_parsed, key), do: {:error, {:invalid_contract_shape, key}}
end

defmodule DisclosureAutomation.ParserCapabilities do
  @moduledoc false

  alias DisclosureAutomation.Support.YamlLoader

  @cache_key :parser_capabilities_cache

  def load(opts \\ []) do
    path =
      Keyword.get(
        opts,
        :path,
        Application.fetch_env!(:disclosure_automation, :parser_capabilities_path)
      )

    with {:ok, %{"parsers" => parsers} = payload} <- YamlLoader.load_parser_capabilities(path) do
      normalized =
        Enum.map(parsers, fn parser ->
          parser
          |> Map.put_new("enabled", true)
          |> Map.put_new("parser_key", "unknown")
        end)

      {:ok, Map.put(payload, :by_key, Map.new(normalized, &{Map.fetch!(&1, "parser_key"), &1}))}
    end
  end

  def get(parser_key, opts \\ []) when is_binary(parser_key) do
    capabilities =
      Keyword.get_lazy(opts, :cache, fn ->
        Application.get_env(:disclosure_automation, @cache_key, %{})
      end)

    case capabilities do
      %{by_key: by_key} when is_map(by_key) -> Map.fetch(by_key, parser_key)
      %{"by_key" => by_key} when is_map(by_key) -> Map.fetch(by_key, parser_key)
      _ -> :error
    end
  end
end

defmodule DisclosureAutomation.Http do
  @moduledoc false

  @default_headers [{~c"user-agent", ~c"disclosure-automation-phase1"}]

  def fetch(url, opts \\ []) when is_binary(url) do
    timeout = Keyword.get(opts, :timeout, 8_000)
    headers = Keyword.get(opts, :headers, @default_headers)
    method = opts |> Keyword.get(:method, :get) |> normalize_method()
    request = request(method, url, headers, opts)
    http_opts = [timeout: timeout, connect_timeout: timeout, ssl: [verify: :verify_none]]
    request_opts = [body_format: :binary]

    case :httpc.request(method, request, http_opts, request_opts) do
      {:ok, {{_http_version, status_code, _reason_phrase}, response_headers, body}} ->
        {:ok,
         %{
           status_code: status_code,
           headers:
             Enum.map(response_headers, fn {key, value} -> {to_string(key), to_string(value)} end),
           body: body,
           bytes: byte_size(body)
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp normalize_method(method) when method in [:get, :post], do: method

  defp normalize_method(method) when is_binary(method) do
    case String.downcase(method) do
      "post" -> :post
      _method -> :get
    end
  end

  defp normalize_method(_method), do: :get

  defp request(:post, url, headers, opts) do
    body = opts |> Keyword.get(:body, "") |> to_string()
    content_type = opts |> Keyword.get(:content_type, "application/json") |> to_string()
    {String.to_charlist(url), headers, String.to_charlist(content_type), body}
  end

  defp request(_method, url, headers, _opts), do: {String.to_charlist(url), headers}
end

defmodule DisclosureAutomation.Fixtures do
  @moduledoc false

  def daily_digest_fixture_path do
    Application.fetch_env!(:disclosure_automation, :daily_digest_fixture_path)
  end

  def fixtures_root do
    Application.fetch_env!(:disclosure_automation, :fixtures_root)
  end

  def load_daily_digest(opts \\ []) do
    path = Keyword.get(opts, :path, daily_digest_fixture_path())

    with {:ok, raw} <- File.read(path),
         {:ok, decoded} <- Jason.decode(raw) do
      {:ok, decoded}
    end
  end

  def resolve_source_payload_path(relative_path) when is_binary(relative_path) do
    Path.expand(relative_path, fixtures_root())
  end

  def load_source_payload(relative_path) when is_binary(relative_path) do
    path = resolve_source_payload_path(relative_path)

    with {:ok, raw} <- File.read(path) do
      {:ok,
       %{
         relative_path: relative_path,
         path: path,
         raw: raw,
         bytes: byte_size(raw)
       }}
    end
  end
end
