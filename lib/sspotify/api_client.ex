defmodule SSpotify.ApiClient do
  alias SSpotify.TokenManager
  require Logger
  @spotify_api_uri URI.parse("https://api.spotify.com/v1/")

  def track(track_id) do
    URI.parse(@spotify_api_uri)
    |> URI.append_path("/tracks")
    |> URI.append_path("/#{track_id}")
    |> make_api_request()
  end

  def tracks(track_ids) when is_list(track_ids) do
    ids = Enum.join(track_ids, ",")

    URI.parse(@spotify_api_uri)
    |> URI.append_path("/tracks")
    |> URI.append_query("ids=#{ids}")
    |> make_api_request()
    |> case do
      {:ok, %{"tracks" => tracks}} -> {:ok, tracks}
      resp -> resp
    end
  end

  def request_token!(client_id, client_secret) do
    body =
      URI.encode_query(%{
        grant_type: "client_credentials",
        client_id: client_id,
        client_secret: client_secret
      })

    case Req.post(
           "https://accounts.spotify.com/api/token",
           body: body,
           headers: [{"Content-Type", "application/x-www-form-urlencoded"}]
         ) do
      {:ok, %Req.Response{status: 200, body: resp}} ->
        resp

      {:error, error} ->
        Logger.error(inspect(error))
        raise error
    end
  end

  defp make_api_request(uri) do
    auth_opt = [auth: {:bearer, TokenManager.token()}]
    req_opts = Keyword.merge(Application.get_env(:mstr, :sspotify_req_options, []), auth_opt)

    case Req.get(uri, req_opts) do
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
