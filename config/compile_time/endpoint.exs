import Config

config :mstr, MstrWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: MstrWeb.ErrorHTML, json: MstrWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Mstr.PubSub,
  live_view: [signing_salt: "dvhNP+cZ"]

case config_env() do
  :dev ->
    config :mstr, MstrWeb.Endpoint,
      # Binding to loopback ipv4 address prevents access from other machines.
      # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
      http: [ip: {127, 0, 0, 1}, port: 4000],
      check_origin: false,
      code_reloader: true,
      debug_errors: true,
      secret_key_base: "vl34FW0WdJyaL31FiqeETXk8eggTYnsFaCcw3BFhGhhiyuxR5vZ+tpuwMmkOBSy8",
      watchers: [
        esbuild: {Esbuild, :install_and_run, [:mstr, ~w(--sourcemap=inline --watch)]},
        tailwind: {Tailwind, :install_and_run, [:mstr, ~w(--watch)]}
      ],
      live_reload: [
        patterns: [
          ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
          ~r"priv/gettext/.*(po)$",
          ~r"lib/mstr_web/(controllers|live|components)/.*(ex|heex)$"
        ]
      ]

  :prod ->
    config :mstr, MstrWeb.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"

  :test ->
    config :mstr, MstrWeb.Endpoint,
      http: [ip: {127, 0, 0, 1}, port: 4002],
      secret_key_base: "UNeRi76cWUpwvvMxh2Z80Rlamb3zXefS9pthF5GEggWhSce1qEzN4XIFroFgs6k8",
      server: false

  _ ->
    []
end
