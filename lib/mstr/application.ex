defmodule Mstr.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MstrWeb.Telemetry,
      Mstr.Repo,
      {DNSCluster, query: Application.get_env(:mstr, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Mstr.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Mstr.Finch},
      {SSpotify.TokenManager,
       %{
         client_id: Application.fetch_env!(:mstr, :spotify_client_id),
         client_secret: Application.fetch_env!(:mstr, :spotify_client_secret)
       }},
      MstrWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Mstr.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MstrWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
