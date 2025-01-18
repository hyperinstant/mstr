defmodule SSpotify.Errors.InvalidTrackURL do
  defstruct [:url]

  def new(urls) do
    %__MODULE__{
      url: urls
    }
  end
end
