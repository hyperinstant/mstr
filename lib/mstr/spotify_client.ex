defmodule Mstr.SpotifyClient do
  use GenServer
  require Logger
  alias Mstr.SpotifyClient.State

  @spotify_api_uri URI.parse("https://api.spotify.com/v1/")
  @ets_table :spotify_token_store

  # Client
  def track_from(url) when is_binary(url) do
    with {:ok, track_id} <- extract_track_id(url) do
      track(track_id)
    end
  end

  def valid_track_url?(url) do
    case extract_track_id(url) do
      {:ok, _} -> true
      _ -> false
    end
  end

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

    request =
      Finch.build(
        :post,
        "https://accounts.spotify.com/api/token",
        [{"Content-Type", "application/x-www-form-urlencoded"}],
        body
      )

    case Finch.request(request, Mstr.Finch) do
      {:ok, response} ->
        resp = Jason.decode!(response.body)
        State.token_refreshed(state, Map.fetch!(resp, "access_token"), Map.fetch!(resp, "expires_in"))

      {:error, error} ->
        Logger.error(inspect(error))
        raise error
    end
  end

  defp extract_track_id(url) do
    with true <- String.starts_with?(url, "https://open.spotify.com/track/"),
         %{path: "/track/" <> track_id} <- URI.parse(url) do
      {:ok, track_id}
    else
      _ ->
        {:error, :invalid_track_url}
    end
  end

  defp track(track_id) do
    URI.parse("https://api.spotify.com/v1/")
    |> URI.append_path("/tracks")
    |> URI.append_path("/#{track_id}")
    |> make_api_request()
  end

  defp make_api_request(uri) do
    headers = [
      {"Authorization", "Bearer #{token()}"},
      {"Content-Type", "application/json"}
    ]

    request = Finch.build(:get, to_string(uri), headers)

    case Finch.request(request, Mstr.Finch) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, %Finch.Response{status: 401}} ->
        {:error, :unauthorized}

      {:ok, %Finch.Response{status: 404}} ->
        {:error, :not_found}

      {:error, _reason} = error ->
        error
    end
  end

  defp token() do
    Keyword.fetch!(:ets.lookup(:spotify_token_store, :token), :token)
  end
end
