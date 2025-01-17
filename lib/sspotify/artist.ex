defmodule Mstr.SpotifyClient.Artist do
  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          external_urls: map(),
          href: String.t(),
          type: String.t(),
          uri: String.t()
        }

  @enforce_keys [:id, :name]
  defstruct [
    :id,
    :name,
    :external_urls,
    :href,
    :type,
    :uri
  ]

  def from_json(json) when is_map(json) do
    %__MODULE__{
      id: json["id"],
      name: json["name"],
      external_urls: json["external_urls"],
      href: json["href"],
      type: json["type"],
      uri: json["uri"]
    }
  end
end
