import Config

config :phoenix, :json_library, Jason

case config_env() do
  :dev ->
    config :phoenix, :stacktrace_depth, 20
    config :phoenix, :plug_init_mode, :runtime

    config :phoenix_live_view,
      debug_heex_annotations: true,
      enable_expensive_runtime_checks: true

  :test ->
    config :phoenix, :plug_init_mode, :runtime

    config :phoenix_live_view,
      enable_expensive_runtime_checks: true

  _ ->
    []
end
