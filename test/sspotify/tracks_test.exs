defmodule SSpotify.TracksTest do
  use ExUnit.Case, async: true
  alias SSpotify
  alias SSpotify.Errors.InvalidTrackURLs

  describe "SSpotify.tracks/1" do
    test "returns Error.InvalidTracks when url does not start with https://open.spotify.com/track/" do
      urls = ["an invalid url"]
      assert {:error, %InvalidTrackURLs{urls: urls}} == SSpotify.tracks_from(urls)
    end

    test "returns Error.InvalidTracks when url does not have a valid track id" do
      urls = ["https://open.spotify.com/track/an-invalid-id"]
      assert {:error, %InvalidTrackURLs{urls: urls}} == SSpotify.tracks_from(urls)
    end

    test "returns Error.InvalidTracks with all track when all tracks are invalid (wrong url)" do
      urls = ["an invalid url 1", "an invalid url 2", "an invalid url 3"]
      assert {:error, %InvalidTrackURLs{urls: urls}} == SSpotify.tracks_from(urls)
    end

    test "returns Error.InvalidTracks with multiple invalid track when some of them are invalid (wrong url)" do
      invalid_url_1 = "an invalid url 1"
      invalid_url_2 = "an invalid url 2"

      urls = [
        invalid_url_1,
        "https://open.spotify.com/track/4xeOXTjSNsyF4djgo83SiR?si=0dd7da796ab14cd2",
        invalid_url_2
      ]

      assert {:error, %InvalidTrackURLs{urls: [invalid_url_1, invalid_url_2]}} == SSpotify.tracks_from(urls)
    end

    test "returns Tracks for each resolved track" do
      id1 = "33qPnmgyN1aRVLQfbic2Sq"
      id2 = "4xeOXTjSNsyF4djgo83SiR"
      id3 = "5y3mB1q4eauAdC0o9JgLGz"

      defmodule FakeAPIClient do
        def request_token!("a client id", "a client secret") do
          %{"access_token" => "a token", "expires_in" => 3600}
        end
      end

      start_supervised!(
        {SSpotify.TokenManager,
         %{client_id: "a client id", client_secret: "a client secret", api_client: FakeAPIClient}}
      )

      Req.Test.stub(SSpotify.ApiClient, fn conn ->
        Req.Test.json(conn, %{"tracks" => Enum.map([id1, id2, id3], &SSpotify.Fixtures.track_json!/1)})
      end)

      assert {:ok, Enum.map([id1, id2, id3], &SSpotify.Fixtures.track!/1)} ==
               SSpotify.tracks_from([
                 "https://open.spotify.com/track/#{id1}?si=462304c8a05c4d39",
                 "https://open.spotify.com/track/#{id2}?si=0dd7da796ab14cd2",
                 "https://open.spotify.com/track/#{id3}?si=16f565fbc24249f7"
               ])
    end
  end
end
