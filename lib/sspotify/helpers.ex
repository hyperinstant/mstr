defmodule SSpotify.Helpers do
  # Helper functions
  def map_if_present(nil, _fun), do: nil
  def map_if_present(list, fun) when is_list(list), do: Enum.map(list, fun)

  # https://developer.spotify.com/documentation/web-api/concepts/spotify-uris-ids
  def valid_base62_id?(<<id::binary-size(22)>>) do
    String.match?(id, ~r/^[0-9A-Za-z]+$/)
  end

  def valid_base62_id?(_), do: false
end
