defmodule SSpotify do
  alias SSpotify.Helpers
  alias SSpotify.ApiClient
  alias SSpotify.Track
  alias SSpotify.Errors.InvalidTrackURL
  alias SSpotify.Errors.InvalidTrackURLs

  def track_from(url) when is_binary(url) do
    with {:ok, track_id} <- extract_track_id(url),
         {:ok, track_map} <- ApiClient.track(track_id) do
      Track.from_json(track_map)
    end
  end

  def tracks_from(urls) when is_list(urls) do
    validated_urls = validate_urls(urls)

    if validated_urls.valid == urls do
      ids = Enum.map(urls, &extract_track_id!/1)

      with {:ok, tracks_map} <- ApiClient.tracks(ids) do
        {:ok, Enum.map(tracks_map, &Track.from_json/1)}
      end
    else
      {:error, InvalidTrackURLs.new(validated_urls.invalid)}
    end
  end

  defp validate_urls(urls) do
    Enum.reduce(urls, %{valid: [], invalid: []}, fn url, acc ->
      if valid_track_url?(url) do
        %{acc | valid: acc.valid ++ [url]}
      else
        %{acc | invalid: acc.invalid ++ [url]}
      end
    end)
  end

  def valid_track_url?(url) do
    case extract_track_id(url) do
      {:ok, _} -> true
      _ -> false
    end
  end

  defp extract_track_id!(url) do
    {:ok, id} = extract_track_id(url)
    id
  end

  defp extract_track_id(url) do
    with true <- String.starts_with?(url, "https://open.spotify.com/track/"),
         %{path: "/track/" <> track_id} <- URI.parse(url),
         true <- Helpers.valid_base62_id?(track_id) do
      {:ok, track_id}
    else
      _ ->
        {:error, InvalidTrackURL.new(url)}
    end
  end
end
