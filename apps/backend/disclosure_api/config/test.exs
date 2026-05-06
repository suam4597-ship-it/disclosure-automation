import Config

config :disclosure_automation, DisclosureAutomation.Repo,
  username: System.get_env("POSTGRES_USER") || "postgres",
  password: System.get_env("POSTGRES_PASSWORD") || "postgres",
  hostname: System.get_env("POSTGRES_HOST") || "localhost",
  database: System.get_env("POSTGRES_TEST_DB") || "disclosure_automation_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 5

config :disclosure_automation, DisclosureAutomationWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "test-key",
  server: false

config :disclosure_automation, Oban,
  repo: DisclosureAutomation.Repo,
  testing: :manual,
  plugins: false,
  queues: false,
  peer: false

config :disclosure_automation, :source_health_permission_param_fallback, :test_only

config :logger, level: :warning
