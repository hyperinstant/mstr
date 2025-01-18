defmodule SSpotify.Fixtures do
  alias SSpotify.Track

  def track!(id) do
    id
    |> track_json!()
    |> Track.from_json()
  end

  def track_json!(id) do
    "test/support/fixtures/tracks_json/#{id}.json"
    |> File.read!()
    |> JSON.decode!()
  end
end
