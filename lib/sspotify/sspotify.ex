defmodule SSpotify do
  alias SSpotify.Track
  alias SSpotify.TokenManager

  @spotify_api_uri URI.parse("https://api.spotify.com/v1/")

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
    case Req.get(uri, auth: {:bearer, TokenManager.token()}) do
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
end
