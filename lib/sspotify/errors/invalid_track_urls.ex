defmodule SSpotify.Errors.InvalidTrackURLs do
  defstruct [:urls]

  def new(urls) when is_list(urls) do
    %__MODULE__{
      urls: urls
    }
  end
end
