defmodule SSpotify.TokenManager do
  @ets_table :spotify_token_store
  alias SSpotify.TokenManager.State
  use GenServer
  require Logger

  # Server

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(args) do
    :ets.new(@ets_table, [:set, :protected, :named_table])
    {:ok, State.new!(args.client_id, args.client_secret), {:continue, nil}}
  end

  def handle_continue(_args, state) do
    {:noreply, refresh_token(state)}
  end

  defp refresh_token(state) do
    state = request_token!(state)
    :ets.insert(:spotify_token_store, {:token, state.token})
    state
  end

  defp request_token!(state) do
    body =
      URI.encode_query(%{
        grant_type: "client_credentials",
        client_id: state.client_id,
        client_secret: state.client_secret
      })

    case Req.post(
           "https://accounts.spotify.com/api/token",
           body: body,
           headers: [{"Content-Type", "application/x-www-form-urlencoded"}]
         ) do
      {:ok, %Req.Response{status: 200, body: resp}} ->
        State.token_refreshed(state, Map.fetch!(resp, "access_token"), Map.fetch!(resp, "expires_in"))

      {:error, error} ->
        Logger.error(inspect(error))
        raise error
    end
  end

  def token() do
    Keyword.fetch!(:ets.lookup(:spotify_token_store, :token), :token)
  end
end
