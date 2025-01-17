defmodule Mstr.SpotifyClient.Track do
  alias Mstr.SpotifyClient.Artist
  alias Mstr.SpotifyClient.Album
  import Mstr.SpotifyClient.Helpers

  @type external_id_type :: :isrc | :ean | :upc
  @type external_ids :: %{optional(external_id_type) => String.t()}

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          duration_ms: integer(),
          explicit: boolean(),
          external_ids: external_ids(),
          external_urls: map(),
          href: String.t(),
          is_local: boolean(),
          is_playable: boolean(),
          preview_url: String.t() | nil,
          uri: String.t(),
          album: Album.t(),
          artists: list(Artist.t()),
          available_markets: list(String.t()),
          disc_number: integer(),
          popularity: integer(),
          restrictions: map() | nil,
          track_number: integer(),
          type: String.t(),
          linked_from: map() | nil
        }

  @enforce_keys [:id, :name]
  defstruct [
    :id,
    :name,
    :duration_ms,
    :explicit,
    :external_ids,
    :external_urls,
    :href,
    :is_local,
    :is_playable,
    :preview_url,
    :uri,
    :album,
    :artists,
    :available_markets,
    :disc_number,
    :popularity,
    :restrictions,
    :track_number,
    :type,
    :linked_from
  ]

  def from_json(json) when is_map(json) do
    %__MODULE__{
      id: json["id"],
      name: json["name"],
      duration_ms: json["duration_ms"],
      explicit: json["explicit"],
      external_ids: parse_external_ids(json["external_ids"]),
      external_urls: json["external_urls"],
      href: json["href"],
      is_local: json["is_local"],
      is_playable: json["is_playable"],
      preview_url: json["preview_url"],
      uri: json["uri"],
      album: json["album"] && Album.from_json(json["album"]),
      artists: map_if_present(json["artists"], &Artist.from_json/1),
      available_markets: json["available_markets"],
      disc_number: json["disc_number"],
      popularity: json["popularity"],
      restrictions: json["restrictions"],
      track_number: json["track_number"],
      type: json["type"],
      linked_from: json["linked_from"]
    }
  end

  @doc """
  Returns the duration of the track in seconds.
  """
  def duration_in_seconds(%__MODULE__{duration_ms: duration_ms}) when is_integer(duration_ms) do
    duration_ms / 1000
  end

  @doc """
  Returns a formatted duration string in the format MM:SS
  """
  def formatted_duration(%__MODULE__{duration_ms: duration_ms}) when is_integer(duration_ms) do
    total_seconds = floor(duration_ms / 1000)
    minutes = floor(total_seconds / 60)
    seconds = rem(total_seconds, 60)

    :io_lib.format("~2..0B:~2..0B", [minutes, seconds])
    |> to_string()
  end

  @doc """
  Returns the main artist name of the track
  """
  def main_artist(%__MODULE__{artists: [first_artist | _]}) do
    first_artist.name
  end

  def main_artist(_), do: nil

  @doc """
  Returns all artist names joined by commas
  """
  def artist_names(%__MODULE__{artists: artists}) when is_list(artists) do
    artists
    |> Enum.map(& &1.name)
    |> Enum.join(", ")
  end

  def artist_names(_), do: ""

  @doc """
  Returns true if the track has a preview URL available
  """
  def has_preview?(%__MODULE__{preview_url: url}), do: !is_nil(url)

  def parse_external_ids(nil), do: %{}

  def parse_external_ids(external_ids) when is_map(external_ids) do
    external_ids
    |> Enum.map(fn {key, value} -> {String.to_existing_atom(key), value} end)
    |> Map.new()
  rescue
    # In case of unknown external ID types
    ArgumentError -> %{}
  end

  @doc """
  Gets the ISRC (International Standard Recording Code) if available.
  """
  def isrc(%__MODULE__{external_ids: external_ids}) do
    external_ids[:isrc]
  end

  @doc """
  Gets a specific external ID by type.
  """
  def external_id(%__MODULE__{external_ids: external_ids}, type) when is_atom(type) do
    external_ids[type]
  end
end
