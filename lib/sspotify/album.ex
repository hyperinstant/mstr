defmodule Mstr.SpotifyClient.Album do
  import Mstr.SpotifyClient.Helpers
  alias Mstr.SpotifyClient.Artist
  alias Mstr.SpotifyClient.Image

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          album_type: String.t(),
          artists: list(Artist.t()),
          available_markets: list(String.t()),
          external_urls: map(),
          href: String.t(),
          images: list(Image.t()),
          release_date: String.t(),
          release_date_precision: String.t(),
          restrictions: map() | nil,
          total_tracks: integer(),
          type: String.t(),
          uri: String.t()
        }

  @enforce_keys [:id, :name]
  defstruct [
    :id,
    :name,
    :album_type,
    :artists,
    :available_markets,
    :external_urls,
    :href,
    :images,
    :release_date,
    :release_date_precision,
    :restrictions,
    :total_tracks,
    :type,
    :uri
  ]

  def from_json(json) when is_map(json) do
    %__MODULE__{
      id: json["id"],
      name: json["name"],
      album_type: json["album_type"],
      artists: map_if_present(json["artists"], &Artist.from_json/1),
      available_markets: json["available_markets"],
      external_urls: json["external_urls"],
      href: json["href"],
      images: map_if_present(json["images"], &Image.from_json/1),
      release_date: json["release_date"],
      release_date_precision: json["release_date_precision"],
      restrictions: json["restrictions"],
      total_tracks: json["total_tracks"],
      type: json["type"],
      uri: json["uri"]
    }
  end
end
