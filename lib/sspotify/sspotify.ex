defmodule SSpotify do
  alias SSpotify.ApiClient
  alias SSpotify.Track

  def track_from(url) when is_binary(url) do
    with {:ok, track_id} <- extract_track_id(url),
         {:ok, track_map} <- ApiClient.track(track_id) do
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
end
