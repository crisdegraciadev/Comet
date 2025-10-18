import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :argon2_elixir, t_cost: 1, m_cost: 8

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
# config :comet, Comet.Repo,
#   username: "postgres",
#   password: "postgres",
#   hostname: "localhost",
#   database: "comet_test#{System.get_env("MIX_TEST_PARTITION")}",
#   pool: Ecto.Adapters.SQL.Sandbox,
#   pool_size: System.schedulers_online() * 2


config :comet, Comet.Repo,
  adapter: Ecto.Adapters.SQLite3,
  database: Path.expand("../database/comet_test.sqlite3", __DIR__)

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :comet, CometWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "QuhmkLRTiugPRQKoqLJ+LqtYkCZQkBxxcPBtxEflyyZ3Zcx4zI3M6E3QqyxEADxL",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
