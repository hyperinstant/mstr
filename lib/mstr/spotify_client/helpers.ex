defmodule Mstr.SpotifyClient.Helpers do
  # Helper functions
  def map_if_present(nil, _fun), do: nil
  def map_if_present(list, fun) when is_list(list), do: Enum.map(list, fun)
end
