defmodule Mstr.SpotifyClient do
  use GenServer
  require Logger
  alias Mstr.SpotifyClient.State
  alias Mstr.SpotifyClient.Track

  @spotify_api_uri URI.parse("https://api.spotify.com/v1/")
  @ets_table :spotify_token_store

  # Client
  def track_from(url) when is_binary(url) do
    with {:ok, track_id} <- extract_track_id(url),
         {:ok, track_map} <- track(track_id) do
      Track.from_json(track_map)
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
    URI.parse(@spotify_api_uri)
    |> URI.append_path("/tracks")
    |> URI.append_path("/#{track_id}")
    |> make_api_request()
  end

  defp make_api_request(uri) do
    case Req.get(uri, auth: {:bearer, token()}) do
      {:ok, %Req.Response{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Req.Response{status: 401}} ->
        {:error, :unauthorized}

      {:ok, %Req.Response{status: 400, body: %{"error" => %{"message" => "Invalid base62 id", "status" => 400}}}} ->
        {:error, :malformed_id}

      {:ok, %Req.Response{status: 404}} ->
        {:error, :not_found}

      {:error, _reason} = error ->
        error
    end
  end

  defp token() do
    Keyword.fetch!(:ets.lookup(:spotify_token_store, :token), :token)
  end
end
