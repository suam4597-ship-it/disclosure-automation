import Config

config :disclosure_automation,
  ecto_repos: [DisclosureAutomation.Repo],
  generators: [binary_id: true],
  source_registry_path: Path.expand("../priv/config_samples/source_registry.sample.yaml", __DIR__),
  delivery_windows_path: Path.expand("../priv/config_samples/delivery_windows.sample.yaml", __DIR__),
  parser_capabilities_path: Path.expand("../priv/config_samples/parser_capabilities.sample.yaml", __DIR__),
  fixtures_root: Path.expand("../priv/fixtures", __DIR__),
  daily_digest_fixture_path: Path.expand("../priv/fixtures/daily_feed.sample.json", __DIR__)

config :disclosure_automation, DisclosureAutomation.Repo,
  migration_primary_key: [type: :binary_id],
  migration_foreign_key: [type: :binary_id]

config :disclosure_automation, DisclosureAutomationWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [formats: [json: DisclosureAutomationWeb.ErrorJSON], layout: false],
  secret_key_base: "phase1-local-dev",
  server: false

config :disclosure_automation, Oban,
  repo: DisclosureAutomation.Repo,
  plugins: [{Oban.Plugins.Pruner, max_age: 86400}],
  queues: [source_polling: 10, health_checks: 5]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

case config_env() do
  :test -> import_config "test.exs"
  :prod -> import_config "prod.exs"
  _ -> import_config "dev.exs"
end
