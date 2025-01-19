import Config

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

case config_env() do
  :dev ->
    config :logger, :console, format: "[$level] $message\n"

  :prod ->
    config :logger, level: :info

  :test ->
    config :logger, level: :warning

  _ ->
    []
end
