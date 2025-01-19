import Config

config :mstr,
  ecto_repos: [Mstr.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

config :mstr, Mstr.Mailer, adapter: Swoosh.Adapters.Local

case config_env() do
  :dev ->
    config :mstr, dev_routes: true

  :test ->
    config :mstr, Mstr.Mailer, adapter: Swoosh.Adapters.Test
    config :mstr, sspotify_req_options: [plug: {Req.Test, SSpotify.ApiClient}]

  _ ->
    []
end
