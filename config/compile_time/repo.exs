import Config

case config_env() do
  :dev ->
    config :mstr, Mstr.Repo,
      username: "postgres",
      password: "postgres",
      hostname: "localhost",
      database: "mstr_dev",
      stacktrace: true,
      show_sensitive_data_on_connection_error: true,
      pool_size: 10

  :test ->
    config :mstr, Mstr.Repo,
      username: "postgres",
      password: "postgres",
      hostname: "localhost",
      database: "mstr_test#{System.get_env("MIX_TEST_PARTITION")}",
      pool: Ecto.Adapters.SQL.Sandbox,
      pool_size: System.schedulers_online() * 2

  _ ->
    []
end
