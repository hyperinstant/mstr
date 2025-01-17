defmodule SSpotify.ApiClient do
  alias SSpotify.TokenManager
  @spotify_api_uri URI.parse("https://api.spotify.com/v1/")

  def track(track_id) do
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
