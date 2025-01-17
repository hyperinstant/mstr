defmodule Mstr.SpotifyClient.Image do
  @type t :: %__MODULE__{
          url: String.t(),
          height: integer(),
          width: integer()
        }

  defstruct [:url, :height, :width]

  def from_json(json) when is_map(json) do
    %__MODULE__{
      url: json["url"],
      height: json["height"],
      width: json["width"]
    }
  end
end
