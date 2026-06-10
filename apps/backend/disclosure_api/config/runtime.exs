import Config

if System.get_env("PHX_SERVER") do
  config :disclosure_automation, DisclosureAutomationWeb.Endpoint, server: true
end

database_url = System.get_env("DATABASE_URL")
pool_size = String.to_integer(System.get_env("POOL_SIZE") || "10")

if database_url do
  config :disclosure_automation, DisclosureAutomation.Repo,
    url: database_url,
    pool_size: pool_size,
    socket_options: if(System.get_env("ECTO_IPV6"), do: [:inet6], else: [])
end

if config_env() == :prod do
  secret_key_base = System.get_env("SECRET_KEY_BASE") || raise "SECRET_KEY_BASE is missing"
  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  if is_nil(database_url) do
    raise "DATABASE_URL is missing"
  end

  config :disclosure_automation, DisclosureAutomationWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: port],
    secret_key_base: secret_key_base
end
