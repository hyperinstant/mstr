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

    if urls == validated_urls.valid do
      ids = Enum.map(urls, &extract_track_id!/1)

      with {:ok, track_maps} <- ApiClient.tracks(ids) do
        {:ok, split_found_and_missing_tracks(urls, ids, track_maps)}
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

  def extract_track_id!(url) do
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

  # When fetching multiple tracks from Spotify, the API doesn't indicate which specific IDs weren't found.
  # Instead, it just returns data for tracks it could find. To identify which URLs resulted in missing tracks:
  # 1. We start with user-provided URLs and their extracted IDs
  # 2. We receive track data only for found tracks from Spotify
  # 3. We need to match IDs back to original URLs to identify which URLs led to missing tracks
  #
  # Returns a map with:
  # - found: List of parsed Track structs from successful Spotify lookups
  # - missing: List of original URLs that didn't yield Spotify tracks
  defp split_found_and_missing_tracks(urls, ids, track_maps) do
    Enum.reduce(ids, %{found: [], missing: []}, fn id, acc ->
      track_map = Enum.find(track_maps, &(&1["id"] == id))

      if track_map do
        %{acc | found: acc.found ++ [Track.from_json(track_map)]}
      else
        %{acc | missing: acc.missing ++ [Enum.find(urls, &(extract_track_id!(&1) == id))]}
      end
    end)
  end
end
