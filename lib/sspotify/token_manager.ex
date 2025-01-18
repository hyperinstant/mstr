defmodule SSpotify.TokenManager do
  @ets_table :spotify_token_store
  # safety buffer in seconds
  @refresh_buffer 60

  alias SSpotify.TokenManager.State
  use GenServer
  require Logger

  ## Client
  def token() do
    Keyword.fetch!(:ets.lookup(@ets_table, :token), :token)
  end

  ## Server

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(args) do
    :ets.new(@ets_table, [:set, :protected, :named_table])
    {:ok, State.new!(args), {:continue, nil}}
  end

  def handle_continue(_args, state) do
    {:noreply, refresh_token(state)}
  end

  def handle_info(:refresh_token, state) do
    {:noreply, refresh_token(state)}
  end

  defp refresh_token(state) do
    state = request_token!(state)
    :ets.insert(@ets_table, {:token, state.token})
    schedule_refresh(state.expires_in)
    state
  end

  defp request_token!(state) do
    resp = state.api_client.request_token!(state.client_id, state.client_secret)
    State.token_refreshed(state, Map.fetch!(resp, "access_token"), Map.fetch!(resp, "expires_in"))
  end

  defp schedule_refresh(expires_in) do
    # Schedule refresh before token expires (subtracting buffer time)
    refresh_in = max((expires_in - @refresh_buffer) * 1000, 0)
    Process.send_after(self(), :refresh_token, refresh_in)
  end
end
