defmodule SSpotify.TokenManager.State do
  defstruct [:client_id, :client_secret, :token, :refreshed_at, :expires_in, :api_client]
  alias __MODULE__

  def new!(args) do
    validate!(args.client_id, args.client_secret)
    %State{client_id: args.client_id, client_secret: args.client_secret, api_client: api_client_with_defaults(args)}
  end

  def token(state, token) do
    Map.put(state, :token, token)
  end

  def token_refreshed(state, new_token, expires_in) do
    state
    |> Map.put(:token, new_token)
    |> Map.put(:expires_in, expires_in)
    |> Map.put(:refreshed_at, DateTime.utc_now())
  end

  defp validate!(client_id, client_secret) do
    if not is_binary(client_id) do
      raise "Spotify client_id must be a string"
    end

    if not is_binary(client_secret) do
      raise "Spotify client_secret must be a string"
    end
  end

  defp api_client_with_defaults(%{api_client: api_client}) do
    api_client
  end

  defp api_client_with_defaults(_) do
    SSpotify.ApiClient
  end
end
