defmodule Mstr.SpotifyClient do
  use GenServer
  require Logger

  @spotify_api_uri URI.parse("https://api.spotify.com/v1/")
  @ets_table :spotify_token_store

  defstruct [:token]

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
    validate!(args)
    :ets.new(@ets_table, [:set, :protected, :named_table])
    {:ok, %__MODULE__{}, {:continue, args}}
  end

  def handle_continue(args, state) do
    token = request_token!(args.client_id, args.client_secret)
    :ets.insert(:spotify_token_store, {:token, token})
    state = %{state | token: token}
    {:noreply, state}
  end

  defp request_token!(client_id, client_secret) do
    body =
      URI.encode_query(%{
        grant_type: "client_credentials",
        client_id: client_id,
        client_secret: client_secret
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
        Jason.decode!(response.body)["access_token"]

      {:error, error} ->
        Logger.error(inspect(error))
        raise error
    end
  end

  defp validate!(args) do
    if not is_binary(args.client_id) do
      raise "Spotify client_id must be a string"
    end

    if not is_binary(args.client_secret) do
      raise "Spotify client_secret must be a string"
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
