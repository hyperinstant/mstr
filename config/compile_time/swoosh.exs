import Config

case config_env() do
  :dev ->
    config :swoosh, :api_client, false

  :prod ->
    config :swoosh, api_client: Swoosh.ApiClient.Finch, finch_name: Mstr.Finch
    config :swoosh, local: false

  :test ->
    config :swoosh, :api_client, false

  _ ->
    []
end
